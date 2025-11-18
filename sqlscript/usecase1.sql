-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

-- Check whether the newly insert hospital already exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM "SIGMAmed"."ClinicalInstitution"
        WHERE "ClinicalInstitutionName" = 'Gleaneagles Hospital'
          AND "IsDeleted" = FALSE
    ) THEN
        RAISE EXCEPTION 'Clinical institution with this name already exists';
    END IF;
END $$;

-- Insert new Clinical Institution
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
RETURNING "ClinicalInstitutionID", "ClinicalInstitutionName", "CreatedAt", "UpdatedAt";

-- Commit transaction
COMMIT;
