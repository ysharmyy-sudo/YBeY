from pydantic import BaseModel, EmailStr, validator
from datetime import datetime
from typing import Optional

# -----------------------------
# USER REGISTRATION (INPUT)
# -----------------------------
class UserRegistration(BaseModel):
    username: str
    email: EmailStr
    password: str
    confirm_password: str
    problem_description: Optional[str] = None
    remember_me: bool = False

    @validator("username")
    def validate_username(cls, v):
        v = v.strip()
        if not v:
            raise ValueError("Username cannot be empty")
        if len(v) < 3:
            raise ValueError("Username must be at least 3 characters")
        return v

    @validator("password")
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v

    @validator("confirm_password")
    def validate_confirm_password(cls, v, values):
        if "password" in values and v != values["password"]:
            raise ValueError("Passwords do not match")
        return v


# -----------------------------
# USER RESPONSE (OUTPUT)
# -----------------------------
class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    remember_me: bool
    problem_description: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# -----------------------------
# VISITOR (TRACKING)
# -----------------------------
class VisitorCreate(BaseModel):
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None


# -----------------------------
# STATISTICS RESPONSE
# -----------------------------
class StatisticsResponse(BaseModel):
    total_visitors: int
    total_registrations: int
