import medspacy
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import date
from db_config import DBConfig
import re
import spacy

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
        
    def fetch_single_report(self, report_id):
        query = f"""
            SELECT *
            FROM "{self.schema}"."PatientReport"
            WHERE "PatientReportId" = %s
              AND "IsDeleted" = FALSE
        """
        self.cursor.execute(query, (report_id,))
        return self.cursor.fetchone()
    
    # Fully dynamic extraction
    def extract_medical_keywords(self, description):
        no_quotes_description = description.replace("'", "")
        cleaned_description = re.sub(r'\s+', ' ', no_quotes_description).strip()
        doc = self.nlp(cleaned_description)
        results = set()

        for ent in doc.ents:
            # Skip negated entities
            if hasattr(ent._, "context") and ent._.context.is_negated:
                continue
            results.add(ent.text.strip())

            # Optional debug:
            print(f"[DEBUG] Found entity: {ent.text}, label: {ent.label_}, negated? {getattr(ent._, 'context', None) and ent._.context.is_negated}")

        return results

    # Insert into description
    def insert_keywords(self, record_id, keywords):
        self.cursor.execute(f"""
            UPDATE "{self.schema}"."PatientReport"
            SET "Keywords" = %s
            WHERE "PatientReportId" = %s
        """, (keywords, record_id))

    # Process a single report
    def process_single_report(self, report_id):
        report = self.fetch_single_report(report_id)
        if not report:
            print(f"[SKIP] Report {report_id} already processed or not found.")
            return

        keywords = self.extract_medical_keywords(report['Description'])
        keywords_str = ", ".join(keywords)
        print(f"[DEBUG] Extracted keywords: {keywords}")

        self.insert_keywords(report_id,keywords_str)
        self.conn.commit()
        print(f"[DONE] Processed report {report_id}")

    def close(self):
        self.cursor.close()
        self.conn.close()
