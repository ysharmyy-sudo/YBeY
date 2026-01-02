from fastapi import FastAPI, Depends, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func
import hashlib

# Absolute imports
import models
import schemas
from database import SessionLocal, engine, Base

# Create DB tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="YBEY Backend API",
    version="1.0.0"
)

# CORS (Flutter / Web)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# DB dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Password hashing
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

# Root
@app.get("/")
def root():
    return {"message": "YBEY backend running successfully 🚀"}

# -------------------------------
# REGISTER USER (Flutter form)
# -------------------------------
@app.post("/api/register", response_model=schemas.UserResponse)
def register_user(
    payload: schemas.UserRegistration,
    db: Session = Depends(get_db)
):
    # Check email exists
    existing_user = db.query(models.User).filter(
        models.User.email == payload.email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    user = models.User(
        username=payload.username,
        email=payload.email,
        password_hash=hash_password(payload.password),
        remember_me=payload.remember_me,
        problem_description=payload.problem_description
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return user

# -------------------------------
# TRACK VISITOR (Home page load)
# -------------------------------
@app.post("/api/track-visitor")
def track_visitor(
    request: Request,
    db: Session = Depends(get_db)
):
    visitor = models.Visitor(
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent")
    )

    db.add(visitor)
    db.commit()

    return {"status": "visitor tracked"}

# -------------------------------
# STATISTICS (Backend only)
# -------------------------------
@app.get("/api/statistics", response_model=schemas.StatisticsResponse)
def get_statistics(db: Session = Depends(get_db)):
    total_visitors = db.query(func.count(models.Visitor.id)).scalar() or 0
    total_registrations = db.query(func.count(models.User.id)).scalar() or 0

    return {
        "total_visitors": total_visitors,
        "total_registrations": total_registrations
    }
