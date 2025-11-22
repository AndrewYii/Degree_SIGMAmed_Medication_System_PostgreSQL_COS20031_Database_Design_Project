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
    doctor_exists BOOLEAN;
DECLARE 
    clinicalinstitution_id UUID;
    new_user_id UUID;
    new_role "SIGMAmed".user_role_enum;
    hospital_admin_id UUID;
BEGIN
-- Select the clinical institution id for Gleaneagles Hospital
    SELECT "ClinicalInstitutionId" INTO clinicalinstitution_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName"='Gleaneagles Hospital' AND "IsDeleted"=FALSE;

-- Select the hospital admin role for Danielchester Medical Center
SELECT u."UserId" INTO hospital_admin_id
FROM "SIGMAmed"."User" AS u
JOIN "SIGMAmed"."ClinicalInstitution" AS ci
ON u."ClinicalInstitutionId" = ci."ClinicalInstitutionId"
JOIN "SIGMAmed"."Admin" AS ad
ON u."UserId" = ad."UserId"
WHERE ci."ClinicalInstitutionName" = 'Danielchester Medical Center'
AND u."Role" = 'admin'
AND ad."AdminLevel"='hospital'
AND u."IsDeleted" = FALSE;

RAISE NOTICE 'Switching ActedBy user to hospital admin ID: %', hospital_admin_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(hospital_admin_id);

-- Insert new User
SELECT EXISTS (
    SELECT 1
    FROM "SIGMAmed"."User"
    WHERE "ICPassportNumber" = 'GH2849372949'
        AND "IsDeleted" = FALSE
) INTO doctor_exists;
IF doctor_exists IS FALSE THEN  
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
END IF;

-- Update the record for doctor
UPDATE "SIGMAmed"."Doctor"
SET
    "Specialization" = 'Eye Specialist',
    "YearOfExperience" = 10
WHERE "UserId" = new_user_id;

END $$;
-- Commit transaction
COMMIT;
