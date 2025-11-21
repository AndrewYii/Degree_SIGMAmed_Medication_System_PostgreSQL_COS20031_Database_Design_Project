-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE
    hospital_doctor_id UUID;
BEGIN
-- Select the doctor id from new hospital
    SELECT "UserId"
    FROM "SIGMAmed"."User" INTO hospital_doctor_id
    WHERE "ICPassportNumber" = 'GH2849372949';
RAISE NOTICE 'Switching ActedBy user to hospital doctor ID: %', hospital_doctor_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(hospital_doctor_id);
-- Update the default day-of-week mask in prescribed medication table
UPDATE "SIGMAmed"."PrescribedMedication"
SET "DefaultDayMask" = '1010101' 
WHERE "PrescribedMedicationId" = '279db00a-68b5-40d8-ba47-e2db794af1e2';

END $$;
-- Commit transaction
COMMIT;





