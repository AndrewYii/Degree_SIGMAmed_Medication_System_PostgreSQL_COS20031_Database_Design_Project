import psycopg2
from psycopg2.extras import RealDictCursor, execute_values
import sys
from datetime import datetime, timedelta, date, time
import random
from db_config import DBConfig
from data_generator import SIGMAmedDataGenerator

class DummyDataInserter100K:
    """
    High-performance data inserter for 100K+ records per table
    Includes super admin creation and meaningful, valid data generation
    """
    
    def __init__(self):
        try:
            DBConfig.validate()
            self.conn = psycopg2.connect(**DBConfig.get_connection_params())
            self.conn.autocommit = False
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            self.schema = DBConfig.SCHEMA
            self.generator = SIGMAmedDataGenerator()
            self.super_admin_id = None
            self.ic_counter = 1  # Global counter for unique ICPassportNumber generation
            self.phone_counter = 1  # Global counter for unique Phone generation
            print(f"✓ Connected to database: {DBConfig.NAME}")
            print(f"✓ Using schema: {self.schema}")
        except Exception as e:
            print(f"✗ Failed to connect to database: {e}")
            sys.exit(1)
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
    
    def close(self):
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        print("✓ Database connection closed")
    
    def set_search_path(self):
        self.cursor.execute(f'SET search_path TO "{self.schema}", public;')
    
    def disable_triggers(self):
        """Disable automatic role creation triggers for bulk insertion"""
        print("  ⚙️  Disabling auto-creation triggers for bulk insert...")
        try:
            # First, check what triggers exist on User table
            self.cursor.execute(f'''
                SELECT tgname FROM pg_trigger 
                WHERE tgrelid = '"{self.schema}"."User"'::regclass
                AND tgname LIKE '%auto%'
            ''')
            triggers = self.cursor.fetchall()
            
            if triggers:
                for trigger in triggers:
                    trigger_name = trigger['tgname'] if isinstance(trigger, dict) else trigger[0]
                    print(f"    Disabling trigger: {trigger_name}")
                    self.cursor.execute(f'''
                        ALTER TABLE "{self.schema}"."User" DISABLE TRIGGER {trigger_name};
                    ''')
                self.conn.commit()
                print("  ✓ Triggers disabled")
            else:
                print("  ℹ️  No auto-creation triggers found - will create role records manually")
                self.conn.commit()
        except Exception as e:
            print(f"  ⚠️  Could not disable triggers: {e}")
            self.conn.rollback()
    
    def enable_triggers(self):
        """Re-enable automatic role creation triggers"""
        print("  ⚙️  Re-enabling auto-creation triggers...")
        try:
            # Get all disabled triggers on User table
            self.cursor.execute(f'''
                SELECT tgname FROM pg_trigger 
                WHERE tgrelid = '"{self.schema}"."User"'::regclass
                AND tgname LIKE '%auto%'
            ''')
            triggers = self.cursor.fetchall()
            
            if triggers:
                for trigger in triggers:
                    trigger_name = trigger['tgname'] if isinstance(trigger, dict) else trigger[0]
                    print(f"    Enabling trigger: {trigger_name}")
                    self.cursor.execute(f'''
                        ALTER TABLE "{self.schema}"."User" ENABLE TRIGGER {trigger_name};
                    ''')
                self.conn.commit()
                print("  ✓ Triggers enabled")
            else:
                print("  ℹ️  No triggers to re-enable")
                self.conn.commit()
        except Exception as e:
            print(f"  ⚠️  Could not enable triggers: {e}")
            self.conn.rollback()
    
    def create_super_admin(self, institution_id):
        """Create THE super admin user - only one in the system (or return existing)
        Super admin has NULL ClinicalInstitutionId (not tied to any specific institution)"""
        print(f"\n👑 Ensuring SUPER ADMIN exists...")
        
        # Check if super admin already exists
        self.cursor.execute(f'''
            SELECT u."UserId", u."Username", u."Email", u."ClinicalInstitutionId"
            FROM "{self.schema}"."User" u
            JOIN "{self.schema}"."Admin" a ON u."UserId" = a."UserId"
            WHERE a."AdminLevel" = 'super'
            LIMIT 1
        ''')
        
        existing_admin = self.cursor.fetchone()
        
        if existing_admin:
            super_admin_user_id = existing_admin['UserId']
            self.super_admin_id = super_admin_user_id
            institution_status = "NULL (System-wide)" if existing_admin['ClinicalInstitutionId'] is None else f"Institution: {existing_admin['ClinicalInstitutionId']}"
            print(f"  ✓ Super Admin already exists: {existing_admin['Username']} / {existing_admin['Email']}")
            print(f"  ✓ Institution: {institution_status}")
            print(f"  ✓ User ID: {super_admin_user_id}")
            return super_admin_user_id
        
        # Create super admin user with NULL institution (system-wide access)
        try:
            self.cursor.execute(f'''
                INSERT INTO "{self.schema}"."User" 
                ("ClinicalInstitutionId", "Username", "Email", "PasswordHash", "Role",
                 "ICPassportNumber", "FirstName", "LastName", "Phone", "DateOfBirth", "IsDeleted")
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT ("Username") DO UPDATE 
                SET "ClinicalInstitutionId" = NULL
                RETURNING "UserId"
            ''', (
                None,  # NULL - Super admin is not tied to any specific institution
                'superadmin',
                'admin@sigmamed.com',
                '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYILSBfz.3O',  # password: password123
                'admin',
                'SA000000',
                'Super',
                'Admin',
                '+1-555-ADMIN-01',
                date(1980, 1, 1),
                False
            ))
            
            user_result = self.cursor.fetchone()
            super_admin_user_id = user_result['UserId']
            
            # Create admin record (with conflict handling)
            self.cursor.execute(f'''
                INSERT INTO "{self.schema}"."Admin" ("UserId", "AdminLevel")
                VALUES (%s, %s)
                ON CONFLICT ("UserId") DO UPDATE
                SET "AdminLevel" = EXCLUDED."AdminLevel"
            ''', (super_admin_user_id, 'super'))
            
            self.conn.commit()
            self.super_admin_id = super_admin_user_id
            
            print(f"  ✓ Super Admin created: superadmin / admin@sigmamed.com")
            print(f"  ✓ Password: password123")
            print(f"  ✓ Institution: NULL (System-wide access)")
            print(f"  ✓ User ID: {super_admin_user_id}")
            
            return super_admin_user_id
            
        except Exception as e:
            self.conn.rollback()
            print(f"  ⚠️  Error creating super admin: {e}")
            # Try to find existing one
            self.cursor.execute(f'''
                SELECT u."UserId" FROM "{self.schema}"."User" u
                WHERE u."Username" = 'superadmin'
            ''')
            result = self.cursor.fetchone()
            if result:
                return result['UserId']
            raise
    
    def insert_institutions(self, count):
        """Insert clinical institutions with unique names"""
        print(f"\n📍 Inserting {count:,} clinical institutions...")
        
        batch_size = 5000
        institution_ids = []
        
        for i in range(0, count, batch_size):
            batch_count = min(batch_size, count - i)
            institutions = self.generator.generate_clinical_institution(batch_count)
            
            values = [
                (inst['ClinicalInstitutionName'], inst['IsDeleted'])
                for inst in institutions
            ]
            
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."ClinicalInstitution" 
                    ("ClinicalInstitutionName", "IsDeleted")
                    VALUES %s 
                    ON CONFLICT DO NOTHING
                    RETURNING "ClinicalInstitutionId"''',
                values,
                fetch=True
            )
            
            batch_ids = [row['ClinicalInstitutionId'] if isinstance(row, dict) else row[0] for row in result]
            institution_ids.extend(batch_ids)
            self.conn.commit()
            print(f"  ✓ Progress: {len(institution_ids):,}/{count:,} institutions created", end='\r')
        
        print(f"\n  ✓ Created {len(institution_ids):,} institutions")
        return institution_ids
    
    def insert_users(self, institution_ids, role, count):
        """Insert users with specific role"""
        print(f"\n👤 Inserting {count:,} {role}(s)...")
        
        batch_size = 10000
        user_ids = []
        
        for i in range(0, count, batch_size):
            batch_count = min(batch_size, count - i)
            
            batch_users = []
            for j in range(batch_count):
                institution_id = random.choice(institution_ids)
                user_data = self.generator.generate_user(institution_id, role, 1)[0]
                # Override IC and Phone with deterministic unique values BEFORE insert
                user_data['ICPassportNumber'] = f"IC{self.ic_counter:012d}"
                user_data['Phone'] = f"+60{self.phone_counter:011d}"
                self.ic_counter += 1
                self.phone_counter += 1
                batch_users.append(user_data)
            
            values = [
                (
                    u['ClinicalInstitutionId'], u['Username'], u['Email'], u['PasswordHash'],
                    u['Role'], u['ICPassportNumber'], u['FirstName'], u['LastName'],
                    u['Phone'], u['DateOfBirth'], u['IsDeleted']
                )
                for u in batch_users
            ]
            
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."User" 
                    ("ClinicalInstitutionId", "Username", "Email", "PasswordHash", "Role",
                     "ICPassportNumber", "FirstName", "LastName", "Phone", "DateOfBirth", "IsDeleted")
                    VALUES %s 
                    ON CONFLICT ("Username") DO NOTHING
                    RETURNING "UserId"''',
                values,
                fetch=True
            )
            
            batch_ids = [row['UserId'] if isinstance(row, dict) else row[0] for row in result]
            user_ids.extend(batch_ids)
            self.conn.commit()
            print(f"  ✓ Progress: {len(user_ids):,}/{count:,} {role}s created", end='\r')
        
        print(f"\n  ✓ Created {len(user_ids):,} {role}s")
        return user_ids
    
    def insert_role_specific_records(self, user_ids, role):
        """Insert role-specific records (Doctor, Patient, Admin)"""
        print(f"\n🔧 Creating {role}-specific records for {len(user_ids):,} users...")
        
        batch_size = 10000
        created_count = 0
        
        for i in range(0, len(user_ids), batch_size):
            batch_ids = user_ids[i:i+batch_size]
            
            if role == 'doctor':
                # Get max existing medical license number to avoid collisions
                # Determine the highest combined numeric part of existing MedicalLicenseNumber
                # We strip all non-digits then cast to bigint, this creates an 8-digit numeric code that
                # can be formatted into MD-####-#### reliably. This avoids collisions due to random suffixes.
                self.cursor.execute(f'''
                    SELECT COALESCE(MAX(
                        CAST(REGEXP_REPLACE("MedicalLicenseNumber", '[^0-9]', '', 'g') AS BIGINT)
                    ), 0) as max_num
                    FROM "{self.schema}"."Doctor"
                    WHERE "MedicalLicenseNumber" ~ '^MD-[0-9]{{4}}-[0-9]{{4}}$'
                ''')
                result = self.cursor.fetchone()
                start_num = (result['max_num'] if result and result['max_num'] else 0) + 1
                
                # Build deterministic set of license numbers for the batch and check for collisions
                values = []
                license_candidates = []
                for idx, user_id in enumerate(batch_ids):
                    doc = self.generator.generate_doctor(user_id)
                    seq_val = start_num + idx
                    high = (seq_val // 10000) % 10000
                    low = seq_val % 10000
                    license_num = f"MD-{high:04d}-{low:04d}"
                    values.append((doc['UserId'], license_num, 
                                  doc['Specialization'], doc['YearOfExperience']))
                    license_candidates.append(license_num)

                # If any of the candidate license numbers already exist in the database, shift the
                # sequence forward until we find an unused block. This guards against collisions
                # from previous runs or partial data.
                attempts = 0
                existing_conflicts = True
                while existing_conflicts and attempts < 10:
                    self.cursor.execute(
                        f'''SELECT "MedicalLicenseNumber" FROM "{self.schema}"."Doctor"
                            WHERE "MedicalLicenseNumber" = ANY(%s)''',
                        (license_candidates,)
                    )
                    conflicts = [r[0] if not isinstance(r, dict) else r['MedicalLicenseNumber'] for r in self.cursor.fetchall()]
                    if not conflicts:
                        existing_conflicts = False
                        break

                    # Move start_num forward by batch size to try next block
                    attempts += 1
                    start_num += len(batch_ids)
                    license_candidates = []
                    for idx in range(len(batch_ids)):
                        seq_val = start_num + idx
                        high = (seq_val // 10000) % 10000
                        low = seq_val % 10000
                        license_candidates.append(f"MD-{high:04d}-{low:04d}")

                if existing_conflicts:
                    # If after a few attempts we still find conflicts, fail fast to avoid partial inserts
                    raise Exception("Could not generate unique MedicalLicenseNumber for doctors — collisions remain")
                
                execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."Doctor"
                        ("UserId", "MedicalLicenseNumber", "Specialization", "YearOfExperience")
                        VALUES %s
                        ON CONFLICT ("UserId") DO NOTHING''',
                    values
                )
                
                # Advance the global counter so the next batch starts after the last value used
                start_num += len(batch_ids)
                
            elif role == 'patient':
                # Get the max patient number to avoid conflicts
                self.cursor.execute(f'''
                    SELECT COALESCE(MAX(
                        CASE 
                            WHEN "PatientNumber" ~ '^PAT-[0-9]+$' 
                            THEN CAST(SUBSTRING("PatientNumber" FROM 5) AS INTEGER)
                            ELSE 0 
                        END
                    ), 0) as max_num
                    FROM "{self.schema}"."Patient"
                    WHERE "PatientNumber" IS NOT NULL AND "PatientNumber" != ''
                ''')
                result = self.cursor.fetchone()
                start_num = (result['max_num'] if result and result['max_num'] else 0) + 1
                
                values = []
                for idx, user_id in enumerate(batch_ids):
                    pat = self.generator.generate_patient(user_id)
                    # Generate unique patient number
                    patient_number = f"PAT-{(start_num + idx):010d}"
                    values.append((pat['UserId'], patient_number, pat['BloodType'], pat['HeightCm'], 
                                  pat['WeightKg'], pat['EmergencyContactName'], 
                                  pat['EmergencyContactNumber'], pat['MedicationAllergies']))
                
                execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."Patient"
                        ("UserId", "PatientNumber", "BloodType", "HeightCm", "WeightKg", "EmergencyContactName",
                         "EmergencyContactNumber", "MedicationAllergies")
                        VALUES %s
                        ON CONFLICT ("UserId") DO NOTHING''',
                    values
                )
                
                # Update start_num for next batch
                start_num += len(batch_ids)
                
            elif role == 'admin':
                values = []
                for user_id in batch_ids:
                    admin = self.generator.generate_admin(user_id)
                    values.append((admin['UserId'], admin['AdminLevel']))
                
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."Admin"
                        ("UserId", "AdminLevel")
                        VALUES %s
                        ON CONFLICT ("UserId") DO NOTHING
                        RETURNING "UserId"''',
                    values,
                    fetch=True
                )
                actual_inserted = len(result) if result else 0
                if actual_inserted < len(batch_ids):
                    print(f"\n  ⚠️  Warning: Only {actual_inserted}/{len(batch_ids)} admin records inserted (conflicts detected)")
            
            created_count += len(batch_ids)
            self.conn.commit()
            print(f"  ✓ Progress: {created_count:,}/{len(user_ids):,} {role} records created", end='\r')
        
        print(f"\n  ✓ Created {created_count:,} {role} records")
        return created_count
    
    def insert_medications(self, institution_ids):
        """Insert medications - distribute medications across institutions"""
        print(f"\n💊 Inserting medications across {len(institution_ids):,} institutions...")
        
        total_meds = 0
        batch_size = 5000
        values = []
        
        for institution_id in institution_ids:
            # Each institution gets 1-3 random medications
            num_meds = random.randint(1, 3)
            meds = self.generator.generate_medication(institution_id, num_meds)
            
            for med in meds:
                values.append((med['ClinicalInstitutionId'], med['MedicationName'],
                              med['Unit'], med['DosageForm'], med['IsDeleted']))
            
            # Insert when batch is full
            if len(values) >= batch_size:
                execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."Medication"
                        ("ClinicalInstitutionId", "MedicationName", "Unit", "DosageForm", "IsDeleted")
                        VALUES %s
                        ON CONFLICT ("ClinicalInstitutionId", "MedicationName") DO NOTHING''',
                    values
                )
                total_meds += len(values)
                self.conn.commit()
                print(f"  ✓ Progress: {total_meds:,} medications created", end='\r')
                values = []
        
        # Insert remaining
        if values:
            execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."Medication"
                    ("ClinicalInstitutionId", "MedicationName", "Unit", "DosageForm", "IsDeleted")
                    VALUES %s
                    ON CONFLICT ("ClinicalInstitutionId", "MedicationName") DO NOTHING''',
                values
            )
            total_meds += len(values)
            self.conn.commit()
        
        # Get all medication IDs
        self.cursor.execute(f'SELECT "MedicationId" FROM "{self.schema}"."Medication" WHERE "IsDeleted" = false')
        medication_ids = [row['MedicationId'] for row in self.cursor.fetchall()]
        
        print(f"\n  ✓ Created {total_meds:,} medication records ({len(medication_ids):,} unique)")
        return medication_ids
    
    def insert_patient_care_teams(self, doctor_ids, patient_ids, target_count=100000):
        """Assign doctors to patients - each patient gets 1-2 doctors"""
        print(f"\n🤝 Creating {target_count:,} doctor-patient care team assignments...")
        
        batch_size = 5000
        care_team_ids = []
        assignments = []
        
        # Strategy: Each patient gets 1 primary doctor, some get secondary
        for i, patient_id in enumerate(patient_ids):
            if len(care_team_ids) >= target_count:
                break
            
            # Primary doctor
            primary_doctor = random.choice(doctor_ids)
            role = random.choice(['General Practitioner', 'Primary Care Physician', 'Family Doctor'])
            assignments.append((primary_doctor, patient_id, 'primary', role, True, False))
            
            # 40% chance of secondary doctor
            if random.random() < 0.4 and len(care_team_ids) + len(assignments) < target_count:
                secondary_doctor = random.choice([d for d in doctor_ids if d != primary_doctor])
                secondary_role = random.choice(['Specialist', 'Consultant', 'Surgeon'])
                assignments.append((secondary_doctor, patient_id, 'secondary', secondary_role, True, False))
            
            # Insert batch
            if len(assignments) >= batch_size:
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."PatientCareTeam"
                        ("DoctorId", "PatientId", "DoctorLevel", "Role", "IsActive", "IsDeleted")
                        VALUES %s
                        ON CONFLICT ("DoctorId", "PatientId", "DoctorLevel") DO NOTHING
                        RETURNING "PatientCareTeamId"''',
                    assignments,
                    fetch=True
                )
                batch_ids = [row['PatientCareTeamId'] if isinstance(row, dict) else row[0] for row in result]
                care_team_ids.extend(batch_ids)
                self.conn.commit()
                print(f"  ✓ Progress: {len(care_team_ids):,}/{target_count:,} care team assignments created", end='\r')
                assignments = []
        
        # Insert remaining
        if assignments:
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."PatientCareTeam"
                    ("DoctorId", "PatientId", "DoctorLevel", "Role", "IsActive", "IsDeleted")
                    VALUES %s
                    ON CONFLICT ("DoctorId", "PatientId", "DoctorLevel") DO NOTHING
                    RETURNING "PatientCareTeamId"''',
                assignments,
                fetch=True
            )
            batch_ids = [row['PatientCareTeamId'] if isinstance(row, dict) else row[0] for row in result]
            care_team_ids.extend(batch_ids)
            self.conn.commit()
        
        print(f"\n  ✓ Created {len(care_team_ids):,} patient care team assignments")
        return care_team_ids
    
    def insert_medical_histories(self, patient_ids, target_count=100000):
        """Insert medical histories for patients"""
        print(f"\n🏥 Creating {target_count:,} medical history records...")
        
        batch_size = 5000
        history_ids = []
        values = []
        
        # Each patient gets 1-3 medical histories
        patient_idx = 0
        while len(history_ids) < target_count and patient_idx < len(patient_ids):
            patient_id = patient_ids[patient_idx]
            num_histories = random.randint(1, 3)
            
            diseases = random.sample(self.generator.DISEASES, min(num_histories, len(self.generator.DISEASES)))
            for disease in diseases:
                if len(history_ids) + len(values) >= target_count:
                    break
                    
                severity = random.choice(['mild', 'moderate', 'severe'])
                diagnosed_date = self.generator.fake.date_between(start_date='-5y', end_date='today')
                resolution_date = self.generator.fake.date_between(start_date=diagnosed_date, end_date='today') if random.random() > 0.4 else None
                values.append((patient_id, disease, severity, diagnosed_date, resolution_date, False))
            
            patient_idx += 1
            
            # Insert batch
            if len(values) >= batch_size:
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."MedicalHistory"
                        ("PatientId", "DiseaseName", "Severity", "DiagnosedDate", "ResolutionDate", "IsDeleted")
                        VALUES %s
                        RETURNING "MedicalHistoryId"''',
                    values,
                    fetch=True
                )
                batch_ids = [row['MedicalHistoryId'] if isinstance(row, dict) else row[0] for row in result]
                history_ids.extend(batch_ids)
                self.conn.commit()
                print(f"  ✓ Progress: {len(history_ids):,}/{target_count:,} medical histories created", end='\r')
                values = []
        
        # Insert remaining
        if values:
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."MedicalHistory"
                    ("PatientId", "DiseaseName", "Severity", "DiagnosedDate", "ResolutionDate", "IsDeleted")
                    VALUES %s
                    RETURNING "MedicalHistoryId"''',
                values,
                fetch=True
            )
            batch_ids = [row['MedicalHistoryId'] if isinstance(row, dict) else row[0] for row in result]
            history_ids.extend(batch_ids)
            self.conn.commit()
        
        print(f"\n  ✓ Created {len(history_ids):,} medical history records")
        return history_ids
    
    def insert_patient_symptoms(self, patient_ids, target_count=100000):
        """Insert patient symptoms linked to medical histories"""
        print(f"\n🩺 Creating {target_count:,} patient symptom records...")
        
        # Get medical histories with their patient IDs
        self.cursor.execute(f'''
            SELECT "MedicalHistoryId", "PatientId", "DiseaseName"
            FROM "{self.schema}"."MedicalHistory"
            WHERE "IsDeleted" = false
        ''')
        medical_histories = self.cursor.fetchall()
        
        if not medical_histories:
            print("  ⚠️  No medical histories found. Creating symptoms without medical history links...")
            medical_histories = [{'MedicalHistoryId': None, 'PatientId': pid, 'DiseaseName': None} 
                               for pid in patient_ids[:target_count]]
        
        batch_size = 5000
        symptom_ids = []
        values = []
        
        history_idx = 0
        while len(symptom_ids) < target_count and history_idx < len(medical_histories):
            history = medical_histories[history_idx]
            
            # Each history gets 1-3 symptoms
            num_symptoms = random.randint(1, 3)
            symptoms = random.sample(self.generator.SYMPTOMS, min(num_symptoms, len(self.generator.SYMPTOMS)))
            
            for symptom in symptoms:
                if len(symptom_ids) + len(values) >= target_count:
                    break
                
                severity = random.choice(['mild', 'moderate', 'severe'])
                onset_date = self.generator.fake.date_between(start_date='-6m', end_date='today')
                # 50% resolved
                resolution_date = self.generator.fake.date_between(start_date=onset_date, end_date='today') if random.random() > 0.5 else None
                
                values.append((history['MedicalHistoryId'], history['PatientId'], symptom, severity, onset_date, resolution_date))
            
            history_idx += 1
            
            # Insert batch
            if len(values) >= batch_size:
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."PatientSymptom"
                        ("MedicalHistoryId", "PatientId", "SymptomName", "Severity", "OnsetDate", "ResolutionDate")
                        VALUES %s
                        ON CONFLICT ("MedicalHistoryId", "SymptomName") DO NOTHING
                        RETURNING "PatientSymptomId"''',
                    values,
                    fetch=True
                )
                batch_ids = [row['PatientSymptomId'] if isinstance(row, dict) else row[0] for row in result]
                symptom_ids.extend(batch_ids)
                self.conn.commit()
                print(f"  ✓ Progress: {len(symptom_ids):,}/{target_count:,} symptoms created", end='\r')
                values = []
        
        # Insert remaining
        if values:
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."PatientSymptom"
                    ("MedicalHistoryId", "PatientId", "SymptomName", "Severity", "OnsetDate", "ResolutionDate")
                    VALUES %s
                    ON CONFLICT ("MedicalHistoryId", "SymptomName") DO NOTHING
                    RETURNING "PatientSymptomId"''',
                values,
                fetch=True
            )
            batch_ids = [row['PatientSymptomId'] if isinstance(row, dict) else row[0] for row in result]
            symptom_ids.extend(batch_ids)
            self.conn.commit()
        
        print(f"\n  ✓ Created {len(symptom_ids):,} patient symptom records")
        return symptom_ids
    
    def insert_prescriptions(self, doctor_ids, patient_ids, target_count=100000):
        """Insert prescriptions with pre-calculated prescription numbers"""
        print(f"\n📝 Inserting {target_count:,} prescriptions...")
        
        # Get current max prescription number
        year = datetime.now().strftime('%Y')
        month = datetime.now().strftime('%m')
        
        self.cursor.execute(f'''
            SELECT COALESCE(MAX(
                CAST(SUBSTRING("PrescriptionNumber" FROM 10 FOR 5) AS INT)
            ), 0) as max_num
            FROM "{self.schema}"."Prescription"
            WHERE "PrescriptionNumber" LIKE 'RX-{year}{month}-%'
        ''')
        result = self.cursor.fetchone()
        start_num = (result['max_num'] if result else 0) + 1
        
        batch_size = 5000
        prescription_ids = []
        
        for i in range(0, target_count, batch_size):
            batch_count = min(batch_size, target_count - i)
            
            values = []
            for j in range(batch_count):
                doctor_id = random.choice(doctor_ids)
                patient_id = random.choice(patient_ids)
                prescribed_date = self.generator.fake.date_between(start_date='-1y', end_date='today')
                expiry_date = prescribed_date + timedelta(days=random.randint(90, 365))
                prescription_num = f"RX-{year}{month}-{(start_num + i + j):05d}"
                status = random.choice(['active', 'completed'])  # Only valid ENUM values
                
                values.append((doctor_id, patient_id, prescription_num, status, 
                              prescribed_date, expiry_date, False))
            
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."Prescription"
                    ("DoctorId", "PatientId", "PrescriptionNumber", "Status", 
                     "PrescribedDate", "ExpiryDate", "IsDeleted")
                    VALUES %s RETURNING "PrescriptionId"''',
                values,
                fetch=True
            )
            
            batch_ids = [row['PrescriptionId'] if isinstance(row, dict) else row[0] for row in result]
            prescription_ids.extend(batch_ids)
            self.conn.commit()
            print(f"  ✓ Progress: {len(prescription_ids):,}/{target_count:,} prescriptions created", end='\r')
        
        print(f"\n  ✓ Created {len(prescription_ids):,} prescriptions")
        return prescription_ids
    
    def insert_prescribed_medications(self, prescription_ids, medication_ids, target_count=200000):
        """Insert prescribed medications - link prescriptions to medications"""
        print(f"\n💊 Creating {target_count:,} prescribed medication records...")
        
        batch_size = 5000
        prescribed_med_ids = []
        values = []
        
        prescription_idx = 0
        while len(prescribed_med_ids) < target_count and prescription_idx < len(prescription_ids):
            prescription_id = prescription_ids[prescription_idx]
            
            # Each prescription gets 1-3 medications
            num_meds = random.randint(1, 3)
            selected_meds = random.sample(medication_ids, min(num_meds, len(medication_ids)))
            
            for med_id in selected_meds:
                if len(prescribed_med_ids) + len(values) >= target_count:
                    break
                
                # Get medication name for snapshot
                self.cursor.execute(f'''
                    SELECT "MedicationName" FROM "{self.schema}"."Medication" 
                    WHERE "MedicationId" = %s
                ''', (med_id,))
                med_result = self.cursor.fetchone()
                med_name = med_result['MedicationName'] if med_result else 'Unknown Medication'
                
                dosage_amount = round(random.uniform(10, 500), 2)
                dose_per_time = round(random.uniform(5, 100), 2)
                times_per_day = random.randint(1, 4)
                prescribed_date = self.generator.fake.date_between(start_date='-6m', end_date='today')
                status = random.choice(['active', 'completed', 'stop'])  # Updated ENUM values
                default_day_mask = '1111111' if random.random() > 0.3 else '1111100'  # Weekdays vs all days
                # DoseInterval: hours between doses (e.g., 6, 8, 12, 24 hours)
                dose_interval_hours = random.choice([6, 8, 12, 24])
                dose_interval = timedelta(hours=dose_interval_hours)
                
                values.append((prescription_id, med_id, dosage_amount, dose_per_time, status,
                              default_day_mask, dose_interval, prescribed_date, med_name, times_per_day, False))
            
            prescription_idx += 1
            
            # Insert batch
            if len(values) >= batch_size:
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."PrescribedMedication"
                        ("PrescriptionId", "MedicationId", "DosageAmountPrescribed", "DosePerTime",
                         "Status", "DefaultDayMask", "DoseInterval", "PrescribedDate", "MedicationNameSnapshot",
                         "TimesPerDay", "IsDeleted")
                        VALUES %s
                        RETURNING "PrescribedMedicationId"''',
                    values,
                    fetch=True
                )
                batch_ids = [row['PrescribedMedicationId'] if isinstance(row, dict) else row[0] for row in result]
                prescribed_med_ids.extend(batch_ids)
                self.conn.commit()
                print(f"  ✓ Progress: {len(prescribed_med_ids):,}/{target_count:,} prescribed medications created", end='\r')
                values = []
        
        # Insert remaining
        if values:
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."PrescribedMedication"
                    ("PrescriptionId", "MedicationId", "DosageAmountPrescribed", "DosePerTime",
                     "Status", "DefaultDayMask", "DoseInterval", "PrescribedDate", "MedicationNameSnapshot",
                     "TimesPerDay", "IsDeleted")
                    VALUES %s
                    RETURNING "PrescribedMedicationId"''',
                values,
                fetch=True
            )
            batch_ids = [row['PrescribedMedicationId'] if isinstance(row, dict) else row[0] for row in result]
            prescribed_med_ids.extend(batch_ids)
            self.conn.commit()
        
        print(f"\n  ✓ Created {len(prescribed_med_ids):,} prescribed medication records")
        return prescribed_med_ids
    
    def insert_medication_schedules(self, prescribed_med_ids, target_count=300000):
        """Insert medication schedules - dosing times for prescribed medications"""
        print(f"\n⏰ Creating {target_count:,} medication schedule records...")
        
        batch_size = 5000
        schedule_ids = []
        values = []
        
        med_idx = 0
        while len(schedule_ids) < target_count and med_idx < len(prescribed_med_ids):
            prescribed_med_id = prescribed_med_ids[med_idx]
            
            # Each prescribed medication gets 1-4 schedules (times per day)
            num_schedules = random.randint(1, 4)
            
            # Generate realistic reminder times
            reminder_times = []
            if num_schedules == 1:
                reminder_times = [time(8, 0)]
            elif num_schedules == 2:
                reminder_times = [time(8, 0), time(20, 0)]
            elif num_schedules == 3:
                reminder_times = [time(8, 0), time(14, 0), time(20, 0)]
            else:
                reminder_times = [time(8, 0), time(12, 0), time(16, 0), time(20, 0)]
            
            for idx, reminder_time in enumerate(reminder_times):
                if len(schedule_ids) + len(values) >= target_count:
                    break
                
                day_mask = '1111111' if random.random() > 0.2 else '1111100'
                dose_sequence = idx + 1
                
                values.append((prescribed_med_id, reminder_time, day_mask, dose_sequence))
            
            med_idx += 1
            
            # Insert batch
            if len(values) >= batch_size:
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."PrescribedMedicationSchedule"
                        ("PrescribedMedicationId", "ReminderTime", "DayOfWeekMask", "DoseSequenceId")
                        VALUES %s
                        RETURNING "PrescribedMedicationScheduleId"''',
                    values,
                    fetch=True
                )
                batch_ids = [row['PrescribedMedicationScheduleId'] if isinstance(row, dict) else row[0] for row in result]
                schedule_ids.extend(batch_ids)
                self.conn.commit()
                print(f"  ✓ Progress: {len(schedule_ids):,}/{target_count:,} schedules created", end='\r')
                values = []
        
        # Insert remaining
        if values:
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."PrescribedMedicationSchedule"
                    ("PrescribedMedicationId", "ReminderTime", "DayOfWeekMask", "DoseSequenceId")
                    VALUES %s
                    RETURNING "PrescribedMedicationScheduleId"''',
                values,
                fetch=True
            )
            batch_ids = [row['PrescribedMedicationScheduleId'] if isinstance(row, dict) else row[0] for row in result]
            schedule_ids.extend(batch_ids)
            self.conn.commit()
        
        print(f"\n  ✓ Created {len(schedule_ids):,} medication schedule records")
        return schedule_ids
    
    def insert_appointments(self, doctor_ids, patient_ids, target_count=100000):
        """Insert future appointments"""
        print(f"\n📅 Creating {target_count:,} appointments...")
        
        batch_size = 5000
        appointment_ids = []
        
        for i in range(0, target_count, batch_size):
            batch_count = min(batch_size, target_count - i)
            
            values = []
            for j in range(batch_count):
                doctor_id = random.choice(doctor_ids)
                patient_id = random.choice(patient_ids)
                
                # Future appointments (1-180 days ahead)
                days_ahead = random.randint(1, 180)
                appointment_date = datetime.combine(
                    date.today() + timedelta(days=days_ahead),
                    time(hour=random.randint(8, 17), minute=random.choice([0, 15, 30, 45]))
                )
                appt_type = random.choice(['consultation', 'follow-up'])  # Only valid ENUM values
                status = random.choice(['scheduled', 'completed', 'cancelled'])  # Valid values from schema
                
                values.append((doctor_id, patient_id, appointment_date, appt_type, status, False))
            
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."Appointment"
                    ("DoctorId", "PatientId", "AppointmentDate", "AppointmentType", "Status", "IsDeleted")
                    VALUES %s RETURNING "AppointmentId"''',
                values,
                fetch=True
            )
            
            batch_ids = [row['AppointmentId'] if isinstance(row, dict) else row[0] for row in result]
            appointment_ids.extend(batch_ids)
            self.conn.commit()
            print(f"  ✓ Progress: {len(appointment_ids):,}/{target_count:,} appointments created", end='\r')
        
        print(f"\n  ✓ Created {len(appointment_ids):,} appointments")
        return appointment_ids
    
    def insert_patient_reports(self, doctor_ids, patient_ids, prescribed_med_ids, target_count=100000):
        """Insert patient reports"""
        print(f"\n📄 Creating {target_count:,} patient reports...")
        
        batch_size = 5000
        report_ids = []
        
        for i in range(0, target_count, batch_size):
            batch_count = min(batch_size, target_count - i)
            
            values = []
            for j in range(batch_count):
                doctor_id = random.choice(doctor_ids)
                patient_id = random.choice(patient_ids)
                report_type = random.choice(['SideEffect', 'Symptom', 'General'])  # Updated ENUM
                
                # Some reports link to prescribed medications
                prescribed_med_id = random.choice(prescribed_med_ids) if random.random() > 0.5 else None
                description = self.generator.fake.text(max_nb_chars=500)  # Changed from reason
                keywords = ', '.join(self.generator.fake.words(nb=random.randint(3, 6))) if random.random() > 0.5 else None
                voice_directory = f"/voice/reports/{self.generator.fake.uuid4()}.mp3" if random.random() > 0.3 else None
                doctor_note = self.generator.fake.text(max_nb_chars=200) if random.random() > 0.5 else None
                severity = random.choice(['mild', 'moderate', 'severe'])
                review_time = self.generator.fake.date_time_between(start_date='-1m', end_date='now') if random.random() > 0.4 else None
                
                values.append((doctor_id, patient_id, prescribed_med_id, report_type,
                              description, keywords, voice_directory, doctor_note, severity, review_time, False))
            
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."PatientReport"
                    ("DoctorId", "PatientId", "PrescribedMedicationId", "Type", "Description",
                     "Keywords", "VoiceDirectory", "DoctorNote", "Severity", "ReviewTime", "IsDeleted")
                    VALUES %s RETURNING "PatientReportID"''',
                values,
                fetch=True
            )
            
            batch_ids = [row['PatientReportID'] if isinstance(row, dict) else row[0] for row in result]
            report_ids.extend(batch_ids)
            self.conn.commit()
            print(f"  ✓ Progress: {len(report_ids):,}/{target_count:,} reports created", end='\r')
        
        print(f"\n  ✓ Created {len(report_ids):,} patient reports")
        return report_ids
    
    def insert_side_effects(self, prescribed_med_ids, target_count=100000):
        """Insert patient side effects for prescribed medications"""
        print(f"\n⚠️  Creating {target_count:,} side effect records...")
        
        batch_size = 5000
        side_effect_ids = []
        values = []
        
        med_idx = 0
        while len(side_effect_ids) < target_count and med_idx < len(prescribed_med_ids):
            prescribed_med_id = prescribed_med_ids[med_idx]
            
            # 50% of prescribed medications have side effects
            if random.random() > 0.5:
                # 1-2 side effects per medication
                num_effects = random.randint(1, 2)
                side_effects = random.sample(self.generator.SIDE_EFFECTS, min(num_effects, len(self.generator.SIDE_EFFECTS)))
                
                for effect in side_effects:
                    if len(side_effect_ids) + len(values) >= target_count:
                        break
                    
                    onset_date = self.generator.fake.date_between(start_date='-3m', end_date='today')
                    severity = random.choice(['mild', 'moderate', 'severe'])  # Updated ENUM
                    # 60% resolved
                    resolution_date = self.generator.fake.date_between(start_date=onset_date, end_date='today') if random.random() > 0.4 else None
                    
                    values.append((prescribed_med_id, effect, severity, onset_date, resolution_date))
            
            med_idx += 1
            
            # Insert batch
            if len(values) >= batch_size:
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."PatientSideEffect"
                        ("PrescribedMedicationId", "SideEffectName", "Severity", "OnsetDate", "ResolutionDate")
                        VALUES %s
                        ON CONFLICT ("PrescribedMedicationId", "SideEffectName") DO NOTHING
                        RETURNING "PatientSideEffectId"''',
                    values,
                    fetch=True
                )
                batch_ids = [row['PatientSideEffectId'] if isinstance(row, dict) else row[0] for row in result]
                side_effect_ids.extend(batch_ids)
                self.conn.commit()
                print(f"  ✓ Progress: {len(side_effect_ids):,}/{target_count:,} side effects created", end='\r')
                values = []
        
        # Insert remaining
        if values:
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."PatientSideEffect"
                    ("PrescribedMedicationId", "SideEffectName", "Severity", "OnsetDate", "ResolutionDate")
                    VALUES %s
                    ON CONFLICT ("PrescribedMedicationId", "SideEffectName") DO NOTHING
                    RETURNING "PatientSideEffectId"''',
                values,
                fetch=True
            )
            batch_ids = [row['PatientSideEffectId'] if isinstance(row, dict) else row[0] for row in result]
            side_effect_ids.extend(batch_ids)
            self.conn.commit()
        
        print(f"\n  ✓ Created {len(side_effect_ids):,} side effect records")
        return side_effect_ids
    
    def insert_medication_adherence_records(self, schedule_ids, target_count=100000):
        """Insert medication adherence records for medication schedules with violation scenarios"""
        print(f"\n🔔 Creating {target_count:,} medication adherence records...")
        print(f"  📊 Generating records with dose violations for sliding window alerts...")
        
        batch_size = 5000
        adherence_ids = []
        values = []
        
        # Get all schedules with their DosePerTime for violation detection
        schedule_dose_map = {}
        
        schedule_idx = 0
        
        while len(adherence_ids) < target_count and schedule_idx < len(schedule_ids):
            schedule_id = schedule_ids[schedule_idx]
            
            # Get DosePerTime from PrescribedMedication via schedule
            if schedule_id not in schedule_dose_map:
                self.cursor.execute(f'''
                    SELECT pm."DosePerTime"
                    FROM "{self.schema}"."PrescribedMedicationSchedule" pms
                    JOIN "{self.schema}"."PrescribedMedication" pm 
                        ON pms."PrescribedMedicationId" = pm."PrescribedMedicationId"
                    WHERE pms."PrescribedMedicationScheduleId" = %s
                ''', (schedule_id,))
                result = self.cursor.fetchone()
                if result:
                    schedule_dose_map[schedule_id] = float(result['DosePerTime'])
                else:
                    schedule_dose_map[schedule_id] = 1.0  # Default fallback
            
            dose_per_time = schedule_dose_map[schedule_id]
            
            # Each schedule gets 3-7 adherence records (past doses)
            num_records = random.randint(3, 7)
            for _ in range(num_records):
                if len(adherence_ids) + len(values) >= target_count:
                    break
                
                # Status distribution: 60% Taken, 20% Missed, 20% Pending
                rand = random.random()
                if rand < 0.6:
                    current_status = 'Taken'
                elif rand < 0.8:
                    current_status = 'Missed'
                else:
                    current_status = 'Pending'
                
                # Set DoseQuantity based on status and violation scenarios
                if current_status == 'Missed':
                    # Missed = NULL dose quantity
                    dose_quantity = None
                elif current_status == 'Pending':
                    # Pending = NULL dose quantity (not taken yet)
                    dose_quantity = None
                else:  # Taken
                    # Distribution of dose scenarios for violation detection:
                    # 50% correct dose (DoseQuantity = DosePerTime)
                    # 25% overdose (DoseQuantity > DosePerTime) - VIOLATION for alert
                    # 25% underdose (DoseQuantity < DosePerTime) - VIOLATION for alert
                    scenario = random.random()
                    
                    if scenario < 0.5:
                        # Correct dose
                        dose_quantity = round(dose_per_time, 2)
                    elif scenario < 0.75:
                        # Overdose: 10%-50% more than prescribed
                        overdose_multiplier = random.uniform(1.1, 1.5)
                        dose_quantity = round(dose_per_time * overdose_multiplier, 2)
                    else:
                        # Underdose: 30%-70% of prescribed dose
                        underdose_multiplier = random.uniform(0.3, 0.7)
                        dose_quantity = round(dose_per_time * underdose_multiplier, 2)
                
                # Generate timestamps
                scheduled_time = self.generator.fake.date_time_between(start_date='-14d', end_date='now')
                
                if current_status == 'Taken':
                    # Taken: action time within -15 to +60 minutes of scheduled time
                    action_time = scheduled_time + timedelta(minutes=random.randint(-15, 60))
                elif current_status == 'Missed':
                    # Missed: action time is past scheduled time (or NULL)
                    action_time = scheduled_time + timedelta(hours=random.randint(2, 12)) if random.random() > 0.3 else None
                else:  # Pending
                    # Pending: no action time yet
                    action_time = None
                
                values.append((schedule_id, current_status, dose_quantity, scheduled_time, action_time))
            
            schedule_idx += 1
            
            # Insert batch
            if len(values) >= batch_size:
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."MedicationAdherenceRecord"
                        ("PrescribedMedicationScheduleId", "CurrentStatus", "DoseQuantity",
                         "ScheduledTime", "ActionTime")
                        VALUES %s
                        RETURNING "MedicationAdherenceRecordId"''',
                    values,
                    fetch=True
                )
                batch_ids = [row['MedicationAdherenceRecordId'] if isinstance(row, dict) else row[0] for row in result]
                adherence_ids.extend(batch_ids)
                self.conn.commit()
                print(f"  ✓ Progress: {len(adherence_ids):,}/{target_count:,} adherence records created", end='\r')
                values = []
        
        # Insert remaining
        if values:
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."MedicationAdherenceRecord"
                    ("PrescribedMedicationScheduleId", "CurrentStatus", "DoseQuantity",
                     "ScheduledTime", "ActionTime")
                    VALUES %s
                    RETURNING "MedicationAdherenceRecordId"''',
                values,
                fetch=True
            )
            batch_ids = [row['MedicationAdherenceRecordId'] if isinstance(row, dict) else row[0] for row in result]
            adherence_ids.extend(batch_ids)
            self.conn.commit()
        
        print(f"\n  ✓ Created {len(adherence_ids):,} medication adherence records")
        print(f"  ✓ Violation scenarios: ~25% overdose, ~25% underdose, ~20% missed for sliding window alerts")
        return adherence_ids
    
    def insert_appointment_reminders(self, appointment_ids, target_count=50000):
        """Insert appointment reminders"""
        print(f"\n📅 Creating {target_count:,} appointment reminder records...")
        
        batch_size = 5000
        reminder_ids = []
        values = []
        
        appointment_idx = 0
        
        while len(reminder_ids) < target_count and appointment_idx < len(appointment_ids):
            appointment_id = appointment_ids[appointment_idx]
            
            # Get appointment date
            self.cursor.execute(f'''
                SELECT "AppointmentDate" FROM "{self.schema}"."Appointment"
                WHERE "AppointmentId" = %s
            ''', (appointment_id,))
            appt = self.cursor.fetchone()
            if appt:
                appt_date = appt['AppointmentDate']
                # Create reminders 1 day and 1 hour before appointment
                scheduled_times = [
                    appt_date - timedelta(days=1),
                    appt_date - timedelta(hours=1)
                ]
                for scheduled_time in scheduled_times:
                    if len(reminder_ids) + len(values) >= target_count:
                        break
                    values.append((appointment_id, scheduled_time))
            
            appointment_idx += 1
            
            # Insert batch
            if len(values) >= batch_size:
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."AppointmentReminder"
                        ("AppointmentId", "ScheduledTime")
                        VALUES %s
                        RETURNING "AppointmentReminderId"''',
                    values,
                    fetch=True
                )
                batch_ids = [row['AppointmentReminderId'] if isinstance(row, dict) else row[0] for row in result]
                reminder_ids.extend(batch_ids)
                self.conn.commit()
                print(f"  ✓ Progress: {len(reminder_ids):,}/{target_count:,} appointment reminders created", end='\r')
                values = []
        
        # Insert remaining
        if values:
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."AppointmentReminder"
                    ("AppointmentId", "ScheduledTime")
                    VALUES %s
                    RETURNING "AppointmentReminderId"''',
                values,
                fetch=True
            )
            batch_ids = [row['AppointmentReminderId'] if isinstance(row, dict) else row[0] for row in result]
            reminder_ids.extend(batch_ids)
            self.conn.commit()
        
        print(f"\n  ✓ Created {len(reminder_ids):,} appointment reminder records")
        return reminder_ids
    
    def validate_data_integrity(self):
        """Run validation queries to ensure data integrity"""
        print("\n🔍 Validating data integrity...")
        
        checks = [
            ("Orphaned Patients", f'''
                SELECT COUNT(*) as count FROM "{self.schema}"."Patient" p
                LEFT JOIN "{self.schema}"."User" u ON p."UserId" = u."UserId"
                WHERE u."UserId" IS NULL
            '''),
            ("Orphaned Doctors", f'''
                SELECT COUNT(*) as count FROM "{self.schema}"."Doctor" d
                LEFT JOIN "{self.schema}"."User" u ON d."UserId" = u."UserId"
                WHERE u."UserId" IS NULL
            '''),
            ("Duplicate PatientCareTeam", f'''
                SELECT COUNT(*) as count FROM (
                    SELECT "DoctorId", "PatientId", "DoctorLevel", COUNT(*)
                    FROM "{self.schema}"."PatientCareTeam"
                    GROUP BY "DoctorId", "PatientId", "DoctorLevel"
                    HAVING COUNT(*) > 1
                ) AS dups
            '''),
            ("Invalid Prescription Dates", f'''
                SELECT COUNT(*) as count FROM "{self.schema}"."Prescription"
                WHERE "ExpiryDate" <= "PrescribedDate"
            '''),
        ]
        
        all_valid = True
        for check_name, query in checks:
            self.cursor.execute(query)
            result = self.cursor.fetchone()
            count = result['count']
            if count > 0:
                print(f"  ⚠️  {check_name}: {count} issues found")
                all_valid = False
            else:
                print(f"  ✓ {check_name}: Passed")
        
        return all_valid
    
    def seed_100k_per_table(self):
        """
        Main orchestration method - populate all tables with 100K+ records
        Ensures ONE super admin + meaningful, valid data
        """
        print("\n" + "="*80)
        print("🌱 STARTING LARGE-SCALE DATABASE SEEDING (100K+ PER TABLE)")
        print("="*80)
        print("\n⚠️  This will create 1.5M+ records and may take 60-90 minutes...")
        print("⚠️  Ensure you have sufficient disk space (~10GB)")
        
        # Check for existing data - MUST clear to avoid conflicts
        try:
            self.set_search_path()
            self.cursor.execute(f'SELECT COUNT(*) as count FROM "{self.schema}"."User"')
            user_count = self.cursor.fetchone()['count']
            
            self.cursor.execute(f'SELECT COUNT(*) as count FROM "{self.schema}"."Doctor"')
            doctor_count = self.cursor.fetchone()['count']
            
            if user_count > 0 or doctor_count > 0:
                print(f"\n⚠️  WARNING: Database contains {user_count:,} users and {doctor_count:,} doctors!")
                print(f"⚠️  For 100K seeding to work, database MUST be completely empty.")
                print(f"⚠️  Existing data will cause duplicate key conflicts.")
                print(f"\n🗑️  AUTOMATICALLY CLEARING ALL DATA to ensure clean slate...")
                self.clear_all_data()
                print("\n" + "="*80)
                print("🌱 RESUMING DATABASE SEEDING WITH CLEAN DATABASE")
                print("="*80)
        except Exception as e:
            print(f"  ℹ️  Could not check existing data: {e}")
        
        confirm = input("\nContinue with seeding? (yes/no): ").strip().lower()
        if confirm != 'yes':
            print("❌ Operation cancelled")
            return
        
        start_time = datetime.now()
        
        try:
            self.set_search_path()
            
            # Disable auto-creation triggers for bulk insert performance
            self.disable_triggers()
            
            # Phase 1: Foundation (500 realistic institutions)
            # Small hospitals: ~100 doctors, ~200 patients, 1-2 admins
            # Large hospitals: ~300 doctors, ~500 patients, 2-3 admins
            institution_ids = self.insert_institutions(500)
            
            # Phase 2: Super Admin (FIRST and ONLY)
            super_admin_id = self.create_super_admin(None)
            
            # Phase 3: Users with realistic distribution
            # 1,000 hospital admins (avg 2 per institution - realistic!)
            # 100,000 doctors (avg 200 per institution)  
            # 150,000 patients (avg 300 per institution)
            admin_ids = self.insert_users(institution_ids, 'admin', 1000)
            doctor_ids = self.insert_users(institution_ids, 'doctor', 100000)
            patient_ids = self.insert_users(institution_ids, 'patient', 500000)
            
            # Phase 4: Role-specific records
            self.insert_role_specific_records(admin_ids, 'admin')
            self.insert_role_specific_records(doctor_ids, 'doctor')
            self.insert_role_specific_records(patient_ids, 'patient')
            
            # Phase 5: Medications
            medication_ids = self.insert_medications(institution_ids)
            
            # Phase 6: Doctor-Patient Care Team Relationships
            care_team_ids = self.insert_patient_care_teams(doctor_ids, patient_ids, 500000)
            
            # Phase 7: Medical Histories & Symptoms
            medical_history_ids = self.insert_medical_histories(patient_ids, 500000)
            patient_symptom_ids = self.insert_patient_symptoms(patient_ids, 500000)
            
            # Phase 8: Prescriptions Chain
            prescription_ids = self.insert_prescriptions(doctor_ids, patient_ids, 500000)
            prescribed_med_ids = self.insert_prescribed_medications(prescription_ids, medication_ids, 800000)
            schedule_ids = self.insert_medication_schedules(prescribed_med_ids, 1200000)
            
            # Phase 9: Appointments
            appointment_ids = self.insert_appointments(doctor_ids, patient_ids, 400000)
            
            # Phase 10: Reports & Side Effects
            report_ids = self.insert_patient_reports(doctor_ids, patient_ids, prescribed_med_ids, 300000)
            side_effect_ids = self.insert_side_effects(prescribed_med_ids, 200000)
            
            # Phase 11: Medication Adherence Records & Appointment Reminders
            adherence_ids = self.insert_medication_adherence_records(schedule_ids, 500000)
            appointment_reminder_ids = self.insert_appointment_reminders(appointment_ids, 200000)
            
            # Phase 12: Validation
            is_valid = self.validate_data_integrity()
            
            # Re-enable triggers
            self.enable_triggers()
            
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            print("\n" + "="*80)
            print("✅ DATABASE SEEDING COMPLETED SUCCESSFULLY!")
            print("="*80)
            print(f"\n⏱️  Total time: {duration:.2f} seconds ({duration/60:.2f} minutes)")
            print(f"\n📊 Final Record Counts:")
            print(f"  • Clinical Institutions: {len(institution_ids):,} (realistic healthcare facilities)")
            print(f"    → Average per institution:")
            print(f"      • ~{len(doctor_ids)//len(institution_ids)} doctors")
            print(f"      • ~{len(patient_ids)//len(institution_ids)} patients")
            print(f"      • ~{len(admin_ids)//len(institution_ids)} admins")
            print(f"  • Super Admin: 1 (system-wide)")
            print(f"  • Hospital Admins: {len(admin_ids):,}")
            print(f"  • Doctors: {len(doctor_ids):,}")
            print(f"  • Patients: {len(patient_ids):,}")
            print(f"  • Medications: {len(medication_ids):,}")
            print(f"  • Patient Care Teams: {len(care_team_ids):,}")
            print(f"  • Medical Histories: {len(medical_history_ids):,}")
            print(f"  • Patient Symptoms: {len(patient_symptom_ids):,}")
            print(f"  • Prescriptions: {len(prescription_ids):,}")
            print(f"  • Prescribed Medications: {len(prescribed_med_ids):,}")
            print(f"  • Medication Schedules: {len(schedule_ids):,}")
            print(f"  • Appointments: {len(appointment_ids):,}")
            print(f"  • Patient Reports: {len(report_ids):,}")
            print(f"  • Side Effects: {len(side_effect_ids):,}")
            print(f"  • Medication Adherence Records: {len(adherence_ids):,}")
            print(f"  • Appointment Reminders: {len(appointment_reminder_ids):,}")
            
            total_records = (len(institution_ids) + 1 + len(admin_ids) + len(doctor_ids) + 
                           len(patient_ids) + len(medication_ids) + len(care_team_ids) +
                           len(medical_history_ids) + len(patient_symptom_ids) + len(prescription_ids) +
                           len(prescribed_med_ids) + len(schedule_ids) + len(appointment_ids) +
                           len(report_ids) + len(side_effect_ids) + len(adherence_ids) + len(appointment_reminder_ids))
            
            print(f"\n  📈 TOTAL RECORDS CREATED: {total_records:,}")
            print(f"\n✨ Data Validation: {'✓ PASSED' if is_valid else '⚠️ WARNINGS FOUND'}")
            print(f"\n💡 Realistic Distribution:")
            print(f"  • 500 healthcare institutions (hospitals, clinics, medical centers)")
            print(f"  • Each institution averages:")
            print(f"    - 200 doctors (specializations distributed)")
            print(f"    - 1000 patients (5:1 patient-to-doctor ratio)")
            print(f"    - 2 admins (hospital management)")
            print(f"    - Multiple medications in inventory")
            print(f"  • System managed by 1 super admin with global access")
            
            print("\n🔐 Super Admin Credentials:")
            print("  Username: superadmin")
            print("  Email: admin@sigmamed.com")
            print("  Password: password123")
            print("  Level: super")
            print("  Institution: NULL (System-wide access - not tied to any institution)")
            
            return {
                'duration_minutes': duration/60,
                'total_records': total_records,
                'validation_passed': is_valid
            }
            
        except Exception as e:
            self.conn.rollback()
            # Try to re-enable triggers even on error
            try:
                self.enable_triggers()
            except:
                pass
            print(f"\n❌ Error during seeding: {e}")
            import traceback
            traceback.print_exc()
            raise
    
    def clear_all_data(self):
        """Clear all data from the database - NUCLEAR OPTION with CASCADE"""
        print("\n🗑️  Clearing all data from database (CASCADE mode)...")
        
        try:
            self.set_search_path()
            
            # First disable triggers to avoid conflicts during deletion
            try:
                self.cursor.execute(f'''
                    SELECT tgname, tgrelid::regclass 
                    FROM pg_trigger 
                    WHERE tgrelid::regclass::text LIKE '%{self.schema}%'
                    AND tgenabled = 'O'
                ''')
                triggers = self.cursor.fetchall()
                for trigger in triggers:
                    try:
                        trigger_name = trigger['tgname'] if isinstance(trigger, dict) else trigger[0]
                        table_name = str(trigger['tgrelid'] if isinstance(trigger, dict) else trigger[1]).replace(f'"{self.schema}".', '')
                        self.cursor.execute(f'ALTER TABLE "{self.schema}".{table_name} DISABLE TRIGGER {trigger_name};')
                    except:
                        pass
            except:
                pass
            
            # Use TRUNCATE CASCADE for faster, cleaner deletion
            # Clear in reverse dependency order
            tables_to_clear = [
                # Level 7 - Deepest dependencies
                'MedicationAdherenceRecord',
                'AppointmentReminder',
                # Level 6
                'PatientSideEffect',
                'PrescribedMedicationSchedule',
                # Level 5
                'PatientReport',
                'PrescribedMedication',
                'PatientSymptom',
                # Level 4
                'Prescription',
                'Appointment',
                'MedicalHistory',
                'PatientCareTeam',
                # Level 3
                'Admin',
                'Doctor',
                'Patient',
                # Level 2
                'Medication',
                'User',
                # Level 1
                'ClinicalInstitution',
                # Audit logs
                'UserLog', 'PrescriptionLog', 'PrescribedMedicationLog',
                'PrescribedMedicationScheduleLog', 'MedicalHistoryLog',
                'PatientReportLog', 'PatientSideEffectLog', 'MedicationLog',
                'AppointmentLog', 'AuditLog'
            ]
            
            total_deleted = 0
            for table in tables_to_clear:
                try:
                    # Try TRUNCATE first (faster and resets sequences)
                    self.cursor.execute(f'TRUNCATE TABLE "{self.schema}"."{table}" CASCADE;')
                    print(f"  ✓ Truncated {table}")
                    total_deleted += 1
                except Exception as e1:
                    try:
                        # Fall back to DELETE if TRUNCATE fails
                        self.cursor.execute(f'DELETE FROM "{self.schema}"."{table}";')
                        count = self.cursor.rowcount
                        if count > 0:
                            print(f"  ✓ Deleted {count:,} rows from {table}")
                            total_deleted += count
                    except Exception as e2:
                        print(f"  ⚠️  Could not clear {table}: {e2}")
            
            # Re-enable triggers
            try:
                self.cursor.execute(f'''
                    SELECT tgname, tgrelid::regclass 
                    FROM pg_trigger 
                    WHERE tgrelid::regclass::text LIKE '%{self.schema}%'
                    AND tgenabled = 'D'
                ''')
                triggers = self.cursor.fetchall()
                for trigger in triggers:
                    try:
                        trigger_name = trigger['tgname'] if isinstance(trigger, dict) else trigger[0]
                        table_name = str(trigger['tgrelid'] if isinstance(trigger, dict) else trigger[1]).replace(f'"{self.schema}".', '')
                        self.cursor.execute(f'ALTER TABLE "{self.schema}".{table_name} ENABLE TRIGGER {trigger_name};')
                    except:
                        pass
            except:
                pass
            
            self.conn.commit()
            print(f"\n✓ Successfully cleared all data from database")
            
        except Exception as e:
            self.conn.rollback()
            print(f"\n✗ Error clearing data: {e}")
            raise


def main():
    """Main entry point"""
    print("\n" + "="*80)
    print("SIGMAmed 100K+ Per Table Data Generator")
    print("="*80)
    print("\nOptions:")
    print("1. Seed 100K+ records per table (1.5M+ total records)")
    print("2. Clear all data from database")
    print("3. Exit")
    
    choice = input("\nEnter your choice (1-3): ").strip()
    
    with DummyDataInserter100K() as seeder:
        if choice == '1':
            seeder.seed_100k_per_table()
        elif choice == '2':
            confirm = input("\n⚠️  This will DELETE ALL DATA. Continue? (yes/no): ").strip().lower()
            if confirm == 'yes':
                seeder.clear_all_data()
            else:
                print("❌ Operation cancelled")
        elif choice == '3':
            print("👋 Goodbye!")
        else:
            print("❌ Invalid choice")


if __name__ == '__main__':
    main()
