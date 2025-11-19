-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    user_id UUID;
    prescription_id UUID;
    medication1_id UUID;
    medication2_id UUID;
    new_pm1_id UUID;
    new_pm2_id UUID;
BEGIN
-- Check whether that prescription number exists before
    IF EXISTS (
        SELECT 1
        FROM "SIGMAmed"."Prescription"
        WHERE "PrescriptionNumber" = 'PRESCRIPTION1-2025-091119'
        AND "IsDeleted" = FALSE
    ) THEN
        RAISE EXCEPTION 'The current prescription already exists';
    END IF;

-- Select the patient id based on ICPassportNumber
SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;

-- Insert the new prescription inside the prescription table
INSERT INTO "SIGMAmed"."Prescription" (
    "DoctorId",
    "PatientId",
    "PrescriptionNumber",
    "Status",
    "PrescribedDate",
    "ExpiryDate",
    "IsDeleted",
    "UpdatedAt",
    "CreatedAt"
) VALUES (
    '2595018b-69fd-4435-9c8e-3eaa91ef5bae', 
    user_id,                    
    'PRESCRIPTION1-2025-091119',                   
    'active',  
    '2025-01-05',
    '2025-02-05',
    FALSE,
    NOW(),
    NOW()
)
RETURNING "PrescriptionId" INTO prescription_id;

-- Select the medication id based on medication name
SELECT "MedicationID" INTO medication1_id FROM "SIGMAmed"."Medication" WHERE "MedicationName"='Lisinopril (10mg)' AND "IsDeleted"=FALSE;

SELECT "MedicationID" INTO medication2_id FROM "SIGMAmed"."Medication" WHERE "MedicationName"='Hydrochlorothiazide (25mg)' AND "IsDeleted"=FALSE;

-- Insert new prescribed medication records into the PrescribeMedication table
INSERT INTO "SIGMAmed"."PrescribedMedication" (
    "PrescriptionId",
    "MedicationId",
    "DosageAmountPrescribed",
    "DosePerTime",
    "Status",
    "DefaultDayMask",
    "PrescribedDate",
    "IsDeleted",
    "MedicationNameSnapshot",
    "TimesPerDay",
    "UpdatedAt",
    "CreatedAt"
)
VALUES (
    prescription_id,
    medication1_id,
    90.00,                             
    1.00,                             
    'active',                               
    '1111111',   
    '2025-01-10',   
    FALSE,     
    'Lisinopril (10mg)',   
    3,
    NOW(),
    NOW()                     
)
RETURNING "PrescribedMedicationId" INTO new_pm1_id;

INSERT INTO "SIGMAmed"."PrescribedMedication" (
    "PrescriptionId",
    "MedicationId",
    "DosageAmountPrescribed",
    "DosePerTime",
    "Status",
    "DefaultDayMask",
    "PrescribedDate",
    "IsDeleted",
    "MedicationNameSnapshot",
    "TimesPerDay",
    "UpdatedAt",
    "CreatedAt"
)
VALUES (
    prescription_id,
    medication2_id,
    90.00,                             
    1.00,                             
    'active',                               
    '1111111',   
    '2025-01-12',   
    FALSE,     
    'Hydrochlorothiazide (25mg)',   
    1,
    NOW(),
    NOW()                     
)
RETURNING "PrescribedMedicationId" INTO new_pm2_id;

-- Insert new record for prescribed medication schedule
INSERT INTO "SIGMAmed"."PrescribedMedicationSchedule" (
    "PrescribedMedicationId",
    "ReminderTime",
    "DayOfWeekMask",
    "UpdatedAt",
    "DoseSequenceId",
    "CreatedAt"
)
VALUES
(
    new_pm1_id,
    '08:00:00',
    '1111111',
    NOW(),
    1,
    NOW()
),

(
    new_pm1_id,
    '14:00:00',
    '1111111',
    NOW(),
    2,
    NOW()
),

(
    new_pm1_id,
    '20:00:00',
    '1111111',
    NOW(),
    3,
    NOW()
),

(
    new_pm2_id,
    '08:00:00',
    '1111111',
    NOW(),
    1,
    NOW()
);

END $$;
-- Commit transaction
COMMIT;
