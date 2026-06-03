# ─────────────────────────────────────────────
# File History Routes - 24-hour access
# ─────────────────────────────────────────────

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from datetime import datetime, timedelta
from typing import List, Optional
import uuid

from auth import get_current_user, require_auth
from database import get_db_connection

router = APIRouter(prefix="/api/history", tags=["File History"])

# ─── Models ──────────────────────────────────

class FileHistoryItem(BaseModel):
    id: str
    tool_id: str
    tool_name: str
    status: str
    output_name: str
    file_size: Optional[int] = None
    created_at: datetime
    expires_at: datetime
    is_expired: bool

class FileHistoryResponse(BaseModel):
    items: List[FileHistoryItem]
    total: int

# ─── Helper Functions ────────────────────────

TOOL_NAMES = {
    "merge": "Merge PDF",
    "split": "Split PDF",
    "compress": "Compress PDF",
    "rotate": "Rotate PDF",
    "watermark": "Watermark PDF",
    "protect": "Protect PDF",
    "unlock": "Unlock PDF",
    "images-to-pdf": "Images to PDF",
    "pdf-to-images": "PDF to Images",
    "extract-text": "Extract Text",
    "text-to-pdf": "Text to PDF",
    "word-to-pdf": "Word to PDF",
    "pdf-to-word": "PDF to Word",
    "pdf-to-excel": "PDF to Excel",
    "excel-to-pdf": "Excel to PDF",
    "powerpoint-to-pdf": "PowerPoint to PDF",
    "pdf-to-powerpoint": "PDF to PowerPoint",
    "html-url-to-pdf": "HTML to PDF",
    "organize": "Organize PDF",
    "add-page-numbers": "Add Page Numbers",
    "ocr": "OCR PDF",
    "crop": "Crop PDF",
    "redact": "Redact PDF"
}

def get_tool_name(tool_id: str) -> str:
    return TOOL_NAMES.get(tool_id, tool_id.title())

# ─────────────────────────────────────────────
#  SAVE FILE TO HISTORY
# ─────────────────────────────────────────────
async def save_to_history(
    user_id: Optional[str],
    tool_id: str,
    output_file: str,
    output_name: str,
    file_size: Optional[int] = None
) -> str:
    """Save processed file to history (24-hour retention)."""
    if not user_id:
        return None  # Guest users don't get history
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        job_id = str(uuid.uuid4())
        expires_at = datetime.utcnow() + timedelta(hours=24)
        
        cursor.execute("""
            INSERT INTO processing_jobs (
                id, user_id, tool_id, status, output_file, output_name, expires_at
            )
            VALUES (%s, %s, %s, 'done', %s, %s, %s)
            RETURNING id
        """, (job_id, user_id, tool_id, output_file, output_name, expires_at))
        
        conn.commit()
        return job_id
    
    except Exception as e:
        conn.rollback()
        print(f"Failed to save history: {e}")
        return None
    
    finally:
        cursor.close()
        conn.close()

# ─────────────────────────────────────────────
#  GET USER FILE HISTORY
# ─────────────────────────────────────────────
@router.get("/", response_model=FileHistoryResponse)
async def get_file_history(
    limit: int = 50,
    current_user: dict = Depends(require_auth)
):
    """Get user's file processing history (last 24 hours)."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get files from last 24 hours
        cursor.execute("""
            SELECT 
                id, tool_id, status, output_name, 
                created_at, expires_at
            FROM processing_jobs
            WHERE user_id = %s
                AND status = 'done'
                AND created_at >= NOW() - INTERVAL '24 hours'
            ORDER BY created_at DESC
            LIMIT %s
        """, (current_user["user_id"], limit))
        
        rows = cursor.fetchall()
        now = datetime.utcnow()
        
        items = []
        for row in rows:
            job_id, tool_id, status, output_name, created_at, expires_at = row
            
            # Check if expired
            is_expired = expires_at < now if expires_at else False
            
            items.append(FileHistoryItem(
                id=job_id,
                tool_id=tool_id,
                tool_name=get_tool_name(tool_id),
                status=status,
                output_name=output_name,
                created_at=created_at,
                expires_at=expires_at,
                is_expired=is_expired
            ))
        
        return FileHistoryResponse(
            items=items,
            total=len(items)
        )
    
    finally:
        cursor.close()
        conn.close()

# ─────────────────────────────────────────────
#  DOWNLOAD FILE FROM HISTORY
# ─────────────────────────────────────────────
@router.get("/{job_id}/download")
async def download_from_history(
    job_id: str,
    current_user: dict = Depends(require_auth)
):
    """Download a file from history (if not expired)."""
    from fastapi.responses import FileResponse
    from pathlib import Path
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get job details
        cursor.execute("""
            SELECT output_file, output_name, expires_at, user_id
            FROM processing_jobs
            WHERE id = %s AND status = 'done'
        """, (job_id,))
        
        job = cursor.fetchone()
        
        if not job:
            raise HTTPException(status_code=404, detail="File not found")
        
        output_file, output_name, expires_at, owner_id = job
        
        # Check ownership
        if owner_id != current_user["user_id"]:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Check expiration
        if expires_at and expires_at < datetime.utcnow():
            raise HTTPException(status_code=410, detail="File has expired")
        
        # Check if file exists
        file_path = Path(output_file)
        if not file_path.exists():
            raise HTTPException(status_code=404, detail="File no longer available")
        
        return FileResponse(
            path=str(file_path),
            filename=output_name,
            media_type="application/pdf"
        )
    
    finally:
        cursor.close()
        conn.close()

# ─────────────────────────────────────────────
#  DELETE FILE FROM HISTORY
# ─────────────────────────────────────────────
@router.delete("/{job_id}")
async def delete_from_history(
    job_id: str,
    current_user: dict = Depends(require_auth)
):
    """Delete a file from history."""
    from pathlib import Path
    import os
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get job details
        cursor.execute("""
            SELECT output_file, user_id
            FROM processing_jobs
            WHERE id = %s
        """, (job_id,))
        
        job = cursor.fetchone()
        
        if not job:
            raise HTTPException(status_code=404, detail="File not found")
        
        output_file, owner_id = job
        
        # Check ownership
        if owner_id != current_user["user_id"]:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Delete file from disk
        try:
            file_path = Path(output_file)
            if file_path.exists():
                os.remove(file_path)
        except Exception as e:
            print(f"Failed to delete file: {e}")
        
        # Delete from database
        cursor.execute("DELETE FROM processing_jobs WHERE id = %s", (job_id,))
        conn.commit()
        
        return {"message": "File deleted successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        cursor.close()
        conn.close()

# ─────────────────────────────────────────────
#  CLEANUP EXPIRED FILES (Background Task)
# ─────────────────────────────────────────────
@router.post("/cleanup")
async def cleanup_expired_files():
    """Cleanup expired files (admin/cron endpoint)."""
    from pathlib import Path
    import os
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get expired files
        cursor.execute("""
            SELECT id, output_file
            FROM processing_jobs
            WHERE expires_at < NOW()
                AND status = 'done'
                AND output_file IS NOT NULL
        """)
        
        expired = cursor.fetchall()
        deleted_count = 0
        
        for job_id, output_file in expired:
            try:
                # Delete file from disk
                file_path = Path(output_file)
                if file_path.exists():
                    os.remove(file_path)
                
                # Mark as expired in DB
                cursor.execute("""
                    UPDATE processing_jobs
                    SET status = 'expired', output_file = NULL
                    WHERE id = %s
                """, (job_id,))
                
                deleted_count += 1
            
            except Exception as e:
                print(f"Failed to cleanup {job_id}: {e}")
        
        conn.commit()
        
        return {
            "message": f"Cleaned up {deleted_count} expired files",
            "deleted": deleted_count
        }
    
    finally:
        cursor.close()
        conn.close()
