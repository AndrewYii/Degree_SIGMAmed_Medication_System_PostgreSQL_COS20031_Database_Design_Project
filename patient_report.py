import medspacy
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import date
from db_config import DBConfig

class Extract_keyword:
    def __init__(self):
        # Load MedSpaCy pipeline (pre-trained)
        self.nlp = medspacy.load("en_core_sci_sm-0.5.0", disable=["parser"])
        self.sentencizer = self.nlp.get_pipe("medspacy_pyrush")
        self.context = self.nlp.get_pipe("medspacy_context")
        self.matcher = self.nlp.get_pipe("medspacy_target_matcher")

        try:
            DBConfig.validate()
            self.conn = psycopg2.connect(**DBConfig.get_connection_params())
            self.conn.autocommit = False
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            self.schema = DBConfig.SCHEMA
            print(f"✓ Connected to database: {DBConfig.NAME}")
            print(f"✓ Using schema: {self.schema}")
        except Exception as e:
            print(f"✗ Failed to connect to database: {e}")
            raise

    # Fetch a single report by ID
    def fetch_single_report(self, report_id):
        query = f"""
            SELECT "PatientReportID", "PrescribedMedicationId", "Description",
                   "Type", "Severity", "PatientId"
            FROM "{self.schema}"."PatientReport"
            WHERE "PatientReportID" = %s
              AND "IsDeleted" = FALSE
              AND "IsProcessed" = FALSE
        """
        self.cursor.execute(query, (report_id,))
        return self.cursor.fetchone()

    # Fully dynamic extraction
    def extract_medical_keywords(self, text):
        doc = self.nlp(text)
        results = set()

        for ent in doc.ents:
            # Skip negated entities
            if hasattr(ent._, "context") and ent._.context.is_negated:
                continue
            results.add(ent.text.strip())

            # Optional debug:
            print(f"[DEBUG] Found entity: {ent.text}, label: {ent.label_}, negated? {getattr(ent._, 'context', None) and ent._.context.is_negated}")

        return results

    # Insert side effects
    def insert_side_effect(self, prescribedMedication_id, sideEffects, severity):
        for effect in sideEffects:
            self.cursor.execute(f"""
                INSERT INTO "{self.schema}"."PatientSideEffect"(
                    "PrescribedMedicationID", "SideEffectName", "Severity", "OnsetDate"
                ) VALUES (%s, %s, %s, %s)
                ON CONFLICT ("PrescribedMedicationID", "SideEffectName") DO NOTHING
            """, (prescribedMedication_id, effect, severity, date.today()))

    # Insert symptoms
    def insert_symptom(self, patient_id, symptoms, severity):
        for symptom in symptoms:
            self.cursor.execute(f"""
                INSERT INTO "{self.schema}"."PatientSymptom"(
                    "PatientId", "SymptomName", "Severity"
                ) VALUES (%s, %s, %s)
            """, (patient_id, symptom, severity))

    # Mark report as processed
    def mark_processed(self, report_id):
        self.cursor.execute(f"""
            UPDATE "{self.schema}"."PatientReport"
            SET "IsProcessed" = TRUE
            WHERE "PatientReportID" = %s
        """, (report_id,))

    # Process a single report
    def process_single_report(self, report_id):
        report = self.fetch_single_report(report_id)
        if not report:
            print(f"[SKIP] Report {report_id} already processed or not found.")
            return

        keywords = self.extract_medical_keywords(report["Description"])
        print(f"[DEBUG] Extracted keywords: {keywords}")

        if report["Type"] == "SideEffect":
            self.insert_side_effect(report["PrescribedMedicationId"], keywords, report["Severity"])
        elif report["Type"] == "Symptom":
            self.insert_symptom(report["PatientId"], keywords, report["Severity"])

        self.mark_processed(report_id)
        self.conn.commit()
        print(f"[DONE] Processed report {report_id}")

    def close(self):
        self.cursor.close()
        self.conn.close()
