# ─────────────────────────────────────────────
# Authentication Routes
# ─────────────────────────────────────────────

from fastapi import APIRouter, HTTPException, Depends
from datetime import datetime
from typing import Optional
import uuid

from auth import (
    UserRegister, UserLogin, Token, UserResponse,
    RefreshTokenRequest, hash_password, verify_password, create_access_token,
    create_refresh_token, decode_refresh_token, require_auth
)
from database import get_db_connection

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# ─────────────────────────────────────────────
#  REGISTER
# ─────────────────────────────────────────────
@router.post("/register", response_model=Token)
async def register(user_data: UserRegister):
    """Register a new user account."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Check if user already exists
        cursor.execute("SELECT id FROM users WHERE email = %s", (user_data.email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Create new user
        user_id = str(uuid.uuid4())
        password_hash = hash_password(user_data.password)
        
        cursor.execute("""
            INSERT INTO users (id, email, name, password_hash, provider, plan)
            VALUES (%s, %s, %s, %s, 'email', 'free')
            RETURNING id, email, name
        """, (user_id, user_data.email, user_data.name, password_hash))
        
        user = cursor.fetchone()
        conn.commit()
        
        # Create tokens
        access_token = create_access_token(user[0], user[1])
        refresh_token = create_refresh_token(user[0], user[1])
        
        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
            user_id=user[0],
            email=user[1],
            name=user[2]
        )
    
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")
    finally:
        cursor.close()
        conn.close()

# ─────────────────────────────────────────────
#  LOGIN
# ─────────────────────────────────────────────
@router.post("/login", response_model=Token)
async def login(credentials: UserLogin):
    """Login with email and password."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get user by email
        cursor.execute("""
            SELECT id, email, name, password_hash, plan
            FROM users
            WHERE email = %s AND provider = 'email'
        """, (credentials.email,))
        
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        user_id, email, name, password_hash, plan = user
        
        # Verify password
        if not verify_password(credentials.password, password_hash):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        # Create tokens
        access_token = create_access_token(user_id, email)
        refresh_token = create_refresh_token(user_id, email)
        
        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
            user_id=user_id,
            email=email,
            name=name
        )
    
    finally:
        cursor.close()
        conn.close()

# ─────────────────────────────────────────────
#  REFRESH
# ─────────────────────────────────────────────
@router.post("/refresh", response_model=Token)
async def refresh_token(request: RefreshTokenRequest):
    """Exchange a refresh token for a new access token pair."""
    payload = decode_refresh_token(request.refresh_token)
    user_id = payload["sub"]
    email = payload["email"]

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT id, email, name
            FROM users
            WHERE id = %s AND email = %s
        """, (user_id, email))

        user = cursor.fetchone()
        if not user:
            raise HTTPException(status_code=401, detail="User not found")

        next_access_token = create_access_token(user[0], user[1])
        next_refresh_token = create_refresh_token(user[0], user[1])

        return Token(
            access_token=next_access_token,
            refresh_token=next_refresh_token,
            user_id=user[0],
            email=user[1],
            name=user[2],
        )
    finally:
        cursor.close()
        conn.close()

# ─────────────────────────────────────────────
#  GET CURRENT USER
# ─────────────────────────────────────────────
@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: dict = Depends(require_auth)):
    """Get current user information."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT id, email, name, plan, created_at
            FROM users
            WHERE id = %s
        """, (current_user["user_id"],))
        
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        return UserResponse(
            id=user[0],
            email=user[1],
            name=user[2],
            plan=user[3],
            created_at=user[4]
        )
    
    finally:
        cursor.close()
        conn.close()

# ─────────────────────────────────────────────
#  LOGOUT (Client-side token removal)
# ─────────────────────────────────────────────
@router.post("/logout")
async def logout(_: Optional[RefreshTokenRequest] = None):
    """Logout endpoint (token should be removed client-side)."""
    return {"message": "Logged out successfully"}
