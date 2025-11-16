-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Appointment Table
BEGIN;

CREATE TABLE "SIGMAmed"."Appointment" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "AppointmentId" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "DoctorId" UUID NOT NULL REFERENCES "SIGMAmed"."Doctor"("UserId") ON DELETE RESTRICT,
    "PatientId" UUID NOT NULL REFERENCES "SIGMAmed"."Patient"("UserId") ON DELETE CASCADE,
    "AppointmentDate" DATE NOT NULL,
    "AppointmentTime" TIME NOT NULL,
    "DurationMinutes" INT NOT NULL,
    "AppointmentType" "SIGMAmed".appointment_type_enum NOT NULL,
    "Status" "SIGMAmed".appointment_status_enum DEFAULT 'scheduled',
    "Notes" TEXT,
    "IsEmergency" BOOLEAN DEFAULT FALSE,
    "IsDeleted" BOOLEAN DEFAULT FALSE,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
    CONSTRAINT chk_duration CHECK ("DurationMinutes" > 0 AND "DurationMinutes" <= 480)
);

COMMENT ON TABLE "SIGMAmed"."Appointment" IS 'Medical appointments between doctors and patients';


-- Commit transaction for Creating Appointment Table
COMMIT;