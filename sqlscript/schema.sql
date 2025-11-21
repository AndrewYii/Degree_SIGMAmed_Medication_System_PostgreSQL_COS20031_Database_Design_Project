-- For PostgreSQL Database Schema for SIGMAmed Medication System
-- In this project, our group will collaborate using the online Service "GitHub" and "Supabase" for simulating the online database environment.
-- This script created for the both local development and deployment to Supabase PostgreSQL database
-- Assume use the default public database in PostgreSQL for both local and Supabase deployment

-- Create SIGMAmed Database
-- DROP DATABASE IF EXISTS "SIGMAmed";
-- CREATE DATABASE "SIGMAmed";
-- Create SIGMAmed Schema
CREATE SCHEMA IF NOT EXISTS "SIGMAmed";

-- Set search path to SIGMAmed and public schemas
SET search_path TO "SIGMAmed", public;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "citext" SCHEMA public;
-- CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" SCHEMA public;

-- Create Enums for SIGMAmed
CREATE TYPE "SIGMAmed".user_role_enum AS ENUM ('admin', 'doctor', 'patient');
CREATE TYPE "SIGMAmed".action_type_enum AS ENUM ('insert', 'update', 'delete');
CREATE TYPE "SIGMAmed".prescription_status_enum AS ENUM ('active', 'completed');
CREATE TYPE "SIGMAmed".prescribedmedication_status_enum AS ENUM ('active', 'completed','stop');
CREATE TYPE "SIGMAmed".appointment_status_enum AS ENUM ('scheduled', 'confirmed', 'completed', 'cancelled');
CREATE TYPE "SIGMAmed".appointment_type_enum AS ENUM ('consultation', 'follow-up');
CREATE TYPE "SIGMAmed".patient_report_status_enum AS ENUM ('SideEffect', 'Symptom','General');
CREATE TYPE "SIGMAmed".doctor_level_enum AS ENUM ('primary', 'secondary');
CREATE TYPE "SIGMAmed".reminder_status_enum AS ENUM ('Taken', 'Missed', 'Pending');
CREATE TYPE "SIGMAmed".admin_level_enum AS ENUM ('super', 'hospital');
CREATE TYPE "SIGMAmed".weekday_enum AS ENUM ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');
CREATE TYPE "SIGMAmed".dosage_form_enum AS ENUM ('tablet','capsule','syrup','injection');
CREATE TYPE "SIGMAmed".severity_enum AS ENUM ('mild','moderate','severe');

