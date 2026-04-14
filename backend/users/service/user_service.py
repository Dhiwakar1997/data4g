import ulid
import hashlib
import smtplib
import logging

import bcrypt
from email.message import EmailMessage
from datetime import datetime, timedelta

from fastapi import HTTPException
from jose import jwt, JWTError, ExpiredSignatureError

from core.config import settings
from users.data.repository import UserRepository
from users.data.model import User
from users.data.schema import (
    SignupRequest, LoginRequest, LoginResponse,
    GetUserResponse, UpdateUserRequest,
)

logger = logging.getLogger(__name__)


# ── Email Service ───────────────────────────────────────────────

class EmailService:
    def __init__(self):
        self.smtp_server = settings.SMTP_SERVER
        self.smtp_port = settings.SMTP_PORT
        self.smtp_username = settings.SMTP_USERNAME
        self.smtp_password = settings.SMTP_PASSWORD
        self.domain_endpoint = settings.DOMAIN_ENDPOINT

    @property
    def is_configured(self) -> bool:
        return bool(self.smtp_username and self.smtp_password)

    def _send(self, to: str, subject: str, body: str):
        if not self.is_configured:
            logger.warning("SMTP not configured — skipping email to %s", to)
            return

        msg = EmailMessage()
        msg.set_content(body)
        msg["Subject"] = subject
        msg["From"] = self.smtp_username
        msg["To"] = to

        try:
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_username, self.smtp_password)
                server.send_message(msg)
            logger.info("Email sent to %s: %s", to, subject)
        except Exception as e:
            logger.error("Failed to send email to %s: %s", to, e)

    def send_verification_email(self, email_id: str, verification_code: str, user_id: str):
        link = f"{self.domain_endpoint}/auth/verify-email?verification_code={verification_code}&user_id={user_id}"
        body = (
            f"Dear User,\n\n"
            f"Thank you for registering with DataForge.\n"
            f"To complete your registration, please verify your email:\n\n{link}\n\n"
            f"If you did not create an account, please disregard this email.\n\n"
            f"Best regards,\nDataForge Team"
        )
        self._send(email_id, "Verify your email — DataForge", body)

    def send_verification_success_email(self, email_id: str):
        body = "Your email has been verified successfully. You can now login to your account."
        self._send(email_id, "Email Verified — DataForge", body)

    def send_password_reset_email(self, email_id: str, reset_code: str):
        body = (
            f"Dear User,\n\n"
            f"We received a request to reset your password.\n"
            f"Please use the following code:\n\n{reset_code}\n\n"
            f"If you did not request this, please ignore this email.\n\n"
            f"Best regards,\nDataForge Team"
        )
        self._send(email_id, "Password Reset — DataForge", body)


# ── User Service ────────────────────────────────────────────────

class UserService:

    def __init__(self):
        self.repo = UserRepository()
        self.email_service = EmailService()

    def _requires_email_verification(self) -> bool:
        if not settings.EMAIL_VERIFICATION_REQUIRED:
            return False
        if not self.email_service.is_configured:
            logger.warning(
                "EMAIL_VERIFICATION_REQUIRED is enabled but SMTP is not configured; "
                "skipping email verification for this environment"
            )
            return False
        return True

    # ── Query ───────────────────────────────────────────────────

    async def get_user_by_id(self, user_id: str) -> GetUserResponse:
        user = await self.repo.get_user_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return self._to_response(user)

    async def search_users(self, query: str, current_user_id: str) -> list[dict]:
        return await self.repo.search_users(query, current_user_id)

    # ── Mutation ────────────────────────────────────────────────

    async def create_user(self, req: SignupRequest) -> User:
        existing = await self.repo.get_user_by_email_id(req.email_id)
        if existing:
            raise HTTPException(
                status_code=409,
                detail={
                    "code": (
                        "account_exists_unverified"
                        if not existing.is_verified
                        else "account_exists_verified"
                    ),
                    "message": "Account already exists. Please log in or use another email.",
                    "can_resend_verification": not existing.is_verified,
                },
            )

        requires_verification = self._requires_email_verification()
        verification_code = str(ulid.new())
        dob = None
        if req.date_of_birth:
            dob = datetime.strptime(req.date_of_birth, "%d-%m-%Y")

        user = User(
            user_id="user_" + str(ulid.new()),
            email_id=req.email_id,
            first_name=req.first_name,
            last_name=req.last_name,
            date_of_birth=dob,
            gender=req.gender.value if req.gender else None,
            password=self._hash_password(req.password),
            auth_provider="email",
            is_verified=not requires_verification,
            verification_code=verification_code if requires_verification else None,
            verification_code_expires_at=(
                datetime.now() + timedelta(hours=1)
                if requires_verification
                else None
            ),
        )
        created = await self.repo.create_user(user)

        if requires_verification:
            self.email_service.send_verification_email(
                created.email_id, verification_code, created.user_id,
            )
        return created

    async def resend_verification_email(self, email_id: str) -> str:
        user = await self.repo.get_user_by_email_id(email_id)
        if not user:
            return "If this account exists and is awaiting verification, a new verification email has been sent."

        if user.is_verified:
            return "This account is already verified. Please log in."

        verification_code = str(ulid.new())
        user.verification_code = verification_code
        user.verification_code_expires_at = datetime.now() + timedelta(hours=1)
        await self.repo.update_user(user)
        self.email_service.send_verification_email(
            user.email_id,
            verification_code,
            user.user_id,
        )
        return "Verification email sent. Please check your inbox."

    async def update_user(self, user_id: str, req: UpdateUserRequest) -> GetUserResponse:
        user = await self._get_user_or_404(user_id)
        if req.first_name is not None:
            user.first_name = req.first_name
        if req.last_name is not None:
            user.last_name = req.last_name
        if req.date_of_birth is not None:
            user.date_of_birth = datetime.strptime(req.date_of_birth, "%d-%m-%Y")
        if req.gender is not None:
            user.gender = req.gender.value
        await self.repo.update_user(user)
        return self._to_response(user)

    async def update_bio(self, user_id: str, bio: str | None) -> GetUserResponse:
        user = await self._get_user_or_404(user_id)
        user.bio = bio
        await self.repo.update_user(user)
        return self._to_response(user)

    async def delete_user(self, user_id: str):
        deleted = await self.repo.delete_user(user_id)
        if not deleted:
            raise HTTPException(status_code=404, detail="User not found")
        return deleted

    # ── Auth ────────────────────────────────────────────────────

    async def login_user(self, req: LoginRequest) -> LoginResponse:
        user = await self.repo.get_user_by_email_id(req.email_id)
        if not user:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        if self._requires_email_verification() and not user.is_verified:
            raise HTTPException(
                status_code=403,
                detail={
                    "code": "email_not_verified",
                    "message": "Your account exists, but email verification is still pending.",
                    "can_resend_verification": True,
                },
            )
        if not self._verify_password(req.password, user.password):
            raise HTTPException(status_code=401, detail="Invalid email or password")

        access_token, refresh_token = self._generate_tokens(user.user_id)
        return LoginResponse(access_token=access_token, refresh_token=refresh_token, user_id=user.user_id)

    async def handle_google_oauth(self, google_user_info: dict) -> LoginResponse:
        google_sub = google_user_info["sub"]
        email = google_user_info["email"]
        given_name = google_user_info.get("given_name", "")
        family_name = google_user_info.get("family_name", "")
        name = google_user_info.get("name", "")

        if not given_name and not family_name and name:
            parts = name.split(" ", 1)
            given_name = parts[0]
            family_name = parts[1] if len(parts) > 1 else ""

        # Check existing OAuth user
        user = await self.repo.get_user_by_provider_id(google_sub, "google")
        if user:
            access_token, refresh_token = self._generate_tokens(user.user_id)
            return LoginResponse(access_token=access_token, refresh_token=refresh_token, user_id=user.user_id)

        # Check existing email user (conflict)
        existing = await self.repo.get_user_by_email_id(email)
        if existing:
            raise HTTPException(
                status_code=409,
                detail="An account with this email already exists. Please use your original sign-in method.",
            )

        # Create new OAuth user
        user = User(
            user_id="user_" + str(ulid.new()),
            email_id=email,
            first_name=given_name or "User",
            last_name=family_name or None,
            auth_provider="google",
            provider_id=google_sub,
            is_verified=True,
            password=None,
        )
        created = await self.repo.create_user(user)
        access_token, refresh_token = self._generate_tokens(created.user_id)
        return LoginResponse(access_token=access_token, refresh_token=refresh_token, user_id=created.user_id)

    async def verify_email(self, verification_code: str, user_id: str):
        user = await self._get_user_or_404(user_id)
        if user.verification_code != verification_code:
            raise HTTPException(status_code=400, detail="Invalid verification code")
        if user.verification_code_expires_at and user.verification_code_expires_at < datetime.now():
            raise HTTPException(status_code=400, detail="Verification code expired")

        user.is_verified = True
        user.verification_code = None
        user.verification_code_expires_at = None
        await self.repo.update_user(user)
        self.email_service.send_verification_success_email(user.email_id)

    async def forget_password(self, email_id: str):
        user = await self.repo.get_user_by_email_id(email_id)
        if not user:
            # Don't reveal whether the email exists
            return

        reset_code = str(ulid.new())
        user.pwd_reset_code = reset_code
        user.pwd_reset_code_expires_at = datetime.now() + timedelta(hours=1)
        await self.repo.update_user(user)
        self.email_service.send_password_reset_email(email_id, reset_code)

    async def reset_password(self, email_id: str, reset_code: str, new_password: str):
        user = await self.repo.get_user_by_email_id(email_id)
        if not user:
            raise HTTPException(status_code=400, detail="Invalid reset request")
        if user.pwd_reset_code != reset_code:
            raise HTTPException(status_code=400, detail="Invalid reset code")
        if user.pwd_reset_code_expires_at and user.pwd_reset_code_expires_at < datetime.now():
            raise HTTPException(status_code=400, detail="Reset code expired")

        user.password = self._hash_password(new_password)
        user.pwd_reset_code = None
        user.pwd_reset_code_expires_at = None
        await self.repo.update_user(user)

    def get_new_access_token(self, refresh_token: str) -> tuple[str, str] | None:
        try:
            payload = jwt.decode(refresh_token, settings.SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
            if payload.get("type") != "refresh":
                return None
            user_id = payload["sub"]
            new_access_token = self._create_access_token(user_id)
            return new_access_token, user_id
        except (ExpiredSignatureError, JWTError):
            return None

    # ── Private helpers ─────────────────────────────────────────

    async def _get_user_or_404(self, user_id: str) -> User:
        user = await self.repo.get_user_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user

    def _to_response(self, user: User) -> GetUserResponse:
        return GetUserResponse(
            user_id=user.user_id,
            first_name=user.first_name,
            last_name=user.last_name,
            date_of_birth=user.date_of_birth.isoformat() if user.date_of_birth else None,
            gender=user.gender,
            email_id=user.email_id,
            created_at=user.created_at.isoformat() if user.created_at else "",
            updated_at=user.updated_at.isoformat() if user.updated_at else "",
            deleted_at=user.deleted_at.isoformat() if user.deleted_at else None,
            is_deleted=user.is_deleted,
            is_active=user.is_active,
            is_verified=user.is_verified,
            is_private=user.is_private,
            bio=user.bio,
        )

    def _generate_tokens(self, user_id: str) -> tuple[str, str]:
        return self._create_access_token(user_id), self._create_refresh_token(user_id)

    def _create_access_token(self, user_id: str) -> str:
        payload = {
            "sub": user_id,
            "type": "access",
            "exp": datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        }
        return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

    def _create_refresh_token(self, user_id: str) -> str:
        payload = {
            "sub": user_id,
            "type": "refresh",
            "exp": datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        }
        return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

    def _hash_password(self, password: str) -> str:
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    def _verify_password(self, plain: str, hashed: str) -> bool:
        # Dual-check: try bcrypt first, fall back to legacy SHA256 for migration
        try:
            return bcrypt.checkpw(plain.encode(), hashed.encode())
        except (ValueError, TypeError):
            # Legacy SHA256 hash — verify and signal migration needed
            return hashlib.sha256(plain.encode()).hexdigest() == hashed


# ── Google Auth Service ─────────────────────────────────────────

class GoogleAuthService:

    def __init__(self):
        if not settings.GOOGLE_WEB_CLIENT_ID:
            raise HTTPException(status_code=500, detail="Google OAuth is not configured on this server")
        from google.oauth2 import id_token
        from google.auth.transport import requests
        self._id_token = id_token
        self._request_session = requests.Request()
        self._client_id = settings.GOOGLE_WEB_CLIENT_ID

    def verify_id_token(self, id_token_string: str) -> dict:
        try:
            id_info = self._id_token.verify_oauth2_token(
                id_token_string, self._request_session, self._client_id,
            )

            if not id_info.get("email_verified", False):
                raise HTTPException(status_code=403, detail="Email address not verified by Google")

            sub = id_info.get("sub")
            email = id_info.get("email")
            if not sub or not email:
                raise HTTPException(status_code=401, detail="Invalid Google token: missing claims")

            return {
                "sub": sub,
                "email": email,
                "name": id_info.get("name", ""),
                "email_verified": id_info.get("email_verified", False),
                "picture": id_info.get("picture"),
                "given_name": id_info.get("given_name"),
                "family_name": id_info.get("family_name"),
            }

        except HTTPException:
            raise
        except ValueError as e:
            raise HTTPException(status_code=401, detail=f"Invalid Google ID token: {e}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Google token verification failed: {e}")
