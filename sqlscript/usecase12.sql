-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

DO $$
DECLARE 
    patient_id UUID;
BEGIN
-- Select the patient id 
    SELECT "UserId"
    FROM "SIGMAmed"."User" INTO patient_id
    WHERE "ICPassportNumber" = 'XH69273838';
RAISE NOTICE 'Switching ActedBy user to patient ID: %', patient_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(patient_id);
-- Update the CurrentStatus and DoseQuantity column in the MedicationAdherenceRecord table
UPDATE "SIGMAmed"."MedicationAdherenceRecord"
SET "CurrentStatus" = 'Taken', "DoseQuantity" = 1
WHERE "MedicationAdherenceRecordId" = '0000fea7-abe8-482d-b9f7-e81bf0300bdf';

END $$;
