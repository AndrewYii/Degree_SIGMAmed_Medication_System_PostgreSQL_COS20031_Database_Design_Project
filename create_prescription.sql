-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Prescription Table
BEGIN;

CREATE TABLE "SIGMAmed"."Prescription" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PrescriptionId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor"("UserId") ON DELETE RESTRICT,
    "PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient"("UserId") ON DELETE CASCADE,
    "MedicationId" UUID NOT NULL REFERENCES "SIGMAmed"."Medication"("MedicationID") ON DELETE RESTRICT,
    "PrescriptionNumber" VARCHAR(50) UNIQUE NOT NULL,
    "Status" "SIGMAmed".prescription_status_enum NOT NULL,
    "PrescribedDate" DATE NOT NULL,
    "StartDate" DATE NOT NULL,
    "EndDate" DATE NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    CONSTRAINT chk_prescription_dates CHECK ("StartDate" <= "EndDate" AND "PrescribedDate" <= "StartDate")
);

COMMENT ON TABLE "SIGMAmed"."Prescription" IS 'Medication prescriptions issued by doctors';

-- Commit transaction for Creating Prescription Table
COMMIT;