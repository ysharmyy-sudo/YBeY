from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# =====================================================
# DATABASE URL
# =====================================================
# Render automatically DATABASE_URL provide karta hai
DATABASE_URL = os.getenv("DATABASE_URL")

if DATABASE_URL:
    # PostgreSQL (Production - Render)
    SQLALCHEMY_DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://")
    connect_args = {}
else:
    # SQLite (Local Development only)
    SQLALCHEMY_DATABASE_URL = "sqlite:///./ybey.db"
    connect_args = {"check_same_thread": False}

# =====================================================
# ENGINE
# =====================================================
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True
)

# =====================================================
# SESSION
# =====================================================
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# =====================================================
# BASE
# =====================================================
Base = declarative_base()
