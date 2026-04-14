from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from dataforge.schemas.comparison import (
    TopologyCompareRequest, TopologyCompareResponse, MetricComparison,
)
from dataforge.service.comparison_service import ComparisonService

comparison_router = APIRouter(prefix="/topologies", tags=["comparison"])


@comparison_router.post("/compare", response_model=TopologyCompareResponse)
async def compare_topologies(
    req: TopologyCompareRequest,
    user_id: str = Depends(verify_access_token),
):
    """Compare two topologies from the same or different projects.
    User must have access to both projects and topologies."""
    service = ComparisonService()
    return await service.compare_topologies(req, user_id)


@comparison_router.post("/compare/metrics", response_model=MetricComparison)
async def compare_topology_metrics(
    project_id: str,
    topology_a_id: str,
    topology_b_id: str,
    user_id: str = Depends(verify_access_token),
):
    """Compare cost, performance, and risk metrics between two topologies."""
    service = ComparisonService()
    return await service.compare_metrics(project_id, topology_a_id, topology_b_id, user_id)
