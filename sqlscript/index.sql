-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- ClinicalInstitution Indexes
CREATE INDEX idx_clinical_institution_name ON "SIGMAmed"."ClinicalInstitution"("ClinicalInstitutionName") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_clinical_institution_deleted ON "SIGMAmed"."ClinicalInstitution"("IsDeleted");

-- User Indexes
CREATE INDEX idx_user_email ON "SIGMAmed"."User"("Email") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_user_username ON "SIGMAmed"."User"("Username") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_user_role ON "SIGMAmed"."User"("Role") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_user_institution ON "SIGMAmed"."User"("ClinicalInstitutionId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_user_ic_passport ON "SIGMAmed"."User"("ICPassportNumber") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_user_active ON "SIGMAmed"."User"("IsActive", "IsDeleted");
CREATE INDEX idx_user_dob ON "SIGMAmed"."User"("DateOfBirth");

-- UserLog Indexes
CREATE INDEX idx_userlog_user ON "SIGMAmed"."UserLog"("UserId", "ActedAt" DESC);
CREATE INDEX idx_userlog_acted_by ON "SIGMAmed"."UserLog"("ActedBy", "ActedAt" DESC);
CREATE INDEX idx_userlog_action_type ON "SIGMAmed"."UserLog"("ActionType", "ActedAt" DESC);
CREATE INDEX idx_userlog_acted_at ON "SIGMAmed"."UserLog"("ActedAt" DESC);

-- Doctor Indexes
CREATE INDEX idx_doctor_license ON "SIGMAmed"."Doctor"("MedicalLicenseNumber");
CREATE INDEX idx_doctor_specialization ON "SIGMAmed"."Doctor"("Specialization");
CREATE INDEX idx_doctor_experience ON "SIGMAmed"."Doctor"("YearOfExperience" DESC);

-- Patient Indexes
CREATE INDEX idx_patient_number ON "SIGMAmed"."Patient"("PatientNumber");
CREATE INDEX idx_patient_blood_type ON "SIGMAmed"."Patient"("BloodType") WHERE "BloodType" IS NOT NULL;
CREATE INDEX idx_patient_allergies ON "SIGMAmed"."Patient" USING GIN("MedicationAllergies");

-- AssignedDoctor Indexes
CREATE INDEX idx_assigned_doctor_doctor ON "SIGMAmed"."AssignedDoctor"("DoctorId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_assigned_doctor_patient ON "SIGMAmed"."AssignedDoctor"("PatientId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_assigned_doctor_level ON "SIGMAmed"."AssignedDoctor"("DoctorLevel") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_assigned_doctor_time ON "SIGMAmed"."AssignedDoctor"("AssignedTime" DESC);

-- AssignedDoctorLog Indexes
CREATE INDEX idx_assigned_doctor_log_id ON "SIGMAmed"."AssignedDoctorLog"("AssignedDoctorId", "ActedAt" DESC);
CREATE INDEX idx_assigned_doctor_log_acted_by ON "SIGMAmed"."AssignedDoctorLog"("ActedBy", "ActedAt" DESC);

-- MedicalHistory Indexes
CREATE INDEX idx_medical_history_patient ON "SIGMAmed"."MedicalHistory"("PatientId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_medical_history_disease ON "SIGMAmed"."MedicalHistory"("DiseaseName") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_medical_history_severity ON "SIGMAmed"."MedicalHistory"("Severity" DESC) WHERE "IsDeleted" = FALSE;

-- MedicalHistoryLog Indexes
CREATE INDEX idx_medical_history_log_id ON "SIGMAmed"."MedicalHistoryLog"("MedicalHistoryId", "ActedAt" DESC);
CREATE INDEX idx_medical_history_log_acted_by ON "SIGMAmed"."MedicalHistoryLog"("ActedBy", "ActedAt" DESC);

-- PatientSymptom Indexes
CREATE INDEX idx_patient_symptom_history ON "SIGMAmed"."PatientSymptom"("MedicalHistoryId");
CREATE INDEX idx_patient_symptom_name ON "SIGMAmed"."PatientSymptom"("SymptomName");

-- Medication Indexes
CREATE INDEX idx_medication_institution ON "SIGMAmed"."Medication"("ClinicalInstitutionID") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_medication_name ON "SIGMAmed"."Medication"("MedicationName") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_medication_amount ON "SIGMAmed"."Medication"("TotalAmount") WHERE "IsDeleted" = FALSE;

-- MedicationLog Indexes
CREATE INDEX idx_medication_log_id ON "SIGMAmed"."MedicationLog"("MedicationID", "ActedAt" DESC);
CREATE INDEX idx_medication_log_acted_by ON "SIGMAmed"."MedicationLog"("ActedBy", "ActedAt" DESC);

-- Prescription Indexes
CREATE INDEX idx_prescription_doctor ON "SIGMAmed"."Prescription"("DoctorId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_prescription_patient ON "SIGMAmed"."Prescription"("PatientId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_prescription_status ON "SIGMAmed"."Prescription"("Status") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_prescription_number ON "SIGMAmed"."Prescription"("PrescriptionNumber") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_prescription_date ON "SIGMAmed"."Prescription"("PrescribedDate") WHERE "IsDeleted" = FALSE;

-- PrescriptionLog Indexes
CREATE INDEX idx_prescription_log_id ON "SIGMAmed"."PrescriptionLog"("PrescriptionId", "ActedAt" DESC);
CREATE INDEX idx_prescription_log_acted_by ON "SIGMAmed"."PrescriptionLog"("ActedBy", "ActedAt" DESC);

-- PrescribedMedication Indexes 
CREATE INDEX idx_prescribed_medication_prescription ON "SIGMAmed"."PrescribedMedication"("PrescriptionId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_prescribed_medication_medication ON "SIGMAmed"."PrescribedMedication"("MedicationId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_prescribed_medication_dates ON "SIGMAmed"."PrescribedMedication"("StartDate", "EndDate") WHERE "IsDeleted" = FALSE;

-- PrescribedMedicationLog Indexes
CREATE INDEX idx_prescribed_medication_log_id ON "SIGMAmed"."PrescribedMedicationLog"("PrescribedMedicationId", "ActedAt" DESC);
CREATE INDEX idx_prescribed_medication_log_acted_by ON "SIGMAmed"."PrescribedMedicationLog"("ActedBy", "ActedAt" DESC);

-- PrescribedMedicationSchedule Indexes
CREATE INDEX idx_prescribed_schedule_medication ON "SIGMAmed"."PrescribedMedicationSchedule"("PrescribedMedicationId");
CREATE INDEX idx_prescribed_schedule_weekday ON "SIGMAmed"."PrescribedMedicationSchedule"("Weekday");
CREATE INDEX idx_prescribed_schedule_time ON "SIGMAmed"."PrescribedMedicationSchedule"("MealTiming");

-- PrescribedMedicationScheduleLog Indexes
CREATE INDEX idx_prescribed_schedule_log_id ON "SIGMAmed"."PrescribedMedicationScheduleLog"("PrescribedMedicationScheduleId", "ActedAt" DESC);
CREATE INDEX idx_prescribed_schedule_log_acted_by ON "SIGMAmed"."PrescribedMedicationScheduleLog"("ActedBy", "ActedAt" DESC);

-- Reminder Indexes
CREATE INDEX idx_reminder_status ON "SIGMAmed"."Reminder"("CurrentStatus") WHERE "IsActive" = TRUE;
CREATE INDEX idx_reminder_active ON "SIGMAmed"."Reminder"("IsActive");

-- PatientSideEffect Indexes
CREATE INDEX idx_side_effect_prescribed_medication ON "SIGMAmed"."PatientSideEffect"("PrescribedMedicationID");
CREATE INDEX idx_side_effect_name ON "SIGMAmed"."PatientSideEffect"("SideEffectName");
CREATE INDEX idx_side_effect_severity ON "SIGMAmed"."PatientSideEffect"("Severity" DESC);
CREATE INDEX idx_side_effect_dates ON "SIGMAmed"."PatientSideEffect"("OnsetDate", "ResolutionDate");

-- PatientSideEffectLog Indexes
CREATE INDEX idx_side_effect_log_id ON "SIGMAmed"."PatientSideEffectLog"("PatientSideEffectID", "ActedAt" DESC);
CREATE INDEX idx_side_effect_log_acted_by ON "SIGMAmed"."PatientSideEffectLog"("ActedBy", "ActedAt" DESC);

-- PatientReport Indexes
CREATE INDEX idx_patient_report_doctor ON "SIGMAmed"."PatientReport"("DoctorId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_patient_report_patient ON "SIGMAmed"."PatientReport"("PatientId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_patient_report_status ON "SIGMAmed"."PatientReport"("Status") WHERE "IsDeleted" = FALSE;

-- PatientReportLog Indexes
CREATE INDEX idx_patient_report_log_id ON "SIGMAmed"."PatientReportLog"("PatientReportId", "ActedAt" DESC);
CREATE INDEX idx_patient_report_log_acted_by ON "SIGMAmed"."PatientReportLog"("ActedBy", "ActedAt" DESC);

-- Appointment Indexes
CREATE INDEX idx_appointment_doctor ON "SIGMAmed"."Appointment"("DoctorId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_appointment_patient ON "SIGMAmed"."Appointment"("PatientId") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_appointment_date ON "SIGMAmed"."Appointment"("AppointmentDate") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_appointment_datetime ON "SIGMAmed"."Appointment"("AppointmentDate", "AppointmentTime") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_appointment_status ON "SIGMAmed"."Appointment"("Status") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_appointment_type ON "SIGMAmed"."Appointment"("AppointmentType") WHERE "IsDeleted" = FALSE;
CREATE INDEX idx_appointment_emergency ON "SIGMAmed"."Appointment"("IsEmergency") WHERE "IsEmergency" = TRUE AND "IsDeleted" = FALSE;
CREATE INDEX idx_appointment_upcoming ON "SIGMAmed"."Appointment"("AppointmentDate", "AppointmentTime", "Status") 
    WHERE "Status" IN ('scheduled', 'confirmed') AND "IsDeleted" = FALSE;

-- AppointmentLog Indexes
CREATE INDEX idx_appointment_log_id ON "SIGMAmed"."AppointmentLog"("AppointmentId", "ActedAt" DESC);
CREATE INDEX idx_appointment_log_acted_by ON "SIGMAmed"."AppointmentLog"("ActedBy", "ActedAt" DESC);