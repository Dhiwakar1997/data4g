"""Project API key management.

Owners mint project-scoped API keys that the `data4g-mcp` server uses to
ingest scan data. Plaintext keys are shown exactly once at creation; storage
is a SHA-256 hash. Verify endpoint doubles as `data4g doctor` ping.
"""

import secrets
import string

from fastapi import APIRouter, Depends, HTTPException

from core.access_control import (
    hash_api_key,
    require_project_api_key,
    require_project_owner,
)
from dataforge.data.model import ProjectApiKey
from dataforge.data.repository import ProjectApiKeyRepository
from dataforge.schemas.scan import (
    ApiKeyCreateRequest,
    ApiKeyCreateResponse,
    ApiKeySummary,
    ApiKeyVerifyResponse,
)

api_key_router = APIRouter(prefix="/projects/{project_id}/keys", tags=["api-keys"])

MAX_ACTIVE_KEYS_PER_PROJECT = 2
KEY_PREFIX = "d4g_"
KEY_BODY_LEN = 40
_BASE62 = string.ascii_letters + string.digits


def _generate_plaintext_key() -> str:
    body = "".join(secrets.choice(_BASE62) for _ in range(KEY_BODY_LEN))
    return f"{KEY_PREFIX}{body}"


def _summary(key: ProjectApiKey) -> ApiKeySummary:
    return ApiKeySummary(
        key_id=str(key.id),
        last_four=key.last_four,
        label=key.label,
        created_by=key.created_by,
        created_at=key.created_at,
        last_used_at=key.last_used_at,
        revoked_at=key.revoked_at,
    )


@api_key_router.post("", response_model=ApiKeyCreateResponse, status_code=201)
async def create_api_key(
    project_id: str,
    payload: ApiKeyCreateRequest,
    user_id: str = Depends(require_project_owner),
) -> ApiKeyCreateResponse:
    repo = ProjectApiKeyRepository()
    active_count = await repo.count_active(project_id)
    if active_count >= MAX_ACTIVE_KEYS_PER_PROJECT:
        raise HTTPException(
            status_code=409,
            detail=(
                f"Project already has {MAX_ACTIVE_KEYS_PER_PROJECT} active API keys. "
                "Revoke one before creating another."
            ),
        )

    plaintext = _generate_plaintext_key()
    key = ProjectApiKey(
        project_id=project_id,
        key_hash=hash_api_key(plaintext),
        last_four=plaintext[-4:],
        label=payload.label.strip(),
        created_by=user_id,
    )
    await repo.create(key)

    return ApiKeyCreateResponse(
        key_id=str(key.id),
        plaintext_key=plaintext,
        last_four=key.last_four,
        label=key.label,
        created_at=key.created_at,
    )


@api_key_router.get("", response_model=list[ApiKeySummary])
async def list_api_keys(
    project_id: str,
    include_revoked: bool = False,
    _user_id: str = Depends(require_project_owner),
) -> list[ApiKeySummary]:
    repo = ProjectApiKeyRepository()
    keys = (
        await repo.list_all(project_id)
        if include_revoked
        else await repo.list_active(project_id)
    )
    return [_summary(k) for k in keys]


@api_key_router.delete("/{key_id}", response_model=ApiKeySummary)
async def revoke_api_key(
    project_id: str,
    key_id: str,
    _user_id: str = Depends(require_project_owner),
) -> ApiKeySummary:
    repo = ProjectApiKeyRepository()
    key = await repo.get_by_id(key_id)
    if not key or key.project_id != project_id:
        raise HTTPException(status_code=404, detail="API key not found")
    if key.revoked_at is not None:
        return _summary(key)
    await repo.revoke(key)
    return _summary(key)


@api_key_router.post("/verify", response_model=ApiKeyVerifyResponse)
async def verify_api_key(
    project_id: str,
    key: ProjectApiKey = Depends(require_project_api_key),
) -> ApiKeyVerifyResponse:
    """`data4g doctor` ping — returns 200 if key is live and bound here."""
    return ApiKeyVerifyResponse(
        key_id=str(key.id),
        project_id=project_id,
        label=key.label,
    )
