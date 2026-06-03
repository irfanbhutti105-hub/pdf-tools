# ─────────────────────────────────────────────
# Database Connection Module
# ─────────────────────────────────────────────

import os
import psycopg2
from typing import Optional

def get_db_connection():
    """Get a PostgreSQL database connection."""
    database_url = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:admin@localhost:5432/pdf_tools"
    )
    
    try:
        conn = psycopg2.connect(database_url)
        return conn
    except Exception as e:
        print(f"Database connection failed: {e}")
        raise

def init_database():
    """Initialize database tables if they don't exist."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Check if users table exists
        cursor.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'users'
            )
        """)
        
        exists = cursor.fetchone()[0]
        
        if not exists:
            print("Database tables not found. Please run schema.sql first.")
            print("Run: psql -d pdf_tools -f schema.sql")
        
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Database initialization check failed: {e}")
        if cursor:
            cursor.close()
        if conn:
            conn.close()
