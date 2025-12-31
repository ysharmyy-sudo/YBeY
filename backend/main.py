from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func
import hashlib
from . import models, schemas
from .database import SessionLocal, engine, Base

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="YBEY API", version="1.0.0")

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app URLs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def hash_password(password: str) -> str:
    """Simple password hashing (use bcrypt in production)"""
    return hashlib.sha256(password.encode()).hexdigest()

@app.get("/")
def read_root():
    return {"message": "YBEY API is running", "version": "1.0.0"}

@app.post("/api/register", response_model=schemas.UserResponse)
def register_user(user_data: schemas.UserRegistration, db: Session = Depends(get_db)):
    """
    Register a new user
    """
    # Check if username already exists
    existing_user = db.query(models.User).filter(models.User.username == user_data.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    # Check if email already exists
    existing_email = db.query(models.User).filter(models.User.email == user_data.email).first()
    if existing_email:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create new user
    hashed_password = hash_password(user_data.password)
    new_user = models.User(
        username=user_data.username,
        email=user_data.email,
        password_hash=hashed_password,
        remember_me=user_data.remember_me,
        problem_description=user_data.problem_description
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

@app.post("/api/track-visitor")
def track_visitor(request: Request, db: Session = Depends(get_db)):
    """
    Track a visitor to the website
    """
    # Get client IP address
    client_ip = request.client.host if request.client else None
    # Get user agent
    user_agent = request.headers.get("user-agent", None)
    
    # Create visitor record
    visitor = models.Visitor(
        ip_address=client_ip,
        user_agent=user_agent
    )
    
    db.add(visitor)
    db.commit()
    db.refresh(visitor)
    
    return {"message": "Visitor tracked", "visitor_id": visitor.id}

@app.get("/api/statistics", response_model=schemas.StatisticsResponse)
def get_statistics(db: Session = Depends(get_db)):
    """
    Get statistics: total visitors and total registrations
    """
    total_visitors = db.query(func.count(models.Visitor.id)).scalar() or 0
    total_registrations = db.query(func.count(models.User.id)).scalar() or 0
    
    return {
        "total_visitors": total_visitors,
        "total_registrations": total_registrations
    }

@app.get("/api/users", response_model=list[schemas.UserResponse])
def get_all_users(db: Session = Depends(get_db)):
    """
    Get all registered users (for admin/testing)
    """
    users = db.query(models.User).all()
    return users

@app.get("/api/users/{user_id}", response_model=schemas.UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    """
    Get a specific user by ID
    """
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
