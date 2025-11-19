-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Patient Report Table
BEGIN;

CREATE TABLE "SIGMAmed"."PatientReport" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PatientReportID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor"("UserId") ON DELETE RESTRICT,
    "PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient"("UserId") ON DELETE CASCADE,
    "PrescribedMedicationId" UUID NULL REFERENCES "SIGMAmed"."PrescribedMedication"("PrescribedMedicationId"),
    "Type" "SIGMAmed".patient_report_status_enum NULL,
    "Description" TEXT,
    "AttachmentDirectory" TEXT NULL,
    "DoctorNote" TEXT NULL,
    "Severity" "SIGMAmed".severity_enum DEFAULT 'mild',
    "ReviewTime" TIMESTAMPTZ NULL,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "IsProcessed" BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE "SIGMAmed"."PatientReport" IS 'Patient health reports and communications';

-- Commit transaction for Creating Patient Report Table
COMMIT;
