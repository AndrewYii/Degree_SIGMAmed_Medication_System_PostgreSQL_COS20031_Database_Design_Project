import psycopg2
from psycopg2.extras import RealDictCursor, execute_values
import sys
from datetime import datetime
import random
from db_config import DBConfig
from data_generator import SIGMAmedDataGenerator

class DummyDataInserter:
    
    def __init__(self):
        try:
            DBConfig.validate()
            self.conn = psycopg2.connect(**DBConfig.get_connection_params())
            self.conn.autocommit = False
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            self.schema = DBConfig.SCHEMA
            self.generator = SIGMAmedDataGenerator()
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
    
    def insert_institutions(self, count):
        print(f"\n📍 Inserting {count:,} clinical institutions...")
        
        institutions = self.generator.generate_clinical_institution(count)
        
        values = [
            (inst['ClinicalInstitutionName'], inst['Description'], inst['IsDeleted'])
            for inst in institutions
        ]
        
        institution_ids = execute_values(
            self.cursor,
            f'''INSERT INTO "{self.schema}"."ClinicalInstitution" 
                ("ClinicalInstitutionName", "Description", "IsDeleted")
                VALUES %s RETURNING "ClinicalInstitutionID"''',
            values,
            fetch=True
        )
        
        self.conn.commit()
        # execute_values returns list of tuples or RealDictRow objects
        result_ids = [row['ClinicalInstitutionID'] if isinstance(row, dict) else row[0] for row in institution_ids]
        print(f"  ✓ Created {len(result_ids):,} institutions")
        return result_ids
    
    def insert_users(self, institution_ids, role, count):
        print(f"\n👤 Inserting {count:,} {role}(s)...")
        
        batch_size = 10000
        user_ids = []
        
        # Generate and insert in one pass - don't store everything in memory!
        for i in range(0, count, batch_size):
            batch_count = min(batch_size, count - i)
            
            # Generate batch on the fly
            batch_users = []
            for j in range(batch_count):
                institution_id = random.choice(institution_ids)
                user_data = self.generator.generate_user(institution_id, role, 1)[0]
                batch_users.append(user_data)
            
            values = [
                (
                    u['ClinicalInstitutionId'], u['Username'], u['Email'], u['PasswordHash'],
                    u['Role'], u['ICPassportNumber'], u['FirstName'], u['LastName'],
                    u['Phone'], u['DateOfBirth'], u['FcmKey'], u['ProfilePictureUrl'],
                    u['IsActive'], u['IsDeleted']
                )
                for u in batch_users
            ]
            
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."User" 
                    ("ClinicalInstitutionId", "Username", "Email", "PasswordHash", "Role",
                     "ICPassportNumber", "FirstName", "LastName", "Phone", "DateOfBirth",
                     "FcmKey", "ProfilePictureUrl", "IsActive", "IsDeleted")
                    VALUES %s RETURNING "UserId"''',
                values,
                fetch=True
            )
            
            batch_ids = [row['UserId'] if isinstance(row, dict) else row[0] for row in result]
            user_ids.extend(batch_ids)
            self.conn.commit()
            print(f"  ✓ Progress: {len(user_ids):,}/{count:,} {role}s created", end='\r')
        
        print(f"\n  ✓ Created {len(user_ids):,} {role}s")
        return user_ids
    
    def insert_medications(self, institution_ids, meds_per_institution=20):
        """Insert medications"""
        total_count = len(institution_ids) * meds_per_institution
        print(f"\n💊 Inserting {total_count:,} medications...")
        
        all_medications = []
        for institution_id in institution_ids:
            meds = self.generator.generate_medication(institution_id, meds_per_institution)
            all_medications.extend(meds)
        
        values = [
            (m['ClinicalInstitutionID'], m['MedicationName'], m['TotalAmount'], m['IsDeleted'])
            for m in all_medications
        ]
        
        medication_ids = execute_values(
            self.cursor,
            f'''INSERT INTO "{self.schema}"."Medication"
                ("ClinicalInstitutionID", "MedicationName", "TotalAmount", "IsDeleted")
                VALUES %s RETURNING "MedicationID"''',
            values,
            fetch=True
        )
        
        self.conn.commit()
        result_ids = [row['MedicationID'] if isinstance(row, dict) else row[0] for row in medication_ids]
        print(f"  ✓ Created {len(result_ids):,} medications")
        return result_ids
    
    def insert_assigned_doctors(self, doctor_ids, patient_ids):
        print(f"\n🤝 Assigning doctors to patients...")
        
        assignments = []
        # Each patient gets 1 primary doctor and possibly 1 secondary
        for patient_id in patient_ids:
            # Primary doctor
            primary_doctor = random.choice(doctor_ids)
            assignments.append(
                (primary_doctor, patient_id, 'primary', False)
            )
            
            # 30% chance of secondary doctor
            if random.random() < 0.3:
                secondary_doctor = random.choice([d for d in doctor_ids if d != primary_doctor])
                assignments.append(
                    (secondary_doctor, patient_id, 'secondary', False)
                )
        
        # Insert in batches to avoid unique constraint issues
        batch_size = 5000
        assigned_ids = []
        
        for i in range(0, len(assignments), batch_size):
            batch = assignments[i:i+batch_size]
            
            try:
                result = execute_values(
                    self.cursor,
                    f'''INSERT INTO "{self.schema}"."AssignedDoctor"
                        ("DoctorId", "PatientId", "DoctorLevel", "IsDeleted")
                        VALUES %s 
                        ON CONFLICT ("DoctorId", "PatientId", "DoctorLevel") DO NOTHING
                        RETURNING "AssignedDoctorId"''',
                    batch,
                    fetch=True
                )
                batch_ids = [row['AssignedDoctorId'] if isinstance(row, dict) else row[0] for row in result]
                assigned_ids.extend(batch_ids)
                self.conn.commit()
                print(f"  ✓ Progress: {len(assigned_ids):,}/{len(assignments):,} assignments created", end='\r')
            except Exception as e:
                self.conn.rollback()
                print(f"\n  ⚠️  Batch failed: {e}")
        
        print(f"\n  ✓ Created {len(assigned_ids):,} doctor-patient assignments")
        return assigned_ids
    
    def insert_prescriptions(self, doctor_ids, patient_ids, count):
        """Insert prescriptions with pre-calculated numbers to avoid trigger conflicts"""
        print(f"\n📝 Inserting {count:,} prescriptions (bypassing trigger)...")
        
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
        
        print(f"  ✓ Starting from: RX-{year}{month}-{start_num:05d}")
        
        batch_size = 5000
        prescription_ids = []
        
        # Generate and insert with pre-calculated prescription numbers
        for i in range(0, count, batch_size):
            batch_count = min(batch_size, count - i)
            
            values = []
            for j in range(batch_count):
                doctor_id = random.choice(doctor_ids)
                patient_id = random.choice(patient_ids)
                p = self.generator.generate_prescription(doctor_id, patient_id)
                
                # Pre-calculate prescription number (bypass trigger!)
                prescription_num = f"RX-{year}{month}-{(start_num + i + j):05d}"
                values.append((p['DoctorId'], p['PatientId'], prescription_num, 
                              p['Status'], p['PrescribedDate'], p['IsDeleted']))
            
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."Prescription"
                    ("DoctorId", "PatientId", "PrescriptionNumber", "Status", "PrescribedDate", "IsDeleted")
                    VALUES %s RETURNING "PrescriptionId"''',
                values,
                fetch=True
            )
            
            batch_ids = [row['PrescriptionId'] if isinstance(row, dict) else row[0] for row in result]
            prescription_ids.extend(batch_ids)
            self.conn.commit()
            
            if (i + batch_count) % 5000 == 0 or (i + batch_count) == count:
                print(f"  ✓ Progress: {len(prescription_ids):,}/{count:,} prescriptions created", end='\r')
        
        print(f"\n  ✓ Created {len(prescription_ids):,} prescriptions")
        return prescription_ids
    
    def insert_prescribed_medications(self, prescription_ids, medication_ids, avg_per_prescription=2):
        """Insert prescribed medications"""
        print(f"\n💊 Inserting prescribed medications...")
        
        batch_size = 10000  # Increased from 5000
        prescribed_med_ids = []
        
        # Process prescriptions in chunks to avoid memory issues
        chunk_size = 10000
        for chunk_start in range(0, len(prescription_ids), chunk_size):
            chunk_end = min(chunk_start + chunk_size, len(prescription_ids))
            prescription_chunk = prescription_ids[chunk_start:chunk_end]
            
            # Generate prescribed meds for this chunk
            values = []
            for prescription_id in prescription_chunk:
                num_meds = random.randint(1, 3)
                selected_meds = random.sample(medication_ids, min(num_meds, len(medication_ids)))
                
                for med_id in selected_meds:
                    pm = self.generator.generate_prescribed_medication(prescription_id, med_id)
                    values.append((pm['PrescriptionId'], pm['MedicationId'], pm['StartDate'], 
                                  pm['EndDate'], pm['DosageInstruction'], pm['IsDeleted']))
                
                # Insert when batch is full
                if len(values) >= batch_size:
                    try:
                        result = execute_values(
                            self.cursor,
                            f'''INSERT INTO "{self.schema}"."PrescribedMedication"
                                ("PrescriptionId", "MedicationId", "StartDate", "EndDate", 
                                 "DosageInstruction", "IsDeleted")
                                VALUES %s 
                                ON CONFLICT ("PrescriptionId", "MedicationId") DO NOTHING
                                RETURNING "PrescribedMedicationId"''',
                            values,
                            fetch=True
                        )
                        batch_ids = [row['PrescribedMedicationId'] if isinstance(row, dict) else row[0] for row in result]
                        prescribed_med_ids.extend(batch_ids)
                        self.conn.commit()
                        print(f"  ✓ Progress: {len(prescribed_med_ids):,} prescribed medications created", end='\r')
                        values = []  # Clear for next batch
                    except Exception as e:
                        self.conn.rollback()
                        print(f"\n  ⚠️  Batch failed: {e}")
                        values = []
            
            # Insert remaining values from this chunk
            if values:
                try:
                    result = execute_values(
                        self.cursor,
                        f'''INSERT INTO "{self.schema}"."PrescribedMedication"
                            ("PrescriptionId", "MedicationId", "StartDate", "EndDate", 
                             "DosageInstruction", "IsDeleted")
                            VALUES %s 
                            ON CONFLICT ("PrescriptionId", "MedicationId") DO NOTHING
                            RETURNING "PrescribedMedicationId"''',
                        values,
                        fetch=True
                    )
                    batch_ids = [row['PrescribedMedicationId'] if isinstance(row, dict) else row[0] for row in result]
                    prescribed_med_ids.extend(batch_ids)
                    self.conn.commit()
                    print(f"  ✓ Progress: {len(prescribed_med_ids):,} prescribed medications created", end='\r')
                except Exception as e:
                    self.conn.rollback()
                    print(f"\n  ⚠️  Final batch failed: {e}")
        
        print(f"\n  ✓ Created {len(prescribed_med_ids):,} prescribed medications")
        return prescribed_med_ids
    
    def insert_appointments(self, doctor_ids, patient_ids, count):
        """Insert appointments"""
        print(f"\n📅 Inserting {count:,} appointments...")
        
        batch_size = 10000  # Increased from 5000
        appointment_ids = []
        
        # Generate and insert on the fly
        for i in range(0, count, batch_size):
            batch_count = min(batch_size, count - i)
            
            # Generate batch
            values = []
            for j in range(batch_count):
                doctor_id = random.choice(doctor_ids)
                patient_id = random.choice(patient_ids)
                a = self.generator.generate_appointment(doctor_id, patient_id)
                values.append((a['DoctorId'], a['PatientId'], a['AppointmentDate'], a['AppointmentTime'],
                              a['DurationMinutes'], a['AppointmentType'], a['Status'], a['Notes'],
                              a['IsEmergency'], a['IsDeleted']))
            
            result = execute_values(
                self.cursor,
                f'''INSERT INTO "{self.schema}"."Appointment"
                    ("DoctorId", "PatientId", "AppointmentDate", "AppointmentTime", "DurationMinutes",
                     "AppointmentType", "Status", "Notes", "IsEmergency", "IsDeleted")
                    VALUES %s RETURNING "AppointmentId"''',
                values,
                fetch=True
            )
            
            batch_ids = [row['AppointmentId'] if isinstance(row, dict) else row[0] for row in result]
            appointment_ids.extend(batch_ids)
            self.conn.commit()
            print(f"  ✓ Progress: {len(appointment_ids):,}/{count:,} appointments created", end='\r')
        
        print(f"\n  ✓ Created {len(appointment_ids):,} appointments")
        return appointment_ids
    
    def seed_100k_scenario(self):
        """
        Seed 100k records scenario
        Creates a realistic large-scale medical system with:
        - 100 institutions
        - 100k patients
        - 10k doctors
        - 1k admins
        - 100k prescriptions
        - 200k prescribed medications
        - 50k appointments
        """
        print("\n" + "="*80)
        print("🌱 STARTING LARGE-SCALE DATABASE SEEDING (100K RECORDS)")
        print("="*80)
        print("\n⚠️  This will take several minutes. Please be patient...")
        
        start_time = datetime.now()
        
        try:
            self.set_search_path()
            
            # 1. Create 100 Clinical Institutions
            institution_ids = self.insert_institutions(100)
            
            # 2. Create 1,000 Admin Users
            admin_ids = self.insert_users(institution_ids, 'admin', 1000)
            
            # 3. Create 10,000 Doctor Users
            doctor_ids = self.insert_users(institution_ids, 'doctor', 10000)
            
            # 4. Create 100,000 Patient Users
            patient_ids = self.insert_users(institution_ids, 'patient', 100000)
            
            # 5. Create Medications (20 per institution = 2000 total)
            medication_ids = self.insert_medications(institution_ids, 20)
            
            # 6. Assign Doctors to Patients
            assigned_ids = self.insert_assigned_doctors(doctor_ids, patient_ids)
            
            # 7. Create 100,000 Prescriptions
            prescription_ids = self.insert_prescriptions(doctor_ids, patient_ids, 100000)
            
            # 8. Create Prescribed Medications (avg 2 per prescription)
            prescribed_med_ids = self.insert_prescribed_medications(
                prescription_ids, medication_ids, avg_per_prescription=2
            )
            
            # 9. Create 50,000 Appointments
            appointment_ids = self.insert_appointments(doctor_ids, patient_ids, 50000)
            
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            print("\n" + "="*80)
            print("✅ DATABASE SEEDING COMPLETED SUCCESSFULLY!")
            print("="*80)
            print(f"\n⏱️  Total time: {duration:.2f} seconds ({duration/60:.2f} minutes)")
            print(f"\n📊 Final Summary:")
            print(f"  • Institutions: {len(institution_ids):,}")
            print(f"  • Admins: {len(admin_ids):,}")
            print(f"  • Doctors: {len(doctor_ids):,}")
            print(f"  • Patients: {len(patient_ids):,}")
            print(f"  • Medications: {len(medication_ids):,}")
            print(f"  • Doctor-Patient Assignments: {len(assigned_ids):,}")
            print(f"  • Prescriptions: {len(prescription_ids):,}")
            print(f"  • Prescribed Medications: {len(prescribed_med_ids):,}")
            print(f"  • Appointments: {len(appointment_ids):,}")
            print(f"\n  📈 Total Records: {len(institution_ids) + len(admin_ids) + len(doctor_ids) + len(patient_ids) + len(medication_ids) + len(assigned_ids) + len(prescription_ids) + len(prescribed_med_ids) + len(appointment_ids):,}")
            
            return {
                'institution_ids': institution_ids,
                'admin_ids': admin_ids,
                'doctor_ids': doctor_ids,
                'patient_ids': patient_ids,
                'medication_ids': medication_ids,
                'prescription_ids': prescription_ids,
                'prescribed_med_ids': prescribed_med_ids,
                'appointment_ids': appointment_ids,
                'duration_seconds': duration
            }
            
        except Exception as e:
            self.conn.rollback()
            print(f"\n❌ Error during seeding: {e}")
            raise
    
    def clear_all_data(self):
        """Clear all data from the database"""
        print("\n🗑️  Clearing all data from database...")
        
        try:
            self.set_search_path()
            
            tables_to_clear = [
                'UserLog', 'AssignedDoctorLog', 'MedicalHistoryLog', 'MedicationLog',
                'PrescriptionLog', 'PrescribedMedicationLog', 'PrescribedMedicationScheduleLog',
                'PatientSideEffectLog', 'PatientReportLog', 'AppointmentLog',
                'Reminder', 'PrescribedMedicationSchedule', 'PatientSideEffect',
                'PrescribedMedication', 'Prescription', 'PatientSymptom',
                'MedicalHistory', 'Appointment', 'PatientReport', 'AssignedDoctor',
                'Medication', 'Admin', 'Doctor', 'Patient', 'User', 'ClinicalInstitution'
            ]
            
            deleted_counts = {}
            for table in tables_to_clear:
                self.cursor.execute(f'DELETE FROM "{self.schema}"."{table}";')
                count = self.cursor.rowcount
                deleted_counts[table] = count
                if count > 0:
                    print(f"  ✓ Deleted {count:,} rows from {table}")
            
            self.conn.commit()
            total_deleted = sum(deleted_counts.values())
            print(f"\n✓ Successfully cleared {total_deleted:,} total rows from {len(tables_to_clear)} tables")
            
        except Exception as e:
            self.conn.rollback()
            print(f"\n✗ Error clearing data: {e}")
            raise


def main():
    """Main entry point for the dummy data inserter"""
    print("\n" + "="*80)
    print("SIGMAmed Dummy Data Inserter (High Performance)")
    print("="*80)
    print("\nOptions:")
    print("1. Seed 100K scenario (100 institutions, 100k patients, 10k doctors, etc.)")
    print("2. Clear all data from database")
    print("3. Exit")
    
    choice = input("\nEnter your choice (1-3): ").strip()
    
    with DummyDataInserter() as seeder:
        if choice == '1':
            confirm = input("\n⚠️  This will create 100K+ records. Continue? (yes/no): ").strip().lower()
            if confirm == 'yes':
                seeder.seed_100k_scenario()
            else:
                print("❌ Operation cancelled")
        elif choice == '2':
            confirm = input("\n⚠️  Are you sure you want to delete ALL data? (yes/no): ").strip().lower()
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
