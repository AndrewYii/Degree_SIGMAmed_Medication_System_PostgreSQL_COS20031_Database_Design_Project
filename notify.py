import psycopg2
import select
from patient_report import Extract_keyword
from transcribe import transcribe_audio
from db_config import DBConfig
import json

processor=Extract_keyword()
report_processor=transcribe_audio()

conn=psycopg2.connect(**DBConfig.get_connection_params())
conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
cur=conn.cursor()

# Listen to both channels
cur.execute("LISTEN report_ready_for_processing;")
cur.execute("LISTEN new_patient_report;")
cur.execute("LISTEN new_desc_patient_report;")

print("Listener started")

while True:
    if select.select([conn],[],[],5)==([],[],[]):
        continue
    conn.poll()
    while conn.notifies:
        notify=conn.notifies.pop(0)
        report_id=notify.payload
        
        if notify.channel=="report_ready_for_processing":
            try:
                processor.process_single_report(report_id)
                print(f"[PROCESS] Running keyword extraction for {report_id}")
            except Exception as e:
                print(f"[ERROR] Failed to process report {report_id}: {e}")
        elif notify.channel == "new_patient_report":
            try:
                payload = json.loads(notify.payload) 
                audio_path = payload['voice_path']
                report_id = payload['report_id']
                report_processor.run_transcriber_system(audio_path, report_id)
                print(f"[PROCESS] Currently converting the audio to transcript for {report_id}")
            except Exception as e:
                print(f"[ERROR] Failed to process audio for {report_id}: {e}")
        elif notify.channel == "new_desc_patient_report":
            try:
                processor.process_single_report(report_id)
                print(f"[PROCESS] Running general report processing for {report_id}")
            except Exception as e:
                print(f"[ERROR] Failed to process report {report_id}: {e}")
