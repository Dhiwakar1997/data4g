from pydantic import BaseModel


class TeamCreateRequest(BaseModel):
    name: str


class TeamUpdateRequest(BaseModel):
    name: str | None = None


class TeamResponse(BaseModel):
    team_id: str
    name: str
    owner_id: str
    member_ids: list[str]
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


class TeamListResponse(BaseModel):
    teams: list[TeamResponse]
    total: int


class TeamInviteCreateRequest(BaseModel):
    max_uses: int | None = None
    expires_in_days: int | None = 7


class TeamInviteResponse(BaseModel):
    invite_id: str
    team_id: str
    invite_token: str
    invite_url: str
    max_uses: int | None = None
    use_count: int = 0
    expires_at: str | None = None
    created_at: str

    class Config:
        from_attributes = True
