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
    daniel_exists BOOLEAN;
    super_admin_id UUID;
    hospital_admin_id UUID;
BEGIN
    -- Select the super_admin_id
    SELECT "UserId" INTO super_admin_id FROM "SIGMAmed"."Admin" WHERE "AdminLevel"='super';

    RAISE NOTICE 'Switching ActedBy user to Super admin ID: %', super_admin_id;
    EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(super_admin_id);
    
    SELECT EXISTS (
        SELECT 1
        FROM "SIGMAmed"."ClinicalInstitution"
        WHERE "ClinicalInstitutionName" = 'Danielchester Medical Center'
          AND "IsDeleted" = FALSE
    ) INTO daniel_exists;

    IF daniel_exists IS FALSE THEN
        INSERT INTO "SIGMAmed"."ClinicalInstitution" (
            "ClinicalInstitutionName",
            "IsDeleted",
            "CreatedAt",
            "UpdatedAt"
        ) VALUES (
            'Danielchester Medical Center', 
            FALSE,                    
            NOW(),                   
            NOW()                      
        );
    END IF;
-- Select the clinical institution id for Danielchester Medical Center
    SELECT "ClinicalInstitutionId" INTO clinicalinstitution_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName"='Danielchester Medical Center' AND "IsDeleted"=FALSE;

-- Check whether the newly insert patients already exists
    IF EXISTS (
        SELECT 1
        FROM "SIGMAmed"."User"
        WHERE "ICPassportNumber" = 'XH69273838'
          AND "IsDeleted" = FALSE
    ) THEN
        RAISE EXCEPTION 'The current user already exists';
    END IF;

    -- Insert new hospital admin and assigned to that hospital
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
        'john.moore101335',                    
        'john88@gmail.com',                   
        crypt('john123', gen_salt('bf')),  
        'admin',
        'XH45434536',
        'John',
        'Lin',
        '(678)453-7890',
        '1971-08-08',
        NOW(),
        FALSE,
        NOW()
    );
    
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
    FALSE,
    NOW()
)
RETURNING "UserId","Role" INTO new_user_id, new_role;

UPDATE "SIGMAmed"."Patient"
SET
    "BloodType" = 'O+',
    "HeightCm" = 175,
    "WeightKg" = 70,
    "EmergencyContactName" = 'John Doe',
    "EmergencyContactNumber" = '0123456789'
WHERE "UserId" = new_user_id;

END $$;
-- Commit transaction
COMMIT;
