-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- ClinicalInstitution Indexes
CREATE INDEX idx_clinical_institution_name ON "SIGMAmed"."ClinicalInstitution"("ClinicalInstitutionName") WHERE "IsDeleted" = FALSE;

-- User Indexes
CREATE INDEX idx_user_ic_passport ON "SIGMAmed"."User"("ICPassportNumber") WHERE "IsDeleted" = FALSE;

-- Medication Indexes
CREATE INDEX idx_medication_name ON "SIGMAmed"."Medication"("MedicationName") WHERE "IsDeleted" = FALSE;

-- Prescription Indexes
CREATE INDEX idx_prescription_number ON "SIGMAmed"."Prescription"("PrescriptionNumber") WHERE "IsDeleted" = FALSE; 
CREATE INDEX idx_prescription_patient_date ON "SIGMAmed"."Prescription"("PatientId","PrescribedDate") WHERE "IsDeleted" = FALSE; 

-- PrescribedMedication Indexes 
CREATE INDEX idx_prescribed_medication_prescription ON "SIGMAmed"."PrescribedMedication"("PrescriptionId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_prescribed_medication_status ON "SIGMAmed"."PrescribedMedication"("MedicationId","PrescriptionId","Status") WHERE "IsDeleted" = FALSE;

-- MedicationAdherenceRecord Indexes
CREATE INDEX idx_adherence_schedule ON "SIGMAmed"."MedicationAdherenceRecord"("ScheduledTime", "PrescribedMedicationScheduleId");

-- PrescribedMedicationSchedule Indexes
CREATE INDEX idx_prescribed_schedule_medication ON "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationId"); 

-- PatientReport Indexes
CREATE INDEX idx_report_patient_time ON "SIGMAmed"."PatientReport"("PatientId","CreatedAt") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_report_doctor ON "SIGMAmed"."PatientReport"("DoctorId") WHERE "IsDeleted" = FALSE;

-- PatientCareTeam Indexes
CREATE INDEX idx_care_patient ON "SIGMAmed"."PatientCareTeam"("PatientId","IsActive") WHERE "IsDeleted" = FALSE;

-- Appointment Indexes
CREATE INDEX idx_appointment_patient_date ON "SIGMAmed"."Appointment"("PatientId","AppointmentDate") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_appointment_doctor ON "SIGMAmed"."Appointment"("DoctorId") WHERE "IsDeleted" = FALSE;

-- AppointmentReminder Indexes
CREATE INDEX idx_appointment_reminder_appointment ON "SIGMAmed"."AppointmentReminder"("AppointmentId");

-- MedicalHistory Indexes
CREATE INDEX idx_medical_history_patient ON "SIGMAmed"."MedicalHistory"("PatientId") WHERE "IsDeleted" = FALSE;

-- PatientSymptom Indexes
CREATE INDEX idx_patient_symptoms_medical_history ON "SIGMAmed"."PatientSymptom"("MedicalHistoryId") WHERE "IsDeleted" = FALSE;