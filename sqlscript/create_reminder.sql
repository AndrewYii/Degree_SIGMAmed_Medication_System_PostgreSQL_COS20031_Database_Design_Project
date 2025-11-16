-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Reminder Table
BEGIN;

CREATE TABLE "SIGMAmed"."Reminder" (
    "ReminderID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescribedMedicationScheduleID" UUID NULL REFERENCES "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationScheduleId"),
    "AppointmentID" UUID NULL REFERENCES "SIGMAmed"."Appointment"("AppointmentId"),
    "IsActive" BOOLEAN DEFAULT TRUE,
    "CurrentStatus" "SIGMAmed".reminder_status_enum NOT NULL,
    "RemindGap" INTERVAL NULL,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NULL
);

COMMENT ON TABLE "SIGMAmed"."Reminder" IS 'Medication intake reminders for patients';

-- Commit transaction for Creating Reminder Table
COMMIT;