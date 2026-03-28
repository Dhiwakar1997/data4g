from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from dataforge.schemas.membership import (
    AddMemberRequest, UpdateMemberRequest, ShareTopologyRequest,
    MemberResponse, MemberListResponse,
)
from dataforge.service.membership_service import MembershipService

membership_router = APIRouter(
    prefix="/projects/{project_id}/members",
    tags=["membership"],
)


@membership_router.post("", response_model=MemberResponse)
async def add_member(
    project_id: str,
    req: AddMemberRequest,
    user_id: str = Depends(verify_access_token),
):
    service = MembershipService()
    return await service.add_member(project_id, req, added_by=user_id)


@membership_router.get("", response_model=MemberListResponse)
async def list_members(
    project_id: str,
    user_id: str = Depends(verify_access_token),
):
    service = MembershipService()
    return await service.list_members(project_id)


@membership_router.put("/{member_user_id}", response_model=MemberResponse)
async def update_member(
    project_id: str,
    member_user_id: str,
    req: UpdateMemberRequest,
    user_id: str = Depends(verify_access_token),
):
    service = MembershipService()
    return await service.update_member(project_id, member_user_id, req, caller_id=user_id)


@membership_router.delete("/{member_user_id}")
async def remove_member(
    project_id: str,
    member_user_id: str,
    user_id: str = Depends(verify_access_token),
):
    service = MembershipService()
    await service.remove_member(project_id, member_user_id, caller_id=user_id)
    return {"message": "Member removed successfully"}


@membership_router.post("/share-topologies", response_model=MemberResponse)
async def share_topologies(
    project_id: str,
    req: ShareTopologyRequest,
    user_id: str = Depends(verify_access_token),
):
    service = MembershipService()
    return await service.share_topologies(project_id, req, caller_id=user_id)
