-- For PostgreSQL Database Schema for SIGMAmed Medication System
-- In this project, our group will collaborate using the online Service "GitHub" and "Supabase" for simulating the online database environment.
-- This script created for the both local development and deployment to Supabase PostgreSQL database
-- Assume use the default public database in PostgreSQL for both local and Supabase deployment

-- Enable necessary extensions for PostgreSQL
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";

-- Create custom ENUM types
CREATE TYPE user_role AS ENUM ('doctor', 'patient', 'admin');
CREATE TYPE action_type AS ENUM ('create', 'update', 'delete', 'restore');
CREATE TYPE doctor_type AS ENUM('primary', 'secondary');
CREATE TYPE prescription_status AS ENUM ('active', 'completed');
CREATE TYPE log_action AS ENUM ('create','update');
CREATE TYPE report_status AS ENUM ('Appointment', 'SideEffect', 'Symptom','No');
CREATE TYPE reminder_status AS ENUM ('ignored','completed');
CREATE TYPE appointment_type AS ENUM('consultation','follow-up');
CREATE TYPE appointment_status AS ENUM('scheduled','confirmed','completed','cancelled');

-- Create the SIGMAmed schema
CREATE SCHEMA IF NOT EXISTS "SIGMAmed";

-- Include public so extension functions (e.g., uuid_generate_v4) resolve without schema-qualification
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating ClinicalInstitution Table
BEGIN;

-- ClinicalInstitution Table
CREATE TABLE IF NOT EXISTS "ClinicalInstitution" (
    "ClinicalInstitutionID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionName" VARCHAR(100) NOT NULL,
    "Description" TEXT,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for ClinicalInstitution:
-- Optimize search by institution name.
CREATE INDEX idx_clinicalinstitution_name ON "ClinicalInstitution"("ClinicalInstitutionName");
-- Speed up queries filtering out soft-deleted records.
CREATE INDEX idx_clinicalinstitution_isdeleted ON "ClinicalInstitution"("IsDeleted");

COMMIT;
-- End of the ClinicalInstitution Table creation


-- Start transaction for Creating User Table (base table for different roles)
BEGIN;

-- User Table (base table for different roles)
CREATE TABLE IF NOT EXISTS "User" (
    "UserId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionID" UUID,
    "Username" VARCHAR(50) UNIQUE NOT NULL,
    "Email" CITEXT UNIQUE NOT NULL,
    "PasswordHash" VARCHAR(255) NOT NULL,
    "Role" user_role NOT NULL,
    "ICPassportNumber" VARCHAR(50) UNIQUE NOT NULL,
    "FirstName" VARCHAR(100) NOT NULL,
    "LastName" VARCHAR(100) NOT NULL,
    "Phone" VARCHAR(20) NOT NULL,
    "DateOfBirth" DATE NOT NULL,
    "FcmKey" VARCHAR(255)  NULL,
    "ProfilePictureUrl" TEXT NULL,
    "IsActive" BOOLEAN DEFAULT TRUE,
    "IsDeleted" BOOLEAN DEFAULT FALSE 
);

-- Index on Role for efficient filtering based on user role
CREATE INDEX idx_user_role ON "User"("Role");

-- Add foreign key constraint to link User to ClinicalInstitution
ALTER TABLE "User" ADD CONSTRAINT "fk_user_clinicalinstitution" FOREIGN KEY ("ClinicalInstitutionID") REFERENCES "ClinicalInstitution"("ClinicalInstitutionID");

COMMIT;
-- End of the User Table creation

-- Start transaction for Creating Medication Table
BEGIN;

-- Medication Table
CREATE TABLE IF NOT EXISTS "Medication" (
    "MedicationID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionID" UUID,
    "MedicationName" VARCHAR(100) NOT NULL,
    "TotalAmount" INT NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE
);

-- Search the medication based on medication name
CREATE INDEX idx_medication_name ON "Medication"("MedicationName");
-- Filter the medication based on clinical institution
CREATE INDEX idx_clinical_institutionid ON "Medication"("ClinicalInstitutionID");

-- Add foreign key constraint to link Medication to ClinicalInstitution
ALTER TABLE "Medication" ADD CONSTRAINT "fk_medication_clinicalinstitution" FOREIGN KEY ("ClinicalInstitutionID") REFERENCES "ClinicalInstitution"("ClinicalInstitutionID");

COMMIT;
-- End of the Medication Table creation

-- Start transaction for Creating Medication Log Table
BEGIN;

-- Medication Log Table
CREATE TABLE IF NOT EXISTS "MedicationLog" (
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "MedicationID" UUID,
    "ActedBy" UUID,
    "ActionType" action_type NOT NULL,
    "PreviousValue" JSONB DEFAULT '[]'::jsonb,
    "Action" JSONB DEFAULT '[]'::jsonb,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Search medication log based on the user id
CREATE INDEX idx_modify_at ON "MedicationLog"("ActedBy");

-- Add foreign key constraint to link Medication Log to Medication
ALTER TABLE "MedicationLog" ADD CONSTRAINT "fk_medicationlog_medication" FOREIGN KEY ("MedicationID") REFERENCES "Medication"("MedicationID");
-- Add foreign key constraint to link Medication Log to User
ALTER TABLE "MedicationLog" ADD CONSTRAINT "fk_medicationlog_user" FOREIGN KEY ("ActedBy") REFERENCES "User"("UserId");


COMMIT;
-- End of the Medication Log Table creation

-- Start transaction for Creating User Log Table
BEGIN;

-- User Log Table
CREATE TABLE IF NOT EXISTS "UserLog" (
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "UserId" UUID,
    "ActedBy" UUID,
    "ActionType" action_type NOT NULL,
    "PreviousValue" JSONB DEFAULT '[]'::jsonb,
    "Action" JSONB DEFAULT '[]'::jsonb,
    "Reason" TEXT,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Search the user log table based on the user id
CREATE INDEX idx_userlog_userid ON "UserLog"("UserId");

-- Add foreign key constraint to link UserLog to User
ALTER TABLE "UserLog" ADD CONSTRAINT "fk_userlog_user" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");
-- Add foreign key constraint to link UserLog to User
ALTER TABLE "UserLog" ADD CONSTRAINT "fk_userlog_modify" FOREIGN KEY ("ActedBy") REFERENCES "User"("UserId");

COMMIT;
-- End of the User Log Table creation

-- Start transaction for Creating Doctor Table
BEGIN;

-- Doctor Table
CREATE TABLE IF NOT EXISTS "Doctor" (
    "UserId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "MedicalLicenseNumber" VARCHAR(50) UNIQUE NOT NULL,
    "Specialization" VARCHAR(100) NOT NULL,
    "YearOfExperience" INT NOT NULL,
    "MedicalSchool" VARCHAR(255) NOT NULL,
    "Bio" TEXT NULL
);

-- Search the doctor table based on the specialization
CREATE INDEX idx_doctor_specialization ON "Doctor"("Specialization");

-- Add foreign key constraint to link Doctor to User
ALTER TABLE "Doctor" ADD CONSTRAINT "fk_doctor_user" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");

COMMIT;
-- End of the Doctor Table creation

-- Start transaction for Creating Patient Table
BEGIN;

-- Patient Table
CREATE TABLE IF NOT EXISTS "Patient" (
    "UserId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PatientNumber" VARCHAR(20) UNIQUE NOT NULL,
    "BloodType" VARCHAR(5)  NULL,
    "HeightCm" DECIMAL(5,2)  NULL,
    "WeightKg" DECIMAL(5,2)  NULL,
    "EmergencyContactName" VARCHAR(100) NULL,
    "EmergencyContactNumber" VARCHAR(20) NULL,
    "MedicationAllergies" JSONB DEFAULT '[]'::jsonb
);

-- Search the patient table based on the patient number
CREATE INDEX idx_patient_patientno ON "Patient"("PatientNumber");

-- Add foreign key constraint to link Patient to User
ALTER TABLE "Patient" ADD CONSTRAINT "fk_patient_user" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");

COMMIT;
-- End of the Patient Table creation

-- Start transaction for Creating Medical History Table
BEGIN;

-- Medical History Table
CREATE TABLE IF NOT EXISTS "MedicalHistory" (
    "MedicalHistoryId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PatientId" UUID,
    "DiseaseName" VARCHAR(100) NOT NULL,
    "Severity" INT DEFAULT 0,
    "IsDeleted" BOOLEAN DEFAULT FALSE
);

-- Add foreign key constraint to link Medical History to Patient
ALTER TABLE "MedicalHistory" ADD CONSTRAINT "fk_medicalhistory_patient" FOREIGN KEY ("PatientId") REFERENCES "Patient"("UserId");

COMMIT;
-- End of the Medical_History Table creation

-- Start transaction for Creating Medical History Log Table
BEGIN;

-- Medical History Log Table
CREATE TABLE IF NOT EXISTS "MedicalHistoryLog" (
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "MedicalHistoryId" UUID,
    "ActedBy" UUID,
    "ActionType" action_type NOT NULL,
    "PreviousValue" JSONB DEFAULT '[]'::jsonb,
    "Action" JSONB DEFAULT '[]'::jsonb,
    "Reason" TEXT,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Search the medical history log table based on the id
CREATE INDEX idx_mhlog_medicalhistory ON "MedicalHistoryLog"("MedicalHistoryId");

-- Add foreign key constraint to link Medical History Log to Medical History
ALTER TABLE "MedicalHistoryLog" ADD CONSTRAINT "fk_medicalhistorylog_medicalhistory" FOREIGN KEY ("MedicalHistoryId") REFERENCES "MedicalHistory"("MedicalHistoryId");
-- Add foreign key constraint to link MedicalHistoryLog to User
ALTER TABLE "MedicalHistoryLog" ADD CONSTRAINT "fk_medicalhistorylog_modify" FOREIGN KEY ("ActedBy") REFERENCES "User"("UserId");

COMMIT;
-- End of the Medical History Log Table creation

-- Start transaction for Creating Patient Symptom Table
BEGIN;

-- Patient Symptom Table
CREATE TABLE IF NOT EXISTS "PatientSymptom" (
    "PatientSymptomId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "MedicalHistoryId" UUID,
    "SymptomName" VARCHAR(100) NOT NULL,
    UNIQUE("MedicalHistoryId", "SymptomName")
);

-- Add foreign key constraint to link Patient Symptom to Medical History
ALTER TABLE "PatientSymptom" ADD CONSTRAINT "fk_patientsymptom_medicalhistory" FOREIGN KEY ("MedicalHistoryId") REFERENCES "MedicalHistory"("MedicalHistoryId");

COMMIT;
-- End of the Patient Symptom Table creation

-- Start transaction for Creating Assigned Doctor Table
BEGIN;

-- Assigned Doctor Table
CREATE TABLE IF NOT EXISTS "AssignedDoctor" (
    "AssignedDoctorId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID,
    "PatientId" UUID,
    "DoctorLevel" doctor_type  NOT NULL,
    "AssignedTime" TIMESTAMPTZ DEFAULT NOW(),
    "IsDeleted" BOOLEAN DEFAULT FALSE
);

-- Search the assigned doctor and assigned patient
CREATE UNIQUE INDEX "idx_assigneddoctor_doctorid_patientid" ON "AssignedDoctor" ("DoctorId", "PatientId") WHERE "IsDeleted" = FALSE;

-- Add foreign key constraint to link Assigned Doctor to Doctor
ALTER TABLE "AssignedDoctor" ADD CONSTRAINT "fk_assigneddoctor_doctor" FOREIGN KEY ("DoctorId") REFERENCES "Doctor"("UserId");
-- Add foreign key constraint to link Assigned Doctor to Patient
ALTER TABLE "AssignedDoctor" ADD CONSTRAINT "fk_assigneddoctor_patient" FOREIGN KEY ("PatientId") REFERENCES "Patient"("UserId");

COMMIT;
-- End of the Assigned Doctor Table creation

-- Start transaction for Creating Assigned Doctor Log Table
BEGIN;

-- Assigned Doctor Log Table
CREATE TABLE IF NOT EXISTS "AssignedDoctorLog" (
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "AssignedDoctorId" UUID,
    "ActedBy" UUID,
    "ActionType" action_type NOT NULL,
    "PreviousValue" JSONB DEFAULT '[]'::jsonb,
    "Action" JSONB DEFAULT '[]'::jsonb,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Search the Assigned Doctor log table based on the id
CREATE INDEX idx_adlog_assigneddoctor ON "AssignedDoctorLog"("AssignedDoctorId");

-- Add foreign key constraint to link Assigned Doctor Log to Assigned Doctor
ALTER TABLE "AssignedDoctorLog" ADD CONSTRAINT "fk_adlog_assigneddoctor" FOREIGN KEY ("AssignedDoctorId") REFERENCES "AssignedDoctor"("AssignedDoctorId");
-- Add foreign key constraint to link Assigned Doctor Log to User
ALTER TABLE "AssignedDoctorLog" ADD CONSTRAINT "fk_adlog_modify" FOREIGN KEY ("ActedBy") REFERENCES "User"("UserId");

COMMIT;
-- End of the Assigned Doctor Log Table creation

-- Start transaction for Creating Prescription Table
BEGIN;

-- Prescription Table
CREATE TABLE IF NOT EXISTS "Presciption" (
    "PrescriptionId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID,
    "PatientId" UUID,
    "MedicationId" UUID,
    "PrescriptionNumber" VARCHAR(50) UNIQUE NOT NULL,
    "Frequency" VARCHAR(100) NOT NULL,
    "DurationDays" INT NOT NULL,
    "DosageAmountPrescribed" INT NOT NULL,
    "Status" prescription_status NOT NULL,
    "PrescribedDate" DATE NOT NULL,
    "StartDate" DATE NOT NULL,
    "EndDate" DATE NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE
);

-- Search the prescription made by doctor to patient
CREATE UNIQUE INDEX "idx_prescription_doctorid_patientid" ON "Prescription" ("DoctorId", "PatientId") WHERE "IsDeleted" = FALSE;
-- Search the prescription based on prescriptionNumber
CREATE INDEX idx_prescription_prescriptionnumber ON "Prescription"("PrescriptionNumber");

-- Add foreign key constraint to link Prescription to Doctor
ALTER TABLE "Prescription" ADD CONSTRAINT "fk_prescription_doctor" FOREIGN KEY ("DoctorId") REFERENCES "Doctor"("UserId");
-- Add foreign key constraint to link Prescription to Patient
ALTER TABLE "Prescription" ADD CONSTRAINT "fk_prescription_patient" FOREIGN KEY ("PatientId") REFERENCES "Patient"("UserId");
-- Add foreign key constraint to link Prescription to Medication
ALTER TABLE "Prescription" ADD CONSTRAINT "fk_prescription_medication" FOREIGN KEY ("MedicationId") REFERENCES "Medication"("MedicationId");

COMMIT;
-- End of the Prescription Table creation

-- Start transaction for Creating Prescription Log Table
BEGIN;

-- Prescription Log Table
CREATE TABLE IF NOT EXISTS "PresciptionLog" (
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescriptionId" UUID,
    "ActedBy" UUID,
    "ActionType" log_action NOT NULL,
    "PreviousValue" JSONB DEFAULT '[]'::jsonb,
    "Action" JSONB DEFAULT '[]'::jsonb,
    "Reason" TEXT,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Search the prescription log table based on the id
CREATE INDEX idx_plog_prescription ON "PrescriptionLog"("PrescriptionId");

-- Add foreign key constraint to link PrescriptionLog to Prescription
ALTER TABLE "Prescriptionlog" ADD CONSTRAINT "fk_prescriptionlog_prescription" FOREIGN KEY ("PrescriptionId") REFERENCES "Prescription"("PrescriptionId");
-- Add foreign key constraint to link Prescription Log to User
ALTER TABLE "PrescriptionLog" ADD CONSTRAINT "fk_prescriptionlog_modify" FOREIGN KEY ("ActedBy") REFERENCES "User"("UserId");

COMMIT;
-- End of the Prescription Log Table creation

-- Start transaction for Creating Patient Report Table
BEGIN;

-- Patient Report Table
CREATE TABLE IF NOT EXISTS "PatientReport" (
    "PatientReportID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID,
    "PatientId" UUID,
    "Status" report_status NOT NULL,
    "Reason" TEXT,
    "AttachmentDirectory" TEXT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE
);

-- Search the patient report made by patient to doctor
CREATE UNIQUE INDEX "idx_patientreport_doctorid_patientid" ON "PatientReport" ("DoctorId", "PatientId") WHERE "IsDeleted" = FALSE;

-- Add foreign key constraint to link Patient Report to Doctor
ALTER TABLE "PatientReport" ADD CONSTRAINT "fk_patientreport_doctor" FOREIGN KEY ("DoctorId") REFERENCES "Doctor"("UserId");
-- Add foreign key constraint to link Patient Report to Patient
ALTER TABLE "PatientReport" ADD CONSTRAINT "fk_patientreport_patient" FOREIGN KEY ("PatientId") REFERENCES "Patient"("UserId");

COMMIT;
-- End of the Patient Report Table creation

-- Start transaction for Creating Patient Report Log Table
BEGIN;

-- Patient Report Log Table
CREATE TABLE IF NOT EXISTS "PatientReportLog" (
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PatientReportId" UUID,
    "ActedBy" UUID,
    "ActionType" action_type NOT NULL,
    "PreviousValue" JSONB DEFAULT '[]'::jsonb,
    "Action" JSONB DEFAULT '[]'::jsonb,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Search the patient report log table based on the id
CREATE INDEX idx_prlog_patientreport ON "PatientReportLog"("PatientReportId");

-- Add foreign key constraint to link PatientReportLog to Patient Report
ALTER TABLE "Prescriptionlog" ADD CONSTRAINT "fk_prescriptionlog_prescription" FOREIGN KEY ("PrescriptionId") REFERENCES "Prescription"("PrescriptionId");
-- Add foreign key constraint to link Patient Report Log to User
ALTER TABLE "PatientReportLog" ADD CONSTRAINT "fk_prlog_modify" FOREIGN KEY ("ActedBy") REFERENCES "User"("UserId");

COMMIT;
-- End of the Patient Report Log Table creation

-- Start transaction for Creating Prescribed Medication Schedule Table
BEGIN;

-- Prescribed Medication Schedule Table
CREATE TABLE IF NOT EXISTS "PrescribedMedicationSchedule" (
    "PrescribedMedicationScheduleId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescriptionId" UUID,
    "MealTiming" TIMESTAMPTZ NOT NULL
);

-- Add foreign key constraint to link Prescribed Medication Schedule to Prescription
ALTER TABLE "PrescribedMedicationSchedule" ADD CONSTRAINT "fk_pms_prescription" FOREIGN KEY ("PrescriptionId") REFERENCES "Prescription"("PrescriptionId");

COMMIT;
-- End of the Prescribed Medication Schedule Table creation

-- Start transaction for Creating Patient Side Effect Table
BEGIN;

-- Patient Side Effect Table
CREATE TABLE IF NOT EXISTS "PatientSideEffect" (
    "PatientSideEffectId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescriptionId" UUID,
    "SideEffectName" VARCHAR(100) NOT NULL,
    "Severity" INT DEFAULT 0,
    "OnsetDate" DATE,
    "PatientNotes" TEXT,
    "ResolutionDate" DATE,
    UNIQUE("PrescriptionId", "SideEffectName")
);

-- Search the side effect based on the prescription id
CREATE INDEX idx_sideeffect_prescription ON "PatientSideEffect"("PrescriptionId");

-- Add foreign key constraint to link Patient Side Effect to Prescription
ALTER TABLE "PatientSideEffect" ADD CONSTRAINT "fk_patientse_prescription" FOREIGN KEY ("PrescriptionId") REFERENCES "Prescription"("PrescriptionId");

COMMIT;
-- End of the Patient Side Effect Table creation

-- Start transaction for Creating Patient Side Effect Log Table
BEGIN;

-- Patient Side Effect Log Table
CREATE TABLE IF NOT EXISTS "PatientSideEffectLog" (
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PatientSideEffectId" UUID,
    "ActedBy" UUID,
    "ActionType" log_action NOT NULL,
    "PreviousValue" JSONB DEFAULT '[]'::jsonb,
    "Action" JSONB DEFAULT '[]'::jsonb,
    "Reason" TEXT,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Search the Patient Side Effect Log table based on the id
CREATE INDEX idx_pselog_patientsideeffect ON "PatientSideEffectLog"("PatientSideEffectId");

-- Add foreign key constraint to link Patient Side Effect Log to Patient Side Effect
ALTER TABLE "PatientSideEffectLog" ADD CONSTRAINT "fk_pselog_patientsideeffect" FOREIGN KEY ("PatientSideEffectId") REFERENCES "PatientSideEffect"("PatientSideEffectId");
-- Add foreign key constraint to link Patient Side Effect Log to User
ALTER TABLE "PatientSideEffectLog" ADD CONSTRAINT "fk_pselog_modify" FOREIGN KEY ("ActedBy") REFERENCES "User"("UserId");

COMMIT;
-- End of the Patient Side Effect Log Table creation

-- Start transaction for Creating Reminder Table
BEGIN;

-- Reminder Table
CREATE TABLE IF NOT EXISTS "Reminder" (
    "MedicationScheduleID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "IsActive" BOOLEAN DEFAULT TRUE,
    "CurrentStatus" reminder_status NOT NULL,
    "RemindGap" TIMESTAMPTZ 
);

-- Add foreign key constraint to link Reminder to Prescribed Medication Schedule
ALTER TABLE "Reminder" ADD CONSTRAINT "fk_reminder_medicationschedule" FOREIGN KEY ("MedicationScheduleID") REFERENCES "PrescribedMedicationSchedule"("PrescribedMedicationScheduleId");

COMMIT;
-- End of the Reminder Table creation

-- Start transaction for Creating Prescribed Medication Schedule Log Table
BEGIN;

-- Prescribed Medication Schedule Log Table
CREATE TABLE IF NOT EXISTS "PrescribedMedicationScheduleLog" (
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescribedMedicationScheduleId" UUID,
    "ActedBy" UUID,
    "ActionType" log_action NOT NULL,
    "PreviousValue" JSONB DEFAULT '[]'::jsonb,
    "Action" JSONB DEFAULT '[]'::jsonb,
    "Reason" TEXT,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Search the Prescribed Medication Schedule Log table based on the id
CREATE INDEX idx_pmslog_prescribedmedicationschedule ON "PrescribedMedicationScheduleLog"("PrescribedMedicationScheduleId");

-- Add foreign key constraint to link Prescribed Medication Schedule Log to Prescribed Medication Schedule
ALTER TABLE "PrescribedMedicationScheduleLog" ADD CONSTRAINT "fk_pmslog_prescribedmedicationschedule" FOREIGN KEY ("PrescribedMedicationScheduleId") REFERENCES "PrescribedMedicationSchedule"("PrescribedMedicationScheduleId");
-- Add foreign key constraint to link Prescribed Medication Schedule Log to User
ALTER TABLE "PrescribedMedicationScheduleLog" ADD CONSTRAINT "fk_pmslog_modify" FOREIGN KEY ("ActedBy") REFERENCES "User"("UserId");

COMMIT;
-- End of the Prescribed Medication Schedule Log Table creation

-- Start transaction for Creating Appointment Table
BEGIN;

-- Appointment Table
CREATE TABLE IF NOT EXISTS "Appointment" (
    "AppointmentId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID,
    "PatientId" UUID,
    "AppointmentDate" DATE NOT NULL,
    "AppointmentTime" TIME NOT NULL,
    "DurationMinutes" INT NOT NULL,
    "AppointmentType" appointment_type  NOT NULL,
    "Status" appointment_status DEFAULT scheduled,
    "Notes" TEXT NULL,
    "IsEmergency" BOOLEAN DEFAULT FALSE,
    "IsDeleted" BOOLEAN DEFAULT FALSE 
);

-- Search the appointment booked by patient and doctor
CREATE UNIQUE INDEX "idx_appointment_doctorid_patientid" ON "Appointment" ("DoctorId", "PatientId") WHERE "IsDeleted" = FALSE;

-- Add foreign key constraint to link Appointment to Doctor
ALTER TABLE "Appointment" ADD CONSTRAINT "fk_appointment_doctor" FOREIGN KEY ("DoctorId") REFERENCES "Doctor"("UserId");
-- Add foreign key constraint to link Appointment to Patient
ALTER TABLE "Appointment" ADD CONSTRAINT "fk_appointment_patient" FOREIGN KEY ("PatientId") REFERENCES "Patient"("UserId");

COMMIT;
-- End of the Appointment Table creation

-- Start transaction for Creating Appointment Log Table
BEGIN;

-- Prescribed Appointment Log Table
CREATE TABLE IF NOT EXISTS "AppointmentLog" (
    "LogId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "AppointmentId" UUID,
    "ActedBy" UUID,
    "ActionType" action_type NOT NULL,
    "PreviousValue" JSONB DEFAULT '[]'::jsonb,
    "Action" JSONB DEFAULT '[]'::jsonb,
    "Reason" TEXT,
    "ActedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Search the Appointment Log table based on the id
CREATE INDEX idx_appointmentlog_appointment ON "AppointmentLog"("AppointmentId");

-- Add foreign key constraint to link Appointment Log to Appointment
ALTER TABLE "AppointmentLog" ADD CONSTRAINT "fk_Appointmentlog_Appointment" FOREIGN KEY ("AppointmentId") REFERENCES "Appointment"("AppointmentId");
-- Add foreign key constraint to link Appointment Log to User
ALTER TABLE "AppointmentLog" ADD CONSTRAINT "fk_Appointmentlog_modify" FOREIGN KEY ("ActedBy") REFERENCES "User"("UserId");

COMMIT;
-- End of the Appointment Log Table creation
