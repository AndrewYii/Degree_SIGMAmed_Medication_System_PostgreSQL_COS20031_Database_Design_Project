-- Set search path for current session
SET search_path TO "SIGMAmed", public;
-- Ensure uuid-ossp extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction for Creating Medical History Table
BEGIN;

CREATE TABLE "SIGMAmed"."MedicalHistory" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "MedicalHistoryId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient"("UserId") ON DELETE CASCADE,
    "DiseaseName" VARCHAR(100) NOT NULL,
    "Severity" INT DEFAULT 0,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT chk_severity CHECK ("Severity" >= 0 AND "Severity" <= 10)
);

COMMENT ON TABLE "SIGMAmed"."MedicalHistory" IS 'Patient medical history and chronic conditions';

-- Commit transaction for Creating Medical History Table
COMMIT;