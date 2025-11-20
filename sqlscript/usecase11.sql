-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
BEGIN
-- Update the default day-of-week mask in prescribed medication table
UPDATE "SIGMAmed"."PrescribedMedication"
SET "DefaultDayMask" = '1010101' 
WHERE "PrescribedMedicationId" = '279db00a-68b5-40d8-ba47-e2db794af1e2';

END $$;
-- Commit transaction
COMMIT;





