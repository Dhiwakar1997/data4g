import ulid
import secrets
from datetime import datetime, timedelta

from fastapi import HTTPException

from teams.data.model import Team, TeamInvite
from teams.data.repository import TeamRepository, TeamInviteRepository
from teams.data.schema import (
    TeamCreateRequest, TeamUpdateRequest, TeamResponse, TeamListResponse,
    TeamInviteCreateRequest, TeamInviteResponse,
)
from core.config import settings


class TeamService:

    def __init__(self):
        self.repo = TeamRepository()
        self.invite_repo = TeamInviteRepository()

    # ── CRUD ────────────────────────────────────────────────────

    async def create_team(self, req: TeamCreateRequest, owner_id: str) -> TeamResponse:
        team = Team(
            team_id="team_" + str(ulid.new()),
            name=req.name,
            owner_id=owner_id,
            member_ids=[owner_id],
        )
        created = await self.repo.create_team(team)
        return self._to_response(created)

    async def get_team(self, team_id: str) -> TeamResponse:
        team = await self._get_or_404(team_id)
        return self._to_response(team)

    async def list_teams(self, user_id: str) -> TeamListResponse:
        teams = await self.repo.list_teams_for_user(user_id)
        return TeamListResponse(
            teams=[self._to_response(t) for t in teams],
            total=len(teams),
        )

    async def update_team(self, team_id: str, req: TeamUpdateRequest, user_id: str) -> TeamResponse:
        team = await self._get_or_404(team_id)
        if team.owner_id != user_id:
            raise HTTPException(status_code=403, detail="Only the team owner can update the team")
        if req.name is not None:
            team.name = req.name
        updated = await self.repo.update_team(team)
        return self._to_response(updated)

    async def delete_team(self, team_id: str, user_id: str):
        team = await self._get_or_404(team_id)
        if team.owner_id != user_id:
            raise HTTPException(status_code=403, detail="Only the team owner can delete the team")
        await self.repo.delete_team(team_id)

    # ── Invites ─────────────────────────────────────────────────

    async def create_invite(
        self, team_id: str, req: TeamInviteCreateRequest, user_id: str,
    ) -> TeamInviteResponse:
        team = await self._get_or_404(team_id)
        if team.owner_id != user_id:
            raise HTTPException(status_code=403, detail="Only the team owner can generate invites")

        invite = TeamInvite(
            invite_id="inv_" + str(ulid.new()),
            team_id=team_id,
            invited_by=user_id,
            invite_token=secrets.token_urlsafe(32),
            max_uses=req.max_uses,
            expires_at=(
                datetime.now() + timedelta(days=req.expires_in_days)
                if req.expires_in_days
                else None
            ),
        )
        created = await self.invite_repo.create_invite(invite)
        return self._invite_to_response(created)

    async def join_via_invite(self, invite_token: str, user_id: str) -> TeamResponse:
        invite = await self.invite_repo.get_invite_by_token(invite_token)
        if not invite:
            raise HTTPException(status_code=404, detail="Invalid or expired invite link")

        if invite.expires_at and invite.expires_at < datetime.now():
            raise HTTPException(status_code=400, detail="Invite link has expired")

        if invite.max_uses and invite.use_count >= invite.max_uses:
            raise HTTPException(status_code=400, detail="Invite link has reached maximum uses")

        team = await self._get_or_404(invite.team_id)
        if user_id in team.member_ids:
            raise HTTPException(status_code=409, detail="You are already a member of this team")

        team.member_ids.append(user_id)
        await self.repo.update_team(team)

        invite.use_count += 1
        await self.invite_repo.update_invite(invite)

        return self._to_response(team)

    # ── Member management ───────────────────────────────────────

    async def remove_member(self, team_id: str, member_user_id: str, user_id: str) -> TeamResponse:
        team = await self._get_or_404(team_id)
        if team.owner_id != user_id:
            raise HTTPException(status_code=403, detail="Only the team owner can remove members")
        if member_user_id == team.owner_id:
            raise HTTPException(status_code=400, detail="Cannot remove the team owner")
        if member_user_id not in team.member_ids:
            raise HTTPException(status_code=404, detail="User is not a member of this team")

        team.member_ids.remove(member_user_id)
        updated = await self.repo.update_team(team)
        return self._to_response(updated)

    # ── Helpers ──────────────────────────────────────────────────

    async def _get_or_404(self, team_id: str) -> Team:
        team = await self.repo.get_team_by_id(team_id)
        if not team:
            raise HTTPException(status_code=404, detail="Team not found")
        return team

    def _to_response(self, team: Team) -> TeamResponse:
        return TeamResponse(
            team_id=team.team_id,
            name=team.name,
            owner_id=team.owner_id,
            member_ids=team.member_ids,
            created_at=team.created_at.isoformat() if team.created_at else "",
            updated_at=team.updated_at.isoformat() if team.updated_at else "",
        )

    def _invite_to_response(self, invite: TeamInvite) -> TeamInviteResponse:
        base_url = settings.DOMAIN_ENDPOINT
        return TeamInviteResponse(
            invite_id=invite.invite_id,
            team_id=invite.team_id,
            invite_token=invite.invite_token,
            invite_url=f"{base_url}/api/v1/teams/join/{invite.invite_token}",
            max_uses=invite.max_uses,
            use_count=invite.use_count,
            expires_at=invite.expires_at.isoformat() if invite.expires_at else None,
            created_at=invite.created_at.isoformat() if invite.created_at else "",
        )
