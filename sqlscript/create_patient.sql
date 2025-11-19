-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Patient Table
BEGIN;

CREATE TABLE "SIGMAmed"."Patient" (
    "UserId" UUID PRIMARY KEY REFERENCES "SIGMAmed"."User"("UserId") ON DELETE CASCADE,
    "PatientNumber" VARCHAR(20) UNIQUE NOT NULL,
    "BloodType" VARCHAR(5) NULL,
    "HeightCm" DECIMAL(5,2) NOT NULL,
    "WeightKg" DECIMAL(5,2) NOT NULL,
    "EmergencyContactName" VARCHAR(100) NOT NULL,
    "EmergencyContactNumber" VARCHAR(20) NOT NULL,
    "MedicationAllergies" JSONB DEFAULT '[]',
    CONSTRAINT chk_blood_type CHECK ("BloodType" IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') OR "BloodType" IS NULL),
    CONSTRAINT chk_height CHECK (("HeightCm" > 0 AND "HeightCm" < 300) OR "HeightCm" = 0),
    CONSTRAINT chk_weight CHECK (("WeightKg" > 0 AND "WeightKg" < 500) OR "WeightKg" = 0)
);

COMMENT ON TABLE "SIGMAmed"."Patient" IS 'Patient-specific information extending User table';
COMMENT ON COLUMN "SIGMAmed"."Patient"."MedicationAllergies" IS 'JSONB array of medication allergies';

-- Commit transaction for Creating Patient Table
COMMIT;