-- FUNCTION: Create record inside appointment reminder table 
CREATE OR REPLACE FUNCTION "SIGMAmed".fn_generate_appointment_reminders()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert reminder 1 day before
    INSERT INTO "SIGMAmed"."AppointmentReminder"(
        "AppointmentId",
        "ScheduledTime"
    ) VALUES (
        NEW."AppointmentId",
        NEW."AppointmentDate" - INTERVAL '1 day'
    );

    -- Insert reminder 1 hour before
    INSERT INTO "SIGMAmed"."AppointmentReminder"(
        "AppointmentId",
        "ScheduledTime"
    ) VALUES (
        NEW."AppointmentId",
        NEW."AppointmentDate" - INTERVAL '1 hour'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION "SIGMAmed".fn_generate_appointment_reminders IS 'Create record inside appointment reminder table.';

CREATE TRIGGER trg_after_appointment_insert
AFTER INSERT ON "SIGMAmed"."Appointment"
FOR EACH ROW
EXECUTE FUNCTION "SIGMAmed".fn_generate_appointment_reminders();