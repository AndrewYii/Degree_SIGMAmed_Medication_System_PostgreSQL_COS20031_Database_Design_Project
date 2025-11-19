-- Set search path
SET search_path TO "SIGMAmed", public;

-- Ensure uuid-ossp exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Use DO block for variables and logic
DO $$
DECLARE 
    user_id UUID;
BEGIN
    -- Get user ID
    SELECT "UserId"
    INTO user_id
    FROM "SIGMAmed"."User"
    WHERE "ICPassportNumber" = '040fb724-6e8d-4ace-9d37-630633d7823f'
      AND "IsDeleted" = FALSE;

    -- Run MedicalHistory SELECT, but discard output
    PERFORM *
    FROM "SIGMAmed"."MedicalHistory"
    WHERE "PatientId" = user_id
      AND "IsDeleted" = FALSE;

END $$;

-- Create the view OUTSIDE the DO block
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
    PM."TimesPerDay"
FROM "SIGMAmed"."Prescription" AS P
INNER JOIN "SIGMAmed"."PrescribedMedication" AS PM
    ON P."PrescriptionId" = PM."PrescriptionId"
INNER JOIN "SIGMAmed"."User" AS U
    ON P."PatientId" = U."UserId"
WHERE P."IsDeleted" = FALSE;

-- View query
SELECT * FROM "SIGMAmed"."PatientPrescriptionsView";
