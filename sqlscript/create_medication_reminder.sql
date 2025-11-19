-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Reminder Table
BEGIN;

CREATE TABLE "SIGMAmed"."MedicationReminder" (
    "MedicationReminderID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescribedMedicationScheduleID" UUID NULL REFERENCES "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationScheduleId"),
    "CurrentStatus" "SIGMAmed".reminder_status_enum NOT NULL,
    "RemindGap" INTERVAL NULL,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NULL,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."Reminder" IS 'Medication intake reminders for patients';

-- Commit transaction for Creating Reminder Table
COMMIT;

-- MODIFYING