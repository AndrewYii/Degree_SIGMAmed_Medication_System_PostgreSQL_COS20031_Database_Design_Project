-- Set search path for current session
SET search_path TO "SIGMAmed", public;
-- Ensure uuid-ossp extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction for Creating ClinicalInstitution Table
BEGIN;

CREATE TABLE "SIGMAmed"."ClinicalInstitution" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "ClinicalInstitutionID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionName" VARCHAR(100) NOT NULL,
    "Description" TEXT,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."ClinicalInstitution" IS 'Healthcare institutions/hospitals in the system';
COMMENT ON COLUMN "SIGMAmed"."ClinicalInstitution"."ClinicalInstitutionID" IS 'Primary key - unique identifier for institution';
COMMENT ON COLUMN "SIGMAmed"."ClinicalInstitution"."ClinicalInstitutionName" IS 'Official name of the healthcare institution';

-- Commit transaction for Creating ClinicalInstitution Table
COMMIT;