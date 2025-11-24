import os
import sys
from dotenv import load_dotenv

# Get the path to the .env file (two directories up from this file)
current_dir = os.path.dirname(__file__)
project_root = os.path.join(current_dir, '..')
env_path = os.path.join(project_root, '.env')

# Manually load the .env file
if os.path.exists(env_path):
    load_dotenv(env_path)
    print(f"✅ Loaded environment from: {env_path}")
else:
    print(f"❌ .env file not found at: {env_path}")
    # Create a default .env file if it doesn't exist
    with open(env_path, 'w') as f:
        f.write("""# PostgreSQL Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=postgres
DB_SCHEMA=SIGMAmed

# Kinetica Cloud Configuration
KINETICA_HOST=cluster1450.saas.kinetica.com
KINETICA_PORT=9191
KINETICA_USERNAME=arynjee_gmail
KINETICA_PASSWORD=Aryn050609

# Compliance Settings
COMPLIANCE_WINDOW_DAYS=30
VIOLATION_THRESHOLD=6
OVERDOSE_THRESHOLD=1.3
UNDERDOSE_THRESHOLD=0.7
MISSED_THRESHOLD=0.1
""")
    print("📝 Created default .env file. Please update with your actual credentials.")

class DBConfig:
    # PostgreSQL Config
    PG_HOST = os.getenv('DB_HOST', 'localhost')
    PG_PORT = os.getenv('DB_PORT', '5432')
    PG_NAME = os.getenv('DB_NAME', 'postgres')
    PG_USER = os.getenv('DB_USER', 'postgres')
    PG_PASSWORD = os.getenv('DB_PASSWORD', '')
    PG_SCHEMA = os.getenv('DB_SCHEMA', 'SIGMAmed')
    
    # Kinetica Config
    KINETICA_HOST = os.getenv('KINETICA_HOST')
    KINETICA_PORT = os.getenv('KINETICA_PORT', '9191')
    KINETICA_USERNAME = os.getenv('KINETICA_USERNAME')
    KINETICA_PASSWORD = os.getenv('KINETICA_PASSWORD')
    
    # Compliance Settings
    COMPLIANCE_WINDOW_DAYS = int(os.getenv('COMPLIANCE_WINDOW_DAYS', '30'))
    VIOLATION_THRESHOLD = int(os.getenv('VIOLATION_THRESHOLD', '6'))
    OVERDOSE_THRESHOLD = float(os.getenv('OVERDOSE_THRESHOLD', '1.3'))
    UNDERDOSE_THRESHOLD = float(os.getenv('UNDERDOSE_THRESHOLD', '0.7'))
    MISSED_THRESHOLD = float(os.getenv('MISSED_THRESHOLD', '0.1'))
    
    @classmethod
    def print_config_status(cls):
        """Print current configuration status"""
        print("\n🔧 Configuration Status:")
        print(f"   PostgreSQL: {cls.PG_USER}@{cls.PG_HOST}:{cls.PG_PORT}/{cls.PG_NAME}")
        print(f"   Kinetica: {cls.KINETICA_USERNAME}@{cls.KINETICA_HOST}" if cls.KINETICA_HOST else "   Kinetica: Not configured")
        print(f"   Window: {cls.COMPLIANCE_WINDOW_DAYS} days, Threshold: {cls.VIOLATION_THRESHOLD} violations")
    
    @classmethod
    def get_postgres_connection_string(cls):
        return f"postgresql://{cls.PG_USER}:{cls.PG_PASSWORD}@{cls.PG_HOST}:{cls.PG_PORT}/{cls.PG_NAME}"
    
    @classmethod
    def get_kinetica_connection_params(cls):
        if not cls.KINETICA_HOST:
            raise ValueError("Kinetica host not configured. Please set KINETICA_HOST in .env file")
        return {
            'host': cls.KINETICA_HOST,
            'port': cls.KINETICA_PORT,
            'username': cls.KINETICA_USERNAME,
            'password': cls.KINETICA_PASSWORD
        }

# Print config status when this module is imported
DBConfig.print_config_status()