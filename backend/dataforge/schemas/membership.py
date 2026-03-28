from pydantic import BaseModel, Field

from dataforge.schemas.enums import ProjectRole


class AddMemberRequest(BaseModel):
    user_id: str
    role: ProjectRole = ProjectRole.MEMBER
    topology_access: list[str] = Field(default_factory=list)


class UpdateMemberRequest(BaseModel):
    role: ProjectRole | None = None
    topology_access: list[str] | None = None


class ShareTopologyRequest(BaseModel):
    """Grant a member access to specific topologies."""
    user_id: str
    topology_ids: list[str]


class MemberResponse(BaseModel):
    project_id: str
    user_id: str
    role: str
    topology_access: list[str]
    added_by: str
    created_at: str

    class Config:
        from_attributes = True


class MemberListResponse(BaseModel):
    members: list[MemberResponse]
    total: int
