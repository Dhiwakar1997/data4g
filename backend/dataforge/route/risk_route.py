from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from dataforge.schemas.risk import RiskDashboard, RiskFinding, EndpointRiskSummary
from dataforge.schemas.enums import RiskType
from dataforge.service.risk_engine import RiskEngine

risk_router = APIRouter(prefix="/projects/{project_id}/risk", tags=["risk"])


@risk_router.get("", response_model=RiskDashboard)
async def get_risk_dashboard(
    project_id: str,
    topology_id: str = "default",
    _: str = Depends(verify_access_token),
):
    engine = RiskEngine()
    return await engine.build_dashboard(project_id, topology_id)


@risk_router.get("/endpoints", response_model=list[EndpointRiskSummary])
async def list_risky_endpoints(
    project_id: str,
    topology_id: str = "default",
    min_score: float = 0.0,
    _: str = Depends(verify_access_token),
):
    engine = RiskEngine()
    return await engine.get_endpoints_by_risk(project_id, topology_id, min_score)


@risk_router.get("/endpoints/{endpoint_id}", response_model=EndpointRiskSummary)
async def get_endpoint_risk(
    project_id: str,
    endpoint_id: str,
    topology_id: str = "default",
    _: str = Depends(verify_access_token),
):
    engine = RiskEngine()
    endpoints = await engine.get_endpoints_by_risk(project_id, topology_id)
    for ep in endpoints:
        if ep.endpoint_id == endpoint_id:
            return ep
    return EndpointRiskSummary(
        endpoint_id=endpoint_id,
        endpoint_path="",
        http_method="",
        overall_risk_score=0.0,
        finding_count=0,
        critical_count=0,
        high_count=0,
        medium_count=0,
    )


@risk_router.get("/by-type/{risk_type}", response_model=list[RiskFinding])
async def filter_by_risk_type(
    project_id: str,
    risk_type: RiskType,
    topology_id: str = "default",
    _: str = Depends(verify_access_token),
):
    engine = RiskEngine()
    return await engine.filter_by_type(project_id, topology_id, risk_type)


@risk_router.post("/analyze", response_model=RiskDashboard)
async def trigger_risk_analysis(
    project_id: str,
    topology_id: str = "default",
    _: str = Depends(verify_access_token),
):
    engine = RiskEngine()
    return await engine.trigger_analysis(project_id, topology_id)
