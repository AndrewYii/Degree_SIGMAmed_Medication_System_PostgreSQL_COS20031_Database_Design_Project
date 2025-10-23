-- For PostgreSQL Database Schema for SIGMAmed Medication System
-- In this project, our group will collaborate using the online Service "GitHub" and "Supabase" for simulating the online database environment.
-- This script created for the both local development and deployment to Supabase PostgreSQL database
-- Assume use the default public database in PostgreSQL for both local and Supabase deployment

-- Enable necessary extensions for PostgreSQL 
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";

-- Create the SIGMAmed schema
CREATE SCHEMA IF NOT EXISTS "SIGMAmed";

-- Include public so extension functions (e.g., uuid_generate_v4) resolve without schema-qualification
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating ClinicalInstitution Table
BEGIN;

-- ClinicalInstitution Table
CREATE TABLE IF NOT EXISTS "ClinicalInstitution" (
    "ClinicalInstitutionID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionName" VARCHAR(100) NOT NULL,
    "Description" TEXT,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for ClinicalInstitution:
-- Optimize search by institution name.
CREATE INDEX idx_clinicalinstitution_name ON "ClinicalInstitution"("ClinicalInstitutionName");
-- Speed up queries filtering out soft-deleted records.
CREATE INDEX idx_clinicalinstitution_isdeleted ON "ClinicalInstitution"("IsDeleted");

COMMIT;
-- End of the ClinicalInstitution Table creation


-- Start transaction for Creating User Table (base table for different roles)
BEGIN;

-- User Table (base table for different roles)
CREATE TABLE IF NOT EXISTS "User" (
    "UserId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionID" UUID,
    "Username" VARCHAR(50) UNIQUE NOT NULL,
    "Email" CITEXT UNIQUE NOT NULL,
    "PasswordHash" VARCHAR(255) NOT NULL,
    "Role" ENUM ('doctor', 'patient', 'admin') NOT NULL,
    "ICPassportNumber" VARCHAR(50) UNIQUE NOT NULL,
    "FirstName" VARCHAR(100) NOT NULL,
    "LastName" VARCHAR(100) NOT NULL,
    "Phone" VARCHAR(20) NOT NULL,
    "DateOfBirth" DATE NOT NULL,
    "FcmKey" VARCHAR(255)  NULL,
    "ProfilePictureUrl" TEXT NULL,
    "IsActive" BOOLEAN DEFAULT TRUE,
    "IsDeleted" BOOLEAN DEFAULT FALSE
);
-- Add foreign key constraint to link User to ClinicalInstitution
ALTER TABLE "User" ADD CONSTRAINT "fk_user_clinicalinstitution" FOREIGN KEY ("ClinicalInstitutionId") REFERENCES "ClinicalInstitution"("ClinicalInstitutionID");

COMMIT;
-- End of the User Table creation

-- Start transaction for Creating Medication Table
BEGIN;

-- Medication Table
CREATE TABLE IF NOT EXISTS "Medication" (
    "MedicationID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionID" UUID
    "MedicationName" VARCHAR(100) NOT NULL,
    "TotalAmount" INT NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE
);
-- Add foreign key constraint to link Medication to ClinicalInstitution
ALTER TABLE "Medication" ADD CONSTRAINT "fk_medication_clinicalinstitution" FOREIGN KEY ("ClinicalInstitutionId") REFERENCES "ClinicalInstitution"("ClinicalInstituionID");

COMMIT;
-- End of the Medication Table creation

-- Start transaction for Creating Medication Table
BEGIN;

-- Medication Log Table
CREATE TABLE IF NOT EXISTS "MedicationLog" (
    "MedicationID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionID" UUID
    "MedicationName" VARCHAR(100) NOT NULL,
    "TotalAmount" INT NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE
);
-- Add foreign key constraint to link Medication to ClinicalInstitution
ALTER TABLE "Medication" ADD CONSTRAINT "fk_medication_clinicalinstitution" FOREIGN KEY ("ClinicalInstitutionId") REFERENCES "ClinicalInstitution"("ClinicalInstituionID");

COMMIT;
-- End of the Medication Table creation







-- Start transaction for Creating Medication Table
BEGIN;

-- Medication Log Table
CREATE TABLE IF NOT EXISTS "MedicationLog" (
    "MedicationID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ClinicalInstitutionID" UUID
    "MedicationName" VARCHAR(100) NOT NULL,
    "TotalAmount" INT NOT NULL,
    "IsDeleted" BOOLEAN DEFAULT FALSE
);
-- Add foreign key constraint to link Medication to ClinicalInstitution
ALTER TABLE "Medication" ADD CONSTRAINT "fk_medication_clinicalinstitution" FOREIGN KEY ("ClinicalInstitutionId") REFERENCES "ClinicalInstitution"("ClinicalInstituionID");

COMMIT;
-- End of the Medication Table creation
