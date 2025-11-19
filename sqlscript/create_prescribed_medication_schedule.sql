-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Prescribed Medication Schedule Table
BEGIN;

CREATE TABLE "SIGMAmed"."PrescribedMedicationSchedule" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PrescribedMedicationScheduleId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescribedMedicationId" UUID NOT NULL REFERENCES "SIGMAmed"."PrescribedMedication"("PrescribedMedicationId") ON DELETE CASCADE,
    "ReminderTime" TIME NOT NULL,
    "DayOfWeekMask" VARCHAR(7) DEFAULT '0000000',
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "DoseSequenceId" INT NOT NULL
);

COMMENT ON TABLE "SIGMAmed"."PrescribedMedicationSchedule" IS 'Medication intake schedule per prescribed medication';

-- Commit transaction for Creating Prescribed Medication Schedule Table
COMMIT;