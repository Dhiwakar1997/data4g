from fastapi import APIRouter

from dataforge.schemas.dashboard import (
    ConsolidatedDashboard, GrowthProjection,
    EntityCostDetail, OptimizationHint, CompareRequest,
)
from dataforge.schemas.compute import ComputeCostBreakdown
from dataforge.schemas.db_model import DBCostBreakdown
from dataforge.schemas.cache_spec import CacheCostBreakdown
from dataforge.service.cost_engine import CostEngine

cost_router = APIRouter(prefix="/projects/{project_id}/cost", tags=["cost"])


@cost_router.get("", response_model=ConsolidatedDashboard)
async def get_cost_dashboard(project_id: str):
    engine = CostEngine()
    return await engine.get_dashboard(project_id)


@cost_router.get("/growth", response_model=list[GrowthProjection])
async def get_growth_projections(project_id: str):
    engine = CostEngine()
    return await engine.get_growth_projections(project_id)


@cost_router.post("/compare", response_model=ConsolidatedDashboard)
async def compare_database(project_id: str, req: CompareRequest):
    engine = CostEngine()
    return await engine.compare_database(project_id, req.alternate_database_id)


@cost_router.get("/per-entity", response_model=list[EntityCostDetail])
async def get_per_entity_costs(project_id: str):
    engine = CostEngine()
    return await engine.get_entity_costs(project_id)


@cost_router.get("/hints", response_model=list[OptimizationHint])
async def get_optimization_hints(project_id: str):
    engine = CostEngine()
    return await engine.get_hints(project_id)


# ── Per-component cost breakdowns ───────────────────────────────

@cost_router.get("/compute/{component_id}", response_model=ComputeCostBreakdown)
async def get_compute_cost(project_id: str, component_id: str):
    engine = CostEngine()
    return await engine.get_compute_cost(project_id, component_id)


@cost_router.get("/database/{component_id}", response_model=DBCostBreakdown)
async def get_db_cost(project_id: str, component_id: str):
    engine = CostEngine()
    return await engine.get_db_cost(project_id, component_id)


@cost_router.get("/cache/{component_id}", response_model=CacheCostBreakdown)
async def get_cache_cost(project_id: str, component_id: str):
    engine = CostEngine()
    return await engine.get_cache_cost(project_id, component_id)
