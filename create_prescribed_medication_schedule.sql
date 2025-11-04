-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Prescribed Medication Schedule Table
BEGIN;

CREATE TABLE "SIGMAmed"."PrescribedMedicationSchedule" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PrescribedMedicationScheduleId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescribedMedicationId" UUID NOT NULL REFERENCES "SIGMAmed"."PrescribedMedication"("PrescribedMedicationId") ON DELETE CASCADE,
    "Weekday" "SIGMAmed".weekday_enum NOT NULL,
    "MealTiming" TIME NOT NULL,
    "Dose" INT NOT NULL,
    CONSTRAINT chk_dose CHECK ("Dose" > 0)
);

COMMENT ON TABLE "SIGMAmed"."PrescribedMedicationSchedule" IS 'Medication intake schedule per prescribed medication';

-- Commit transaction for Creating Prescribed Medication Schedule Table
COMMIT;