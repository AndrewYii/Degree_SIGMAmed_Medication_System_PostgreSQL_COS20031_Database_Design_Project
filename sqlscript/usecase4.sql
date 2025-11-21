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
    hospital_admin_id UUID;
    new_hospital_admin_id UUID;
    new_hospital_doctor_id UUID;
BEGIN
-- Select the patient based on ICPassportNumber
    SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;

-- Select the clinical institution id of new hospital
    SELECT "ClinicalInstitutionId" INTO new_hospital_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName" = 'Gleaneagles Hospital' AND 
    "IsDeleted"=FALSE;
-- Select the hospital admin role for Gleaneagles Hospital
SELECT u."UserId" INTO hospital_admin_id
FROM "SIGMAmed"."User" AS u
JOIN "SIGMAmed"."ClinicalInstitution" AS ci
ON u."ClinicalInstitutionId" = ci."ClinicalInstitutionId"
JOIN "SIGMAmed"."Admin" AS ad
ON u."UserId" = ad."UserId"
WHERE ci."ClinicalInstitutionName" = 'Gleaneagles Hospital'
AND u."Role" = 'admin'
AND ad."AdminLevel"='hospital'
AND u."IsDeleted" = FALSE;
RAISE NOTICE 'Switching ActedBy user to hospital admin ID: %', hospital_admin_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(hospital_admin_id);

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
        WHERE "ClinicalInstitutionName" = 'Danielchester Medical Center'
          AND "IsDeleted" = FALSE
    ) INTO hospital_exists;
    IF hospital_exists THEN
        SELECT "ClinicalInstitutionId" INTO danielchester_hospital_id FROM "SIGMAmed"."ClinicalInstitution" WHERE "ClinicalInstitutionName" = 'Danielchester Medical Center' AND 
        "IsDeleted"=FALSE;
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
    IF previous_assigned_doctor THEN
        UPDATE "SIGMAmed"."PatientCareTeam"
        SET "IsActive" = FALSE
        WHERE "PatientId" = user_id
        AND "IsActive" = TRUE;
    END IF;
    -- Select the doctor id from new hospital
    SELECT "UserId"
    FROM "SIGMAmed"."User" INTO new_hospital_doctor_id
    WHERE "ICPassportNumber" = 'GH2849372949';
    -- Insert new patient care team record in patient care team
    INSERT INTO "SIGMAmed"."PatientCareTeam" (
        "DoctorId",
        "PatientId",
        "DoctorLevel"
    ) VALUES (
        new_hospital_doctor_id, 
        user_id,      
        'primary'
    );
END $$;
-- Commit transaction
COMMIT;
