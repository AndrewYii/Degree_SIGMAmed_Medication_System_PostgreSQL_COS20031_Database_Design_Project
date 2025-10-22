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

-- Add foreign key constraint to link User to ClinicalInstitution
ALTER TABLE "User" ADD CONSTRAINT "fk_user_clinicalinstitution" FOREIGN KEY ("ClinicalInstitutionId") REFERENCES "ClinicalInstitution"("ClinicalInstitutionID");

COMMIT;
-- End of the User Table creation