-- Set search path
SET search_path TO "SIGMAmed", public;

-- Ensure UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

DO $$
DECLARE 
    user_id UUID;
    medication_id UUID;
    hospital_doctor_id UUID;
BEGIN
-- Select the doctor id from new hospital
    SELECT "UserId"
    FROM "SIGMAmed"."User" INTO hospital_doctor_id
    WHERE "ICPassportNumber" = 'GH2849372949';
RAISE NOTICE 'Switching ActedBy user to hospital doctor ID: %', hospital_doctor_id;
EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(hospital_doctor_id);
    -- Select Patient based on ICPassportNumber
    SELECT "UserId" 
    INTO user_id 
    FROM "SIGMAmed"."User" 
    WHERE "ICPassportNumber"='XH69273838'
      AND "IsDeleted"=FALSE;

    -- Select the medication id based on medication name
    SELECT "MedicationId"
    INTO medication_id
    FROM "SIGMAmed"."Medication"
    WHERE "MedicationName"='Lisinopril (10mg)'
      AND "IsDeleted"=FALSE;

    -- -- Create the view of all MedicationAdherenceRecord
    EXECUTE '
        CREATE OR REPLACE VIEW "SIGMAmed"."PatientAdherenceRecordView" AS
        SELECT
            U."UserId",
            U."FirstName",
            U."LastName",
            PM."MedicationId",
            PM."DosePerTime",
            M."MedicationName",
            P."PrescriptionNumber",
            MAR."ScheduledTime",
            MAR."DoseQuantity",
            MAR."CurrentStatus",
            MAR."ActionTime"
        FROM "SIGMAmed"."MedicationAdherenceRecord" AS MAR
        INNER JOIN "SIGMAmed"."PrescribedMedicationSchedule" AS PMS 
            ON MAR."PrescribedMedicationScheduleId" = PMS."PrescribedMedicationScheduleId"
        INNER JOIN "SIGMAmed"."PrescribedMedication" AS PM 
            ON PMS."PrescribedMedicationId" = PM."PrescribedMedicationId"
        INNER JOIN "SIGMAmed"."Medication" AS M 
            ON PM."MedicationId" = M."MedicationId"
        INNER JOIN "SIGMAmed"."Prescription" AS P 
            ON PM."PrescriptionId" = P."PrescriptionId"
        INNER JOIN "SIGMAmed"."User" AS U 
            ON P."PatientId" = U."UserId"
        WHERE PM."IsDeleted" = FALSE 
          AND P."IsDeleted" = FALSE 
          AND U."IsDeleted" = FALSE;
    ';

    -- Taken medication on time and with correct dosage
    RAISE NOTICE 'Taken on time and correct dosage:';
    PERFORM *
    FROM "SIGMAmed"."PatientAdherenceRecordView"
    WHERE "UserId" = user_id
      AND "MedicationId" = medication_id
      AND "CurrentStatus" = 'Taken'
      AND "ActionTime" <= "ScheduledTime" + INTERVAL '30 minutes'
      AND "DoseQuantity" = "DosePerTime" 
      AND "ScheduledTime" >= CURRENT_DATE - INTERVAL '30 days';

    -- Missed the medication
    RAISE NOTICE 'Missed the medication:';
    PERFORM *
    FROM "SIGMAmed"."PatientAdherenceRecordView"
    WHERE "UserId" = user_id
      AND "MedicationId" = medication_id
      AND "CurrentStatus" = 'Missed'
      AND "ScheduledTime" >= CURRENT_DATE - INTERVAL '30 days';

    -- Taken medication but does not on time 
    RAISE NOTICE 'Taken on time but does not on time:';
    PERFORM *
    FROM "SIGMAmed"."PatientAdherenceRecordView"
    WHERE "UserId" = user_id
      AND "MedicationId" = medication_id
      AND "CurrentStatus" = 'Taken'
      AND "ActionTime" > "ScheduledTime" + INTERVAL '30 minutes'
      AND "ScheduledTime" >= CURRENT_DATE - INTERVAL '30 days';
    -- Taken medication but with overdose
    RAISE NOTICE 'Taken on time with overdosage:';
    PERFORM *
    FROM "SIGMAmed"."PatientAdherenceRecordView"
    WHERE "UserId" = user_id
      AND "MedicationId" = medication_id
      AND "CurrentStatus" = 'Taken'
      AND "ActionTime" <= "ScheduledTime" + INTERVAL '30 minutes' AND "DoseQuantity" > "DosePerTime"
      AND "ScheduledTime" >= CURRENT_DATE - INTERVAL '30 days';

    -- Taken medication but with under dosage
    RAISE NOTICE 'Taken on time with under dosage:';
    PERFORM *
    FROM "SIGMAmed"."PatientAdherenceRecordView"
    WHERE "UserId" = user_id
      AND "MedicationId" = medication_id
      AND "CurrentStatus" = 'Taken'
      AND "ActionTime" <= "ScheduledTime" + INTERVAL '30 minutes' AND "DoseQuantity" < "DosePerTime"
      AND "ScheduledTime" >= CURRENT_DATE - INTERVAL '30 days';

END $$;