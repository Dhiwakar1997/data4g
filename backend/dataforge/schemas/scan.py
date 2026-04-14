"""Wire schemas for the MCP-driven scan ingestion pipeline.

These models describe the payloads the local `data4g-mcp` server POSTs to the
backend during an agent-driven sync. The session model is central: nothing
commits to the live topology until `finalize` is called, which lets agents
fail cleanly mid-run without polluting project state.
"""

from datetime import datetime
from typing import Literal, Optional
from uuid import uuid4

from pydantic import BaseModel, Field

from dataforge.schemas.enums import RiskSeverity, RiskType


# ── Registration payloads (one per tool call from the agent) ────


class ScanEndpointField(BaseModel):
    name: str
    type: str
    is_primary_key: bool = False
    is_foreign_key: bool = False
    references: Optional[str] = None
    is_indexed: bool = False
    is_nullable: bool = True


class ScanRegisterEndpoint(BaseModel):
    method: str
    path: str
    handler_file: str
    handler_line: Optional[int] = None
    framework: Optional[str] = None
    auth_required: Optional[bool] = None
    is_hot_path: Optional[bool] = None
    semantic_description: str
    notes: Optional[str] = None


class ScanRegisterEntity(BaseModel):
    name: str
    file: str
    fields: list[ScanEndpointField] = []
    semantic_description: str
    pii_fields: list[str] = []


class ScanRegisterService(BaseModel):
    name: str
    type: str
    depends_on: list[str] = []
    semantic_description: str


class ScanRegisterRisk(BaseModel):
    type: RiskType
    severity: RiskSeverity
    location: str
    description: str
    suggested_fix: str = ""
    confidence: float = 1.0


class ScanRegisterNote(BaseModel):
    target_type: Literal["endpoint", "entity", "service", "risk", "project"]
    target_ref: str
    note: str


# ── Session lifecycle ──────────────────────────────────────────


class ScanSessionStart(BaseModel):
    note: Optional[str] = None


class ScanSessionState(BaseModel):
    sync_id: str
    project_id: str
    state: Literal["active", "finalized", "aborted", "expired"]
    started_at: datetime
    expires_at: datetime
    note: Optional[str] = None
    endpoint_count: int = 0
    entity_count: int = 0
    service_count: int = 0
    risk_count: int = 0
    note_count: int = 0


class ScanSyncResult(BaseModel):
    sync_id: str
    state: Literal["finalized", "aborted"]
    endpoints_added: int = 0
    entities_added: int = 0
    services_added: int = 0
    risks_added: int = 0
    notes_added: int = 0
    topology_url: Optional[str] = None
    synced_at: datetime = Field(default_factory=datetime.utcnow)


# ── Historical log (persisted audit trail) ────────────────────


class ScanSyncLogEntry(BaseModel):
    sync_id: str
    project_id: str
    api_key_id: Optional[str] = None
    status: str
    endpoints_synced: int = 0
    entities_synced: int = 0
    services_synced: int = 0
    risk_findings_count: int = 0
    diff_summary: dict = Field(default_factory=dict)
    synced_at: datetime


# ── API key management ────────────────────────────────────────


class ApiKeyCreateRequest(BaseModel):
    label: str = Field(..., min_length=1, max_length=100)


class ApiKeyCreateResponse(BaseModel):
    key_id: str
    plaintext_key: str
    last_four: str
    label: str
    created_at: datetime


class ApiKeySummary(BaseModel):
    key_id: str
    last_four: str
    label: str
    created_by: str
    created_at: datetime
    last_used_at: Optional[datetime] = None
    revoked_at: Optional[datetime] = None


class ApiKeyVerifyResponse(BaseModel):
    ok: bool = True
    key_id: str
    project_id: str
    label: str
