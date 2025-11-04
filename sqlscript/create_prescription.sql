-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Prescription Table
BEGIN;

CREATE TABLE "SIGMAmed"."Prescription" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PrescriptionId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor"("UserId") ON DELETE RESTRICT,
    "PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient"("UserId") ON DELETE CASCADE,
    "PrescriptionNumber" VARCHAR(50) UNIQUE NOT NULL,
    "Status" "SIGMAmed".prescription_status_enum NOT NULL,
    "PrescribedDate" DATE NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE "SIGMAmed"."Prescription" IS 'Main prescription header - contains overall prescription info';

-- Commit transaction for Creating Prescription Table
COMMIT;