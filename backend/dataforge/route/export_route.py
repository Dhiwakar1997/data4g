from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from dataforge.schemas.export import ExportRequest, ExportResponse
from dataforge.service.export_service import ExportService

export_router = APIRouter(prefix="/projects/{project_id}/export", tags=["export"])


@export_router.post("", response_model=ExportResponse)
async def generate_export(
    project_id: str,
    req: ExportRequest,
    _: str = Depends(verify_access_token),
):
    service = ExportService()
    return await service.generate_export(project_id, req)


@export_router.get("/{export_id}")
async def download_export(
    project_id: str,
    export_id: str,
    _: str = Depends(verify_access_token),
):
    # Stub: in production, serve the generated file
    return {"message": "Export download", "export_id": export_id, "project_id": project_id}
