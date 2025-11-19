-- Set search path for current session
SET search_path TO "SIGMAmed", public;
-- Ensure uuid-ossp extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction for Creating User Table
BEGIN;

CREATE TABLE "SIGMAmed"."User" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "UserId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionId" UUID NULL REFERENCES "SIGMAmed"."ClinicalInstitution"("ClinicalInstitutionID") ON DELETE RESTRICT,
    "Username" VARCHAR(50) UNIQUE NOT NULL,
    "Email" CITEXT UNIQUE NOT NULL,
    "PasswordHash" VARCHAR(255) NOT NULL,
    "Role" "SIGMAmed".user_role_enum NOT NULL,
    "ICPassportNumber" VARCHAR(50) UNIQUE NOT NULL,
    "FirstName" VARCHAR(100) NOT NULL,
    "LastName" VARCHAR(100) NOT NULL,
    "Phone" VARCHAR(20) NOT NULL,
    "DateOfBirth" DATE NOT NULL,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NULL, 
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT chk_user_age CHECK (DATE_PART('year', AGE("DateOfBirth")) >= 0),
    CONSTRAINT chk_email_format CHECK ("Email" ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

COMMENT ON TABLE "SIGMAmed"."User" IS 'Central user table for all system users (doctors, patients, admins)';
COMMENT ON COLUMN "SIGMAmed"."User"."PasswordHash" IS 'Bcrypt hashed password - never store plaintext';

-- Commit transaction for Creating User Table
COMMIT;