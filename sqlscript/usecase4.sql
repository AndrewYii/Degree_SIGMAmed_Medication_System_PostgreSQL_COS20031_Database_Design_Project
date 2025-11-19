-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    user_id UUID;
    new_hospital_id UUID;
BEGIN
-- Select the patient based on ICPassportNumber
    SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;

-- Select the clinical institution id of new hospital
    SELECT "ClinicalInstitutionID" INTO new_hospital_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName" = 'Gleaneagles Hospital' AND 
    "IsDeleted"=FALSE;

-- Update the clinical institution id for the patient
UPDATE "SIGMAmed"."User"
SET
    "ClinicalInstitutionId" = new_hospital_id
WHERE "UserId" = user_id;

END $$;
-- Commit transaction
COMMIT;
