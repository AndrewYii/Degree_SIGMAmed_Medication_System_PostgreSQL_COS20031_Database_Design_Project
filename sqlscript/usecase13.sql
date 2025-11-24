-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    doctor_id UUID;
    user_id UUID;
    report_id UUID;
BEGIN
-- Select the doctor id from new hospital
    SELECT "UserId"
    FROM "SIGMAmed"."User" INTO doctor_id
    WHERE "ICPassportNumber" = 'GH2849372949';

-- Select the patient id based on ICPassportNumber
    SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;


EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(user_id);
RAISE NOTICE 'Switching ActedBy user to Patient ID: %', current_setting('app.current_user_id',TRUE);

-- Insert the new patient report record inside the patient report table 
INSERT INTO "SIGMAmed"."PatientReport" (
    "DoctorId",
    "PatientId",
    "VoiceDirectory",
    "Type"
) VALUES (
    doctor_id, 
    user_id,                    
    'Patient_Audio.mp3',
    'SideEffect'
) RETURNING "PatientReportId" into report_id;

RAISE NOTICE 'Switching ActedBy user to Doctor ID: %', doctor_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(doctor_id);

-- Select the patient id based on ICPassportNumber
    SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;

-- Update the patient report
UPDATE "SIGMAmed"."PatientReport"
SET
    "DoctorNote" = 'This patients has symptom such as nauseous, queasy, nausea.',
    "Type" = 'Symptom',
    "ReviewTime" = NOW()
WHERE "PatientReportId" = report_id;

-- Insert into Symptom table
INSERT INTO "SIGMAmed"."PatientSymptom" (
    "PatientId",
    "SymptomName",
    "Severity",
    "OnsetDate"
) VALUES (
    user_id, 
    'Nausea',                    
    'moderate',
    NOW()
),
(
    user_id, 
    'Queasy',                    
    'mild',
    NOW()
);
END $$;
-- Commit transaction
COMMIT;