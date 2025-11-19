-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
-- Create for bycrypt the password hash
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Start transaction
BEGIN;

-- Check whether the newly insert hospital already exists
DO $$
DECLARE
    hospital_exists BOOLEAN;
    admin_exists BOOLEAN;
    new_hospital_id UUID;
    new_user_id UUID;
    new_role "SIGMAmed".user_role_enum;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM "SIGMAmed"."ClinicalInstitution"
        WHERE "ClinicalInstitutionName" = 'Gleaneagles Hospital'
          AND "IsDeleted" = FALSE
    ) INTO hospital_exists;

    SELECT EXISTS (
        SELECT 1
        FROM "SIGMAmed"."User"
        WHERE "ICPassportNumber" = '739547397hs8437'
          AND "IsDeleted" = FALSE
    ) INTO admin_exists;

    IF hospital_exists THEN
        SELECT "ClinicalInstitutionID" INTO new_hospital_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName"='Gleaneagles Hospital' AND "IsDeleted"=FALSE;
    END IF;

    IF hospital_exists AND admin_exists THEN
        RAISE EXCEPTION 'Hospital and Admin already exist';
    ELSIF hospital_exists THEN
        RAISE NOTICE 'Hospital already exists, only inserting admin';
        -- insert admin code here
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
            new_hospital_id, 
            'jaome.moore101335',                    
            'jaome88@gmail.com',                   
            crypt('jaome123', gen_salt('bf')),  
            'admin', 
            '739547397hs8437',
            'Jaome',
            'Ling',
            '(678)145-6435',
            '1970-05-20',
            NOW(),
            FALSE,
            NOW()
        )
        RETURNING "UserId","Role" INTO new_user_id, new_role;
    ELSIF admin_exists THEN
        RAISE NOTICE 'Admin already exists';
    ELSE
        -- insert hospital and admin code here
        INSERT INTO "SIGMAmed"."ClinicalInstitution" (
            "ClinicalInstitutionName",
            "IsDeleted",
            "CreatedAt",
            "UpdatedAt"
        ) VALUES (
            'Gleaneagles Hospital', 
            FALSE,                    
            NOW(),                   
            NOW()                      
        )
        RETURNING "ClinicalInstitutionID" INTO new_hospital_id;
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
            new_hospital_id, 
            'jaome.moore101335',                    
            'jaome88@gmail.com',                   
            crypt('jaome123', gen_salt('bf')),  
            'admin', 
            '739547397hs8437',
            'Jaome',
            'Ling',
            '(678)145-6435',
            '1970-05-20',
            NOW(),
            FALSE 
        )
        RETURNING "UserId","Role" INTO new_user_id, new_role;
    END IF;

END $$;
-- Commit transaction
COMMIT;
