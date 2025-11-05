import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class DBConfig:
    HOST = os.getenv('DB_HOST', 'localhost')
    PORT = os.getenv('DB_PORT', '5432')
    NAME = os.getenv('DB_NAME', 'postgres')
    USER = os.getenv('DB_USER', 'postgres')
    PASSWORD = os.getenv('DB_PASSWORD', '')
    SCHEMA = os.getenv('DB_SCHEMA', 'SIGMAmed')
    
    @classmethod
    def get_connection_string(cls):
        return f"host={cls.HOST} port={cls.PORT} dbname={cls.NAME} user={cls.USER} password={cls.PASSWORD}"
    
    @classmethod
    def get_connection_params(cls):
        return {
            'host': cls.HOST,
            'port': cls.PORT,
            'database': cls.NAME,
            'user': cls.USER,
            'password': cls.PASSWORD
        }
    
    @classmethod
    def validate(cls):
        if not cls.PASSWORD:
            raise ValueError("DB_PASSWORD is not set in .env file")
        return True
