-- Set search path for current session
SET search_path TO "SIGMAmed", public;

-- Start transaction for Creating Patient Side Effect Table
BEGIN;

CREATE TABLE "SIGMAmed"."PatientSideEffect" (
    -- for supabase, need to use extensions.uuid_generate_v4()
    "PatientSideEffectID" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "PrescribedMedicationID" UUID NOT NULL REFERENCES "SIGMAmed"."PrescribedMedication"("PrescribedMedicationId") ON DELETE CASCADE,
    "SideEffectName" VARCHAR(100) NOT NULL,
    "Severity" INT DEFAULT 0,
    "OnsetDate" DATE NOT NULL,
    "PatientNotes" TEXT,
    "ResolutionDate" DATE NULL,
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT chk_side_effect_severity CHECK ("Severity" >= 0 AND "Severity" <= 10),
    CONSTRAINT chk_side_effect_dates CHECK ("ResolutionDate" IS NULL OR "OnsetDate" <= "ResolutionDate"),
    UNIQUE("PrescribedMedicationID", "SideEffectName")
);

COMMENT ON TABLE "SIGMAmed"."PatientSideEffect" IS 'Side effects reported by patients for prescribed medications';

-- Commit transaction for Creating Patient Side Effect Table
COMMIT;