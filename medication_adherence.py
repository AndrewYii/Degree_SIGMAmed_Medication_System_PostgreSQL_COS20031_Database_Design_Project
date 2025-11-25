import argparse
import os
from datetime import datetime, timedelta
from typing import List, Dict, Any
from collections import defaultdict, deque
import numpy as np
from psycopg2.extras import RealDictCursor
import psycopg2
import uuid
import pandas as pd
from dotenv import load_dotenv
from db_config import DBConfig

# Kinetica library
try:
    import gpudb
except ImportError:
    print("Warning: 'gpudb' library not found. Kinetica connection will be mocked.")
    class GPUdb:
        def __init__(self, **kwargs):
            pass
        def execute_sql(self, sql):
            pass
        def close(self):
            pass
    gpudb = type('MockGPUdb', (), {'GPUdb': GPUdb})()

load_dotenv()

# --- Sliding Window ---
class SlidingWindowComplianceTracker:
    """
    Optimized O(N) sliding window implementation for tracking medication compliance
    Uses deque for efficient window management
    """
    def __init__(self, window_days: int = 90, violation_threshold: int = 6):
        self.window_days = window_days
        self.violation_threshold = violation_threshold
        self.patient_windows = defaultdict(lambda: deque())
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
        
    def add_violation(self, patient_id: str, medication_id: str, violation_date: datetime):
        """Add a violation and maintain sliding window"""
        key = (patient_id, medication_id)
        current_date = violation_date.date()
        
        # Remove violations outside the window
        window = self.patient_windows[key]
        while window and (current_date - window[0]).days > self.window_days:
            window.popleft()
        
        # Add new violation
        window.append(current_date)
        
        return len(window) >= self.violation_threshold, len(window)

# --- Medication Compliance Analyzer ---
class MedicationComplianceAnalyzer:
    def __init__(self):
        try:
            DBConfig.validate()
            self.conn = psycopg2.connect(**DBConfig.get_connection_params())
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            self.db_schema = DBConfig.SCHEMA
            print(f"✓ Analyzer connected to database: {DBConfig.NAME}")
        except Exception as e:
            print(f"✗ Analyzer failed to connect to database: {e}")
            raise
            
        self.window_size_days = 90
        self.violation_threshold = 6
        
        # Compliance thresholds
        self.overdose_threshold = 1.3
        self.underdose_threshold = 0.7
        self.missed_threshold_ratio = 0.01
        
    def load_medication_data(self, lookback_days: int = 120) -> pd.DataFrame:
        """
        Load medication adherence data with optimized query
        """
        query = f"""
        SELECT 
            pr."PatientId",
            pm."PrescribedMedicationId",
            pm."MedicationNameSnapshot",
            CAST(pm."DosePerTime" AS NUMERIC) AS "DosePerTime",
            pm."TimesPerDay",
            mar."DoseQuantity",
            mar."ScheduledTime",
            mar."CurrentStatus",
            mar."ActionTime"
        FROM "{self.db_schema}"."MedicationAdherenceRecord" mar
        JOIN "{self.db_schema}"."PrescribedMedicationSchedule" pms 
            ON mar."PrescribedMedicationScheduleId" = pms."PrescribedMedicationScheduleId"
        JOIN "{self.db_schema}"."PrescribedMedication" pm 
            ON pms."PrescribedMedicationId" = pm."PrescribedMedicationId"
        JOIN "{self.db_schema}"."Prescription" pr 
            ON pm."PrescriptionId" = pr."PrescriptionId"
        WHERE 
            mar."ScheduledTime" >= NOW() - INTERVAL '{lookback_days} days'
            AND mar."CurrentStatus" IN ('Taken', 'Missed')
            AND pr."Status" = 'active'
            AND pm."Status" = 'active'
        ORDER BY 
            pr."PatientId", pm."PrescribedMedicationId", mar."ScheduledTime";
        """
        
        # Suppress pandas warning about psycopg2 connection
        import warnings
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            df = pd.read_sql(query, self.conn)
        
        if not df.empty:
            df['ScheduledTime'] = pd.to_datetime(df['ScheduledTime'])
            df['ScheduledDate'] = df['ScheduledTime'].dt.date
            
        return df
    
    def detect_violations(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Detect violations per intake event
        """
        if df.empty:
            return pd.DataFrame()

        violations_df = df.copy()
        violations_df['ExpectedDosePerIntake'] = violations_df['DosePerTime']
        violations_df['ActualDosePerIntake'] = violations_df['DoseQuantity']
        
        # Handle division by zero and missing doses
        mask = violations_df['ExpectedDosePerIntake'] > 0
        violations_df['DeviationRatio'] = 0.0 
        violations_df.loc[mask, 'DeviationRatio'] = (
            violations_df.loc[mask, 'ActualDosePerIntake'] / 
            violations_df.loc[mask, 'ExpectedDosePerIntake']
        )

        # Detect violation types and classifies
        conditions = [
            # Priority 1: Missed doses (status = Missed OR dose = 0)
            (violations_df['CurrentStatus'] == 'Missed') | (violations_df['ActualDosePerIntake'] <= 0),
            # Priority 2: Overdose (only if not missed)
            (violations_df['DeviationRatio'] >= 1.3) & (violations_df['CurrentStatus'] != 'Missed'),
            # Priority 3: Underdose (only if not missed and not overdose)
            (violations_df['DeviationRatio'] < 0.7) & (violations_df['DeviationRatio'] > 0) & (violations_df['CurrentStatus'] != 'Missed')
        ]
        
        choices = ['missed', 'overdose', 'underdose']
        violations_df['violation_type'] = np.select(conditions, choices, default=None)
        violations_df['is_violation'] = violations_df['violation_type'].notna()

        return violations_df[violations_df['is_violation'] == True]
    
    def apply_sliding_window_optimized(self, violations_df: pd.DataFrame) -> List[Dict[str, Any]]:
        """
        Apply O(N) sliding window to detect patients exceeding threshold
        """
        if violations_df.empty:
            return []

        tracker = SlidingWindowComplianceTracker(
            window_days=self.window_size_days,
            violation_threshold=self.violation_threshold
        )
        
        alerts = []
        current_date = datetime.now().date()
        
        # Sort by date for proper window processing
        violations_df = violations_df.sort_values('ScheduledDate')
        
        for _, row in violations_df.iterrows():
            patient_id = row['PatientId']
            medication_id = row['PrescribedMedicationId']
            violation_date = row['ScheduledTime']
            
            # Check if this violation triggers an alert
            is_alert, violation_count = tracker.add_violation(
                patient_id, medication_id, violation_date
            )
            
            if is_alert:
                # Calculate window boundaries
                window_start = violation_date - timedelta(days=self.window_size_days)
                
                alerts.append({
                    'patient_id': patient_id,
                    'prescribed_medication_id': medication_id,
                    'medication_name': row['MedicationNameSnapshot'],
                    'alert_type': row['violation_type'],
                    'violation_count': int(violation_count),
                    'severity': 'HIGH' if violation_count >= 10 else 'MEDIUM',
                    'window_start': window_start.date(),
                    'window_end': violation_date.date(),
                    'last_violation_date': violation_date,
                    'updated_at': datetime.now()
                })
        
        return alerts
    
    def close(self):
        """Close database connection"""
        if self.conn:
            self.cursor.close()
            self.conn.close()

# --- Kinetica Manager ---
class KineticaManager:
    def __init__(self):
        # Load Kinetica configuration from environment variables
        host = os.getenv('KINETICA_HOST', 'http://localhost')
        port = os.getenv('KINETICA_PORT', '9191')
        use_tls = os.getenv('KINETICA_USE_TLS', 'false').lower() == 'true'
        
        # Construct full URL
        if not host.startswith('http'):
            protocol = 'https' if use_tls else 'http'
            full_url = f"{protocol}://{host}:{port}"
        else:
            full_url = host  # Already has protocol
        
        self.config = type('Config', (), {
            'URL': full_url,
            'USERNAME': os.getenv('KINETICA_USERNAME', ''),
            'PASSWORD': os.getenv('KINETICA_PASSWORD', ''),
            'SCHEMA': os.getenv('KINETICA_SCHEMA', '').strip()
        })()
        self.db = self._connect()
        
    def _connect(self):
        """Connect to Kinetica"""
        try:
            db = gpudb.GPUdb(
                host=self.config.URL,
                username=self.config.USERNAME,
                password=self.config.PASSWORD
            )
            print(f"✓ Connected to Kinetica: {self.config.URL}")
            return db
        except Exception as e:
            print(f"✗ Failed to connect to Kinetica: {e}")
            return None
    
    def ensure_compliance_table(self):
        """Ensure the compliance alerts table exists"""
        if not self.db:
            print("No database connection")
            return None
        
        schema = self.config.SCHEMA
        table_name = f"{schema}.patient_compliance_alerts"
        
        create_table_sql = f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            alert_id STRING,
            patient_id STRING,
            prescribed_medication_id STRING,
            medication_name STRING,
            alert_type STRING,
            violation_count LONG,
            severity STRING,
            window_start DATE,
            window_end DATE,
            last_violation_date TIMESTAMP,
            updated_at TIMESTAMP,
            PRIMARY KEY (alert_id)
        )
        """
        
        try:
            self.db.execute_sql(create_table_sql)
            print(f"✓ Table '{table_name}' ensured")
            return table_name
        except Exception as e:
            print(f"✗ Error creating table: {e}")
            return None

    def check_table_exists(self, table_name: str = None) -> bool:
        """Check if table exists in Kinetica"""
        if not self.db:
            return False
        
        if not table_name:
            table_name = f"{self.config.SCHEMA}.patient_compliance_alerts"
            
        try:
            check_sql = f"SHOW TABLE {table_name}"
            result = self.db.execute_sql(check_sql)
            print(f"✓ Table '{table_name}' exists")
            return True
        except Exception as e:
            print(f"✗ Table '{table_name}' does not exist or error: {e}")
            return False

    def get_table_count(self, table_name: str = None) -> int:
        """Get record count from table"""
        if not self.db:
            return 0
        
        if not table_name:
            table_name = f"{self.config.SCHEMA}.patient_compliance_alerts"
            
        try:
            count_sql = f"SELECT COUNT(*) FROM {table_name}"
            result = self.db.execute_sql(count_sql)
            count = result['records'][0][0] if result['records'] else 0
            print(f"✓ Table '{table_name}' has {count} records")
            return count
        except Exception as e:
            print(f"✗ Error counting records: {e}")
            return 0

    def upsert_alerts(self, alerts: List[Dict[str, Any]]) -> int:
        """Upsert alerts into Kinetica with proper batch processing"""
        if not self.db:
            print("✗ No database connection for upsert")
            return 0
            
        if not alerts:
            print("⚠ No alerts to upsert")
            return 0

        schema = self.config.SCHEMA
        table_name = f"{schema}.patient_compliance_alerts"

        # Process in smaller batches to avoid timeouts
        batch_size = 100
        total_inserted = 0
        
        print(f"Upserting {len(alerts)} alerts in batches of {batch_size}...")
        
        for batch_num, i in enumerate(range(0, len(alerts), batch_size), 1):
            batch = alerts[i:i + batch_size]
            
            try:
                columns = [
                    'alert_id', 'patient_id', 'prescribed_medication_id', 'medication_name',
                    'alert_type', 'violation_count', 'severity', 'window_start',
                    'window_end', 'last_violation_date', 'updated_at'
                ]
                
                values = []
                for alert in batch:
                    # Generate unique ID for each alert
                    alert_id = str(uuid.uuid4())
                    
                    # Properly escape single quotes in medication names
                    med_name = alert['medication_name'].replace("'", "''") if alert['medication_name'] else 'Unknown'
                    
                    values.append(f"""(
                        '{alert_id}',
                        '{alert['patient_id']}',
                        '{alert['prescribed_medication_id']}',
                        '{med_name}',
                        '{alert['alert_type']}',
                        {alert['violation_count']},
                        '{alert['severity']}',
                        '{alert['window_start']}',
                        '{alert['window_end']}',
                        '{alert['last_violation_date'].strftime('%Y-%m-%d %H:%M:%S')}',
                        '{alert['updated_at'].strftime('%Y-%m-%d %H:%M:%S')}'
                    )""")
                
                insert_sql = f"""
                INSERT INTO {table_name} ({', '.join(columns)})
                VALUES {', '.join(values)}
                """

                # Execute the insert for this batch
                self.db.execute_sql(insert_sql)
                total_inserted += len(batch)
                
            except Exception as e:
                print(f"  ✗ Error inserting batch {batch_num}: {e}")
        
        print(f"✓ Total inserted: {total_inserted} alerts")
        return total_inserted

def main(rebuild_kinetica: bool = False):
    """Orchestrates the entire ETL pipeline"""
    print("\n--- Medication Compliance Analysis ---")
    
    # Initialize components
    analyzer = MedicationComplianceAnalyzer()
    kinetica_manager = KineticaManager()
    
    try:
        # Extract and transform data
        raw_data = analyzer.load_medication_data()
        
        if raw_data.empty:
            print("No medication adherence data found. Exiting.")
            return
            
        violations_df = analyzer.detect_violations(raw_data)
        alerts = analyzer.apply_sliding_window_optimized(violations_df)
        
        print(f"Data Loaded: {len(raw_data)} raw records")
        print(f"Violations Detected: {len(violations_df)} intake violations")
        print(f"Alerts Found: {len(alerts)} threshold breaches")
        
        # Load to Kinetica
        if alerts:
            kinetica_manager.ensure_compliance_table()
            inserted = kinetica_manager.upsert_alerts(alerts)
            print(f"Inserted {inserted} alerts to Kinetica")
            
            # Print alert summary
            print("\n--- Alert Summary ---")
            for alert in alerts[:10]:
                print(f"ALERT: Patient {alert['patient_id']} - {alert['medication_name']} "
                      f"({alert['alert_type']}) - {alert['violation_count']} violations - {alert['severity']} severity")
        else:
            print("No compliance alerts generated")
    
    finally:
        # Clean up
        analyzer.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Medication Compliance ETL Pipeline")
    parser.add_argument("--rebuild", action="store_true", help="Rebuild Kinetica tables")
    args = parser.parse_args()
    main(rebuild_kinetica=args.rebuild)