-- Set search path
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Use DO block for variables and logic
DO $$
DECLARE 
    user_id UUID;
    medical_history1_id UUID;
    medical_history2_id UUID;
    hospital_admin_id UUID;
    hospital_doctor_id UUID;
BEGIN
    -- Get user ID
    SELECT "UserId"
    INTO user_id
    FROM "SIGMAmed"."User"
    WHERE "ICPassportNumber" = 'XH69273838'
      AND "IsDeleted" = FALSE;

-- For dummy data 
-- Insert into the previous medical history table
-- Select the hospital admin role for Gleaneagles Hospital
-- Select the doctor id from new hospital
    SELECT "UserId"
    FROM "SIGMAmed"."User" INTO hospital_doctor_id
    WHERE "ICPassportNumber" = 'GH2849372949';
RAISE NOTICE 'Switching ActedBy user to hospital doctor ID: %', hospital_doctor_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(hospital_doctor_id);
INSERT INTO "SIGMAmed"."MedicalHistory" (
    "PatientId",
    "DiseaseName",
    "Severity",
    "DiagnosedDate",
    "ResolutionDate",
    "IsDeleted",
    "UpdatedAt"
)
VALUES (
    user_id,
    'Hypertension Stage 1',
    'moderate',
    '2023-05-12',
    '2024-01-20',
    FALSE,
    NOW()
)
RETURNING "MedicalHistoryId" INTO medical_history1_id;

INSERT INTO "SIGMAmed"."MedicalHistory" (
    "PatientId",
    "DiseaseName",
    "Severity",
    "DiagnosedDate",
    "ResolutionDate",
    "IsDeleted",
    "UpdatedAt"
)
VALUES (
    user_id,
    'Acute Bronchitis',
    'mild',
    '2024-02-10',
    '2024-03-01',
    FALSE,
    NOW()
)
RETURNING "MedicalHistoryId" INTO medical_history2_id;


-- Insert into the patient symptom table
INSERT INTO "SIGMAmed"."PatientSymptom" (
    "MedicalHistoryId",
    "PatientId",
    "SymptomName",
    "Severity",
    "OnsetDate",
    "ResolutionDate",
    "CreatedAt",
    "IsDeleted",
    "UpdatedAt"
)
VALUES
(
    medical_history1_id,
    user_id,
    'Headache',
    'mild',
    NOW(),
    NULL,
    NULL,
    FALSE, 
    NOW() 
),

(
    medical_history1_id,
    user_id,
    'Fatigue',
    'mild',
    NOW(),
    NULL,
    NULL,
    FALSE, 
    NOW() 
),

(
    medical_history1_id,
    user_id,
    'Mild chest pressure',
    'mild',
    NOW(),
    NULL,
    NULL,
    FALSE, 
    NOW() 
),

(
    medical_history2_id,
    user_id,
    'Chest congestion',
    'mild',
    NOW(),
    NULL,
    NULL,
    FALSE, 
    NOW() 
),

(
    medical_history2_id,
    user_id,
    'Sore throat',
    'mild',
    NOW(),
    NULL,
    NULL,
    FALSE, 
    NOW() 
),

(
    medical_history2_id,
    user_id,
    'Shortness of breath',
    'mild',
    NOW(),
    NULL,
    NULL,
    FALSE, 
    NOW() 
);

-- Create the view of medical history with patient symptom
CREATE OR REPLACE VIEW "SIGMAmed"."PatientMedicalHistoryView" AS
SELECT
	U."FirstName",
	U."LastName",
	MH."DiseaseName",
	MH."Severity" AS "DiseaseSeverity",
	MH."DiagnosedDate",
	MH."ResolutionDate" AS "DiseaseResolution",
	PS."SymptomName",
    PS."Severity" AS "SymptomSeverity",
    PS."OnsetDate",
    PS."ResolutionDate" AS "SymptomResolution"
FROM
	"SIGMAmed"."MedicalHistory" AS MH
	INNER JOIN "SIGMAmed"."User" AS U ON U."UserId" = MH."PatientId"
	INNER JOIN "SIGMAmed"."PatientSymptom" AS PS ON MH."MedicalHistoryId" = PS."MedicalHistoryId"
WHERE
	MH."IsDeleted" = FALSE;

END $$;

-- Create the view of patient's prescription 
CREATE OR REPLACE VIEW "SIGMAmed"."PatientPrescriptionsView" AS
SELECT 
    U."FirstName", 
    U."LastName", 
    P."Status" AS "Prescription Status",
    P."PrescribedDate" AS "Prescription Prescribed Date",
    P."ExpiryDate",
    PM."MedicationNameSnapshot",
    PM."DosageAmountPrescribed",
    PM."DosePerTime",
    PM."Status" AS "Prescribed Medication Status",
    PM."DefaultDayMask",
    PM."PrescribedDate" AS "Medication Prescribed Date",
    PM."TimesPerDay",
    PSE."SideEffectName",
    PSE."Severity",
    PSE."OnsetDate",
    PSE."ResolutionDate"
FROM "SIGMAmed"."Prescription" AS P
INNER JOIN "SIGMAmed"."PrescribedMedication" AS PM
    ON P."PrescriptionId" = PM."PrescriptionId"
INNER JOIN "SIGMAmed"."User" AS U
    ON P."PatientId" = U."UserId"
INNER JOIN "SIGMAmed"."PatientSideEffect" AS PSE
    ON PM."PrescribedMedicationId" = PSE."PrescribedMedicationId"
WHERE P."IsDeleted" = FALSE;

-- View query
SELECT * FROM "SIGMAmed"."PatientPrescriptionsView";







