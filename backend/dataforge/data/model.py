from datetime import datetime
from typing import Optional
from beanie import Document
from pydantic import Field


class Project(Document):
    project_id: str = Field(..., unique=True, index=True)
    owner_id: str = Field(..., index=True)
    name: str
    description: str = ""

    # Stage 1: Topology stored as dict (now supports multiple topologies)
    topologies: Optional[dict] = None  # keyed by topology_id

    # Legacy single topology (kept for backward compat)
    topology: Optional[dict] = None

    # Stage 2.1: Compute specs keyed by component_id
    compute_specs: Optional[dict] = None

    # Stage 2.2: DB model specs keyed by component_id
    db_specs: Optional[dict] = None

    # Stage 2: Cache, LB, CDN specs keyed by component_id
    cache_specs: Optional[dict] = None
    lb_specs: Optional[dict] = None
    cdn_specs: Optional[dict] = None

    # Orchestration specs keyed by component_id
    k8s_specs: Optional[dict] = None
    docker_specs: Optional[dict] = None

    # Cached cost snapshot for quick reads
    cost_snapshot: Optional[dict] = None

    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    is_deleted: bool = False

    class Settings:
        name = "projects"


class ProjectMember(Document):
    """Tracks project membership: owner and member access levels."""
    project_id: str = Field(..., index=True)
    user_id: str = Field(..., index=True)
    role: str = "member"  # "owner" or "member"
    # For members, which topology IDs they can access (empty = none)
    topology_access: list[str] = Field(default_factory=list)
    added_by: str = ""
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)

    class Settings:
        name = "project_members"
