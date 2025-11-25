-- For PostgreSQL Database Schema for SIGMAmed Medication System
-- In this project, our group will collaborate using the online Service "GitHub" and "Supabase" for simulating the online database environment.
-- This script created for the both local development and deployment to Supabase PostgreSQL database
-- Assume use the default public database in PostgreSQL for both local and Supabase deployment



-- For PostgreSQL Database Schema for SIGMAmed Medication System
-- Create SIGMAmed Schema
CREATE SCHEMA IF NOT EXISTS "SIGMAmed";

-- Set search path to SIGMAmed and public schemas
SET search_path TO "SIGMAmed", public;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "citext" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create Enums for SIGMAmed
CREATE TYPE "SIGMAmed".user_role_enum AS ENUM ('admin', 'doctor', 'patient');
CREATE TYPE "SIGMAmed".action_type_enum AS ENUM ('insert', 'update', 'delete');
CREATE TYPE "SIGMAmed".prescription_status_enum AS ENUM ('active', 'completed');
CREATE TYPE "SIGMAmed".prescribedmedication_status_enum AS ENUM ('active', 'completed','stop');
CREATE TYPE "SIGMAmed".appointment_status_enum AS ENUM ('scheduled', 'confirmed', 'completed', 'cancelled');
CREATE TYPE "SIGMAmed".appointment_type_enum AS ENUM ('consultation', 'follow-up');
CREATE TYPE "SIGMAmed".patient_report_status_enum AS ENUM ('SideEffect', 'Symptom','General');
CREATE TYPE "SIGMAmed".doctor_level_enum AS ENUM ('primary', 'secondary');
CREATE TYPE "SIGMAmed".reminder_status_enum AS ENUM ('Taken', 'Missed', 'Pending');
CREATE TYPE "SIGMAmed".admin_level_enum AS ENUM ('super', 'hospital');
CREATE TYPE "SIGMAmed".weekday_enum AS ENUM ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');
CREATE TYPE "SIGMAmed".dosage_form_enum AS ENUM ('tablet','capsule','syrup','injection');
CREATE TYPE "SIGMAmed".severity_enum AS ENUM ('mild','moderate','severe');

-- ----------------------------------------------------
--  CREATE TABLES (The Main Structure)
-- ----------------------------------------------------
-- Table 1: ClinicalInstitution
CREATE TABLE IF NOT EXISTS "SIGMAmed"."ClinicalInstitution" (
	"ClinicalInstitutionId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"ClinicalInstitutionName" VARCHAR(100) NOT NULL,
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Table 2: Medication
CREATE TABLE IF NOT EXISTS "SIGMAmed"."Medication" (
	"MedicationId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"ClinicalInstitutionId" UUID NULL REFERENCES "SIGMAmed"."ClinicalInstitution" ("ClinicalInstitutionId") ON DELETE SET NULL,
	"MedicationName" VARCHAR(100) NOT NULL,
	"Unit" VARCHAR(50) NULL,
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"DosageForm" "SIGMAmed".dosage_form_enum,
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE ("ClinicalInstitutionId", "MedicationName")
);

-- Table 3: User
CREATE TABLE IF NOT EXISTS "SIGMAmed"."User" (
	"UserId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"ClinicalInstitutionId" UUID NULL REFERENCES "SIGMAmed"."ClinicalInstitution" ("ClinicalInstitutionId") ON DELETE RESTRICT,
	"Username" VARCHAR(50) UNIQUE NOT NULL,
	"Email" CITEXT UNIQUE NOT NULL,
	"PasswordHash" VARCHAR(255) NOT NULL,
	"Role" "SIGMAmed".user_role_enum NOT NULL,
	"ICPassportNumber" VARCHAR(50) UNIQUE NOT NULL,
	"FirstName" VARCHAR(100) NOT NULL,
	"LastName" VARCHAR(100) NOT NULL,
	"Phone" VARCHAR(20) NOT NULL,
	"DateOfBirth" DATE NOT NULL,
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	CONSTRAINT CHK_USER_AGE CHECK (DATE_PART('year', AGE ("DateOfBirth")) >= 0),
	CONSTRAINT CHK_EMAIL_FORMAT CHECK (
		"Email" ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
	)
);

-- Table 4: AuditLog
CREATE TABLE IF NOT EXISTS "SIGMAmed"."AuditLog" (
	"AuditLogId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"ActedBy" UUID REFERENCES "SIGMAmed"."User" ("UserId") NOT NULL,
	"ActionTimestamp" TIMESTAMPTZ DEFAULT NOW(),
	"TableName" VARCHAR(75) NOT NULL,
	"RecordId" UUID NOT NULL,
	"ActionStatus" "SIGMAmed".action_type_enum NOT NULL,
	"OldValue" JSONB DEFAULT '[]'::JSONB,
	"NewValue" JSONB DEFAULT '[]'::JSONB
);

-- Table 5: Admin
CREATE TABLE IF NOT EXISTS "SIGMAmed"."Admin" (
	"UserId" UUID PRIMARY KEY REFERENCES "SIGMAmed"."User" ("UserId") ON DELETE CASCADE,
	"AdminLevel" "SIGMAmed".admin_level_enum
);

-- Table 6: Doctor
CREATE TABLE IF NOT EXISTS "SIGMAmed"."Doctor" (
	"UserId" UUID PRIMARY KEY REFERENCES "SIGMAmed"."User" ("UserId") ON DELETE CASCADE,
	"MedicalLicenseNumber" VARCHAR(50) UNIQUE NOT NULL,
	"Specialization" VARCHAR(100) NOT NULL,
	"YearOfExperience" INT NOT NULL,
	CONSTRAINT CHK_EXPERIENCE CHECK (
		"YearOfExperience" >= 0
		AND "YearOfExperience" <= 60
	)
);

-- Table 7: Patient
CREATE TABLE IF NOT EXISTS "SIGMAmed"."Patient" (
	"UserId" UUID PRIMARY KEY REFERENCES "SIGMAmed"."User" ("UserId") ON DELETE CASCADE,
	"PatientNumber" VARCHAR(20) UNIQUE NOT NULL,
	"BloodType" VARCHAR(5) NULL,
	"HeightCm" DECIMAL(5, 2) NOT NULL,
	"WeightKg" DECIMAL(5, 2) NOT NULL,
	"EmergencyContactName" VARCHAR(100) NOT NULL,
	"EmergencyContactNumber" VARCHAR(20) NOT NULL,
	"MedicationAllergies" JSONB DEFAULT '[]',
	CONSTRAINT CHK_BLOOD_TYPE CHECK (
		"BloodType" IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')
		OR "BloodType" IS NULL
	),
	CONSTRAINT CHK_HEIGHT CHECK (
		(
			"HeightCm" > 0
			AND "HeightCm" < 300
		)
		OR "HeightCm" = 0
	),
	CONSTRAINT CHK_WEIGHT CHECK (
		(
			"WeightKg" > 0
			AND "WeightKg" < 500
		)
		OR "WeightKg" = 0
	)
);

-- Table 8: Medical History
CREATE TABLE IF NOT EXISTS "SIGMAmed"."MedicalHistory" (
	"MedicalHistoryId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient" ("UserId") ON DELETE CASCADE,
	"DiseaseName" VARCHAR(100) NOT NULL,
	"Severity" "SIGMAmed".severity_enum DEFAULT 'mild',
	"DiagnosedDate" TIMESTAMPTZ NOT NULL,
	"ResolutionDate" TIMESTAMPTZ NULL,
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Table 9: Patient Symptom
CREATE TABLE IF NOT EXISTS "SIGMAmed"."PatientSymptom" (
	"PatientSymptomId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"MedicalHistoryId" UUID NULL REFERENCES "SIGMAmed"."MedicalHistory" ("MedicalHistoryId"),
	"PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient" ("UserId"),
	"SymptomName" VARCHAR(100) NOT NULL,
	"Severity" "SIGMAmed".severity_enum DEFAULT 'mild',
	"OnsetDate" TIMESTAMPTZ NOT NULL,
	"ResolutionDate" TIMESTAMPTZ NULL,
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE ("MedicalHistoryId", "SymptomName")
);

-- Table 10: Patient Care Team
CREATE TABLE IF NOT EXISTS "SIGMAmed"."PatientCareTeam" (
	"PatientCareTeamId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor" ("UserId") ON DELETE CASCADE,
	"PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient" ("UserId") ON DELETE CASCADE,
	"DoctorLevel" "SIGMAmed".doctor_level_enum NOT NULL,
	"Role" VARCHAR(50) NULL,
	"IsActive" BOOLEAN DEFAULT TRUE,
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE ("DoctorId", "PatientId", "DoctorLevel")
);

-- Table 11: Prescription
CREATE TABLE IF NOT EXISTS "SIGMAmed"."Prescription" (
	"PrescriptionId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor" ("UserId") ON DELETE RESTRICT,
	"PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient" ("UserId") ON DELETE CASCADE,
	"PrescriptionNumber" VARCHAR(50) UNIQUE NOT NULL,
	"Status" "SIGMAmed".prescription_status_enum NOT NULL,
	"PrescribedDate" TIMESTAMPTZ NOT NULL,
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"ExpiryDate" TIMESTAMPTZ NOT NULL,
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Table 12: Prescribed Medication
CREATE TABLE IF NOT EXISTS "SIGMAmed"."PrescribedMedication" (
	"PrescribedMedicationId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"PrescriptionId" UUID NOT NULL REFERENCES "SIGMAmed"."Prescription" ("PrescriptionId") ON DELETE CASCADE,
	"MedicationId" UUID NOT NULL REFERENCES "SIGMAmed"."Medication" ("MedicationId") ON DELETE RESTRICT,
	"DosageAmountPrescribed" DECIMAL(5, 2) NOT NULL,
	"DosePerTime" DECIMAL(5, 2) NOT NULL,
	"Status" "SIGMAmed".prescribedmedication_status_enum DEFAULT 'active',
	"DefaultDayMask" VARCHAR(7) NOT NULL,
	"DoseInterval" INTERVAL NOT NULL,
	"PrescribedDate" TIMESTAMPTZ NOT NULL,
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"MedicationNameSnapshot" VARCHAR(100) NOT NULL,
	"TimesPerDay" INT NOT NULL,
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Table 13: Patient Side Effect
CREATE TABLE IF NOT EXISTS "SIGMAmed"."PatientSideEffect" (
	"PatientSideEffectId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"PrescribedMedicationId" UUID NOT NULL REFERENCES "SIGMAmed"."PrescribedMedication" ("PrescribedMedicationId") ON DELETE CASCADE,
	"SideEffectName" VARCHAR(100) NOT NULL,
	"Severity" "SIGMAmed".severity_enum DEFAULT 'mild',
	"OnsetDate" TIMESTAMPTZ NOT NULL,
	"ResolutionDate" TIMESTAMPTZ NULL,
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	CONSTRAINT CHK_SIDE_EFFECT_DATES CHECK (
		"ResolutionDate" IS NULL
		OR "OnsetDate" <= "ResolutionDate"
	),
	UNIQUE ("PrescribedMedicationId", "SideEffectName")
);

-- Table 14: Prescribed Medication Schedule
CREATE TABLE IF NOT EXISTS "SIGMAmed"."PrescribedMedicationSchedule" (
	"PrescribedMedicationScheduleId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"PrescribedMedicationId" UUID NOT NULL REFERENCES "SIGMAmed"."PrescribedMedication" ("PrescribedMedicationId") ON DELETE CASCADE,
	"ReminderTime" TIME NOT NULL,
	"DayOfWeekMask" VARCHAR(7) NULL,
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"DoseSequenceId" INT NOT NULL
);

-- Table 15: Medication Adherence Record
CREATE TABLE IF NOT EXISTS "SIGMAmed"."MedicationAdherenceRecord" (
	"MedicationAdherenceRecordId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"PrescribedMedicationScheduleId" UUID NULL REFERENCES "SIGMAmed"."PrescribedMedicationSchedule" ("PrescribedMedicationScheduleId") ON DELETE CASCADE,
	"CurrentStatus" "SIGMAmed".reminder_status_enum DEFAULT 'Pending',
	"DoseQuantity" DECIMAL(5, 2) NULL,
	"ScheduledTime" TIMESTAMPTZ NOT NULL,
	"ActionTime" TIMESTAMPTZ DEFAULT NOW(),
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Table 16: Patient Report
CREATE TABLE IF NOT EXISTS "SIGMAmed"."PatientReport" (
	"PatientReportId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor" ("UserId") ON DELETE RESTRICT,
	"PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient" ("UserId") ON DELETE CASCADE,
	"PrescribedMedicationId" UUID NULL REFERENCES "SIGMAmed"."PrescribedMedication" ("PrescribedMedicationId"),
	"Type" "SIGMAmed".patient_report_status_enum NULL,
	"Description" TEXT NULL,
	"Keywords" TEXT NULL,
	"VoiceDirectory" TEXT NULL,
	"DoctorNote" TEXT NULL,
	"Severity" "SIGMAmed".severity_enum DEFAULT 'mild',
	"ReviewTime" TIMESTAMPTZ NULL,
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"IsDeleted" BOOLEAN DEFAULT FALSE
);

-- Table 17: Appointment
CREATE TABLE IF NOT EXISTS "SIGMAmed"."Appointment" (
	"AppointmentId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor" ("UserId") ON DELETE RESTRICT,
	"PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient" ("UserId") ON DELETE CASCADE,
	"AppointmentDate" TIMESTAMPTZ NOT NULL,
	"AppointmentType" "SIGMAmed".appointment_type_enum NOT NULL,
	"Status" "SIGMAmed".appointment_status_enum DEFAULT 'scheduled',
	"IsDeleted" BOOLEAN DEFAULT FALSE,
	"UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Table 18: Appointment Reminder
CREATE TABLE IF NOT EXISTS "SIGMAmed"."AppointmentReminder" (
	"AppointmentReminderId" UUID PRIMARY KEY DEFAULT UUID_GENERATE_V4 (),
	"AppointmentId" UUID NULL REFERENCES "SIGMAmed"."Appointment" ("AppointmentId"),
	"ScheduledTime" TIMESTAMPTZ NOT NULL,
	"CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

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

-- View 

-- Audit log
CREATE OR REPLACE VIEW "SIGMAmed"."AuditLogView" AS
SELECT
    A."AuditLogId",
    A."ActionTimestamp",
    A."TableName",
    A."RecordId",
    A."ActionStatus",
    U."FirstName" || ' ' || U."LastName" AS "ActedByFullName", -- Display full name
    U."Username" AS "ActedByUsername",
    U."Role" AS "ActedByRole",
    A."OldValue",
    A."NewValue"
FROM
    "SIGMAmed"."AuditLog" A
JOIN
    "SIGMAmed"."User" U ON A."ActedBy" = U."UserId"
ORDER BY
    A."ActionTimestamp" DESC;

COMMENT ON VIEW "SIGMAmed"."AuditLogView" IS 'Provides a human-readable view of the audit trail, joining the ActedBy UUID to the user''s name and role.';

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

-- -- Create the view of all MedicationAdherenceRecord
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


-- ClinicalInstitution Indexes
CREATE INDEX idx_clinical_institution_name ON "SIGMAmed"."ClinicalInstitution"("ClinicalInstitutionName") WHERE "IsDeleted" = FALSE;
-- UC4

-- User Indexes
CREATE INDEX idx_user_email ON "SIGMAmed"."User"("Email") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_user_ic_passport ON "SIGMAmed"."User"("ICPassportNumber") WHERE "IsDeleted" = FALSE;
-- UC7,8,9,13,14,15

-- Medication Indexes
CREATE INDEX idx_medication_name ON "SIGMAmed"."Medication"("MedicationName") WHERE "IsDeleted" = FALSE;
-- UC8

-- Prescription Indexes
CREATE INDEX idx_prescription_number ON "SIGMAmed"."Prescription"("PrescriptionNumber") WHERE "IsDeleted" = FALSE; 
-- UC9
CREATE INDEX idx_prescription_patient ON "SIGMAmed"."Prescription"("PatientId") WHERE "IsDeleted" = FALSE; 
-- UC14

-- PrescribedMedication Indexes 
CREATE INDEX idx_prescribed_medication_prescription ON "SIGMAmed"."PrescribedMedication"("PrescriptionId") WHERE "IsDeleted" = FALSE;
-- UC7
CREATE INDEX idx_prescribed_medication_medication ON "SIGMAmed"."PrescribedMedication"("MedicationId") WHERE "IsDeleted" = FALSE;
-- UC14
CREATE INDEX idx_prescribed_medication_status ON "SIGMAmed"."PrescribedMedication"("MedicationId","PrescriptionId","Status") WHERE "IsDeleted" = FALSE;
-- UC9

-- MedicationAdherenceRecord Indexes
CREATE INDEX idx_adherence_schedule_time ON "SIGMAmed"."MedicationAdherenceRecord"("ScheduledTime", "CurrentStatus"); 
-- UC14
CREATE INDEX idx_adherence_schedule_id ON "SIGMAmed"."MedicationAdherenceRecord"("PrescribedMedicationScheduleId"); 
-- UC11 (For trigger delete)

-- PrescribedMedicationSchedule Indexes
CREATE INDEX idx_prescribed_schedule_medication ON "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationId"); 
-- UC11 (For trigger delete)
CREATE INDEX idx_schedule_medication_time ON "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationId","ReminderTime"); -- UC10

-- MedicalHistory Indexes
CREATE INDEX idx_medical_history_patient ON "SIGMAmed"."MedicalHistory"("PatientId") WHERE "IsDeleted" = FALSE;
-- UC7

-- PatientSymptom Indexes
CREATE INDEX idx_patient_symptoms_medical_history ON "SIGMAmed"."PatientSymptom"("MedicalHistoryID") WHERE "IsDeleted" = FALSE;
-- UC7


