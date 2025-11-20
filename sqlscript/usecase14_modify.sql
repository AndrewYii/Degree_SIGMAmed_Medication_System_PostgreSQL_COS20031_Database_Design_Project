-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
BEGIN

-- Update the status and review time
UPDATE "SIGMAmed"."PatientReport"
SET
    "Type" = 'Symptom',
    "ReviewTime" = NOW()
WHERE "PatientReportID" = 'a18a96a3-f642-4206-9e6a-632944cf5e46';

END $$;
-- Commit transaction
COMMIT;
