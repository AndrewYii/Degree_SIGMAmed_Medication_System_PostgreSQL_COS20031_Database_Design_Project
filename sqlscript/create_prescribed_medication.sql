-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Prescribed Medication Table
BEGIN;

CREATE TABLE "SIGMAmed"."PrescribedMedication" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PrescribedMedicationId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescriptionId" UUID NOT NULL REFERENCES "SIGMAmed"."Prescription"("PrescriptionId") ON DELETE CASCADE,
    "MedicationId" UUID NOT NULL REFERENCES "SIGMAmed"."Medication"("MedicationID") ON DELETE RESTRICT,
    "DosageAmountPrescribed" INT NOT NULL,
    "Status" prescribedmedication_status_enum DEFAULT 'active',
    "PrescribedDate" DATE NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "MedicationNameSnapshot" VARCHAR(100) NOT NULL,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT chk_prescribed_medication_dates CHECK ("StartDate" <= "EndDate"),
    UNIQUE("PrescriptionId", "MedicationId")
);

COMMENT ON TABLE "SIGMAmed"."PrescribedMedication" IS 'Individual medications within a prescription with dosage details';

-- Commit transaction for Creating Prescribed Medication Table
COMMIT;