import json
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from psycopg2.extras import DictCursor

from auth import get_current_user
from database import get_db_connection

router = APIRouter(prefix="/api/cv-versions", tags=["cv_versions"])

@router.get("/")
async def get_cv_versions(current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
        
    try:
        with conn.cursor(cursor_factory=DictCursor) as cur:
            cur.execute("""
                SELECT id, title, profile_data, template_id, updated_at
                FROM cv_versions
                WHERE user_id = %s
                ORDER BY updated_at DESC
            """, (user_id,))
            rows = cur.fetchall()
            
            versions = []
            for r in rows:
                v = dict(r)
                v["id"] = str(v["id"])
                v["updated_at"] = v["updated_at"].isoformat() if v["updated_at"] else None
                versions.append(v)
            return {"versions": versions}
    finally:
        conn.close()

@router.post("/")
async def create_cv_version(
    payload: dict,
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user["user_id"]
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
        
    try:
        title = payload.get("title", "New CV")
        profile_data = payload.get("profile_data", {})
        template_id = payload.get("template_id")
        
        with conn.cursor(cursor_factory=DictCursor) as cur:
            cur.execute("""
                INSERT INTO cv_versions (user_id, title, profile_data, template_id)
                VALUES (%s, %s, %s, %s)
                RETURNING id, updated_at
            """, (user_id, title, json.dumps(profile_data), template_id))
            row = cur.fetchone()
            conn.commit()
            
            return {
                "id": str(row["id"]),
                "updated_at": row["updated_at"].isoformat() if row["updated_at"] else None,
                "message": "CV version created successfully"
            }
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

@router.put("/{version_id}")
async def update_cv_version(
    version_id: str,
    payload: dict,
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user["user_id"]
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
        
    try:
        title = payload.get("title")
        profile_data = payload.get("profile_data")
        template_id = payload.get("template_id")
        
        if not title or not profile_data:
            raise HTTPException(status_code=400, detail="Missing title or profile_data")
            
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE cv_versions
                SET title = %s, profile_data = %s, template_id = %s, updated_at = NOW()
                WHERE id = %s AND user_id = %s
            """, (title, json.dumps(profile_data), template_id, version_id, user_id))
            
            if cur.rowcount == 0:
                raise HTTPException(status_code=404, detail="CV version not found or unauthorized")
                
            conn.commit()
            return {"message": "CV version updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

@router.delete("/{version_id}")
async def delete_cv_version(
    version_id: str,
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user["user_id"]
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
        
    try:
        with conn.cursor() as cur:
            cur.execute("""
                DELETE FROM cv_versions
                WHERE id = %s AND user_id = %s
            """, (version_id, user_id))
            
            if cur.rowcount == 0:
                raise HTTPException(status_code=404, detail="CV version not found or unauthorized")
                
            conn.commit()
            return {"message": "CV version deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()
