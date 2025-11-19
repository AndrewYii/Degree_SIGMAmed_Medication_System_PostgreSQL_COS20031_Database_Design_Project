-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
-- Used for hash the password
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    clinicalinstitution_id UUID;
    new_user_id UUID;
    new_role "SIGMAmed".user_role_enum;
BEGIN
-- Select the clinical institution id for Gleaneagles Hospital
    SELECT "ClinicalInstitutionID" INTO clinicalinstitution_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName"='Danielchester Medical Center' AND "IsDeleted"=FALSE;

-- Check whether the newly insert patients already exists
    IF EXISTS (
        SELECT 1
        FROM "SIGMAmed"."User"
        WHERE "ICPassportNumber" = 'XH69273838'
          AND "IsDeleted" = FALSE
    ) THEN
        RAISE EXCEPTION 'The current user already exists';
    END IF;

-- Insert new User
INSERT INTO "SIGMAmed"."User" (
    "ClinicalInstitutionId",
    "Username",
    "Email",
    "PasswordHash",
    "Role",
    "ICPassportNumber",
    "FirstName",
    "LastName",
    "Phone",
    "DateOfBirth",
    "UpdatedAt",
    "IsDeleted"
) VALUES (
    clinicalinstitution_id, 
    'james.moore101335',                    
    'james88@gmail.com',                   
    crypt('MySecret123', gen_salt('bf')),  
    'patient',
    'XH69273838',
    'James',
    'Lin',
    '(678)421-3453',
    '1969-08-08',
    NOW(),
    FALSE 
)
RETURNING "UserId","Role" INTO new_user_id, new_role;

UPDATE "SIGMAmed"."Patient"
SET
    "PatientNumber"='PAT-2025-029999',
    "BloodType" = 'O+',
    "HeightCm" = 175,
    "WeightKg" = 70,
    "EmergencyContactName" = 'John Doe',
    "EmergencyContactNumber" = '0123456789'
WHERE "UserId" = '040fb724-6e8d-4ace-9d37-630633d7823f';

END $$;
-- Commit transaction
COMMIT;
