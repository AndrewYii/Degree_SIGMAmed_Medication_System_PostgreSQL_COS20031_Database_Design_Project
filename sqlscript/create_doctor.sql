-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Doctor Table
BEGIN;

CREATE TABLE "SIGMAmed"."Doctor" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "UserId" UUID PRIMARY KEY REFERENCES "SIGMAmed"."User"("UserId") ON DELETE CASCADE,
    "MedicalLicenseNumber" VARCHAR(50) UNIQUE NOT NULL,
    "Specialization" VARCHAR(100) NOT NULL,
    "YearOfExperience" INT NOT NULL
    CONSTRAINT chk_experience CHECK ("YearOfExperience" >= 0 AND "YearOfExperience" <= 60)
);

COMMENT ON TABLE "SIGMAmed"."Doctor" IS 'Doctor-specific information extending User table';
COMMENT ON COLUMN "SIGMAmed"."Doctor"."MedicalLicenseNumber" IS 'Unique medical license number for the doctor';

-- Commit transaction for Creating Doctor Table
COMMIT;