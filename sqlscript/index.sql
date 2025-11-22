-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- ClinicalInstitution Indexes
CREATE INDEX idx_clinical_institution_name ON "SIGMAmed"."ClinicalInstitution"("ClinicalInstitutionName") WHERE "IsDeleted" = FALSE;
-- UC4

-- User Indexes
CREATE INDEX idx_user_email ON "SIGMAmed"."User"("Email") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_user_role ON "SIGMAmed"."User"("Role") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_user_ic_passport ON "SIGMAmed"."User"("ICPassportNumber") WHERE "IsDeleted" = FALSE;
-- UC7,8,9,13,14,15

-- Medication Indexes
CREATE INDEX idx_medication_name ON "SIGMAmed"."Medication"("MedicationName") WHERE "IsDeleted" = FALSE;
-- UC8,9,14

-- Prescription Indexes
CREATE INDEX idx_prescription_number ON "SIGMAmed"."Prescription"("PrescriptionNumber") WHERE "IsDeleted" = FALSE; --UC9
CREATE INDEX idx_prescription_patient ON "SIGMAmed"."Prescription"("PatientId") WHERE "IsDeleted" = FALSE; -- UC14

-- PrescribedMedication Indexes 
CREATE INDEX idx_prescribed_medication_prescription ON "SIGMAmed"."PrescribedMedication"("PrescriptionId") WHERE "IsDeleted" = FALSE;
-- UC7
CREATE INDEX idx_prescribed_medication_medication ON "SIGMAmed"."PrescribedMedication"("MedicationId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_prescribed_medication_status ON "SIGMAmed"."PrescribedMedication"("Status") WHERE "IsDeleted" = FALSE;
-- UC8,9

-- MedicationAdherenceRecord Indexes
CREATE INDEX idx_adherence_schedule_time ON "SIGMAmed"."MedicationAdherenceRecord"("ScheduledTime", "CurrentStatus"); --UC14
CREATE INDEX idx_adherence_schedule_id ON "SIGMAmed"."MedicationAdherenceRecord"("PrescribedMedicationScheduleId"); --UC11

-- PrescribedMedicationSchedule Indexes
CREATE INDEX idx_prescribed_schedule_medication ON "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationId"); --UC11
CREATE INDEX idx_prescribed_reminder_time ON "SIGMAmed"."PrescribedMedicationSchedule"("ReminderTime"); --UC10
CREATE INDEX idx_schedule_medication_time ON "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationId","ReminderTime"); --UC10

-- Appointment Indexes
CREATE INDEX idx_appointment_doctor ON "SIGMAmed"."Appointment"("DoctorId","AppointmentDate") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_appointment_patient ON "SIGMAmed"."Appointment"("PatientId","AppointmentDate") WHERE "IsDeleted" = FALSE;
-- UC15

-- PatientReport Indexes
CREATE INDEX idx_patient_report_patient ON "SIGMAmed"."PatientReport"("PatientId") WHERE "IsDeleted" = FALSE; -- UC13

-- MedicalHistory Indexes
CREATE INDEX idx_medical_history_patient ON "SIGMAmed"."MedicalHistory"("PatientId") WHERE "IsDeleted" = FALSE;
-- UC7

-- PatientSymptom Indexes
CREATE INDEX idx_patient_symptoms_medical_history ON "SIGMAmed"."PatientSymptom"("MedicalHistoryID") WHERE "IsDeleted" = FALSE;