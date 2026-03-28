from pydantic import BaseModel

from dataforge.schemas.enums import ComponentType, DatabaseId


class ComponentCostSummary(BaseModel):
    topology_component_id: str
    component_name: str
    component_type: ComponentType
    total_monthly: float
    details: dict[str, float] = {}


class CategoryCostSummary(BaseModel):
    category: str
    total_monthly: float
    percentage: float


class GrowthProjection(BaseModel):
    user_count: int
    total_monthly: float
    per_component: list[ComponentCostSummary]


class EntityCostDetail(BaseModel):
    entity_id: str
    entity_name: str
    record_count: int
    storage_gb: float
    storage_cost_monthly: float
    percentage_of_db_cost: float


class OptimizationHint(BaseModel):
    category: str
    message: str
    estimated_savings_monthly: float
    confidence: float


class CompareRequest(BaseModel):
    alternate_database_id: DatabaseId


class ConsolidatedDashboard(BaseModel):
    project_id: str
    project_name: str
    deployment_mode: str
    base_user_count: int
    total_monthly_cost: float
    per_component: list[ComponentCostSummary]
    per_category: list[CategoryCostSummary]
    per_entity_storage: list[EntityCostDetail]
    growth_projections: list[GrowthProjection]
    comparison_database: DatabaseId | None = None
    comparison_total_monthly: float | None = None
    comparison_delta: float | None = None
    optimization_hints: list[OptimizationHint] = []
