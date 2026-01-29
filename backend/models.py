from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text
from datetime import datetime
from database import Base   # absolute import (correct)

# =========================
# USERS TABLE
# =========================
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)

    password_hash = Column(String(255), nullable=False)

    remember_me = Column(Boolean, default=False)
    problem_description = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)


# =========================
# VISITORS TABLE
# =========================
class Visitor(Base):
    __tablename__ = "visitors"

    id = Column(Integer, primary_key=True, index=True)

    ip_address = Column(String(50), nullable=True)
    user_agent = Column(Text, nullable=True)

    visited_at = Column(DateTime, default=datetime.utcnow)
