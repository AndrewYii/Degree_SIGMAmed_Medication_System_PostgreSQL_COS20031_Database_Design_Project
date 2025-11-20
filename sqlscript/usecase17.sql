-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    secondary_doctor_id UUID;
    user_id UUID;
    
BEGIN
-- Insert dummy data for doctor
INSERT INTO "SIGMAmed"."User" (
    "ClinicalInstitutionId",
    "Username",
    "Email",
    "PasswordHash",
    "Role",
    "ICPassportNumber",
    "FirstName",
    "LastName",
    "Phone",
    "DateOfBirth",
    "UpdatedAt",
    "IsDeleted",
    "CreatedAt"
) VALUES (
    '48436c9e-4a5c-411e-a58b-b22b911fbe72', 
    'brenda.moore101335',                    
    'brenda88@gmail.com',                   
    crypt('brenda123', gen_salt('bf')),  
    'doctor',
    'GH3434556768',
    'Brenda',
    'Wong',
    '(678)434-4534',
    '2000-07-15',
    NOW(),
    FALSE,
    NOW()
) RETURNING "UserId" INTO secondary_doctor_id;

-- Select the patient based on ICPassportNumber
    SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;

-- Assigned a new secondary doctor record into PatientCareTeam table
INSERT INTO "SIGMAmed"."PatientCareTeam"(
    "DoctorId",
    "PatientId",
    "DoctorLevel",
    "Role"
)
VALUES (
    secondary_doctor_id,
    user_id,
    'secondary',                      
    'psychiatrist'
);

END $$;
-- Commit transaction
COMMIT;
