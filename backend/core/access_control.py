from fastapi import Depends, HTTPException, Request

from core.middleware import verify_access_token
from dataforge.data.repository import MemberRepository

_member_repo = MemberRepository()


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
