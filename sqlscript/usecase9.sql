-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp extension is available (for UUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Start transaction
BEGIN;

DO $$
DECLARE 
    user_id UUID;
    prescribed_medication_id UUID;
    medication_id UUID;
    prescription_id UUID;
BEGIN
-- Select the patient based on ICPassportNumber
    SELECT "UserId" INTO user_id FROM "SIGMAmed"."User" WHERE "ICPassportNumber"='XH69273838' AND "IsDeleted"=FALSE;

-- Select medication id based on medication name
    SELECT "MedicationID" INTO medication_id FROM "SIGMAmed"."Medication" WHERE "MedicationName"='Lisinopril (10mg)' AND "IsDeleted"=FALSE;

-- Select prescription id based on prescription number
    SELECT "PrescriptionId" INTO prescription_id FROM "SIGMAmed"."Prescription" WHERE "PrescriptionNumber"='PRESCRIPTION1-2025-091119' AND "IsDeleted"=FALSE;

-- Select the old prescribed medication id
    SELECT "PrescribedMedicationId" FROM "SIGMAmed"."PrescribedMedication" INTO prescribed_medication_id WHERE "MedicationId"=medication_id AND "PrescriptionId"= prescription_id AND "Status"='active' AND "IsDeleted"=FALSE;

-- Update the status for the previous prescribed medication record
UPDATE "SIGMAmed"."PrescribedMedication"
SET 
    "Status" = 'stop',
    "IsDeleted" = FALSE,  
    "UpdatedAt" = NOW()
WHERE "PrescribedMedicationId" = prescribed_medication_id
  AND "IsDeleted" = FALSE;

-- Insert new prescribed medication record with adjusted dosage
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
    "CreatedAt"
)
VALUES (
    prescription_id,
    medication_id,
    120.00,                      
    2.00,                    
    'active',
    '1111111',   
    CURRENT_DATE,
    FALSE,
    'Lisinopril (10mg)',
    3,
    NOW()
);


END $$;
-- Commit transaction
COMMIT;
