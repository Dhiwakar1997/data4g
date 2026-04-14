import ulid
from fastapi import HTTPException

from dataforge.data.repository import ProjectRepository, MemberRepository
from dataforge.data.model import Project, ProjectMember
from dataforge.schemas.project import (
    ProjectCreateRequest, ProjectUpdateRequest,
    ProjectResponse, ProjectListResponse,
)


class ProjectService:

    def __init__(self):
        self.repo = ProjectRepository()
        self.member_repo = MemberRepository()

    async def create_project(self, req: ProjectCreateRequest, owner_id: str) -> ProjectResponse:
        project = Project(
            project_id="proj_" + str(ulid.new()),
            owner_id=owner_id,
            name=req.name,
            description=req.description,
            git_repo_url=req.git_repo_url,
            team_id=req.team_id,
            cloud_provider=req.cloud_provider.value if req.cloud_provider else "aws",
            topologies={},
            topology=None,
            compute_specs={},
            db_specs={},
            cache_specs={},
            lb_specs={},
            cdn_specs={},
            k8s_specs={},
            docker_specs={},
            api_gateway_specs={},
            cron_specs={},
            object_storage_specs={},
            service_mesh_specs={},
            third_party_specs={},
            cost_snapshot=None,
        )
        created = await self.repo.create_project(project)

        # Auto-add the creator as owner in the membership table
        owner_member = ProjectMember(
            project_id=created.project_id,
            user_id=owner_id,
            role="owner",
            topology_access=[],
            added_by=owner_id,
        )
        await self.member_repo.add_member(owner_member)

        return self._to_response(created)

    async def get_project(self, project_id: str) -> ProjectResponse:
        project = await self._get_or_404(project_id)
        return self._to_response(project)

    async def list_projects(self, user_id: str, skip: int = 0, limit: int = 50) -> ProjectListResponse:
        """List only projects the user has access to."""
        projects, total = await self.repo.list_projects_for_user(user_id, skip, limit)
        return ProjectListResponse(
            projects=[self._to_response(p) for p in projects],
            total=total,
        )

    async def update_project(self, project_id: str, req: ProjectUpdateRequest) -> ProjectResponse:
        project = await self._get_or_404(project_id)
        if req.name is not None:
            project.name = req.name
        if req.description is not None:
            project.description = req.description
        if req.git_repo_url is not None:
            project.git_repo_url = req.git_repo_url
        if req.team_id is not None:
            project.team_id = req.team_id
        if req.cloud_provider is not None:
            project.cloud_provider = req.cloud_provider.value
        updated = await self.repo.update_project(project)
        return self._to_response(updated)

    async def delete_project(self, project_id: str):
        deleted = await self.repo.delete_project(project_id)
        if not deleted:
            raise HTTPException(status_code=404, detail="Project not found")
        # Clean up all memberships
        await self.member_repo.remove_all_members(project_id)
        return deleted

    # ── Helpers ──────────────────────────────────────────────────

    async def _get_or_404(self, project_id: str) -> Project:
        project = await self.repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")
        return project

    def _to_response(self, project: Project) -> ProjectResponse:
        return ProjectResponse(
            project_id=project.project_id,
            owner_id=project.owner_id,
            name=project.name,
            description=project.description or "",
            topology_count=len(project.topologies) if project.topologies else 0,
            git_repo_url=project.git_repo_url,
            team_id=project.team_id,
            cloud_provider=project.cloud_provider or "aws",
            created_at=project.created_at.isoformat() if project.created_at else "",
            updated_at=project.updated_at.isoformat() if project.updated_at else "",
        )
