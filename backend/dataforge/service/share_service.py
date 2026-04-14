import secrets
from datetime import datetime, timedelta

from fastapi import HTTPException

from dataforge.data.repository import ShareLinkRepository
from dataforge.data.model import ShareLink
from dataforge.schemas.share import ShareLinkCreateRequest, ShareLinkResponse
from core.config import settings


class ShareService:
    """Manages shareable links for topologies, dashboards, comparisons."""

    def __init__(self):
        self.repo = ShareLinkRepository()

    async def create_link(
        self, req: ShareLinkCreateRequest, project_id: str, user_id: str,
    ) -> ShareLinkResponse:
        token = secrets.token_urlsafe(32)
        expires_at = (
            datetime.now() + timedelta(days=req.expires_in_days)
            if req.expires_in_days
            else None
        )

        link = ShareLink(
            share_token=token,
            resource_type=req.resource_type,
            resource_id=req.resource_id,
            project_id=project_id,
            created_by=user_id,
            expires_at=expires_at,
        )
        await self.repo.create_link(link)

        base_url = settings.DOMAIN_ENDPOINT
        return ShareLinkResponse(
            share_token=token,
            share_url=f"{base_url}/share/{token}",
            resource_type=req.resource_type,
            expires_at=expires_at,
            created_at=link.created_at,
        )

    async def resolve_link(self, token: str) -> dict:
        link = await self.repo.get_by_token(token)
        if not link:
            raise HTTPException(status_code=404, detail="Share link not found or expired")

        if link.expires_at and link.expires_at < datetime.now():
            raise HTTPException(status_code=410, detail="Share link has expired")

        return {
            "resource_type": link.resource_type,
            "resource_id": link.resource_id,
            "project_id": link.project_id,
            "created_by": link.created_by,
        }

    async def revoke_link(self, token: str, user_id: str):
        link = await self.repo.get_by_token(token)
        if not link:
            raise HTTPException(status_code=404, detail="Share link not found")
        if link.created_by != user_id:
            raise HTTPException(status_code=403, detail="Only the link creator can revoke it")
        await self.repo.deactivate(token)
