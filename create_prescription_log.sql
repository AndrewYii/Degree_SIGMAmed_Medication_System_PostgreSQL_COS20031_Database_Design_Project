-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Prescription Log Table
BEGIN;

CREATE TABLE "SIGMAmed"."PrescriptionLog" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescriptionId" UUID NOT NULL REFERENCES "SIGMAmed"."Prescription"("PrescriptionId") ON DELETE CASCADE,
    "ActedBy" UUID NOT NULL REFERENCES "SIGMAmed"."User"("UserId") ON DELETE RESTRICT,
    "ActionType" "SIGMAmed".action_type_enum NOT NULL,
    "PreviousValue" JSONB DEFAULT '{}',
    "Action" JSONB DEFAULT '{}',
    "Reason" TEXT,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."PrescriptionLog" IS 'Audit trail for prescription changes';

-- Commit transaction for Creating Prescription Log Table
COMMIT;