import whisper
import os
import psycopg2
from db_config import DBConfig
from psycopg2.extras import RealDictCursor
from datetime import datetime


class transcribe_audio:
    def __init__(self):
        self.MODEL_SIZE = "base"
        self.MODEL = None
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
    # Insert into the description column
    def save_transcript_to_patient_report(self, report_id, transcript_text):
        sql = f"""
            UPDATE "{self.schema}"."PatientReport"
            SET "Description" = %s
            WHERE "PatientReportId" = %s
        """
        self.cursor.execute(sql, (transcript_text, report_id))
        self.conn.commit()
        
    # Core transcription function
    def run_transcriber_system(self,audio_path,report_id):
        """Loads model, transcribes, and saves result to the database."""
        
        # Load model once if it hasn't been loaded yet (Optimized for multiple runs)
        if self.MODEL is None:
            print(f"Loading Whisper model '{self.MODEL_SIZE}'...")
            self.MODEL = whisper.load_model(self.MODEL_SIZE)
        
        print(f"\n--- Transcribing: {os.path.basename(audio_path)} ---")
        
        # 1. Transcribe the audio file
        result = self.MODEL.transcribe(audio_path, verbose=False)

        full_transcript = result["text"]
        # 3. Save the data to the database
        self.save_transcript_to_patient_report(report_id,full_transcript)

        print("--- Process Complete ---")
       