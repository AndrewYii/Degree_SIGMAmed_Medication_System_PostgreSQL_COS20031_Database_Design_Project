-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    existing_id UUID;
    prescribedmedication_id UUID;
    sequence_id INT;
    patient_id UUID;
BEGIN
-- Select the DoseSequenceId and PrescribedMedicationId from old record
SELECT "DoseSequenceId","PrescribedMedicationId" INTO sequence_id, prescribedmedication_id FROM "SIGMAmed"."PrescribedMedicationSchedule" WHERE "PrescribedMedicationScheduleId" = '3c33ecd0-b9af-4fe3-ba07-f2a2523f0a16'; --Replace to the real one

-- Select the patient id 
    SELECT "UserId"
    FROM "SIGMAmed"."User" INTO patient_id
    WHERE "ICPassportNumber" = 'XH69273838';
RAISE NOTICE 'Switching ActedBy user to patient ID: %', patient_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(patient_id);

-- Update the schedule’s day-of-week mask
UPDATE "SIGMAmed"."PrescribedMedicationSchedule"
SET "DayOfWeekMask" = '1011111' 
WHERE "PrescribedMedicationScheduleId" = '3c33ecd0-b9af-4fe3-ba07-f2a2523f0a16';  --Replace to the real one

-- Assumption: the patient only update the reminder time for tuesday from 8:00am to 8:15am
SELECT "PrescribedMedicationScheduleId" INTO existing_id FROM "SIGMAmed"."PrescribedMedicationSchedule" WHERE "PrescribedMedicationId" = prescribedmedication_id AND "ReminderTime" = '08:15:00';

IF existing_id IS NOT NULL THEN 
    UPDATE "SIGMAmed"."PrescribedMedicationSchedule"
    SET "DayOfWeekMask" = overlay("DayOfWeekMask" placing '1' from 2 for 1)
    WHERE "PrescribedMedicationScheduleId" = existing_id;
ELSE 
    INSERT INTO "SIGMAmed"."PrescribedMedicationSchedule"(
        "PrescribedMedicationId",
        "ReminderTime",
        "DayOfWeekMask",
        "DoseSequenceId"
    )
    VALUES (
        prescribedmedication_id,
        '08:15:00',
        '0100000',                      
        sequence_id
    );
END IF;
END $$;
-- Commit transaction
COMMIT;





