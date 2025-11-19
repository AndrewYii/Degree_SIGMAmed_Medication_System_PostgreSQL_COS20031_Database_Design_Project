import random
from datetime import datetime, timedelta, time, date
from faker import Faker
import json

fake = Faker()
Faker.seed(42)
random.seed(42)

class SIGMAmedDataGenerator:    
    # Medical data constants - Expanded for realistic 100K+ scenarios
    SPECIALIZATIONS = [
        'Cardiology', 'Dermatology', 'Endocrinology', 'Gastroenterology',
        'Hematology', 'Neurology', 'Oncology', 'Orthopedics',
        'Pediatrics', 'Psychiatry', 'Radiology', 'General Practice',
        'Internal Medicine', 'Family Medicine', 'Emergency Medicine',
        'Anesthesiology', 'Pathology', 'Surgery', 'Ophthalmology',
        'Obstetrics and Gynecology', 'Urology', 'Nephrology', 'Pulmonology',
        'Rheumatology', 'Allergy and Immunology', 'Infectious Disease',
        'Geriatrics', 'Sports Medicine', 'Physical Medicine', 'Pain Management'
    ]
    
    BLOOD_TYPES = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
    
    HOSPITAL_TYPES = [
        'General Hospital', 'Medical Center', 'Health Clinic', 'Community Hospital',
        'Regional Medical Center', 'University Hospital', 'Children\'s Hospital',
        'Cancer Center', 'Heart Institute', 'Orthopedic Center', 'Rehabilitation Center',
        'Surgical Hospital', 'Women\'s Hospital', 'Psychiatric Hospital', 'Specialty Clinic'
    ]
    
    DOSAGE_FORMS = ['tablet', 'capsule', 'syrup', 'injection']  # Must match dosage_form_enum in DB
    
    # 200+ Common Medications
    MEDICATIONS = [
        # Cardiovascular
        'Lisinopril', 'Amlodipine', 'Metoprolol', 'Losartan', 'Atorvastatin',
        'Simvastatin', 'Carvedilol', 'Furosemide', 'Warfarin', 'Clopidogrel',
        'Digoxin', 'Diltiazem', 'Verapamil', 'Enalapril', 'Ramipril',
        # Diabetes
        'Metformin', 'Insulin Glargine', 'Insulin Lispro', 'Glipizide', 'Glyburide',
        'Sitagliptin', 'Pioglitazone', 'Empagliflozin', 'Dulaglutide',
        # Antibiotics
        'Amoxicillin', 'Azithromycin', 'Ciprofloxacin', 'Doxycycline', 'Cephalexin',
        'Levofloxacin', 'Clindamycin', 'Trimethoprim-Sulfamethoxazole', 'Penicillin',
        'Ampicillin', 'Ceftriaxone', 'Meropenem', 'Vancomycin', 'Clarithromycin',
        # Pain & Inflammation
        'Ibuprofen', 'Acetaminophen', 'Aspirin', 'Naproxen', 'Celecoxib',
        'Tramadol', 'Morphine', 'Oxycodone', 'Hydrocodone', 'Codeine',
        'Diclofenac', 'Meloxicam', 'Indomethacin', 'Ketorolac',
        # Gastrointestinal
        'Omeprazole', 'Pantoprazole', 'Esomeprazole', 'Ranitidine', 'Famotidine',
        'Lansoprazole', 'Ondansetron', 'Metoclopramide', 'Loperamide', 'Bisacodyl',
        # Respiratory
        'Albuterol', 'Fluticasone', 'Montelukast', 'Budesonide', 'Ipratropium',
        'Salmeterol', 'Tiotropium', 'Theophylline', 'Cetirizine', 'Loratadine',
        'Fexofenadine', 'Diphenhydramine', 'Pseudoephedrine', 'Guaifenesin',
        # Mental Health
        'Sertraline', 'Fluoxetine', 'Escitalopram', 'Citalopram', 'Paroxetine',
        'Venlafaxine', 'Duloxetine', 'Bupropion', 'Mirtazapine', 'Trazodone',
        'Amitriptyline', 'Nortriptyline', 'Alprazolam', 'Lorazepam', 'Clonazepam',
        'Diazepam', 'Zolpidem', 'Aripiprazole', 'Quetiapine', 'Risperidone',
        'Olanzapine', 'Lithium', 'Valproate', 'Lamotrigine', 'Carbamazepine',
        # Endocrine
        'Levothyroxine', 'Methimazole', 'Prednisone', 'Prednisolone', 'Hydrocortisone',
        'Dexamethasone', 'Testosterone', 'Estradiol', 'Progesterone', 'Levonorgestrel',
        # Neurological
        'Gabapentin', 'Pregabalin', 'Levetiracetam', 'Phenytoin', 'Topiramate',
        'Memantine', 'Donepezil', 'Rivastigmine', 'Baclofen', 'Cyclobenzaprine',
        'Tizanidine', 'Sumatriptan', 'Rizatriptan',
        # Urological
        'Tamsulosin', 'Finasteride', 'Dutasteride', 'Oxybutynin', 'Tolterodine',
        'Sildenafil', 'Tadalafil',
        # Hematological
        'Apixaban', 'Rivaroxaban', 'Dabigatran', 'Enoxaparin', 'Heparin',
        'Ferrous Sulfate', 'Folic Acid', 'Vitamin B12', 'Epoetin Alfa',
        # Dermatological
        'Hydrocortisone Cream', 'Triamcinolone', 'Betamethasone', 'Clotrimazole',
        'Ketoconazole', 'Mupirocin', 'Tretinoin', 'Benzoyl Peroxide', 'Tacrolimus',
        # Ophthalmological
        'Latanoprost', 'Timolol', 'Brimonidine', 'Dorzolamide', 'Prednisolone Eye Drops',
        # Others
        'Vitamin D', 'Calcium Carbonate', 'Multivitamin', 'Potassium Chloride',
        'Sodium Chloride', 'Lactobacillus', 'Magnesium', 'Zinc', 'Omega-3'
    ]
    
    # 100+ Diseases
    DISEASES = [
        # Cardiovascular
        'Hypertension', 'Coronary Artery Disease', 'Heart Failure', 'Atrial Fibrillation',
        'Myocardial Infarction', 'Angina Pectoris', 'Cardiomyopathy', 'Peripheral Artery Disease',
        'Deep Vein Thrombosis', 'Pulmonary Embolism', 'Hyperlipidemia', 'Atherosclerosis',
        # Endocrine/Metabolic
        'Type 1 Diabetes', 'Type 2 Diabetes', 'Hypothyroidism', 'Hyperthyroidism',
        'Metabolic Syndrome', 'Obesity', 'Osteoporosis', 'Gout', 'Hypercholesterolemia',
        'Cushing Syndrome', 'Addison Disease', 'Polycystic Ovary Syndrome',
        # Respiratory
        'Asthma', 'COPD', 'Pneumonia', 'Bronchitis', 'Tuberculosis', 'Pulmonary Fibrosis',
        'Sleep Apnea', 'Allergic Rhinitis', 'Sinusitis', 'Emphysema',
        # Gastrointestinal
        'GERD', 'Peptic Ulcer Disease', 'Inflammatory Bowel Disease', 'Crohn Disease',
        'Ulcerative Colitis', 'Irritable Bowel Syndrome', 'Gastritis', 'Diverticulitis',
        'Cirrhosis', 'Hepatitis B', 'Hepatitis C', 'Pancreatitis', 'Celiac Disease',
        # Neurological
        'Migraine', 'Epilepsy', 'Parkinson Disease', 'Alzheimer Disease', 'Multiple Sclerosis',
        'Stroke', 'Transient Ischemic Attack', 'Peripheral Neuropathy', 'Restless Leg Syndrome',
        'Essential Tremor', 'Dementia', 'Meningitis', 'Encephalitis',
        # Psychiatric
        'Depression', 'Anxiety Disorder', 'Bipolar Disorder', 'Schizophrenia',
        'PTSD', 'OCD', 'Panic Disorder', 'Social Anxiety Disorder', 'ADHD',
        'Insomnia', 'Generalized Anxiety Disorder',
        # Musculoskeletal
        'Osteoarthritis', 'Rheumatoid Arthritis', 'Fibromyalgia', 'Lupus', 'Ankylosing Spondylitis',
        'Psoriatic Arthritis', 'Polymyalgia Rheumatica', 'Tendinitis', 'Bursitis',
        'Carpal Tunnel Syndrome', 'Herniated Disc', 'Scoliosis',
        # Renal/Urological
        'Chronic Kidney Disease', 'Acute Kidney Injury', 'Nephrotic Syndrome', 'UTI',
        'Benign Prostatic Hyperplasia', 'Kidney Stones', 'Bladder Cancer', 'Prostate Cancer',
        'Urinary Incontinence', 'Interstitial Cystitis',
        # Hematological
        'Anemia', 'Iron Deficiency Anemia', 'Vitamin B12 Deficiency', 'Thrombocytopenia',
        'Leukemia', 'Lymphoma', 'Sickle Cell Disease', 'Hemophilia', 'Polycythemia Vera',
        # Dermatological
        'Eczema', 'Psoriasis', 'Acne Vulgaris', 'Rosacea', 'Dermatitis', 'Vitiligo',
        'Melanoma', 'Basal Cell Carcinoma', 'Fungal Infection', 'Herpes Zoster',
        # Infectious
        'Influenza', 'COVID-19', 'HIV/AIDS', 'Malaria', 'Dengue Fever', 'Sepsis',
        # Oncological
        'Lung Cancer', 'Breast Cancer', 'Colorectal Cancer', 'Pancreatic Cancer',
        'Ovarian Cancer', 'Thyroid Cancer',
        # Other
        'Glaucoma', 'Cataracts', 'Macular Degeneration', 'Hearing Loss', 'Tinnitus'
    ]
    
    # 100+ Symptoms
    SYMPTOMS = [
        # General
        'Fatigue', 'Fever', 'Chills', 'Night Sweats', 'Weight Loss', 'Weight Gain',
        'Malaise', 'Weakness', 'Loss of Appetite', 'Excessive Thirst', 'Frequent Urination',
        # Pain
        'Headache', 'Migraine', 'Chest Pain', 'Abdominal Pain', 'Back Pain', 'Joint Pain',
        'Muscle Pain', 'Neck Pain', 'Pelvic Pain', 'Bone Pain', 'Burning Pain',
        # Cardiovascular
        'Palpitations', 'Rapid Heartbeat', 'Irregular Heartbeat', 'Leg Swelling',
        'Ankle Swelling', 'Cyanosis', 'Cold Extremities',
        # Respiratory
        'Shortness of Breath', 'Cough', 'Wheezing', 'Chest Tightness', 'Hemoptysis',
        'Nasal Congestion', 'Runny Nose', 'Sore Throat', 'Hoarseness',
        # Gastrointestinal
        'Nausea', 'Vomiting', 'Diarrhea', 'Constipation', 'Bloating', 'Gas',
        'Heartburn', 'Indigestion', 'Difficulty Swallowing', 'Blood in Stool',
        'Black Tarry Stools', 'Loss of Bowel Control', 'Abdominal Cramping',
        # Neurological
        'Dizziness', 'Vertigo', 'Confusion', 'Memory Loss', 'Difficulty Concentrating',
        'Tremor', 'Seizures', 'Numbness', 'Tingling', 'Vision Changes', 'Blurred Vision',
        'Double Vision', 'Hearing Loss', 'Tinnitus', 'Loss of Balance', 'Coordination Problems',
        # Psychiatric
        'Anxiety', 'Depression', 'Mood Swings', 'Irritability', 'Restlessness',
        'Insomnia', 'Excessive Sleepiness', 'Hallucinations', 'Panic Attacks',
        # Musculoskeletal
        'Stiffness', 'Swelling', 'Redness', 'Limited Range of Motion', 'Muscle Spasms',
        'Muscle Weakness', 'Difficulty Walking', 'Limping',
        # Dermatological
        'Rash', 'Itching', 'Dry Skin', 'Hives', 'Skin Discoloration', 'Bruising',
        'Hair Loss', 'Nail Changes',
        # Urological
        'Painful Urination', 'Blood in Urine', 'Urinary Urgency', 'Urinary Frequency',
        'Difficulty Starting Urination', 'Weak Urine Stream', 'Incontinence',
        # Other
        'Hot Flashes', 'Excessive Sweating', 'Sensitivity to Light', 'Sensitivity to Sound',
        'Mouth Sores', 'Dry Mouth', 'Bad Taste', 'Swollen Lymph Nodes'
    ]
    
    # 50+ Side Effects
    SIDE_EFFECTS = [
        'Nausea', 'Vomiting', 'Diarrhea', 'Constipation', 'Abdominal Pain',
        'Dizziness', 'Drowsiness', 'Fatigue', 'Headache', 'Insomnia',
        'Dry Mouth', 'Increased Thirst', 'Loss of Appetite', 'Weight Gain', 'Weight Loss',
        'Rash', 'Itching', 'Hives', 'Swelling', 'Redness',
        'Blurred Vision', 'Eye Irritation', 'Sensitivity to Light',
        'Tremor', 'Muscle Pain', 'Joint Pain', 'Weakness', 'Numbness',
        'Anxiety', 'Nervousness', 'Restlessness', 'Mood Changes', 'Depression',
        'Palpitations', 'Increased Heart Rate', 'Low Blood Pressure', 'High Blood Pressure',
        'Shortness of Breath', 'Cough', 'Nasal Congestion',
        'Upset Stomach', 'Heartburn', 'Gas', 'Bloating',
        'Urinary Frequency', 'Urinary Retention', 'Dark Urine',
        'Sweating', 'Flushing', 'Chills', 'Hot Flashes',
        'Hair Loss', 'Skin Discoloration', 'Bruising', 'Bleeding'
    ]
    
    ALLERGIES = [
        'Penicillin', 'Sulfa Drugs', 'Aspirin', 'Ibuprofen', 'Codeine', 'Morphine',
        'NSAIDs', 'Latex', 'Cephalosporins', 'Tetracycline', 'Vancomycin',
        'Contrast Dye', 'Local Anesthetics', 'Eggs', 'Shellfish'
    ]
    
    WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    
    def __init__(self):
        self.fake = fake
    
    def generate_clinical_institution(self, count=1):
        """Generate unique clinical institutions with diverse, realistic names"""
        institutions = []
        used_names = set()
        
        for i in range(count):
            # Generate unique names to avoid duplicates
            attempts = 0
            while attempts < 10:
                city = fake.city()
                hospital_type = random.choice(self.HOSPITAL_TYPES)
                
                # Add variety with different naming patterns
                naming_pattern = random.choice([
                    f"{city} {hospital_type}",
                    f"{fake.last_name()} {hospital_type}",
                    f"St. {fake.first_name()}'s {hospital_type}",
                    f"{city} {fake.last_name()} {hospital_type}",
                    f"Mount {fake.last_name()} {hospital_type}"
                ])
                
                if naming_pattern not in used_names:
                    used_names.add(naming_pattern)
                    institutions.append({
                        'ClinicalInstitutionName': naming_pattern[:100],  # Respect 100 char limit
                        'IsDeleted': False
                    })
                    break
                attempts += 1
            
            # Fallback if all patterns taken
            if attempts == 10:
                fallback_name = f"{city} Medical Facility {i+1:06d}"
                institutions.append({
                    'ClinicalInstitutionName': fallback_name,
                    'IsDeleted': False
                })
        
        return institutions
    
    def generate_user(self, institution_id, role='patient', count=1):
        users = []
        for i in range(count):
            first_name = fake.first_name()
            last_name = fake.last_name()
            # Add timestamp and larger random number for uniqueness in bulk operations
            username = f"{first_name.lower()}.{last_name.lower()}{random.randint(1, 999999)}"
            
            users.append({
                'ClinicalInstitutionId': institution_id,
                'Username': username,
                'Email': f"{username}@{fake.domain_name()}",
                'PasswordHash': '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYILSBfz.3O',  # 'password123'
                'Role': role,
                'ICPassportNumber': fake.bothify(text='??########', letters='ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                'FirstName': first_name,
                'LastName': last_name,
                'Phone': fake.phone_number()[:20],
                'DateOfBirth': fake.date_of_birth(minimum_age=18, maximum_age=90),
                'FcmKey': None,
                'ProfilePictureUrl': None,
                'IsActive': True,
                'IsDeleted': False
            })
        return users
    
    def generate_doctor(self, user_id):
        # Ensure good distribution across specializations
        # Weight common specializations higher for realism
        specialization_weights = {
            'General Practice': 15,
            'Internal Medicine': 12,
            'Family Medicine': 12,
            'Pediatrics': 10,
            'Surgery': 8,
            'Cardiology': 6,
            'Orthopedics': 5,
            'Emergency Medicine': 5,
            'Anesthesiology': 4,
            'Obstetrics and Gynecology': 4,
            'Psychiatry': 3,
            'Dermatology': 3,
            'Radiology': 2,
            'Neurology': 2,
            'Oncology': 2,
            'Endocrinology': 1,
            'Gastroenterology': 1,
            'Hematology': 1,
            'Nephrology': 1,
            'Pulmonology': 1,
            'Rheumatology': 1,
            'Urology': 1,
            'Ophthalmology': 1,
            'Allergy and Immunology': 1,
            'Infectious Disease': 1,
            'Geriatrics': 1,
            'Sports Medicine': 1,
            'Physical Medicine': 1,
            'Pain Management': 1,
            'Pathology': 1
        }
        
        # Use weighted random choice
        specializations = list(specialization_weights.keys())
        weights = list(specialization_weights.values())
        specialization = random.choices(specializations, weights=weights, k=1)[0]
        
        # Generate realistic years of experience
        # Junior doctors: 1-5 years (30%)
        # Mid-level: 6-15 years (40%)
        # Senior: 16-35 years (30%)
        rand = random.random()
        if rand < 0.3:
            years = random.randint(1, 5)
        elif rand < 0.7:
            years = random.randint(6, 15)
        else:
            years = random.randint(16, 35)
        
        return {
            'UserId': user_id,
            'MedicalLicenseNumber': f"MD-{fake.bothify(text='####-####', letters='0123456789')}",
            'Specialization': specialization,
            'YearOfExperience': years
        }
    
    def generate_patient(self, user_id):
        # Generate random medication allergies (0-3 allergies)
        num_allergies = random.randint(0, 3)
        allergies = random.sample(self.ALLERGIES, min(num_allergies, len(self.ALLERGIES)))
        
        return {
            'UserId': user_id,
            'PatientNumber': '',  # Will be auto-generated by trigger
            'BloodType': random.choice(self.BLOOD_TYPES) if random.random() > 0.1 else None,
            'HeightCm': round(random.uniform(150.0, 200.0), 2),  # NOT NULL - always provide
            'WeightKg': round(random.uniform(45.0, 120.0), 2),    # NOT NULL - always provide
            'EmergencyContactName': fake.name(),  # NOT NULL - always provide
            'EmergencyContactNumber': fake.phone_number()[:20],  # NOT NULL - always provide
            'MedicationAllergies': json.dumps(allergies)
        }
    
    def generate_admin(self, user_id):
        return {
            'UserId': user_id,
            'AdminLevel': 'hospital'  # Only hospital-level admins, super admin created separately
        }
    
    def generate_medication(self, institution_id, count=None):
        """Generate medications with dosage forms and realistic amounts"""
        # If count not specified, use random subset
        if count:
            meds_to_use = random.sample(self.MEDICATIONS, min(count, len(self.MEDICATIONS)))
        else:
            meds_to_use = random.sample(self.MEDICATIONS, random.randint(10, 50))
        
        medications = []
        for med_name in meds_to_use:
            dosage_form = random.choice(self.DOSAGE_FORMS)
            unit = self._get_unit_for_dosage_form(dosage_form)
            
            medications.append({
                'ClinicalInstitutionID': institution_id,
                'MedicationName': med_name,
                'Unit': unit,
                'DosageForm': dosage_form,
                'IsDeleted': False
            })
        return medications
    
    def _get_unit_for_dosage_form(self, dosage_form):
        """Return appropriate unit for dosage form"""
        unit_mapping = {
            'tablet': 'mg',
            'capsule': 'mg',
            'syrup': 'ml',
            'injection': 'ml'
        }
        return unit_mapping.get(dosage_form, 'mg')
    
    def generate_assigned_doctor(self, doctor_id, patient_id, level='primary'):
        return {
            'DoctorId': doctor_id,
            'PatientId': patient_id,
            'DoctorLevel': level,
            'IsDeleted': False
        }
    
    def generate_medical_history(self, patient_id, count=None):
        # Generate 0-3 medical history entries if count not specified
        num_entries = count if count is not None else random.randint(0, 3)
        
        histories = []
        diseases_used = random.sample(self.DISEASES, min(num_entries, len(self.DISEASES)))
        
        for disease in diseases_used:
            histories.append({
                'PatientId': patient_id,
                'DiseaseName': disease,
                'Severity': random.choice(['mild', 'moderate', 'severe', 'life_threatening']),
                'IsDeleted': False
            })
        return histories
    
    def generate_patient_symptom(self, medical_history_id, count=None):
        num_symptoms = count if count is not None else random.randint(1, 4)
        
        symptoms = []
        symptoms_used = random.sample(self.SYMPTOMS, min(num_symptoms, len(self.SYMPTOMS)))
        
        for symptom in symptoms_used:
            symptoms.append({
                'MedicalHistoryId': medical_history_id,
                'SymptomName': symptom
            })
        return symptoms
    
    def generate_prescription(self, doctor_id, patient_id, prescribed_date=None):
        if prescribed_date is None:
            prescribed_date = fake.date_between(start_date='-1y', end_date='today')
        
        return {
            'DoctorId': doctor_id,
            'PatientId': patient_id,
            'PrescriptionNumber': '',  # Will be auto-generated by trigger
            'Status': random.choice(['active', 'completed']),
            'PrescribedDate': prescribed_date,
            'IsDeleted': False
        }
    
    def generate_prescribed_medication(self, prescription_id, medication_id, start_date=None):
        if start_date is None:
            start_date = fake.date_between(start_date='-6m', end_date='today')
        
        duration_days = random.randint(7, 90)
        end_date = start_date + timedelta(days=duration_days)
        
        dosage_instructions = random.choice([
            'Take one tablet daily with food',
            'Take two tablets twice daily',
            'Take one capsule every 8 hours',
            'Take as needed for pain',
            'Apply topically twice daily',
            'Take one tablet at bedtime'
        ])
        
        return {
            'PrescriptionId': prescription_id,
            'MedicationId': medication_id,
            'StartDate': start_date,
            'EndDate': end_date,
            'DosageInstruction': dosage_instructions,
            'IsDeleted': False
        }
    
    def generate_prescribed_medication_schedule(self, prescribed_medication_id, count=None):
        num_schedules = count if count is not None else random.randint(1, 3)
        
        schedules = []
        weekdays_used = random.sample(self.WEEKDAYS, min(num_schedules, len(self.WEEKDAYS)))
        
        for weekday in weekdays_used:
            meal_time = time(
                hour=random.choice([8, 12, 18, 21]),
                minute=random.choice([0, 15, 30, 45])
            )
            
            schedules.append({
                'PrescribedMedicationId': prescribed_medication_id,
                'Weekday': weekday,
                'MealTiming': meal_time,
                'Dose': random.randint(1, 3)
            })
        return schedules
    
    def generate_reminder(self, medication_schedule_id):
        return {
            'MedicationScheduleID': medication_schedule_id,
            'IsActive': random.choice([True, True, True, False]),  # 75% active
            'CurrentStatus': random.choice(['ignored', 'completed']),
            'RemindGap': time(hour=0, minute=random.choice([5, 10, 15, 30]))
        }
    
    def generate_appointment(self, doctor_id, patient_id, appointment_date=None):
        if appointment_date is None:
            # Generate appointments only in the future (1 to 60 days ahead)
            days_offset = random.randint(1, 60)
            appointment_date = date.today() + timedelta(days=days_offset)
        
        # Ensure appointment is not in the past
        if appointment_date < date.today():
            appointment_date = date.today() + timedelta(days=random.randint(1, 30))
        
        # For today's appointments, ensure time is in the future
        current_time = datetime.now().time()
        if appointment_date == date.today():
            # Set appointment at least 1 hour from now
            future_hour = (datetime.now() + timedelta(hours=1)).hour
            if future_hour >= 17:  # If too late, schedule for tomorrow
                appointment_date = date.today() + timedelta(days=1)
                appointment_time = time(hour=random.randint(9, 16), minute=random.choice([0, 15, 30, 45]))
            else:
                appointment_time = time(hour=random.randint(future_hour, 16), minute=random.choice([0, 15, 30, 45]))
        else:
            appointment_time = time(
                hour=random.randint(9, 16),
                minute=random.choice([0, 15, 30, 45])
            )
        
        # Future appointments should be scheduled or confirmed
        status = random.choice(['scheduled', 'confirmed'])
        
        return {
            'DoctorId': doctor_id,
            'PatientId': patient_id,
            'AppointmentDate': appointment_date,
            'AppointmentTime': appointment_time,
            'DurationMinutes': random.choice([15, 30, 45, 60]),
            'AppointmentType': random.choice(['consultation', 'follow-up']),
            'Status': status,
            'Notes': fake.sentence() if random.random() > 0.5 else None,
            'IsEmergency': random.random() < 0.1,  # 10% emergency
            'IsDeleted': False
        }
    
    def generate_patient_side_effect(self, prescribed_medication_id):
        onset_date = fake.date_between(start_date='-3m', end_date='today')
        has_resolved = random.random() > 0.3
        resolution_date = fake.date_between(start_date=onset_date, end_date='today') if has_resolved else None
        
        return {
            'PrescribedMedicationID': prescribed_medication_id,
            'SideEffectName': random.choice(self.SIDE_EFFECTS),
            'Severity': random.choice(['mild', 'moderate', 'severe', 'life_threatening']),
            'OnsetDate': onset_date,
            'PatientNotes': fake.sentence() if random.random() > 0.5 else None,
            'ResolutionDate': resolution_date
        }
    
    def generate_patient_report(self, doctor_id, patient_id):
        return {
            'DoctorId': doctor_id,
            'PatientId': patient_id,
            'Status': random.choice(['SideEffect', 'Symptom', 'No']),
            'Reason': fake.sentence() if random.random() > 0.3 else None,
            'AttachmentDirectory': None,
            'IsDeleted': False
        }
