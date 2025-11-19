import psycopg2
import select
from patient_report import Extract_keyword
from db_config import DBConfig

processor=Extract_keyword()

conn=psycopg2.connect(**DBConfig.get_connection_params())
conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
cur=conn.cursor()

# Listen to both channels
cur.execute("LISTEN new_patient_report;")
cur.execute("LISTEN report_ready_for_processing;")

print("Listener started")

while True:
    if select.select([conn],[],[],5)==([],[],[]):
        continue
    conn.poll()
    while conn.notifies:
        notify=conn.notifies.pop(0)
        report_id=notify.payload
        if notify.channel=="new_patient_report":
            print(f"[INFO] New patient report submitted and awaiting doctor to review: {report_id}")
        elif notify.channel=="report_ready_for_processing":
            try:
                processor.process_single_report(report_id)
                print(f"[PROCESS] Doctor review finish for the report. Current processing for {report_id}")
            except Exception as e:
                print(f"[ERROR] Failed to process report {report_id}: {e}")
