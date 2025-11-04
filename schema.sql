-- For PostgreSQL Database Schema for SIGMAmed Medication System
-- In this project, our group will collaborate using the online Service "GitHub" and "Supabase" for simulating the online database environment.
-- This script created for the both local development and deployment to Supabase PostgreSQL database
-- Assume use the default public database in PostgreSQL for both local and Supabase deployment

-- Create SIGMAmed Schema
CREATE SCHEMA IF NOT EXISTS "SIGMAmed";

-- Set search path so we don't need to prefix everything
SET search_path TO "SIGMAmed", public;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "citext" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" SCHEMA public;

-- Create Enums for SIGMAmed
CREATE TYPE "SIGMAmed".user_role_enum AS ENUM ('admin', 'doctor', 'patient');
CREATE TYPE "SIGMAmed".action_type_enum AS ENUM ('create', 'update', 'delete', 'restore');
CREATE TYPE "SIGMAmed".prescription_status_enum AS ENUM ('active', 'completed');
CREATE TYPE "SIGMAmed".appointment_status_enum AS ENUM ('scheduled', 'confirmed', 'completed', 'cancelled');
CREATE TYPE "SIGMAmed".appointment_type_enum AS ENUM ('consultation', 'follow-up');
CREATE TYPE "SIGMAmed".patient_report_status_enum AS ENUM ('Appointment', 'SideEffect', 'Symptom', 'No');
CREATE TYPE "SIGMAmed".doctor_level_enum AS ENUM ('primary', 'secondary');
CREATE TYPE "SIGMAmed".reminder_status_enum AS ENUM ('ignored', 'completed');
CREATE TYPE "SIGMAmed".admin_level_enum AS ENUM ('super', 'hospital');
CREATE TYPE "SIGMAmed".weekday_enum AS ENUM ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');