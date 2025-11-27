-- No need to run this script, as all type already exists in dummy.sql

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