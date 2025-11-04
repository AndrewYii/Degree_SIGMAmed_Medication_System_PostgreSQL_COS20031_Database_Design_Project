-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Assigned Doctor Log Table
BEGIN;

CREATE TABLE "SIGMAmed"."AssignedDoctorLog" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "AssignedDoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."AssignedDoctor"("AssignedDoctorId") ON DELETE CASCADE,
    "ActedBy" UUID NOT NULL REFERENCES "SIGMAmed"."User"("UserId") ON DELETE RESTRICT,
    "ActionType" "SIGMAmed".action_type_enum NOT NULL,
    "PreviousValue" JSONB DEFAULT '{}',
    "Action" JSONB DEFAULT '{}',
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."AssignedDoctorLog" IS 'Audit trail for doctor-patient assignments';

-- Commit transaction for Creating Assigned Doctor Log Table
COMMIT;