-- Set search path for current session
SET search_path TO "SIGMAmed", public;
-- Ensure uuid-ossp extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction for Creating Patient Symptom Table
BEGIN;

CREATE TABLE "SIGMAmed"."PatientSymptom" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PatientSymptomId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "MedicalHistoryId" UUID NULL REFERENCES "SIGMAmed"."MedicalHistory"("MedicalHistoryId"),
    "PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient"("UserId"),
    "SymptomName" VARCHAR(100) NOT NULL,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE("MedicalHistoryId", "SymptomName")
);

COMMENT ON TABLE "SIGMAmed"."PatientSymptom" IS 'Symptoms associated with medical history entries';

-- Commit transaction for Creating Patient Symptom Table
COMMIT;

