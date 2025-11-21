-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
BEGIN
-- Update the CurrentStatus and DoseQuantity column in the MedicationAdherenceRecord table
UPDATE "SIGMAmed"."MedicationAdherenceRecord"
SET "CurrentStatus" = 'Taken', "DoseQuantity" = 1
WHERE "MedicationAdherenceRecordID" = '0cffe722-96d8-45f9-9d11-37a4a0e5698e';

END $$;
-- Commit transaction
COMMIT;
