from datetime import datetime

from teams.data.model import Team, TeamInvite


class TeamRepository:

    async def create_team(self, team: Team) -> Team:
        await team.insert()
        return team

    async def get_team_by_id(self, team_id: str) -> Team | None:
        return await Team.find_one(Team.team_id == team_id, Team.is_deleted == False)

    async def list_teams_for_user(self, user_id: str) -> list[Team]:
        return await Team.find(
            {"$and": [
                {"is_deleted": False},
                {"$or": [
                    {"owner_id": user_id},
                    {"member_ids": user_id},
                ]},
            ]}
        ).to_list()

    async def update_team(self, team: Team) -> Team:
        team.updated_at = datetime.now()
        await team.save()
        return team

    async def delete_team(self, team_id: str) -> Team | None:
        team = await self.get_team_by_id(team_id)
        if not team:
            return None
        team.is_deleted = True
        team.updated_at = datetime.now()
        await team.save()
        return team


class TeamInviteRepository:

    async def create_invite(self, invite: TeamInvite) -> TeamInvite:
        await invite.insert()
        return invite

    async def get_invite_by_token(self, token: str) -> TeamInvite | None:
        return await TeamInvite.find_one(
            TeamInvite.invite_token == token,
            TeamInvite.is_active == True,
        )

    async def update_invite(self, invite: TeamInvite) -> TeamInvite:
        await invite.save()
        return invite

    async def deactivate_invite(self, invite_id: str) -> bool:
        invite = await TeamInvite.find_one(TeamInvite.invite_id == invite_id)
        if not invite:
            return False
        invite.is_active = False
        await invite.save()
        return True
