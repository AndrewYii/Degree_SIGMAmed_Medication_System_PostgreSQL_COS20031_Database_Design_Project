-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Reminder Table
BEGIN;

CREATE TABLE "SIGMAmed"."Reminder" (
    "MedicationScheduleID" UUID PRIMARY KEY REFERENCES "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationScheduleId") ON DELETE CASCADE,
    "IsActive" BOOLEAN DEFAULT TRUE,
    "CurrentStatus" "SIGMAmed".reminder_status_enum NOT NULL,
    "RemindGap" TIME
);

COMMENT ON TABLE "SIGMAmed"."Reminder" IS 'Medication intake reminders for patients';

-- Commit transaction for Creating Reminder Table
COMMIT;