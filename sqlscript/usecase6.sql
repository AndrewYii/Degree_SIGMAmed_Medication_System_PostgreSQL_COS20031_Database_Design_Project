-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    medication_id UUID;
BEGIN
-- Select the medication id based on the medication name
SELECT "MedicationID" INTO medication_id FROM "SIGMAmed"."Medication" WHERE "MedicationName" = 'Paracetamol (500mg)' AND 
    "IsDeleted"=FALSE;

-- Update the record for medication name
UPDATE "SIGMAmed"."Medication"
SET
    "MedicationName" = 'Paracetamol (400mg)'
WHERE "MedicationID" = medication_id;



END $$;
-- Commit transaction
COMMIT;


