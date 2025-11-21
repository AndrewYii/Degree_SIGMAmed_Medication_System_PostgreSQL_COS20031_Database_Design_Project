-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Prescribed Medication Table
BEGIN;

CREATE TABLE "SIGMAmed"."PrescribedMedication" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PrescribedMedicationId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescriptionId" UUID NOT NULL REFERENCES "SIGMAmed"."Prescription"("PrescriptionId") ON DELETE CASCADE,
    "MedicationId" UUID NOT NULL REFERENCES "SIGMAmed"."Medication"("MedicationId") ON DELETE RESTRICT,
    "DosageAmountPrescribed" DECIMAL(5,2) NOT NULL,
    "DosePerTime" DECIMAL(5,2) NOT NULL,
    "Status" prescribedmedication_status_enum DEFAULT 'active',
    "DefaultDayMask" VARCHAR(7) NOT NULL,
    "DoseInterval" INTERVAL NOT NULL,
    "PrescribedDate" TIMESTAMPTZ NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "MedicationNameSnapshot" VARCHAR(100) NOT NULL,
    "TimesPerDay" INT NOT NULL,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."PrescribedMedication" IS 'Individual medications within a prescription with dosage details';

-- Commit transaction for Creating Prescribed Medication Table
COMMIT;