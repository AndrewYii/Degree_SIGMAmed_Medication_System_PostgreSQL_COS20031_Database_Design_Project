-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Reminder Table
BEGIN;

CREATE TABLE "SIGMAmed"."MedicationAdherenceRecord" (
    "MedicationAdherenceRecordID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescribedMedicationScheduleID" UUID NULL REFERENCES "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationScheduleId"),
    "CurrentStatus" "SIGMAmed".reminder_status_enum DEFAULT 'Pending',
    "DoseQuantity" DECIMAL(5,2) NULL,
    "ScheduledTime" TIMESTAMPTZ NOT NULL,
    "ActionTime" TIMESTAMPTZ DEFAULT NOW(),
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."MedicationAdherenceRecord" IS 'Medication intake reminders for patients';

-- Commit transaction for Creating Reminder Table
COMMIT;

-- MODIFYING