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
BEGIN
-- Select DoctorId based on MedicalLicenseNumber
    SELECT "UserId" INTO doctor_id FROM "SIGMAmed"."Doctor" WHERE "MedicalLicenseNumber" = 'TEMP-b5bd2cc8-f577-43d9-8018-aaaf67bd17f5';

-- Select the patient id based on ICPassportNumber
SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;

-- Insert the new patient report record inside the patient report table
INSERT INTO "SIGMAmed"."PatientReport" (
    "DoctorId",
    "PatientId",
    "Description",
    "Type",
    "Severity"
) VALUES (
    doctor_id, 
    user_id,                    
    'I have been experiencing dizziness and nausea',
    'SideEffect',                   
    'mild'
);

END $$;
-- Commit transaction
COMMIT;
