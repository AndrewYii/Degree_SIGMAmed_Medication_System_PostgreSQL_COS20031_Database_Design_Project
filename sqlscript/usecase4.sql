-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    user_id UUID;
    new_hospital_id UUID;
    hospital_exists BOOLEAN;
    danielchester_hospital_id UUID;
    danielchester_doctor_id UUID;
    previous_assigned_doctor BOOLEAN;
BEGIN
-- Select the patient based on ICPassportNumber
    SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;

-- Select the clinical institution id of new hospital
    SELECT "ClinicalInstitutionID" INTO new_hospital_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName" = 'Gleaneagles Hospital' AND 
    "IsDeleted"=FALSE;

-- Update the clinical institution id for the patient
    UPDATE "SIGMAmed"."User"
    SET
        "ClinicalInstitutionId" = new_hospital_id
    WHERE "UserId" = user_id;

-- Insert dummy data for previous care team on Danielchester Medical Center
    -- Insert into hospital
    SELECT EXISTS (
        SELECT 1
        FROM "SIGMAmed"."ClinicalInstitution"
        WHERE "ClinicalInstitutionName" = 'Gleaneagles Hospital'
          AND "IsDeleted" = FALSE
    ) INTO hospital_exists;
    IF hospital_exists THEN
        SELECT "ClinicalInstitutionID" INTO danielchester_hospital_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName" = 'Gleaneagles Hospital' AND 
        "IsDeleted"=FALSE;
    ELSE
        INSERT INTO "SIGMAmed"."ClinicalInstitution" (
            "ClinicalInstitutionName"
        ) VALUES (
            'Danielchester Medical Center'
        ) RETURNING "ClinicalInstitutionID" INTO danielchester_hospital_id;
    END IF;
    -- Insert into doctor
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
        danielchester_hospital_id, 
        'aryn.moore101335',                    
        'aryn88@gmail.com',                   
        crypt('aryn123', gen_salt('bf')),  
        'doctor',
        'GH72482384928',
        'Aryn',
        'Jee Mei Wei',
        '(678)342-6756',
        '2000-02-15',
        NOW(),
        FALSE,
        NOW()
    ) RETURNING "UserId" INTO danielchester_doctor_id;
    -- assigned for that doctor
    INSERT INTO "SIGMAmed"."PatientCareTeam" (
        "DoctorId",
        "PatientId",
        "DoctorLevel"
    ) VALUES (
        danielchester_doctor_id, 
        user_id,                    
        'primary'
    );
    -- Deactive the previous clinical institution's assigned doctor
     SELECT EXISTS (
        SELECT 
        FROM "SIGMAmed"."PatientCareTeam"
        WHERE "PatientId" = user_id
          AND "IsActive" = TRUE
    ) INTO previous_assigned_doctor;
    
END $$;
-- Commit transaction
COMMIT;
