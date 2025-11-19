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
    SELECT "ClinicalInstitutionID" INTO clinicalinstitution_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName"='Gleaneagles Hospital' AND "IsDeleted"=FALSE;

-- Check whether the newly insert doctors already exists
    IF EXISTS (
        SELECT 1
        FROM "SIGMAmed"."User"
        WHERE "ICPassportNumber" = 'GH2849372949'
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
    "IsDeleted",
    "CreatedAt"
) VALUES (
    clinicalinstitution_id, 
    'yewcheng.moore101335',                    
    'yewcheng88@gmail.com',                   
    crypt('yewcheng123', gen_salt('bf')),  
    'doctor',
    'GH2849372949',
    'Lim',
    'Yew Cheng',
    '(678)254-4653',
    '1965-07-15',
    NOW(),
    FALSE,
    NOW()
)
RETURNING "UserId","Role" INTO new_user_id, new_role;

-- Update the record for doctor
UPDATE "SIGMAmed"."Doctor"
SET
    "Specialization" = 'Eye Specialist',
    "YearOfExperience" = 10
WHERE "UserId" = new_user_id;

END $$;
-- Commit transaction
COMMIT;
