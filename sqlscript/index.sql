-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- ClinicalInstitution Indexes
CREATE INDEX idx_clinical_institution_name ON "SIGMAmed"."ClinicalInstitution"("ClinicalInstitutionName") WHERE "IsDeleted" = FALSE;
-- UC1,4,5

-- User Indexes
CREATE INDEX idx_user_ic_passport ON "SIGMAmed"."User"("ICPassportNumber") WHERE "IsDeleted" = FALSE;
-- UC4,7,8,9,13,14,15,16

-- Medication Indexes
CREATE INDEX idx_medication_name ON "SIGMAmed"."Medication"("MedicationName") WHERE "IsDeleted" = FALSE;
-- UC5,6,8,9,14

-- Prescription Indexes
CREATE INDEX idx_prescription_number ON "SIGMAmed"."Prescription"("PrescriptionNumber") WHERE "IsDeleted" = FALSE; 
-- UC9
CREATE INDEX idx_prescription_patient_date ON "SIGMAmed"."Prescription"("PatientId","PrescribedDate") WHERE "IsDeleted" = FALSE; 
-- UC7,8

-- PrescribedMedication Indexes 
CREATE INDEX idx_prescribed_medication_prescription ON "SIGMAmed"."PrescribedMedication"("PrescriptionId") WHERE "IsDeleted" = FALSE;
-- UC7,8,9
CREATE INDEX idx_prescribed_medication_medication ON "SIGMAmed"."PrescribedMedication"("MedicationId") WHERE "IsDeleted" = FALSE;
-- UC8,9,13,14
CREATE INDEX idx_prescribed_medication_status ON "SIGMAmed"."PrescribedMedication"("MedicationId","PrescriptionId","Status") WHERE "IsDeleted" = FALSE;
-- UC9

-- MedicationAdherenceRecord Indexes
CREATE INDEX idx_adherence_schedule_time ON "SIGMAmed"."MedicationAdherenceRecord"("ScheduledTime", "PrescribedMedicationScheduleId");
-- UC14 ##

-- PrescribedMedicationSchedule Indexes
CREATE INDEX idx_prescribed_schedule_medication ON "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationId"); 
-- UC8,14

-- PatientReport Indexes
CREATE INDEX idx_report_patient_time ON "SIGMAmed"."PatientReport"("PatientId","CreatedAt") WHERE "IsDeleted" = FALSE;
-- UC13
CREATE INDEX idx_report_doctor ON "SIGMAmed"."PatientReport"("DoctorId") WHERE "IsDeleted" = FALSE;
-- UC13

-- PatientCareTeam Indexes
CREATE INDEX idx_care_patient ON "SIGMAmed"."PatientCareTeam"("PatientId","IsActive") WHERE "IsDeleted" = FALSE;
-- UC4,16

-- Appointment Indexes
CREATE INDEX idx_appointment_patient_date ON "SIGMAmed"."Appointment"("PatientId","AppointmentDate") WHERE "IsDeleted" = FALSE;
-- UC15
CREATE INDEX idx_appointment_doctor ON "SIGMAmed"."Appointment"("DoctorId") WHERE "IsDeleted" = FALSE;
-- UC15

-- AppointmentReminder Indexes
CREATE INDEX idx_appointment_reminder_appointment ON "SIGMAmed"."AppointmentReminder"("AppointmentId");
-- UC15 (Trigger)

-- MedicalHistory Indexes
CREATE INDEX idx_medical_history_patient ON "SIGMAmed"."MedicalHistory"("PatientId") WHERE "IsDeleted" = FALSE;
-- UC7

-- PatientSymptom Indexes
CREATE INDEX idx_patient_symptoms_medical_history ON "SIGMAmed"."PatientSymptom"("MedicalHistoryID") WHERE "IsDeleted" = FALSE;
-- UC7