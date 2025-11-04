-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Appointment Log Table
BEGIN;

CREATE TABLE "SIGMAmed"."AppointmentLog" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "AppointmentId" UUID NOT NULL REFERENCES "SIGMAmed"."Appointment"("AppointmentId") ON DELETE CASCADE,
    "ActedBy" UUID NOT NULL REFERENCES "SIGMAmed"."User"("UserId") ON DELETE RESTRICT,
    "ActionType" "SIGMAmed".action_type_enum NOT NULL,
    "Action" JSONB DEFAULT '{}',
    "PreviousValue" JSONB DEFAULT '{}',
    "Reason" TEXT NOT NULL,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."AppointmentLog" IS 'Audit trail for appointment changes';

-- Commit transaction for Creating Appointment Log Table
COMMIT;