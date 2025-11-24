-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    user_id UUID;
    hospital_doctor_id UUID;
BEGIN
-- Select the doctor id from new hospital
    SELECT "UserId"
    FROM "SIGMAmed"."User" INTO hospital_doctor_id
    WHERE "ICPassportNumber" = 'GH2849372949';
RAISE NOTICE 'Switching ActedBy user to hospital doctor ID: %', hospital_doctor_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(hospital_doctor_id);

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
    hospital_doctor_id,
    user_id,
    '2025-12-01 10:00:00+08',                      
    'follow-up'
);

-- Insert new record 

END $$;
-- Commit transaction
COMMIT;
