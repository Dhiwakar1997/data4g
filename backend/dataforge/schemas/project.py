from pydantic import BaseModel, Field

from dataforge.schemas.enums import CloudProvider


class ProjectCreateRequest(BaseModel):
    name: str
    description: str = ""
    git_repo_url: str | None = None
    team_id: str | None = None
    cloud_provider: CloudProvider = CloudProvider.AWS


class ProjectUpdateRequest(BaseModel):
    name: str | None = None
    description: str | None = None
    git_repo_url: str | None = None
    team_id: str | None = None
    cloud_provider: CloudProvider | None = None


class ProjectResponse(BaseModel):
    project_id: str
    owner_id: str
    name: str
    description: str
    topology_count: int = 0
    git_repo_url: str | None = None
    team_id: str | None = None
    cloud_provider: str = "aws"
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


class ProjectListResponse(BaseModel):
    projects: list[ProjectResponse]
    total: int
