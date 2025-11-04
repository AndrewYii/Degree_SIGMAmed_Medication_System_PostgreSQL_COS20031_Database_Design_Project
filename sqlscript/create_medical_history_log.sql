-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Medical History Log Table
BEGIN;

CREATE TABLE "SIGMAmed"."MedicalHistoryLog" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "MedicalHistoryId" UUID NOT NULL REFERENCES "SIGMAmed"."MedicalHistory"("MedicalHistoryId") ON DELETE CASCADE,
    "ActedBy" UUID NOT NULL REFERENCES "SIGMAmed"."User"("UserId") ON DELETE RESTRICT,
    "ActionType" "SIGMAmed".action_type_enum NOT NULL,
    "PreviousValue" JSONB DEFAULT '{}',
    "Action" JSONB DEFAULT '{}',
    "Reason" TEXT,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."MedicalHistoryLog" IS 'Audit trail for medical history changes';

-- Commit transaction for Creating Medical History Log Table
COMMIT;