from fastapi import APIRouter, Depends, Request
from core.middleware import verify_access_token, user_verification

from users.data.schema import (
    GetUserResponse, UpdateUserRequest, UserSearchResponse, UpdateBioRequest,
)
from users.service.user_service import UserService

user_router = APIRouter(prefix="/users", tags=["users"])


@user_router.get("/search", response_model=UserSearchResponse, dependencies=[Depends(verify_access_token)])
async def search_users(q: str, request: Request):
    service = UserService()
    results = await service.search_users(q, request.state.user_id)
    return UserSearchResponse(results=results)


@user_router.get("/{user_id}", response_model=GetUserResponse)
async def get_user(user_id: str, _: str = Depends(user_verification)):
    service = UserService()
    return await service.get_user_by_id(user_id)


@user_router.put("/{user_id}", response_model=GetUserResponse)
async def update_user(user_id: str, req: UpdateUserRequest, _: str = Depends(user_verification)):
    service = UserService()
    return await service.update_user(user_id, req)


@user_router.delete("/{user_id}")
async def delete_user(user_id: str, _: str = Depends(user_verification)):
    service = UserService()
    await service.delete_user(user_id)
    return {"message": "User deleted successfully", "user_id": user_id}


@user_router.patch("/{user_id}/bio")
async def update_bio(user_id: str, req: UpdateBioRequest, _: str = Depends(user_verification)):
    service = UserService()
    await service.update_bio(user_id, req.bio)
    return {"message": "Bio updated", "user_id": user_id}
