-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating AppointmentReminder Table
BEGIN;

CREATE TABLE "SIGMAmed"."AppointmentReminder" (
    "AppointmentReminderID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "AppointmentID" UUID NULL REFERENCES "SIGMAmed"."Appointment"("AppointmentId"),
    "ScheduledTime" TIMESTAMPTZ NOT NULL,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE "SIGMAmed"."AppointmentReminder" IS 'Scheduled appointmet for the patients.';

-- Commit transaction for Creating AppointmentReminder Table
COMMIT;

