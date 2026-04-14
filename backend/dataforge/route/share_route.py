from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from dataforge.schemas.share import ShareLinkCreateRequest, ShareLinkResponse
from dataforge.service.share_service import ShareService

share_router = APIRouter(prefix="/share", tags=["share"])


@share_router.post("", response_model=ShareLinkResponse)
async def create_share_link(
    req: ShareLinkCreateRequest,
    project_id: str = "",
    user_id: str = Depends(verify_access_token),
):
    service = ShareService()
    return await service.create_link(req, project_id=req.resource_id, user_id=user_id)


@share_router.get("/{token}")
async def resolve_share_link(token: str):
    """Public endpoint — no auth required."""
    service = ShareService()
    return await service.resolve_link(token)


@share_router.delete("/{token}")
async def revoke_share_link(token: str, user_id: str = Depends(verify_access_token)):
    service = ShareService()
    await service.revoke_link(token, user_id)
    return {"message": "Share link revoked"}
