-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Patient Report Log Table
BEGIN;

CREATE TABLE "SIGMAmed"."PatientReportLog" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PatientReportId" UUID NOT NULL REFERENCES "SIGMAmed"."PatientReport"("PatientReportID") ON DELETE CASCADE,
    "ActedBy" UUID NOT NULL REFERENCES "SIGMAmed"."User"("UserId") ON DELETE RESTRICT,
    "ActionType" "SIGMAmed".action_type_enum NOT NULL,
    "PreviousValue" JSONB DEFAULT '{}',
    "Action" JSONB DEFAULT '{}',
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."PatientReportLog" IS 'Audit trail for patient reports';

-- Commit transaction for Creating Patient Report Log Table
COMMIT;