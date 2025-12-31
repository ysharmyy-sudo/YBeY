from pydantic import BaseModel, EmailStr, validator
from datetime import datetime
from typing import Optional

class UserRegistration(BaseModel):
    username: str
    email: EmailStr
    password: str
    confirm_password: str
    problem_description: Optional[str] = None
    remember_me: bool = False
    
    @validator('username')
    def validate_username(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError('Username cannot be empty')
        if len(v) < 3:
            raise ValueError('Username must be at least 3 characters')
        return v.strip()
    
    @validator('password')
    def validate_password(cls, v):
        if not v or len(v) < 6:
            raise ValueError('Password must be at least 6 characters')
        return v
    
    @validator('confirm_password')
    def validate_confirm_password(cls, v, values):
        if 'password' in values and v != values['password']:
            raise ValueError('Passwords do not match')
        return v

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    remember_me: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class VisitorCreate(BaseModel):
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None

class StatisticsResponse(BaseModel):
    total_visitors: int
    total_registrations: int
