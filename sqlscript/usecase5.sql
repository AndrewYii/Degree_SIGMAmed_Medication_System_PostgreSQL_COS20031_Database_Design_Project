-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    hospital_id UUID;
    hospital_admin_id UUID;
BEGIN
-- Check whether that medication name exists before
    IF EXISTS (
        SELECT 1
        FROM "SIGMAmed"."Medication"
        WHERE "MedicationName" = 'Paracetamol (500mg)'
        AND "IsDeleted" = FALSE
    ) THEN
        RAISE EXCEPTION 'The current medication name already exists';
    END IF;

-- Select the clinical institution id of Gleaneagles Hospital
    SELECT "ClinicalInstitutionId" INTO hospital_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName" = 'Gleaneagles Hospital' AND 
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

-- Insert the new medication inside the medication table
INSERT INTO "SIGMAmed"."Medication" (
    "ClinicalInstitutionId",
    "MedicationName",
    "Unit",
    "IsDeleted",
    "UpdatedAt",
    "DosageForm",
    "CreatedAt"
) VALUES (
    hospital_id, 
    'Paracetamol (500mg)',                    
    'tablet',                   
    FALSE,  
    NOW(),
    'tablet',
    NOW()
);

INSERT INTO "SIGMAmed"."Medication" (
    "ClinicalInstitutionId",
    "MedicationName",
    "Unit",
    "IsDeleted",
    "UpdatedAt",
    "DosageForm",
    "CreatedAt"
) VALUES (
    hospital_id, 
    'Lisinopril (10mg)',      
    'tablet',                
    FALSE,  
    NOW(),
    'tablet',
    NOW()
);

INSERT INTO "SIGMAmed"."Medication" (
    "ClinicalInstitutionId",
    "MedicationName",
    "Unit",
    "IsDeleted",
    "UpdatedAt",
    "DosageForm",
    "CreatedAt"
) VALUES (
    hospital_id, 
    'Hydrochlorothiazide (25mg)',      
    'tablet',                
    FALSE,  
    NOW(),
    'tablet',
    NOW()
);


END $$;
-- Commit transaction
COMMIT;
