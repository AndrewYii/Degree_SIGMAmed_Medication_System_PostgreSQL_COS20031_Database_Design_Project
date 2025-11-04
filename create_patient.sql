-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Patient Table
BEGIN;

CREATE TABLE "SIGMAmed"."Patient" (
    "UserId" UUID PRIMARY KEY REFERENCES "SIGMAmed"."User"("UserId") ON DELETE CASCADE,
    "PatientNumber" VARCHAR(20) UNIQUE NOT NULL,
    "BloodType" VARCHAR(5),
    "HeightCm" DECIMAL(5,2),
    "WeightKg" DECIMAL(5,2),
    "EmergencyContactName" VARCHAR(100),
    "EmergencyContactNumber" VARCHAR(20),
    "MedicationAllergies" JSONB DEFAULT '[]',
    CONSTRAINT chk_blood_type CHECK ("BloodType" IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') OR "BloodType" IS NULL),
    CONSTRAINT chk_height CHECK ("HeightCm" > 0 AND "HeightCm" < 300),
    CONSTRAINT chk_weight CHECK ("WeightKg" > 0 AND "WeightKg" < 500)
);

COMMENT ON TABLE "SIGMAmed"."Patient" IS 'Patient-specific information extending User table';
COMMENT ON COLUMN "SIGMAmed"."Patient"."MedicationAllergies" IS 'JSONB array of medication allergies';

-- Commit transaction for Creating Patient Table
COMMIT;