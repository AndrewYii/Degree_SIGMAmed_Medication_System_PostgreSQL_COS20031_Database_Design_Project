-- Set search path for current session
SET search_path TO "SIGMAmed", public;
-- Ensure uuid-ossp extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction for Creating Medication Table
BEGIN;

CREATE TABLE "SIGMAmed"."Medication" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "MedicationId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionId" UUID NOT NULL REFERENCES "SIGMAmed"."ClinicalInstitution"("ClinicalInstitutionId") ON DELETE SET NULL,
    "MedicationName" VARCHAR(100) NOT NULL,
    "Unit" VARCHAR(50) NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "DosageForm" "SIGMAmed".dosage_form_enum,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE("ClinicalInstitutionId", "MedicationName")
);

COMMENT ON TABLE "SIGMAmed"."Medication" IS 'Medication inventory per clinical institution';

-- Commit transaction for Creating Medication Table
COMMIT;

