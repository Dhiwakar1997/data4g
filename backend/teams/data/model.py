from datetime import datetime
from typing import Optional

from beanie import Document
from pydantic import Field


class Team(Document):
    team_id: str = Field(..., unique=True, index=True)
    name: str
    owner_id: str = Field(..., index=True)
    member_ids: list[str] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    is_deleted: bool = False

    class Settings:
        name = "teams"


class TeamInvite(Document):
    invite_id: str = Field(..., unique=True, index=True)
    team_id: str = Field(..., index=True)
    invited_by: str
    invite_token: str = Field(..., unique=True, index=True)
    max_uses: Optional[int] = None
    use_count: int = 0
    expires_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.now)
    is_active: bool = True

    class Settings:
        name = "team_invites"
