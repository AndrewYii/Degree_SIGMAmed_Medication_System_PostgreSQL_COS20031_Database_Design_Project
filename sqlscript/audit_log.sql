-- View for AuditLog
CREATE OR REPLACE VIEW "SIGMAmed"."AuditLogView" AS
SELECT
    A."AuditLogId",
    A."ActionTimestamp",
    A."TableName",
    A."RecordId",
    A."ActionStatus",
    U."FirstName" || ' ' || U."LastName" AS "ActedByFullName", -- Display full name
    U."Username" AS "ActedByUsername",
    U."Role" AS "ActedByRole",
    A."OldValue",
    A."NewValue"
FROM
    "SIGMAmed"."AuditLog" A
JOIN
    "SIGMAmed"."User" U ON A."ActedBy" = U."UserId"
ORDER BY
    A."ActionTimestamp" DESC;

COMMENT ON VIEW "SIGMAmed"."AuditLogView" IS 'Provides a human-readable view of the audit trail, joining the ActedBy UUID to the user''s name and role.';

-- Need update this
-- RAISE NOTICE 'Switching ActedBy user to Doctor ID: %', DOCTOR_ID;
--     EXECUTE 'SET SESSION "app.current_user_id" = ' || quote_literal(DOCTOR_ID);