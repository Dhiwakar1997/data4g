from pydantic import BaseModel, Field
from enum import Enum


class Gender(str, Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


# ── User response schemas ───────────────────────────────────────

class UserResponse(BaseModel):
    user_id: str
    first_name: str
    last_name: str | None = None
    date_of_birth: str | None = None
    gender: str | None = None
    email_id: str
    is_verified: bool

    class Config:
        from_attributes = True


class GetUserResponse(BaseModel):
    user_id: str
    first_name: str
    last_name: str | None = None
    date_of_birth: str | None = None
    gender: str | None = None
    email_id: str
    created_at: str
    updated_at: str
    deleted_at: str | None = None
    is_deleted: bool
    is_active: bool
    is_verified: bool
    is_private: bool = False
    bio: str | None = None

    class Config:
        from_attributes = True


class UpdateUserRequest(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    date_of_birth: str | None = None
    gender: Gender | None = None


class UpdateBioRequest(BaseModel):
    bio: str | None = None


# ── Auth schemas ────────────────────────────────────────────────

class SignupRequest(BaseModel):
    email_id: str
    password: str = Field(min_length=8)
    first_name: str = Field(min_length=1)
    last_name: str | None = None
    date_of_birth: str | None = None
    gender: Gender | None = None


class SignupResponse(BaseModel):
    message: str
    user_id: str
    requires_verification: bool = False


class ResendVerificationRequest(BaseModel):
    email_id: str


class MessageResponse(BaseModel):
    message: str


class LoginRequest(BaseModel):
    email_id: str
    password: str


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class ForgetPasswordRequest(BaseModel):
    email_id: str


class ResetPasswordRequest(BaseModel):
    email_id: str
    reset_code: str
    new_password: str = Field(min_length=8)


class GoogleCallbackRequest(BaseModel):
    id_token: str


class GoogleCallbackResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str


# ── Search schemas ──────────────────────────────────────────────

class UserSearchResult(BaseModel):
    user_id: str
    first_name: str
    last_name: str | None = None
    mutual_followers: int = 0
    mutual_following: int = 0
    is_following: bool = False


class UserSearchResponse(BaseModel):
    results: list[UserSearchResult]
