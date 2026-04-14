from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from teams.data.schema import (
    TeamCreateRequest, TeamUpdateRequest, TeamResponse, TeamListResponse,
    TeamInviteCreateRequest, TeamInviteResponse,
)
from teams.service.team_service import TeamService

team_router = APIRouter(prefix="/teams", tags=["teams"])


@team_router.post("", response_model=TeamResponse)
async def create_team(req: TeamCreateRequest, user_id: str = Depends(verify_access_token)):
    service = TeamService()
    return await service.create_team(req, owner_id=user_id)


@team_router.get("", response_model=TeamListResponse)
async def list_teams(user_id: str = Depends(verify_access_token)):
    service = TeamService()
    return await service.list_teams(user_id)


@team_router.get("/{team_id}", response_model=TeamResponse)
async def get_team(team_id: str, _: str = Depends(verify_access_token)):
    service = TeamService()
    return await service.get_team(team_id)


@team_router.put("/{team_id}", response_model=TeamResponse)
async def update_team(team_id: str, req: TeamUpdateRequest, user_id: str = Depends(verify_access_token)):
    service = TeamService()
    return await service.update_team(team_id, req, user_id)


@team_router.delete("/{team_id}")
async def delete_team(team_id: str, user_id: str = Depends(verify_access_token)):
    service = TeamService()
    await service.delete_team(team_id, user_id)
    return {"message": "Team deleted successfully", "team_id": team_id}


@team_router.post("/{team_id}/invite", response_model=TeamInviteResponse)
async def create_invite(team_id: str, req: TeamInviteCreateRequest, user_id: str = Depends(verify_access_token)):
    service = TeamService()
    return await service.create_invite(team_id, req, user_id)


@team_router.post("/join/{invite_token}", response_model=TeamResponse)
async def join_team(invite_token: str, user_id: str = Depends(verify_access_token)):
    service = TeamService()
    return await service.join_via_invite(invite_token, user_id)


@team_router.delete("/{team_id}/members/{member_user_id}", response_model=TeamResponse)
async def remove_member(team_id: str, member_user_id: str, user_id: str = Depends(verify_access_token)):
    service = TeamService()
    return await service.remove_member(team_id, member_user_id, user_id)
