"""Wire schemas shared with the Data4G backend.

These mirror `backend/dataforge/schemas/scan.py`. Keep them in lock-step:
any breaking change here requires a matching backend release (and ideally
a migration to a third `data4g-schemas` package, per the architecture plan).
"""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


# ── Field / entity / endpoint models ──────────────────────────────


class ScanEndpointField(BaseModel):
    name: str
    type: str
    is_primary_key: bool = False
    is_foreign_key: bool = False
    references: str | None = None
    is_indexed: bool = False
    is_nullable: bool = True


class ScanRegisterEndpoint(BaseModel):
    method: str
    path: str
    handler_file: str
    handler_line: int | None = None
    framework: str | None = None
    auth_required: bool | None = None
    is_hot_path: bool | None = None
    semantic_description: str
    notes: str | None = None


class ScanRegisterEntity(BaseModel):
    name: str
    file: str
    fields: list[ScanEndpointField] = Field(default_factory=list)
    semantic_description: str
    pii_fields: list[str] = Field(default_factory=list)


class ScanRegisterService(BaseModel):
    name: str
    type: str
    depends_on: list[str] = Field(default_factory=list)
    semantic_description: str


RiskSeverity = Literal["critical", "high", "medium", "low", "info"]
RiskType = Literal[
    "n_plus_one",
    "missing_pagination",
    "unbounded_fetch",
    "full_table_scan",
    "missing_index",
    "inefficient_join",
    "race_condition",
]


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


# ── Session lifecycle ────────────────────────────────────────────


class ScanSessionStart(BaseModel):
    note: str | None = None


class ScanSessionState(BaseModel):
    sync_id: str
    project_id: str
    state: Literal["active", "finalized", "aborted", "expired"]
    started_at: datetime
    expires_at: datetime
    note: str | None = None
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
    topology_url: str | None = None
    synced_at: datetime | None = None


# ── Analyzer output (local run_static_analysis tool) ─────────────


class AnalyzerResult(BaseModel):
    endpoints: list[ScanRegisterEndpoint] = Field(default_factory=list)
    entities: list[ScanRegisterEntity] = Field(default_factory=list)
    services: list[ScanRegisterService] = Field(default_factory=list)
    risks: list[ScanRegisterRisk] = Field(default_factory=list)
    notes: list[str] = Field(default_factory=list)
