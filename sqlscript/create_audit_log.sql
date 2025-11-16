-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Audit Log Table
BEGIN;

CREATE TABLE "SIGMAmed"."AuditLog" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "AuditLogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ActedBy" UUID REFERENCES "SIGMAmed"."User"("UserId") NOT NULL,
    "ActionTimestamp" TIMESTAMPTZ DEFAULT NOW(),
    "TableName" VARCHAR(75) NOT NULL,
    "RecordId" UUID NOT NULL,
    "ActionStatus" action_type_enum NOT NULL,
    "OldValue" JSONB DEFAULT[],
    "NewValue" JSONB DEFAULT[]
);


-- Commit transaction for Creating Audit Log Table
COMMIT;