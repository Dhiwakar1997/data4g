from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from dataforge.schemas.comparison import (
    TopologyCompareRequest, TopologyCompareResponse,
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
