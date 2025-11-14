-- Set search path for current session
SET search_path TO "SIGMAmed", public;
-- Ensure uuid-ossp extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction for Creating Medication Table
BEGIN;

CREATE TABLE "SIGMAmed"."Medication" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "MedicationID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionID" UUID NOT NULL REFERENCES "SIGMAmed"."ClinicalInstitution"("ClinicalInstitutionID") ON DELETE SET NULL,
    "MedicationName" VARCHAR(100) NOT NULL,
    "TotalAmount" INT NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    CONSTRAINT chk_total_amount CHECK ("TotalAmount" >= 0),
    UNIQUE("ClinicalInstitutionID", "MedicationName")
);

COMMENT ON TABLE "SIGMAmed"."Medication" IS 'Medication inventory per clinical institution';

-- Commit transaction for Creating Medication Table
COMMIT;