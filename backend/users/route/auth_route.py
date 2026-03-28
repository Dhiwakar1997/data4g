from fastapi import APIRouter, HTTPException

from users.data.schema import (
    SignupRequest, SignupResponse, LoginRequest, LoginResponse,
    RefreshTokenRequest, GoogleCallbackRequest, GoogleCallbackResponse,
    ForgetPasswordRequest, ResetPasswordRequest, ResendVerificationRequest,
    MessageResponse,
)
from users.service.user_service import UserService, GoogleAuthService

auth_router = APIRouter(prefix="/auth", tags=["auth"])


@auth_router.post("/signup", response_model=SignupResponse)
async def signup(req: SignupRequest):
    service = UserService()
    user = await service.create_user(req)
    requires_verification = not user.is_verified
    message = (
        "Account created. Please verify your email before signing in."
        if requires_verification
        else "User created successfully"
    )
    return SignupResponse(
        message=message,
        user_id=user.user_id,
        requires_verification=requires_verification,
    )


@auth_router.post("/resend-verification", response_model=MessageResponse)
async def resend_verification(req: ResendVerificationRequest):
    service = UserService()
    message = await service.resend_verification_email(req.email_id)
    return MessageResponse(message=message)


@auth_router.post("/login", response_model=LoginResponse)
async def login(req: LoginRequest):
    service = UserService()
    return await service.login_user(req)


@auth_router.post("/refresh-token", response_model=LoginResponse)
async def refresh_token(req: RefreshTokenRequest):
    service = UserService()
    result = service.get_new_access_token(req.refresh_token)
    if not result:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    new_access_token, user_id = result
    return LoginResponse(access_token=new_access_token, refresh_token=req.refresh_token, user_id=user_id)


@auth_router.get("/verify-email")
async def verify_email(verification_code: str, user_id: str):
    service = UserService()
    await service.verify_email(verification_code, user_id)
    return {"message": "Email verified successfully"}


@auth_router.post("/logout")
async def logout():
    return {"message": "Logged out successfully"}


@auth_router.post("/forget-password")
async def forget_password(req: ForgetPasswordRequest):
    service = UserService()
    await service.forget_password(req.email_id)
    return {"message": "If this email exists, a password reset link has been sent."}


@auth_router.post("/reset-password")
async def reset_password(req: ResetPasswordRequest):
    service = UserService()
    await service.reset_password(req.email_id, req.reset_code, req.new_password)
    return {"message": "Password has been reset successfully."}


@auth_router.post("/google/callback", response_model=GoogleCallbackResponse)
async def google_oauth_callback(req: GoogleCallbackRequest):
    google_service = GoogleAuthService()
    google_user_info = google_service.verify_id_token(req.id_token)
    service = UserService()
    login_resp = await service.handle_google_oauth(google_user_info)
    return GoogleCallbackResponse(
        access_token=login_resp.access_token,
        refresh_token=login_resp.refresh_token,
        user_id=login_resp.user_id,
    )
