-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Patient Side Effect Log Table
BEGIN;

CREATE TABLE "SIGMAmed"."PatientSideEffectLog" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PatientSideEffectID" UUID NOT NULL REFERENCES "SIGMAmed"."PatientSideEffect"("PatientSideEffectID") ON DELETE CASCADE,
    "ActedBy" UUID NOT NULL REFERENCES "SIGMAmed"."User"("UserId") ON DELETE RESTRICT,
    "ActionType" "SIGMAmed".action_type_enum NOT NULL,
    "PreviousValue" JSONB DEFAULT '{}',
    "Action" JSONB DEFAULT '{}',
    "Reason" TEXT,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."PatientSideEffectLog" IS 'Audit trail for side effect reports';

-- Commit transaction for Creating Patient Side Effect Log Table
COMMIT;