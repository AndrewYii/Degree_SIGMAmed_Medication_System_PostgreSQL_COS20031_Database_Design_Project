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
WHERE "PatientReportID" = 'eb526a10-5434-42c3-8481-e367e4833ec8';

END $$;
-- Commit transaction
COMMIT;
