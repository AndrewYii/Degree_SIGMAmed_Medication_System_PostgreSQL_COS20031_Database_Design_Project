-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    hospital_id UUID;
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
    SELECT "ClinicalInstitutionID" INTO hospital_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName" = 'Gleaneagles Hospital' AND 
    "IsDeleted"=FALSE;

-- Insert the new medication inside the medication table
INSERT INTO "SIGMAmed"."Medication" (
    "ClinicalInstitutionID",
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
    "ClinicalInstitutionID",
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
    "ClinicalInstitutionID",
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
