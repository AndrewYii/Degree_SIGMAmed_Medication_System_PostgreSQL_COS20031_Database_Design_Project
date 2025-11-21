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
-- Select the doctor id based on MedicalLicenseNumber
    SELECT "UserId" INTO doctor_id FROM "SIGMAmed"."Doctor" WHERE "MedicalLicenseNumber" = 'TEMP-2595018b-69fd-4435-9c8e-3eaa91ef5bae';

-- Select the patient id based on ICPassportNumber
    SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;

-- Insert a record into Appointment table
INSERT INTO "SIGMAmed"."Appointment"(
    "DoctorId",
    "PatientId",
    "AppointmentDate",
    "AppointmentType"
)
VALUES (
    doctor_id,
    user_id,
    '2025-12-01 10:00:00+08',                      
    'follow-up'
);

END $$;
-- Commit transaction
COMMIT;
