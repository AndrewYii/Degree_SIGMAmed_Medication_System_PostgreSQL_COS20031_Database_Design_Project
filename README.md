# COS20031 – Database Design Project
This repository is used to track progress, updates, and deliverables for the **SIGMAmed** group project in the COS20031 unit. The goal of this project is to design and implement a relational database for a medication management system.

It serves as both a record of our work and a communication tool so that the lecturer, tutor, as well as members can easily follow our updates.

---
## 🛠️ Technology Stack
- **Database**: **PostgreSQL**
- **Platform**: **Supabase**, used to host the database for online simulation and testing.
- **IDE**: **Visual Studio Code**
- **Version Control**: **Git** & **GitHub**

---
## 💻 Prerequisites
To contribute to this project, you will need the following installed and configured:

- **Git**: Required for cloning the repository and managing version control.
- **Visual Studio Code**: The recommended code editor for this project.
- **PostgreSQL Extension for VS Code**: Essential for connecting to our Supabase database and running `.sql` scripts directly from the editor.

---
## 📌 Purpose
- To systematically document the design and implementation of the database schema.
- To provide clear version tracking for major project deliverables, such as the ERD and final SQL scripts.
- To maintain transparency on incremental updates, including schema modifications, function creation, and documentation changes.

---
## 📂 Repository Structure
```
├── /docs               # Project brief, ERDs, and other design/reference documents
├── schema.sql          # The main SQL script for creating the database schema
└── README.md           # This file
```

---
## 🔖 Versioning Guidelines
The repository uses a **(x.y)** versioning system:

- **x (Major Update version):**
  - Incremented when a major idea is finished and approved by the lecturer.
  - Example: Completing the database schema design and ERD → **1.0**

- **y (Minor Update version):**
  - Incremented for smaller updates (e.g., adding a new table, creating a function, updating documentation, bug fixing, inserting dummy value).
  - Example: After adding the `Prescriptions` table to `schema.sql` → **1.1**

- **Format Example:**
  - **1.0** → Database Schema Design & ERD Finished and Approved.

---
👉 This README will evolve as the project progresses, with all updates tracked through the versioning system above.

---
## Kinetica Side-Effect Analysis
Pipeline: `kinetica_analysis_medication.py` pulls data from Postgres and loads Kinetica tables for dashboards:
- `medication_features`
- `side_effects_by_medication`
- `side_effects_by_patient`
- `top_side_effects`

### Prerequisites
- Python 3.10+
- Install deps: `pip install gpudb psycopg2-binary python-dotenv`
- Network access to your Postgres and Kinetica instances

### .env keys (example)
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your_db_password
DB_SCHEMA=SIGMAmed

KINETICA_HOST=https://<your_cluster>/gpudb-0
KINETICA_PORT=443
KINETICA_USERNAME=your_user
KINETICA_PASSWORD=your_password
KINETICA_SCHEMA=        # leave blank to use your default namespace, or set if you have schema rights
KINETICA_USE_TLS=true
```

### Run
```
$env:NO_PROXY="<your_cluster>"
foreach ($v in "HTTPS_PROXY","https_proxy","HTTP_PROXY","http_proxy"){Remove-Item Env:$v -ErrorAction SilentlyContinue}
py kinetica_analysis_medication.py --limit 500   # omit --limit for full load
```
- Script drops and recreates the four target tables each run.

### Quick SQL checks (Workbench)
- `SELECT COUNT(*) FROM side_effects_by_medication;`
- `SELECT patient_name, report_count FROM side_effects_by_patient ORDER BY report_count DESC LIMIT 10;`
- `SELECT * FROM top_side_effects ORDER BY total_reports DESC LIMIT 10;`

### Suggested charts
- Side effects by medication: X=`side_effect_name`, Y=`report_count`, Color=`medication_name`, optional Stack=`severity`.
- Patients reporting most side effects: X=`patient_name` (or `patient_username`), Y=`report_count`, tooltip `unique_side_effects`, `medications`.
- Overall top side effects: X=`side_effect_name`, Y=`total_reports`, tooltip `top_medication`, `top_medication_report_count`.
