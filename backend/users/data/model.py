from datetime import datetime
from typing import Optional
from beanie import Document
from pydantic import Field


class User(Document):
    user_id: str = Field(..., unique=True, index=True)
    first_name: str
    last_name: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    gender: Optional[str] = None
    email_id: str = Field(..., unique=True, index=True)
    password: Optional[str] = None

    # OAuth
    auth_provider: Optional[str] = None
    provider_id: Optional[str] = None

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    deleted_at: Optional[datetime] = None

    # Flags
    is_deleted: bool = False
    is_active: bool = True
    is_verified: bool = False
    is_private: bool = False

    # Profile
    bio: Optional[str] = None

    # Verification
    verification_code: Optional[str] = None
    verification_code_expires_at: Optional[datetime] = None
    pwd_reset_code: Optional[str] = None
    pwd_reset_code_expires_at: Optional[datetime] = None

    class Settings:
        name = "users"
