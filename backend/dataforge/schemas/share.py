from datetime import datetime

from pydantic import BaseModel


class ShareLinkCreateRequest(BaseModel):
    resource_type: str
    resource_id: str
    expires_in_days: int = 30


class ShareLinkResponse(BaseModel):
    share_token: str
    share_url: str
    resource_type: str
    expires_at: datetime | None = None
    created_at: datetime
