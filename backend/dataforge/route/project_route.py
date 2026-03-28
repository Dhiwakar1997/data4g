from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from core.access_control import require_project_owner, require_project_access
from dataforge.schemas.project import (
    ProjectCreateRequest, ProjectUpdateRequest,
    ProjectResponse, ProjectListResponse,
)
from dataforge.service.project_service import ProjectService

project_router = APIRouter(prefix="/projects", tags=["projects"])


@project_router.post("", response_model=ProjectResponse)
async def create_project(req: ProjectCreateRequest, user_id: str = Depends(verify_access_token)):
    service = ProjectService()
    return await service.create_project(req, owner_id=user_id)


@project_router.get("", response_model=ProjectListResponse)
async def list_projects(skip: int = 0, limit: int = 50, user_id: str = Depends(verify_access_token)):
    service = ProjectService()
    return await service.list_projects(user_id, skip, limit)


@project_router.get("/{project_id}", response_model=ProjectResponse)
async def get_project(project_id: str, user_id: str = Depends(require_project_access)):
    service = ProjectService()
    return await service.get_project(project_id)


@project_router.put("/{project_id}", response_model=ProjectResponse)
async def update_project(project_id: str, req: ProjectUpdateRequest, user_id: str = Depends(require_project_owner)):
    service = ProjectService()
    return await service.update_project(project_id, req)


@project_router.delete("/{project_id}")
async def delete_project(project_id: str, user_id: str = Depends(require_project_owner)):
    service = ProjectService()
    await service.delete_project(project_id)
    return {"message": "Project deleted successfully", "project_id": project_id}
