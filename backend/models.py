from sqlalchemy import Column, String, Text, BigInteger, DateTime, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base
import uuid
from datetime import datetime, timedelta


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False)
    name = Column(String)
    avatar_url = Column(String)
    provider = Column(String, default="email")
    password_hash = Column(String)
    plan = Column(String, default="free")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)

    jobs = relationship("ProcessingJob", back_populates="user")
    subscriptions = relationship("Subscription", back_populates="user")


class ProcessingJob(Base):
    __tablename__ = "processing_jobs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    tool_id = Column(String, nullable=False)
    status = Column(String, default="pending")
    input_files = Column(JSON)
    output_file = Column(String)
    output_name = Column(String)
    error_message = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, default=lambda: datetime.utcnow() + timedelta(hours=1))

    user = relationship("User", back_populates="jobs")


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"))
    plan = Column(String, nullable=False)
    status = Column(String, default="active")
    stripe_id = Column(String)
    started_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="subscriptions")


class UsageLog(Base):
    __tablename__ = "usage_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    tool_id = Column(String, nullable=False)
    ip_address = Column(String)
    file_size = Column(BigInteger)
    created_at = Column(DateTime, default=datetime.utcnow)
