from fastapi import HTTPException

from dataforge.data.model import ProjectMember
from dataforge.data.repository import MemberRepository, ProjectRepository
from dataforge.schemas.membership import (
    AddMemberRequest, UpdateMemberRequest, ShareTopologyRequest,
    MemberResponse, MemberListResponse,
)


class MembershipService:

    def __init__(self):
        self.member_repo = MemberRepository()
        self.project_repo = ProjectRepository()

    async def add_member(
        self, project_id: str, req: AddMemberRequest, added_by: str,
    ) -> MemberResponse:
        # Verify project exists
        project = await self.project_repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")

        # Check caller is the owner
        caller = await self.member_repo.get_member(project_id, added_by)
        if not caller or caller.role != "owner":
            raise HTTPException(status_code=403, detail="Only the project owner can add members")

        # Check if user is already a member
        existing = await self.member_repo.get_member(project_id, req.user_id)
        if existing:
            raise HTTPException(status_code=409, detail="User is already a member of this project")

        member = ProjectMember(
            project_id=project_id,
            user_id=req.user_id,
            role=req.role.value,
            topology_access=req.topology_access,
            added_by=added_by,
        )
        created = await self.member_repo.add_member(member)
        return self._to_response(created)

    async def list_members(self, project_id: str) -> MemberListResponse:
        members = await self.member_repo.list_members(project_id)
        return MemberListResponse(
            members=[self._to_response(m) for m in members],
            total=len(members),
        )

    async def update_member(
        self, project_id: str, user_id: str, req: UpdateMemberRequest, caller_id: str,
    ) -> MemberResponse:
        # Check caller is the owner
        caller = await self.member_repo.get_member(project_id, caller_id)
        if not caller or caller.role != "owner":
            raise HTTPException(status_code=403, detail="Only the project owner can update members")

        member = await self.member_repo.get_member(project_id, user_id)
        if not member:
            raise HTTPException(status_code=404, detail="Member not found")

        if req.role is not None:
            member.role = req.role.value
        if req.topology_access is not None:
            member.topology_access = req.topology_access

        updated = await self.member_repo.update_member(member)
        return self._to_response(updated)

    async def remove_member(
        self, project_id: str, user_id: str, caller_id: str,
    ):
        # Check caller is the owner
        caller = await self.member_repo.get_member(project_id, caller_id)
        if not caller or caller.role != "owner":
            raise HTTPException(status_code=403, detail="Only the project owner can remove members")

        # Cannot remove yourself as owner
        if user_id == caller_id:
            raise HTTPException(status_code=400, detail="Cannot remove yourself as owner")

        removed = await self.member_repo.remove_member(project_id, user_id)
        if not removed:
            raise HTTPException(status_code=404, detail="Member not found")

    async def share_topologies(
        self, project_id: str, req: ShareTopologyRequest, caller_id: str,
    ) -> MemberResponse:
        """Grant a member access to specific topologies."""
        caller = await self.member_repo.get_member(project_id, caller_id)
        if not caller or caller.role != "owner":
            raise HTTPException(status_code=403, detail="Only the project owner can share topologies")

        member = await self.member_repo.get_member(project_id, req.user_id)
        if not member:
            raise HTTPException(status_code=404, detail="Member not found")

        # Merge new topology IDs with existing access
        existing = set(member.topology_access)
        existing.update(req.topology_ids)
        member.topology_access = list(existing)

        updated = await self.member_repo.update_member(member)
        return self._to_response(updated)

    def _to_response(self, member: ProjectMember) -> MemberResponse:
        return MemberResponse(
            project_id=member.project_id,
            user_id=member.user_id,
            role=member.role,
            topology_access=member.topology_access,
            added_by=member.added_by,
            created_at=member.created_at.isoformat() if member.created_at else "",
        )
