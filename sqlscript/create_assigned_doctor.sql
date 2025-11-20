-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Assigned Doctor Table
BEGIN;

CREATE TABLE "SIGMAmed"."PatientCareTeam" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PatientCareTeamId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor"("UserId") ON DELETE CASCADE,
    "PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient"("UserId") ON DELETE CASCADE,
    "DoctorLevel" "SIGMAmed".doctor_level_enum NOT NULL,
    "Role" VARCHAR(50) NULL,
    "IsActive" BOOLEAN DEFAULT TRUE,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE("DoctorId", "PatientId", "DoctorLevel")
);

COMMENT ON TABLE "SIGMAmed"."PatientCareTeam" IS 'Doctor-Patient assignment with primary/secondary classification';

-- Commit transaction for Creating Assigned Doctor Table
COMMIT;