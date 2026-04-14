from datetime import datetime
from typing import Literal, Optional
from beanie import Document
from pydantic import Field


class Project(Document):
    project_id: str = Field(..., unique=True, index=True)
    owner_id: str = Field(..., index=True)
    name: str
    description: str = ""

    # Project-level settings
    git_repo_url: Optional[str] = None
    team_id: Optional[str] = None
    cloud_provider: str = "aws"
    mcp_config: dict = Field(default_factory=dict)
    last_mcp_sync_at: Optional[datetime] = None

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

    # New component type specs keyed by component_id
    api_gateway_specs: Optional[dict] = None
    cron_specs: Optional[dict] = None
    object_storage_specs: Optional[dict] = None
    service_mesh_specs: Optional[dict] = None
    third_party_specs: Optional[dict] = None

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


# ── New document models ─────────────────────────────────────────


class EndpointRegistry(Document):
    project_id: str = Field(..., index=True)
    topology_id: str
    component_id: str
    endpoints: list[dict] = Field(default_factory=list)
    last_synced_at: Optional[datetime] = None
    sync_version: int = 0

    class Settings:
        name = "endpoint_registries"


class RiskReport(Document):
    project_id: str = Field(..., index=True)
    topology_id: str
    findings: list[dict] = Field(default_factory=list)
    overall_score: float = 0.0
    analyzed_at: datetime = Field(default_factory=datetime.now)

    class Settings:
        name = "risk_reports"


class CloudPricing(Document):
    provider: str
    service: str
    region: str
    sku: str
    price_per_unit: float
    unit: str
    last_updated: datetime = Field(default_factory=datetime.now)

    class Settings:
        name = "cloud_pricing"


class ShareLink(Document):
    share_token: str = Field(..., unique=True, index=True)
    resource_type: str
    resource_id: str
    project_id: str
    created_by: str
    expires_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.now)
    is_active: bool = True

    class Settings:
        name = "share_links"


class ScanSyncLog(Document):
    """Audit trail of finalised scan syncs (one row per successful finalize)."""
    project_id: str = Field(..., index=True)
    sync_mode: str
    sync_id: str = Field(..., unique=True, index=True)
    status: str
    endpoints_synced: int = 0
    entities_synced: int = 0
    risk_findings_count: int = 0
    diff_summary: dict = Field(default_factory=dict)
    synced_at: datetime = Field(default_factory=datetime.now)
    api_key_id: Optional[str] = None

    class Settings:
        # Collection name kept for backward-compatibility with existing data.
        name = "mcp_sync_logs"


class ProjectApiKey(Document):
    """Project-scoped API key used by the MCP server for ingestion."""
    project_id: str = Field(..., index=True)
    key_hash: str = Field(..., unique=True, index=True)
    last_four: str
    label: str
    created_by: str
    created_at: datetime = Field(default_factory=datetime.now)
    last_used_at: Optional[datetime] = None
    revoked_at: Optional[datetime] = None

    class Settings:
        name = "project_api_keys"


class ScanSession(Document):
    """Staging area for an in-progress agent-driven scan sync.

    Nothing commits to the live topology until `finalize` is called — lets
    partial uploads from non-deterministic agents fail cleanly.
    """
    sync_id: str = Field(..., unique=True, index=True)
    project_id: str = Field(..., index=True)
    api_key_id: str
    started_at: datetime = Field(default_factory=datetime.now)
    expires_at: datetime
    state: Literal["active", "finalized", "aborted", "expired"] = "active"
    note: Optional[str] = None

    endpoints: list[dict] = Field(default_factory=list)
    entities: list[dict] = Field(default_factory=list)
    services: list[dict] = Field(default_factory=list)
    risks: list[dict] = Field(default_factory=list)
    notes: list[dict] = Field(default_factory=list)

    class Settings:
        name = "scan_sessions"
