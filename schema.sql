CREATE TABLE IF NOT EXISTS Users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    role VARCHAR(50) NOT NULL CHECK (role IN ('Administrator', 'Doctor', 'Patient')),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS Medication (
    medication_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    dosage_form VARCHAR(50), -- e.g., 'Tablet', 'Liquid', 'Capsule'
    dosage_strength VARCHAR(50), -- e.g., '500 mg', '10 ml'
    created_at TIMESTAMPTZ DEFAULT now()
);

DROP TABLE IF EXISTS Medication;
DROP TABLE IF EXISTS Users;