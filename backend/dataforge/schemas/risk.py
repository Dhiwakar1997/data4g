from datetime import datetime
from uuid import uuid4

from pydantic import BaseModel, Field

from dataforge.schemas.enums import RiskSeverity, RiskType


class RiskFinding(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    endpoint_id: str
    endpoint_path: str
    risk_type: RiskType
    severity: RiskSeverity
    message: str
    source_file: str
    code_snippet: str | None = None
    recommendation: str = ""
    detected_at: datetime = Field(default_factory=datetime.utcnow)


class EndpointRiskSummary(BaseModel):
    endpoint_id: str
    endpoint_path: str
    http_method: str
    overall_risk_score: float
    finding_count: int
    critical_count: int
    high_count: int
    medium_count: int
    findings: list[RiskFinding] = []


class RiskDashboard(BaseModel):
    project_id: str
    topology_id: str
    total_endpoints: int
    analyzed_endpoints: int
    overall_risk_score: float
    risk_distribution: dict[str, int] = {}
    top_risks: list[EndpointRiskSummary] = []
    risk_by_type: dict[str, int] = {}
    last_analyzed_at: datetime | None = None
