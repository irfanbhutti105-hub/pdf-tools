import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from psycopg2.extras import DictCursor

from auth import get_current_user
from database import get_db_connection

router = APIRouter(prefix="/api/stripe", tags=["stripe"])

@router.post("/create-checkout-session")
async def create_checkout_session(
    current_user: dict = Depends(get_current_user),
):
    """
    Mock Stripe Checkout Session endpoint.
    Since we don't have real Stripe keys, we simulate a successful checkout
    by instantly unlocking the user's premium status and returning a mock URL.
    """
    user_id = current_user["user_id"]
    
    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor() as cur:
                # Upsert subscription as active
                cur.execute("""
                    INSERT INTO subscriptions (user_id, plan, status)
                    VALUES (%s, 'premium', 'active')
                    ON CONFLICT (id) DO UPDATE SET status = 'active'
                """, (user_id,))
                
                # Update user's plan as well just in case
                cur.execute("""
                    UPDATE users SET plan = 'premium' WHERE id = %s
                """, (user_id,))
                
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
        finally:
            conn.close()

    # Return a fake checkout URL
    return {"url": "https://example.com/checkout/success"}

@router.post("/webhook")
async def stripe_webhook(request: Request):
    """
    Mock Stripe Webhook endpoint.
    """
    return {"status": "success"}
