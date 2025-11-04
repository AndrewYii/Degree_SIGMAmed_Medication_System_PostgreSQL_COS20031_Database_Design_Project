-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Assigned Doctor Table
BEGIN;

CREATE TABLE "SIGMAmed"."AssignedDoctor" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "AssignedDoctorId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor"("UserId") ON DELETE CASCADE,
    "PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient"("UserId") ON DELETE CASCADE,
    "DoctorLevel" "SIGMAmed".doctor_level_enum NOT NULL,
    "AssignedTime" TIMESTAMPTZ DEFAULT NOW(),
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    UNIQUE("DoctorId", "PatientId", "DoctorLevel")
);

COMMENT ON TABLE "SIGMAmed"."AssignedDoctor" IS 'Doctor-Patient assignment with primary/secondary classification';

-- Commit transaction for Creating Assigned Doctor Table
COMMIT;