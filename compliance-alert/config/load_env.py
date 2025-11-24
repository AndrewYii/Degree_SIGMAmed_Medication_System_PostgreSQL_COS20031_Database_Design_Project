import os
from dotenv import load_dotenv

def load_environment():
    """Manually load environment variables from .env file"""
    env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
    
    if os.path.exists(env_path):
        load_dotenv(env_path)
        print("✅ Environment variables loaded from .env file")
        
        # Verify critical variables are loaded
        required_vars = ['DB_HOST', 'DB_USER', 'DB_PASSWORD']
        for var in required_vars:
            if not os.getenv(var):
                print(f"⚠️  Warning: {var} is not set in .env file")
    else:
        print("❌ .env file not found. Please create it.")
        
    return True

# Call this function at the start of your main scripts
load_environment()