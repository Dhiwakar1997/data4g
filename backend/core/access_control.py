import hashlib

from fastapi import Depends, Header, HTTPException, Request

from core.middleware import verify_access_token
from dataforge.data.repository import (
    MemberRepository,
    ProjectApiKeyRepository,
    ProjectRepository,
)

_member_repo = MemberRepository()
_project_repo = ProjectRepository()
_api_key_repo = ProjectApiKeyRepository()


def hash_api_key(plaintext: str) -> str:
    """SHA-256 hash used for both storing and looking up API keys."""
    return hashlib.sha256(plaintext.encode("utf-8")).hexdigest()


async def require_project_api_key(
    project_id: str,
    x_api_key: str = Header(..., alias="X-Api-Key"),
):
    """Dependency: authenticate an ingestion request via a project-scoped API key.

    - 401 on missing / unknown key
    - 403 if key has been revoked, or is bound to a different project
    Updates ``last_used_at`` as a fire-and-forget side effect.
    """
    if not x_api_key:
        raise HTTPException(status_code=401, detail="Missing X-Api-Key header")

    key = await _api_key_repo.get_by_hash(hash_api_key(x_api_key))
    if not key:
        raise HTTPException(status_code=401, detail="Invalid API key")
    if key.revoked_at is not None:
        raise HTTPException(status_code=403, detail="API key has been revoked")
    if key.project_id != project_id:
        raise HTTPException(status_code=403, detail="API key is not bound to this project")

    try:
        await _api_key_repo.touch_last_used(key)
    except Exception:
        pass

    return key


async def require_project_owner(
    request: Request,
    project_id: str,
    user_id: str = Depends(verify_access_token),
) -> str:
    """Dependency: ensures the current user is the project owner."""
    member = await _member_repo.get_member(project_id, user_id)
    if not member or member.role != "owner":
        raise HTTPException(status_code=403, detail="Only the project owner can perform this action")
    return user_id


async def require_project_access(
    request: Request,
    project_id: str,
    user_id: str = Depends(verify_access_token),
) -> str:
    """Dependency: ensures the current user has any access to the project."""
    member = await _member_repo.get_member(project_id, user_id)
    if not member:
        raise HTTPException(status_code=403, detail="You do not have access to this project")
    return user_id


async def require_topology_access(
    request: Request,
    project_id: str,
    topology_id: str,
    user_id: str = Depends(verify_access_token),
) -> str:
    """Dependency: ensures the user can access a specific topology.
    Owners have access to all topologies. Members need explicit access."""
    member = await _member_repo.get_member(project_id, user_id)
    if not member:
        raise HTTPException(status_code=403, detail="You do not have access to this project")
    if member.role == "owner":
        return user_id
    if topology_id not in member.topology_access:
        raise HTTPException(status_code=403, detail="You do not have access to this topology")
    return user_id


async def require_team_member(
    request: Request,
    team_id: str,
    user_id: str = Depends(verify_access_token),
) -> str:
    """Dependency: ensures the current user is a member of the team."""
    from teams.data.repository import TeamRepository
    team_repo = TeamRepository()
    team = await team_repo.get_team_by_id(team_id)
    if not team or user_id not in team.member_ids:
        raise HTTPException(status_code=403, detail="You are not a member of this team")
    return user_id


async def require_mutable_topology(
    request: Request,
    project_id: str,
    topology_id: str,
    user_id: str = Depends(verify_access_token),
) -> str:
    """Dependency: ensures the topology is not a live (read-only) topology."""
    from dataforge.schemas.enums import TopologyType
    project = await _project_repo.get_project_by_id(project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    topologies = project.topologies or {}
    if topology_id in topologies:
        topo_data = topologies[topology_id]
        if topo_data.get("topology_type") == TopologyType.LIVE.value:
            raise HTTPException(
                status_code=400,
                detail="Live topology is read-only. Clone to experiment.",
            )
    return user_id
