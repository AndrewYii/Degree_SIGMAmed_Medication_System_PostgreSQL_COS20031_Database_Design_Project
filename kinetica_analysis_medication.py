import argparse
import json
import os
import uuid
from datetime import datetime, date, time

import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
from gpudb import GPUdb

from db_config import DBConfig

load_dotenv()


class KineticaConfig:
    HOST = os.getenv("KINETICA_HOST", "https://cluster1450.saas.kinetica.com/cluster1450/gpudb-0")
    PORT = int(os.getenv("KINETICA_PORT", "443"))
    USERNAME = os.getenv("KINETICA_USERNAME", "andrewyii0801_gmail")
    PASSWORD = os.getenv("KINETICA_PASSWORD", "ABc@328022")
    SCHEMA = os.getenv("KINETICA_SCHEMA", "sigma_med")
    USE_TLS = os.getenv("KINETICA_USE_TLS", "false").lower() == "true"

    @classmethod
    def validate(cls):
        if not cls.PASSWORD:
            raise ValueError("KINETICA_PASSWORD is not set in .env")
        return True


def connect_pg():
    DBConfig.validate()
    return psycopg2.connect(**DBConfig.get_connection_params())


def connect_kinetica():
    KineticaConfig.validate()
    for var in ("HTTPS_PROXY", "https_proxy", "HTTP_PROXY", "http_proxy"):
        os.environ.pop(var, None)
    os.environ["NO_PROXY"] = "cluster1450.saas.kinetica.com"
    host = KineticaConfig.HOST
    # GPUdb toggles TLS via the URL schema, not a use_ssl flag
    if not host.lower().startswith(("http://", "https://")):
        host = ("https://" if KineticaConfig.USE_TLS else "http://") + host
    return GPUdb(
        host=host,
        port=KineticaConfig.PORT,
        username=KineticaConfig.USERNAME,
        password=KineticaConfig.PASSWORD,
    )


def run_sql(db: GPUdb, statements):
    """Execute one or many SQL statements against Kinetica."""
    if isinstance(statements, str):
        statements = [statements]
    for stmt in statements:
        db.execute_sql(stmt)


def qualify(name: str) -> str:
    schema = (KineticaConfig.SCHEMA or "").strip()
    return f"{schema}.{name}" if schema else name


def drop_tables(db: GPUdb):
    """Drop analysis tables if they exist (fresh rebuild)."""
    for tbl in [
        "medication_features",
        "side_effects_by_medication",
        "side_effects_by_patient",
        "top_side_effects",
    ]:
        try:
            db.execute_sql(f"DROP TABLE IF EXISTS {qualify(tbl)};")
            print(f"Dropped {qualify(tbl)}")
        except Exception as exc:
            print(f"Drop failed for {qualify(tbl)}: {exc}")


def ensure_tables(db: GPUdb):
    """Create analysis tables if missing."""
    schema = KineticaConfig.SCHEMA
    ddl = [
        f'CREATE SCHEMA IF NOT EXISTS {schema};' if schema else None,
        f"""
        CREATE TABLE IF NOT EXISTS {qualify("medication_features")} (
            prescribed_medication_id STRING PRIMARY KEY,
            prescription_id STRING,
            patient_id STRING,
            doctor_id STRING,
            medication_id STRING,
            dosage_amount DOUBLE,
            dose_per_time DOUBLE,
            times_per_day INT,
            prescribed_date STRING,
            prescription_status STRING,
            medication_status STRING,
            days_since_prev DOUBLE
        );
        """,
        f"""
        CREATE TABLE IF NOT EXISTS {qualify("side_effects_by_medication")} (
            medication_id STRING,
            medication_name STRING,
            side_effect_name STRING,
            severity STRING,
            report_count LONG,
            patient_count LONG,
            last_reported STRING
        );
        """,
        f"""
        CREATE TABLE IF NOT EXISTS {qualify("side_effects_by_patient")} (
            patient_id STRING,
            patient_name STRING,
            patient_username STRING,
            report_count LONG,
            unique_side_effects LONG,
            last_reported STRING,
            medications STRING
        );
        """,
        f"""
        CREATE TABLE IF NOT EXISTS {qualify("top_side_effects")} (
            side_effect_name STRING,
            total_reports LONG,
            top_medication STRING,
            top_medication_report_count LONG
        );
        """,
    ]
    run_sql(db, [stmt for stmt in ddl if stmt])


def fetch_features(pg_conn, limit=50):
    """
    Pull a feature set from Postgres. Features include a lookback to previous rows
    (days_since_prev) per patient+medication.
    """
    def normalize_feature_row(row):
        """Coerce DB types (UUID/Decimal/date) into Kinetica-friendly primitives."""
        def to_str(val):
            return str(val) if val is not None else ""

        out = {
            "prescribed_medication_id": to_str(row.get("prescribed_medication_id")),
            "prescription_id": to_str(row.get("prescription_id")),
            "patient_id": to_str(row.get("patient_id")),
            "doctor_id": to_str(row.get("doctor_id")),
            "medication_id": to_str(row.get("medication_id")),
            "prescription_status": to_str(row.get("prescription_status")),
            "medication_status": to_str(row.get("medication_status")),
        }

        # Numeric fields
        for key in ("dosage_amount", "dose_per_time", "days_since_prev"):
            val = row.get(key)
            try:
                out[key] = float(val) if val is not None else 0.0
            except Exception:
                out[key] = 0.0

        try:
            out["times_per_day"] = int(row.get("times_per_day") or 0)
        except Exception:
            out["times_per_day"] = 0

        dt = row.get("prescribed_date")
        if isinstance(dt, datetime):
            out["prescribed_date"] = dt.isoformat()
        elif isinstance(dt, date):
            out["prescribed_date"] = datetime.combine(dt, time()).isoformat()
        else:
            out["prescribed_date"] = str(dt) if dt else ""
        return out

    schema = DBConfig.SCHEMA
    sql = f"""
    SELECT
        pm."PrescribedMedicationId" AS prescribed_medication_id,
        pm."PrescriptionId" AS prescription_id,
        p."PatientId" AS patient_id,
        p."DoctorId" AS doctor_id,
        pm."MedicationId" AS medication_id,
        pm."DosageAmountPrescribed" AS dosage_amount,
        pm."DosePerTime" AS dose_per_time,
        pm."TimesPerDay" AS times_per_day,
        pm."PrescribedDate" AS prescribed_date,
        p."Status" AS prescription_status,
        pm."Status" AS medication_status,
        EXTRACT(EPOCH FROM (
            pm."PrescribedDate"::timestamp - LAG(pm."PrescribedDate") OVER (
                PARTITION BY p."PatientId", pm."MedicationId"
                ORDER BY pm."PrescribedDate"
            )::timestamp
        )) / 86400.0 AS days_since_prev
    FROM "{schema}"."PrescribedMedication" pm
    JOIN "{schema}"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
    WHERE p."IsDeleted" = FALSE AND pm."IsDeleted" = FALSE
    ORDER BY pm."PrescribedDate" DESC
    """
    if limit:
        sql += f" LIMIT {int(limit)}"
    with pg_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    return [normalize_feature_row(r) for r in rows]


def fetch_side_effects_by_med(pg_conn):
    schema = DBConfig.SCHEMA
    sql = f"""
    SELECT
        pm."MedicationId" AS medication_id,
        pm."MedicationNameSnapshot" AS medication_name,
        se."SideEffectName" AS side_effect_name,
        se."Severity" AS severity,
        COUNT(*) AS report_count,
        COUNT(DISTINCT pr."PatientId") AS patient_count,
        MAX(se."OnsetDate") AS last_reported
    FROM "{schema}"."PatientSideEffect" se
    JOIN "{schema}"."PrescribedMedication" pm ON se."PrescribedMedicationID" = pm."PrescribedMedicationId"
    JOIN "{schema}"."Prescription" pr ON pm."PrescriptionId" = pr."PrescriptionId"
    WHERE se."IsDeleted" = FALSE AND pm."IsDeleted" = FALSE AND pr."IsDeleted" = FALSE
    GROUP BY pm."MedicationId", pm."MedicationNameSnapshot", se."SideEffectName", se."Severity"
    ORDER BY report_count DESC;
    """
    with pg_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    out = []
    for r in rows:
        out.append(
            {
                "medication_id": str(r.get("medication_id") or ""),
                "medication_name": r.get("medication_name") or "",
                "side_effect_name": r.get("side_effect_name") or "",
                "severity": r.get("severity") or "",
                "report_count": int(r.get("report_count") or 0),
                "patient_count": int(r.get("patient_count") or 0),
                "last_reported": (r.get("last_reported") or ""),
            }
        )
    return out


def fetch_side_effects_by_patient(pg_conn):
    schema = DBConfig.SCHEMA
    sql = f"""
    SELECT
        pr."PatientId" AS patient_id,
        CONCAT(u."FirstName", ' ', u."LastName") AS patient_name,
        u."Username" AS patient_username,
        COUNT(*) AS report_count,
        COUNT(DISTINCT se."SideEffectName") AS unique_side_effects,
        MAX(se."OnsetDate") AS last_reported,
        STRING_AGG(DISTINCT pm."MedicationNameSnapshot", ', ' ORDER BY pm."MedicationNameSnapshot") AS medications
    FROM "{schema}"."PatientSideEffect" se
    JOIN "{schema}"."PrescribedMedication" pm ON se."PrescribedMedicationID" = pm."PrescribedMedicationId"
    JOIN "{schema}"."Prescription" pr ON pm."PrescriptionId" = pr."PrescriptionId"
    JOIN "{schema}"."User" u ON pr."PatientId" = u."UserId"
        WHERE se."IsDeleted" = FALSE AND pm."IsDeleted" = FALSE AND pr."IsDeleted" = FALSE
    GROUP BY pr."PatientId", u."FirstName", u."LastName", u."Username"
    ORDER BY report_count DESC;
    """
    with pg_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    out = []
    for r in rows:
        out.append(
            {
                "patient_id": str(r.get("patient_id") or ""),
                "patient_name": r.get("patient_name") or "",
                "patient_username": r.get("patient_username") or "",
                "report_count": int(r.get("report_count") or 0),
                "unique_side_effects": int(r.get("unique_side_effects") or 0),
                "last_reported": (r.get("last_reported") or ""),
                "medications": r.get("medications") or "",
            }
        )
    return out


def fetch_top_side_effects(pg_conn):
    schema = DBConfig.SCHEMA
    sql = f"""
    WITH counted AS (
        SELECT
            se."SideEffectName" AS side_effect_name,
            pm."MedicationNameSnapshot" AS medication_name,
            COUNT(*) AS cnt
        FROM "{schema}"."PatientSideEffect" se
        JOIN "{schema}"."PrescribedMedication" pm ON se."PrescribedMedicationID" = pm."PrescribedMedicationId"
        JOIN "{schema}"."Prescription" pr ON pm."PrescriptionId" = pr."PrescriptionId"
        WHERE se."IsDeleted" = FALSE AND pm."IsDeleted" = FALSE AND pr."IsDeleted" = FALSE
        GROUP BY se."SideEffectName", pm."MedicationNameSnapshot"
    ),
    ranked AS (
        SELECT
            side_effect_name,
            medication_name,
            cnt,
            SUM(cnt) OVER (PARTITION BY side_effect_name) AS total_reports,
            ROW_NUMBER() OVER (PARTITION BY side_effect_name ORDER BY cnt DESC, medication_name) AS rn
        FROM counted
    )
    SELECT
        side_effect_name,
        total_reports,
        medication_name AS top_medication,
        cnt AS top_medication_report_count
    FROM ranked
    WHERE rn = 1
    ORDER BY total_reports DESC;
    """
    with pg_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    out = []
    for r in rows:
        out.append(
            {
                "side_effect_name": r.get("side_effect_name") or "",
                "total_reports": int(r.get("total_reports") or 0),
                "top_medication": r.get("top_medication") or "",
                "top_medication_report_count": int(r.get("top_medication_report_count") or 0),
            }
        )
    return out


def push_features(db: GPUdb, features):
    if not features:
        return 0
    columns = [
        "prescribed_medication_id",
        "prescription_id",
        "patient_id",
        "doctor_id",
        "medication_id",
        "dosage_amount",
        "dose_per_time",
        "times_per_day",
        "prescribed_date",
        "prescription_status",
        "medication_status",
        "days_since_prev",
    ]
    return bulk_insert_sql(db, qualify("medication_features"), columns, features)


def score_row(row):
    """
    Simple placeholder scoring function. Replace with your ML model or
    Kinetica ML_PREDICT when available.
    """
    base = 0.2
    dose_factor = float(row.get("dose_per_time") or 0) * 0.05
    freq_factor = float(row.get("times_per_day") or 0) * 0.03
    gap_penalty = -0.01 * max(float(row.get("days_since_prev") or 0), 0)
    score = base + dose_factor + freq_factor + gap_penalty
    return max(0.0, min(1.0, score))


def build_prediction_rows(features):
    now = datetime.utcnow().isoformat()
    rows = []
    for row in features:
        score = score_row(row)
        rows.append(
            {
                "prediction_id": str(uuid.uuid4()),
                "prescribed_medication_id": row["prescribed_medication_id"],
                "patient_id": row["patient_id"],
                "medication_id": row["medication_id"],
                "predicted_score": score,
                "reason": "rule_based_v0",
                "predicted_at": now,
                "features_json": json.dumps(row),
            }
        )
    return rows


def push_predictions(db: GPUdb, prediction_rows):
    if not prediction_rows:
        return 0
    # Predictions are not used in this analysis pipeline; kept as a stub
    return 0


def push_side_effects_by_med(db: GPUdb, rows):
    columns = [
        "medication_id",
        "medication_name",
        "side_effect_name",
        "severity",
        "report_count",
        "patient_count",
        "last_reported",
    ]
    # Clear existing summary
    db.execute_sql(f"DELETE FROM {qualify('side_effects_by_medication')};")
    return bulk_insert_sql(db, qualify("side_effects_by_medication"), columns, rows)


def push_side_effects_by_patient(db: GPUdb, rows):
    columns = [
        "patient_id",
        "patient_name",
        "patient_username",
        "report_count",
        "unique_side_effects",
        "last_reported",
        "medications",
    ]
    db.execute_sql(f"DELETE FROM {qualify('side_effects_by_patient')};")
    return bulk_insert_sql(db, qualify("side_effects_by_patient"), columns, rows)


def push_top_side_effects(db: GPUdb, rows):
    columns = [
        "side_effect_name",
        "total_reports",
        "top_medication",
        "top_medication_report_count",
    ]
    db.execute_sql(f"DELETE FROM {qualify('top_side_effects')};")
    return bulk_insert_sql(db, qualify("top_side_effects"), columns, rows)


def bulk_insert_sql(db: GPUdb, table: str, columns: list[str], rows: list[dict]):
    """Insert rows via SQL VALUES."""
    if not rows:
        return 0
    col_sql = ",".join(columns)

    def esc(val):
        if val is None:
            return ""
        return str(val).replace("'", "''")

    batch_size = 100
    total = 0
    for i in range(0, len(rows), batch_size):
        chunk = rows[i : i + batch_size]
        values_sql = []
        for r in chunk:
            vals = []
            for c in columns:
                v = r.get(c)
                if isinstance(v, (int, float)):
                    vals.append(str(v))
                else:
                    vals.append(f"'{esc(v)}'")
            values_sql.append(f"({','.join(vals)})")
        sql = f"INSERT INTO {table} ({col_sql}) VALUES " + ",".join(values_sql) + ";"
        db.execute_sql(sql)
        total += len(chunk)
    return total


def main(limit=None):
    with connect_pg() as pg_conn:
        kin = connect_kinetica()
        drop_tables(kin)
        ensure_tables(kin)

        features = fetch_features(pg_conn, limit=limit)
        inserted = push_features(kin, features)

        med_rows = fetch_side_effects_by_med(pg_conn)
        patient_rows = fetch_side_effects_by_patient(pg_conn)
        top_rows = fetch_top_side_effects(pg_conn)

        med_written = push_side_effects_by_med(kin, med_rows)
        patient_written = push_side_effects_by_patient(kin, patient_rows)
        top_written = push_top_side_effects(kin, top_rows)

        print(
            f"Pushed {inserted} feature rows; "
            f"{med_written} med-side-effect rows; "
            f"{patient_written} patient-side-effect rows; "
            f"{top_written} top-side-effect rows into Kinetica."
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build Kinetica side-effect analytics tables.")
    parser.add_argument("--limit", type=int, default=None, help="Limit rows pulled from Postgres for testing.")
    args = parser.parse_args()
    main(limit=args.limit)
