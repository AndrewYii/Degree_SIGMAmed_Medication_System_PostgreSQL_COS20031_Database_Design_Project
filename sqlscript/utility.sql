-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- FUNCTION: Calculate age from date of birth
CREATE OR REPLACE FUNCTION "SIGMAmed".calculate_age(birth_date DATE)
RETURNS INT AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(birth_date));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION "SIGMAmed".calculate_age IS 'Calculate age in years from date of birth';

-- FUNCTION: Get patient's primary doctor
CREATE OR REPLACE FUNCTION "SIGMAmed".get_primary_doctor(p_patient_id UUID)
RETURNS TABLE (
    "DoctorId" UUID,
    "DoctorName" TEXT,
    "Specialization" VARCHAR,
    "Phone" VARCHAR,
    "Email" CITEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d."UserId",
        u."FirstName" || ' ' || u."LastName",
        d."Specialization",
        u."Phone",
        u."Email"
    FROM "SIGMAmed"."AssignedDoctor" ad
    JOIN "SIGMAmed"."Doctor" d ON ad."DoctorId" = d."UserId"
    JOIN "SIGMAmed"."User" u ON d."UserId" = u."UserId"
    WHERE ad."PatientId" = p_patient_id
      AND ad."DoctorLevel" = 'primary'
      AND ad."IsDeleted" = FALSE
      AND u."IsDeleted" = FALSE
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION "SIGMAmed".get_primary_doctor IS 'Retrieve primary doctor for a patient';

-- FUNCTION: Check if patient has allergy to medication
CREATE OR REPLACE FUNCTION "SIGMAmed".check_medication_allergy(
    p_patient_id UUID,
    p_medication_name VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_allergies JSONB;
    v_allergy TEXT;
BEGIN
    SELECT "MedicationAllergies" INTO v_allergies
    FROM "SIGMAmed"."Patient"
    WHERE "UserId" = p_patient_id;
    
    IF v_allergies IS NULL OR v_allergies = '[]'::JSONB THEN
        RETURN FALSE;
    END IF;
    
    FOR v_allergy IN SELECT jsonb_array_elements_text(v_allergies)
    LOOP
        IF LOWER(p_medication_name) LIKE '%' || LOWER(v_allergy) || '%' THEN
            RETURN TRUE;
        END IF;
    END LOOP;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION "SIGMAmed".check_medication_allergy IS 'Check if patient is allergic to a medication';

-- FUNCTION: Get active prescribed medications for patient
CREATE OR REPLACE FUNCTION "SIGMAmed".get_active_prescribed_medications(p_patient_id UUID)
RETURNS TABLE (
    "PrescriptionId" UUID,
    "PrescriptionNumber" VARCHAR,
    "PrescribedMedicationId" UUID,
    "MedicationName" VARCHAR,
    "StartDate" DATE,
    "EndDate" DATE,
    "DosageInstruction" TEXT,
    "DoctorName" TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p."PrescriptionId",
        p."PrescriptionNumber",
        pm."PrescribedMedicationId",
        m."MedicationName",
        pm."StartDate",
        pm."EndDate",
        pm."DosageInstruction",
        u."FirstName" || ' ' || u."LastName" AS "DoctorName"
    FROM "SIGMAmed"."Prescription" p
    JOIN "SIGMAmed"."PrescribedMedication" pm ON p."PrescriptionId" = pm."PrescriptionId"
    JOIN "SIGMAmed"."Medication" m ON pm."MedicationId" = m."MedicationID"
    JOIN "SIGMAmed"."User" u ON p."DoctorId" = u."UserId"
    WHERE p."PatientId" = p_patient_id
      AND p."Status" = 'active'
      AND p."IsDeleted" = FALSE
      AND pm."IsDeleted" = FALSE
      AND pm."EndDate" >= CURRENT_DATE
    ORDER BY pm."StartDate" DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION "SIGMAmed".get_active_prescribed_medications IS 'Get all active prescribed medications for a patient';

-- FUNCTION: Get upcoming appointments
CREATE OR REPLACE FUNCTION "SIGMAmed".get_upcoming_appointments(
    p_user_id UUID,
    p_days_ahead INT DEFAULT 7
)
RETURNS TABLE (
    "AppointmentId" UUID,
    "AppointmentDate" DATE,
    "AppointmentTime" TIME,
    "DoctorName" TEXT,
    "PatientName" TEXT,
    "Status" "SIGMAmed".appointment_status_enum,
    "AppointmentType" "SIGMAmed".appointment_type_enum
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a."AppointmentId",
        a."AppointmentDate",
        a."AppointmentTime",
        doc."FirstName" || ' ' || doc."LastName" AS "DoctorName",
        pat."FirstName" || ' ' || pat."LastName" AS "PatientName",
        a."Status",
        a."AppointmentType"
    FROM "SIGMAmed"."Appointment" a
    JOIN "SIGMAmed"."User" doc ON a."DoctorId" = doc."UserId"
    JOIN "SIGMAmed"."User" pat ON a."PatientId" = pat."UserId"
    WHERE (a."DoctorId" = p_user_id OR a."PatientId" = p_user_id)
      AND a."AppointmentDate" BETWEEN CURRENT_DATE AND (CURRENT_DATE + p_days_ahead)
      AND a."Status" IN ('scheduled', 'confirmed')
      AND a."IsDeleted" = FALSE
    ORDER BY a."AppointmentDate", a."AppointmentTime";
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION "SIGMAmed".get_upcoming_appointments IS 'Get upcoming appointments for a user (doctor or patient)';

-- =====================================================
-- STEP 8: DATA CLEANUP & MAINTENANCE FUNCTIONS
-- =====================================================

-- FUNCTION: Archive old logs (keep last 2 years)
CREATE OR REPLACE FUNCTION "SIGMAmed".archive_old_logs(p_retention_days INT DEFAULT 730)
RETURNS TABLE (
    "TableName" TEXT,
    "DeletedRows" BIGINT
) AS $$
DECLARE
    v_cutoff_date TIMESTAMPTZ;
    v_deleted BIGINT;
BEGIN
    v_cutoff_date := NOW() - (p_retention_days || ' days')::INTERVAL;
    
    -- UserLog
    DELETE FROM "SIGMAmed"."UserLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'UserLog'::TEXT, v_deleted;
    
    -- AssignedDoctorLog
    DELETE FROM "SIGMAmed"."AssignedDoctorLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'AssignedDoctorLog'::TEXT, v_deleted;
    
    -- MedicalHistoryLog
    DELETE FROM "SIGMAmed"."MedicalHistoryLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'MedicalHistoryLog'::TEXT, v_deleted;
    
    -- MedicationLog
    DELETE FROM "SIGMAmed"."MedicationLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'MedicationLog'::TEXT, v_deleted;
    
    -- PrescriptionLog
    DELETE FROM "SIGMAmed"."PrescriptionLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'PrescriptionLog'::TEXT, v_deleted;
    
    -- PrescribedMedicationLog
    DELETE FROM "SIGMAmed"."PrescribedMedicationLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'PrescribedMedicationLog'::TEXT, v_deleted;
    
    -- PrescribedMedicationScheduleLog
    DELETE FROM "SIGMAmed"."PrescribedMedicationScheduleLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'PrescribedMedicationScheduleLog'::TEXT, v_deleted;
    
    -- PatientSideEffectLog
    DELETE FROM "SIGMAmed"."PatientSideEffectLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'PatientSideEffectLog'::TEXT, v_deleted;
    
    -- PatientReportLog
    DELETE FROM "SIGMAmed"."PatientReportLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'PatientReportLog'::TEXT, v_deleted;
    
    -- AppointmentLog
    DELETE FROM "SIGMAmed"."AppointmentLog" WHERE "ActedAt" < v_cutoff_date;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN QUERY SELECT 'AppointmentLog'::TEXT, v_deleted;
    
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION "SIGMAmed".archive_old_logs IS 'Archive (delete) old log entries older than specified days (default: 2 years)';