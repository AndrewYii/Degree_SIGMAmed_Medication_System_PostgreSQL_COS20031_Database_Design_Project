-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    medication_id UUID;
    hospital_admin_id UUID;
BEGIN
-- Select the medication id based on the medication name
SELECT "MedicationId" INTO medication_id FROM "SIGMAmed"."Medication" WHERE "MedicationName" = 'Paracetamol (500mg)' AND 
    "IsDeleted"=FALSE;

-- Select the hospital admin role for Gleaneagles Hospital
SELECT u."UserId" INTO hospital_admin_id
FROM "SIGMAmed"."User" AS u
JOIN "SIGMAmed"."ClinicalInstitution" AS ci
ON u."ClinicalInstitutionId" = ci."ClinicalInstitutionId"
JOIN "SIGMAmed"."Admin" AS ad
ON u."UserId" = ad."UserId"
WHERE ci."ClinicalInstitutionName" = 'Gleaneagles Hospital'
AND u."Role" = 'admin'
AND ad."AdminLevel"='hospital'
AND u."IsDeleted" = FALSE;
RAISE NOTICE 'Switching ActedBy user to hospital admin ID: %', hospital_admin_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(hospital_admin_id);

-- Update the record for medication name
UPDATE "SIGMAmed"."Medication"
SET
    "MedicationName" = 'Paracetamol (400mg)'
WHERE "MedicationId" = medication_id;



END $$;
-- Commit transaction
COMMIT;


