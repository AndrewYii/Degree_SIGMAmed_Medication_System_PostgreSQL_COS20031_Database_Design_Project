-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Admin Table
BEGIN;

CREATE TABLE "SIGMAmed"."Admin" (
    "UserId" UUID PRIMARY KEY REFERENCES "SIGMAmed"."User"("UserId") ON DELETE CASCADE,
    "AdminLevel" "SIGMAmed".admin_level_enum
);

COMMENT ON TABLE "SIGMAmed"."Admin" IS 'Admin-specific information extending User table';

-- Commit transaction for Creating Admin Table
COMMIT;