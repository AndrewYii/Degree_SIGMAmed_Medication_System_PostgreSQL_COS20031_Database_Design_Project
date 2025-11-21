-- SIGMAMED RBAC Security Implementation
-- Row-Level Security policies for Super Admin, Hospital Admin, Doctor, Patient
-- NOTE: sigmamed_superadmin role = Admin table with AdminLevel='super'
--       sigmamed_hospital_admin role = Admin table with AdminLevel='hospital'

SET search_path TO "SIGMAmed", public;

-- CREATE DATABASE ROLES

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'sigmamed_superadmin') THEN
        CREATE ROLE sigmamed_superadmin;
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'sigmamed_hospital_admin') THEN
        CREATE ROLE sigmamed_hospital_admin;
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'sigmamed_doctor') THEN
        CREATE ROLE sigmamed_doctor;
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'sigmamed_patient') THEN
        CREATE ROLE sigmamed_patient;
    END IF;
END
$$;

-- GRANT TABLE PERMISSIONS
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA "SIGMAmed" TO sigmamed_superadmin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA "SIGMAmed" TO sigmamed_superadmin;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."User" TO sigmamed_hospital_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."Admin" TO sigmamed_hospital_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."Doctor" TO sigmamed_hospital_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."Patient" TO sigmamed_hospital_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."PatientCareTeam" TO sigmamed_hospital_admin;
GRANT SELECT, UPDATE ON TABLE "SIGMAmed"."ClinicalInstitution" TO sigmamed_hospital_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."Medication" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."Appointment" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."AppointmentReminder" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."Prescription" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."PrescribedMedication" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."PrescribedMedicationSchedule" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."MedicationAdherenceRecord" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."MedicalHistory" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."PatientSymptom" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."PatientSideEffect" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."PatientReport" TO sigmamed_hospital_admin;
GRANT SELECT ON TABLE "SIGMAmed"."AuditLog" TO sigmamed_hospital_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA "SIGMAmed" TO sigmamed_hospital_admin;

GRANT SELECT ON TABLE "SIGMAmed"."User" TO sigmamed_doctor;
GRANT SELECT ON TABLE "SIGMAmed"."Doctor" TO sigmamed_doctor;
GRANT SELECT ON TABLE "SIGMAmed"."Patient" TO sigmamed_doctor;
GRANT SELECT ON TABLE "SIGMAmed"."ClinicalInstitution" TO sigmamed_doctor;
GRANT SELECT ON TABLE "SIGMAmed"."Medication" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."PatientCareTeam" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."Appointment" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."AppointmentReminder" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."Prescription" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."PrescribedMedication" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."PrescribedMedicationSchedule" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."MedicationAdherenceRecord" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."MedicalHistory" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."PatientSymptom" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."PatientSideEffect" TO sigmamed_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "SIGMAmed"."PatientReport" TO sigmamed_doctor;
GRANT SELECT ON TABLE "SIGMAmed"."AuditLog" TO sigmamed_doctor;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA "SIGMAmed" TO sigmamed_doctor;

GRANT SELECT ON TABLE "SIGMAmed"."User" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."Patient" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."ClinicalInstitution" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."Medication" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."PatientCareTeam" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."Appointment" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."AppointmentReminder" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."Prescription" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."PrescribedMedication" TO sigmamed_patient;
GRANT SELECT, UPDATE ON TABLE "SIGMAmed"."PrescribedMedicationSchedule" TO sigmamed_patient;
GRANT SELECT, UPDATE ON TABLE "SIGMAmed"."MedicationAdherenceRecord" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."MedicalHistory" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."PatientSymptom" TO sigmamed_patient;
GRANT SELECT ON TABLE "SIGMAmed"."PatientSideEffect" TO sigmamed_patient;
GRANT SELECT, INSERT, UPDATE ON TABLE "SIGMAmed"."PatientReport" TO sigmamed_patient;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA "SIGMAmed" TO sigmamed_patient;

-- SECURITY HELPER FUNCTIONS
CREATE OR REPLACE FUNCTION "SIGMAmed".current_user_id()
RETURNS UUID AS $$
BEGIN
    RETURN NULLIF(current_setting('app.current_user_id', true), '')::UUID;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
CREATE OR REPLACE FUNCTION "SIGMAmed".current_user_role()
RETURNS "SIGMAmed".user_role_enum AS $$
DECLARE
    user_role "SIGMAmed".user_role_enum;
BEGIN
    SELECT "Role" INTO user_role
    FROM "SIGMAmed"."User"
    WHERE "UserId" = "SIGMAmed".current_user_id();
    
    RETURN user_role;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "SIGMAmed".current_user_institution()
RETURNS UUID AS $$
DECLARE
    institution_id UUID;
BEGIN
    SELECT "ClinicalInstitutionId" INTO institution_id
    FROM "SIGMAmed"."User"
    WHERE "UserId" = "SIGMAmed".current_user_id();
    
    RETURN institution_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "SIGMAmed".is_patients_doctor(patient_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM "SIGMAmed"."PatientCareTeam"
        WHERE "DoctorId" = "SIGMAmed".current_user_id()
        AND "PatientId" = patient_id
        AND "IsActive" = true
        AND "IsDeleted" = false
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "SIGMAmed".is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM "SIGMAmed"."Admin" a
        JOIN "SIGMAmed"."User" u ON a."UserId" = u."UserId"
        WHERE u."UserId" = "SIGMAmed".current_user_id()
        AND a."AdminLevel" = 'super'
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "SIGMAmed".is_hospital_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM "SIGMAmed"."Admin" a
        JOIN "SIGMAmed"."User" u ON a."UserId" = u."UserId"
        WHERE u."UserId" = "SIGMAmed".current_user_id()
        AND a."AdminLevel" = 'hospital'
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ENABLE ROW-LEVEL SECURITY (FORCE ensures even table owners must obey RLS)

ALTER TABLE "SIGMAmed"."ClinicalInstitution" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Admin" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Doctor" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Patient" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Medication" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."PatientCareTeam" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Appointment" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."AppointmentReminder" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Prescription" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."PrescribedMedication" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."PrescribedMedicationSchedule" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."MedicationAdherenceRecord" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."MedicalHistory" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."PatientSymptom" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."PatientSideEffect" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."PatientReport" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."AuditLog" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "SIGMAmed"."User" FORCE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Admin" FORCE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Doctor" FORCE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Patient" FORCE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."Prescription" FORCE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."MedicalHistory" FORCE ROW LEVEL SECURITY;
ALTER TABLE "SIGMAmed"."AuditLog" FORCE ROW LEVEL SECURITY;

-- ROW-LEVEL SECURITY POLICIES

-- ClinicalInstitution
CREATE POLICY superadmin_clinicalinstitution_all ON "SIGMAmed"."ClinicalInstitution"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

-- Hospital Admin: Can only see and update their own institution
CREATE POLICY hospital_admin_clinicalinstitution_select ON "SIGMAmed"."ClinicalInstitution"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution());

CREATE POLICY hospital_admin_clinicalinstitution_update ON "SIGMAmed"."ClinicalInstitution"
    FOR UPDATE
    TO sigmamed_hospital_admin
    USING ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution())
    WITH CHECK ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution());

CREATE POLICY doctor_clinicalinstitution_select ON "SIGMAmed"."ClinicalInstitution"
    FOR SELECT
    TO sigmamed_doctor
    USING (true);

CREATE POLICY patient_clinicalinstitution_select ON "SIGMAmed"."ClinicalInstitution"
    FOR SELECT
    TO sigmamed_patient
    USING (true);

-- User
CREATE POLICY superadmin_user_all ON "SIGMAmed"."User"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

-- Hospital Admin: Can manage users in their institution
CREATE POLICY hospital_admin_user_select ON "SIGMAmed"."User"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution());

CREATE POLICY hospital_admin_user_insert ON "SIGMAmed"."User"
    FOR INSERT
    TO sigmamed_hospital_admin
    WITH CHECK ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution());

CREATE POLICY hospital_admin_user_update ON "SIGMAmed"."User"
    FOR UPDATE
    TO sigmamed_hospital_admin
    USING ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution())
    WITH CHECK ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution());

CREATE POLICY hospital_admin_user_delete ON "SIGMAmed"."User"
    FOR DELETE
    TO sigmamed_hospital_admin
    USING ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution());

CREATE POLICY doctor_user_select ON "SIGMAmed"."User"
    FOR SELECT
    TO sigmamed_doctor
    USING (
        "UserId" = "SIGMAmed".current_user_id() OR
        "SIGMAmed".is_patients_doctor("UserId")
    );

CREATE POLICY patient_user_select ON "SIGMAmed"."User"
    FOR SELECT
    TO sigmamed_patient
    USING ("UserId" = "SIGMAmed".current_user_id());

-- Admin
CREATE POLICY superadmin_admin_all ON "SIGMAmed"."Admin"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_admin_select ON "SIGMAmed"."Admin"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Admin"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY hospital_admin_admin_insert ON "SIGMAmed"."Admin"
    FOR INSERT
    TO sigmamed_hospital_admin
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Admin"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY hospital_admin_admin_update ON "SIGMAmed"."Admin"
    FOR UPDATE
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Admin"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Admin"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY hospital_admin_admin_delete ON "SIGMAmed"."Admin"
    FOR DELETE
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Admin"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

-- Doctor
CREATE POLICY superadmin_doctor_all ON "SIGMAmed"."Doctor"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_doctor_select ON "SIGMAmed"."Doctor"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Doctor"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY hospital_admin_doctor_insert ON "SIGMAmed"."Doctor"
    FOR INSERT
    TO sigmamed_hospital_admin
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Doctor"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY hospital_admin_doctor_update ON "SIGMAmed"."Doctor"
    FOR UPDATE
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Doctor"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Doctor"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY hospital_admin_doctor_delete ON "SIGMAmed"."Doctor"
    FOR DELETE
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Doctor"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_doctor_select ON "SIGMAmed"."Doctor"
    FOR SELECT
    TO sigmamed_doctor
    USING (
        "UserId" = "SIGMAmed".current_user_id() OR
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PatientCareTeam" pct1
            WHERE pct1."DoctorId" = "Doctor"."UserId"
            AND pct1."IsActive" = true
            AND pct1."IsDeleted" = false
            AND pct1."PatientId" IN (
                SELECT pct2."PatientId" FROM "SIGMAmed"."PatientCareTeam" pct2
                WHERE pct2."DoctorId" = "SIGMAmed".current_user_id()
                AND pct2."IsActive" = true
                AND pct2."IsDeleted" = false
            )
        )
    );

-- Patient
CREATE POLICY superadmin_patient_all ON "SIGMAmed"."Patient"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_patient_select ON "SIGMAmed"."Patient"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Patient"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY hospital_admin_patient_insert ON "SIGMAmed"."Patient"
    FOR INSERT
    TO sigmamed_hospital_admin
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Patient"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY hospital_admin_patient_update ON "SIGMAmed"."Patient"
    FOR UPDATE
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Patient"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Patient"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY hospital_admin_patient_delete ON "SIGMAmed"."Patient"
    FOR DELETE
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Patient"."UserId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_patient_select ON "SIGMAmed"."Patient"
    FOR SELECT
    TO sigmamed_doctor
    USING ("SIGMAmed".is_patients_doctor("UserId"));

CREATE POLICY patient_patient_select ON "SIGMAmed"."Patient"
    FOR SELECT
    TO sigmamed_patient
    USING ("UserId" = "SIGMAmed".current_user_id());

-- Medication
CREATE POLICY superadmin_medication_all ON "SIGMAmed"."Medication"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

-- Hospital Admin: Full access to their institution's medications
CREATE POLICY hospital_admin_medication_all ON "SIGMAmed"."Medication"
    FOR ALL
    TO sigmamed_hospital_admin
    USING ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution())
    WITH CHECK ("ClinicalInstitutionId" = "SIGMAmed".current_user_institution());

CREATE POLICY doctor_medication_select ON "SIGMAmed"."Medication"
    FOR SELECT
    TO sigmamed_doctor
    USING (true);

CREATE POLICY patient_medication_select ON "SIGMAmed"."Medication"
    FOR SELECT
    TO sigmamed_patient
    USING (true);

-- PatientCareTeam
CREATE POLICY superadmin_careteam_all ON "SIGMAmed"."PatientCareTeam"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

-- Hospital Admin: Can manage care teams in their institution
CREATE POLICY hospital_admin_careteam_all ON "SIGMAmed"."PatientCareTeam"
    FOR ALL
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "PatientCareTeam"."DoctorId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "PatientCareTeam"."DoctorId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_careteam_all ON "SIGMAmed"."PatientCareTeam"
    FOR ALL
    TO sigmamed_doctor
    USING ("DoctorId" = "SIGMAmed".current_user_id())
    WITH CHECK ("DoctorId" = "SIGMAmed".current_user_id());

CREATE POLICY patient_careteam_select ON "SIGMAmed"."PatientCareTeam"
    FOR SELECT
    TO sigmamed_patient
    USING ("PatientId" = "SIGMAmed".current_user_id());

-- Appointment
CREATE POLICY superadmin_appointment_all ON "SIGMAmed"."Appointment"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

-- Hospital Admin: Read-only for their institution
CREATE POLICY hospital_admin_appointment_select ON "SIGMAmed"."Appointment"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Appointment"."DoctorId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_appointment_all ON "SIGMAmed"."Appointment"
    FOR ALL
    TO sigmamed_doctor
    USING ("DoctorId" = "SIGMAmed".current_user_id())
    WITH CHECK ("DoctorId" = "SIGMAmed".current_user_id());

CREATE POLICY patient_appointment_select ON "SIGMAmed"."Appointment"
    FOR SELECT
    TO sigmamed_patient
    USING ("PatientId" = "SIGMAmed".current_user_id());

-- AppointmentReminder
CREATE POLICY superadmin_appt_reminder_all ON "SIGMAmed"."AppointmentReminder"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_appt_reminder_select ON "SIGMAmed"."AppointmentReminder"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."Appointment" a
            JOIN "SIGMAmed"."User" u ON a."DoctorId" = u."UserId"
            WHERE a."AppointmentId" = "AppointmentReminder"."AppointmentId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_appt_reminder_all ON "SIGMAmed"."AppointmentReminder"
    FOR ALL
    TO sigmamed_doctor
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."Appointment" a
            WHERE a."AppointmentId" = "AppointmentReminder"."AppointmentId"
            AND a."DoctorId" = "SIGMAmed".current_user_id()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."Appointment" a
            WHERE a."AppointmentId" = "AppointmentReminder"."AppointmentId"
            AND a."DoctorId" = "SIGMAmed".current_user_id()
        )
    );

CREATE POLICY patient_appt_reminder_select ON "SIGMAmed"."AppointmentReminder"
    FOR SELECT
    TO sigmamed_patient
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."Appointment" a
            WHERE a."AppointmentId" = "AppointmentReminder"."AppointmentId"
            AND a."PatientId" = "SIGMAmed".current_user_id()
        )
    );

-- Prescription
CREATE POLICY superadmin_prescription_all ON "SIGMAmed"."Prescription"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_prescription_select ON "SIGMAmed"."Prescription"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "Prescription"."DoctorId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_prescription_all ON "SIGMAmed"."Prescription"
    FOR ALL
    TO sigmamed_doctor
    USING ("SIGMAmed".is_patients_doctor("PatientId"))
    WITH CHECK ("SIGMAmed".is_patients_doctor("PatientId"));

CREATE POLICY patient_prescription_select ON "SIGMAmed"."Prescription"
    FOR SELECT
    TO sigmamed_patient
    USING ("PatientId" = "SIGMAmed".current_user_id());

-- PrescribedMedication
CREATE POLICY superadmin_prescribed_med_all ON "SIGMAmed"."PrescribedMedication"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_prescribed_med_select ON "SIGMAmed"."PrescribedMedication"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."Prescription" p
            JOIN "SIGMAmed"."User" u ON p."DoctorId" = u."UserId"
            WHERE p."PrescriptionId" = "PrescribedMedication"."PrescriptionId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_prescribed_med_all ON "SIGMAmed"."PrescribedMedication"
    FOR ALL
    TO sigmamed_doctor
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."Prescription" p
            WHERE p."PrescriptionId" = "PrescribedMedication"."PrescriptionId"
            AND "SIGMAmed".is_patients_doctor(p."PatientId")
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."Prescription" p
            WHERE p."PrescriptionId" = "PrescribedMedication"."PrescriptionId"
            AND "SIGMAmed".is_patients_doctor(p."PatientId")
        )
    );

CREATE POLICY patient_prescribed_med_select ON "SIGMAmed"."PrescribedMedication"
    FOR SELECT
    TO sigmamed_patient
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."Prescription" p
            WHERE p."PrescriptionId" = "PrescribedMedication"."PrescriptionId"
            AND p."PatientId" = "SIGMAmed".current_user_id()
        )
    );

-- PrescribedMedicationSchedule
CREATE POLICY superadmin_med_schedule_all ON "SIGMAmed"."PrescribedMedicationSchedule"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_med_schedule_select ON "SIGMAmed"."PrescribedMedicationSchedule"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            JOIN "SIGMAmed"."User" u ON p."DoctorId" = u."UserId"
            WHERE pm."PrescribedMedicationId" = "PrescribedMedicationSchedule"."PrescribedMedicationId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_med_schedule_all ON "SIGMAmed"."PrescribedMedicationSchedule"
    FOR ALL
    TO sigmamed_doctor
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pm."PrescribedMedicationId" = "PrescribedMedicationSchedule"."PrescribedMedicationId"
            AND "SIGMAmed".is_patients_doctor(p."PatientId")
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pm."PrescribedMedicationId" = "PrescribedMedicationSchedule"."PrescribedMedicationId"
            AND "SIGMAmed".is_patients_doctor(p."PatientId")
        )
    );

CREATE POLICY patient_med_schedule_select ON "SIGMAmed"."PrescribedMedicationSchedule"
    FOR SELECT
    TO sigmamed_patient
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pm."PrescribedMedicationId" = "PrescribedMedicationSchedule"."PrescribedMedicationId"
            AND p."PatientId" = "SIGMAmed".current_user_id()
        )
    );

CREATE POLICY patient_med_schedule_update ON "SIGMAmed"."PrescribedMedicationSchedule"
    FOR UPDATE
    TO sigmamed_patient
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pm."PrescribedMedicationId" = "PrescribedMedicationSchedule"."PrescribedMedicationId"
            AND p."PatientId" = "SIGMAmed".current_user_id()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pm."PrescribedMedicationId" = "PrescribedMedicationSchedule"."PrescribedMedicationId"
            AND p."PatientId" = "SIGMAmed".current_user_id()
        )
    );

-- MedicationAdherenceRecord
CREATE POLICY superadmin_adherence_all ON "SIGMAmed"."MedicationAdherenceRecord"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_adherence_select ON "SIGMAmed"."MedicationAdherenceRecord"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedicationSchedule" pms
            JOIN "SIGMAmed"."PrescribedMedication" pm ON pms."PrescribedMedicationId" = pm."PrescribedMedicationId"
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            JOIN "SIGMAmed"."User" u ON p."DoctorId" = u."UserId"
            WHERE pms."PrescribedMedicationScheduleId" = "MedicationAdherenceRecord"."PrescribedMedicationScheduleId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_adherence_all ON "SIGMAmed"."MedicationAdherenceRecord"
    FOR ALL
    TO sigmamed_doctor
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedicationSchedule" pms
            JOIN "SIGMAmed"."PrescribedMedication" pm ON pms."PrescribedMedicationId" = pm."PrescribedMedicationId"
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pms."PrescribedMedicationScheduleId" = "MedicationAdherenceRecord"."PrescribedMedicationScheduleId"
            AND "SIGMAmed".is_patients_doctor(p."PatientId")
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedicationSchedule" pms
            JOIN "SIGMAmed"."PrescribedMedication" pm ON pms."PrescribedMedicationId" = pm."PrescribedMedicationId"
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pms."PrescribedMedicationScheduleId" = "MedicationAdherenceRecord"."PrescribedMedicationScheduleId"
            AND "SIGMAmed".is_patients_doctor(p."PatientId")
        )
    );

CREATE POLICY patient_adherence_select ON "SIGMAmed"."MedicationAdherenceRecord"
    FOR SELECT
    TO sigmamed_patient
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedicationSchedule" pms
            JOIN "SIGMAmed"."PrescribedMedication" pm ON pms."PrescribedMedicationId" = pm."PrescribedMedicationId"
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pms."PrescribedMedicationScheduleId" = "MedicationAdherenceRecord"."PrescribedMedicationScheduleId"
            AND p."PatientId" = "SIGMAmed".current_user_id()
        )
    );

CREATE POLICY patient_adherence_update ON "SIGMAmed"."MedicationAdherenceRecord"
    FOR UPDATE
    TO sigmamed_patient
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedicationSchedule" pms
            JOIN "SIGMAmed"."PrescribedMedication" pm ON pms."PrescribedMedicationId" = pm."PrescribedMedicationId"
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pms."PrescribedMedicationScheduleId" = "MedicationAdherenceRecord"."PrescribedMedicationScheduleId"
            AND p."PatientId" = "SIGMAmed".current_user_id()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedicationSchedule" pms
            JOIN "SIGMAmed"."PrescribedMedication" pm ON pms."PrescribedMedicationId" = pm."PrescribedMedicationId"
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pms."PrescribedMedicationScheduleId" = "MedicationAdherenceRecord"."PrescribedMedicationScheduleId"
            AND p."PatientId" = "SIGMAmed".current_user_id()
        )
    );

-- MedicalHistory
CREATE POLICY superadmin_medical_history_all ON "SIGMAmed"."MedicalHistory"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_medical_history_select ON "SIGMAmed"."MedicalHistory"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "MedicalHistory"."PatientId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_medical_history_all ON "SIGMAmed"."MedicalHistory"
    FOR ALL
    TO sigmamed_doctor
    USING ("SIGMAmed".is_patients_doctor("PatientId"))
    WITH CHECK ("SIGMAmed".is_patients_doctor("PatientId"));

CREATE POLICY patient_medical_history_select ON "SIGMAmed"."MedicalHistory"
    FOR SELECT
    TO sigmamed_patient
    USING ("PatientId" = "SIGMAmed".current_user_id());

-- PatientSymptom
CREATE POLICY superadmin_symptom_all ON "SIGMAmed"."PatientSymptom"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_symptom_select ON "SIGMAmed"."PatientSymptom"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "PatientSymptom"."PatientId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_symptom_all ON "SIGMAmed"."PatientSymptom"
    FOR ALL
    TO sigmamed_doctor
    USING ("SIGMAmed".is_patients_doctor("PatientId"))
    WITH CHECK ("SIGMAmed".is_patients_doctor("PatientId"));

CREATE POLICY patient_symptom_select ON "SIGMAmed"."PatientSymptom"
    FOR SELECT
    TO sigmamed_patient
    USING ("PatientId" = "SIGMAmed".current_user_id());

-- PatientSideEffect
CREATE POLICY superadmin_side_effect_all ON "SIGMAmed"."PatientSideEffect"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_side_effect_select ON "SIGMAmed"."PatientSideEffect"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            JOIN "SIGMAmed"."User" u ON p."DoctorId" = u."UserId"
            WHERE pm."PrescribedMedicationId" = "PatientSideEffect"."PrescribedMedicationId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_side_effect_all ON "SIGMAmed"."PatientSideEffect"
    FOR ALL
    TO sigmamed_doctor
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pm."PrescribedMedicationId" = "PatientSideEffect"."PrescribedMedicationId"
            AND "SIGMAmed".is_patients_doctor(p."PatientId")
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pm."PrescribedMedicationId" = "PatientSideEffect"."PrescribedMedicationId"
            AND "SIGMAmed".is_patients_doctor(p."PatientId")
        )
    );

CREATE POLICY patient_side_effect_select ON "SIGMAmed"."PatientSideEffect"
    FOR SELECT
    TO sigmamed_patient
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."PrescribedMedication" pm
            JOIN "SIGMAmed"."Prescription" p ON pm."PrescriptionId" = p."PrescriptionId"
            WHERE pm."PrescribedMedicationId" = "PatientSideEffect"."PrescribedMedicationId"
            AND p."PatientId" = "SIGMAmed".current_user_id()
        )
    );

-- PatientReport
CREATE POLICY superadmin_report_all ON "SIGMAmed"."PatientReport"
    FOR ALL
    TO sigmamed_superadmin
    USING (true)
    WITH CHECK (true);

CREATE POLICY hospital_admin_report_select ON "SIGMAmed"."PatientReport"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "PatientReport"."DoctorId"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_report_all ON "SIGMAmed"."PatientReport"
    FOR ALL
    TO sigmamed_doctor
    USING ("SIGMAmed".is_patients_doctor("PatientId"))
    WITH CHECK ("SIGMAmed".is_patients_doctor("PatientId"));

CREATE POLICY patient_report_select ON "SIGMAmed"."PatientReport"
    FOR SELECT
    TO sigmamed_patient
    USING ("PatientId" = "SIGMAmed".current_user_id());

CREATE POLICY patient_report_insert ON "SIGMAmed"."PatientReport"
    FOR INSERT
    TO sigmamed_patient
    WITH CHECK ("PatientId" = "SIGMAmed".current_user_id());

CREATE POLICY patient_report_update ON "SIGMAmed"."PatientReport"
    FOR UPDATE
    TO sigmamed_patient
    USING ("PatientId" = "SIGMAmed".current_user_id())
    WITH CHECK ("PatientId" = "SIGMAmed".current_user_id());

-- AuditLog
CREATE POLICY superadmin_audit_all ON "SIGMAmed"."AuditLog"
    FOR SELECT
    TO sigmamed_superadmin
    USING (true);

CREATE POLICY hospital_admin_audit_select ON "SIGMAmed"."AuditLog"
    FOR SELECT
    TO sigmamed_hospital_admin
    USING (
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."User" u
            WHERE u."UserId" = "AuditLog"."ActedBy"
            AND u."ClinicalInstitutionId" = "SIGMAmed".current_user_institution()
        )
    );

CREATE POLICY doctor_audit_select ON "SIGMAmed"."AuditLog"
    FOR SELECT
    TO sigmamed_doctor
    USING (
        "ActedBy" = "SIGMAmed".current_user_id() OR
        EXISTS (
            SELECT 1 FROM "SIGMAmed"."Patient" p
            WHERE p."UserId" = "AuditLog"."RecordId"
            AND "SIGMAmed".is_patients_doctor(p."UserId")
        )
    );

-- SELECT schemaname, tablename, policyname, roles, cmd
-- FROM pg_policies
-- WHERE schemaname = 'SIGMAmed'
-- ORDER BY tablename, policyname;

-- SELECT grantee, table_name, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE table_schema = 'SIGMAmed' AND grantee LIKE 'sigmamed_%'
-- ORDER BY grantee, table_name;
