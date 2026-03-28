from pydantic import BaseModel, Field

from dataforge.schemas.enums import LBAlgorithm


class LoadBalancerSpec(BaseModel):
    topology_component_id: str
    algorithm: LBAlgorithm = LBAlgorithm.ROUND_ROBIN
    target_component_ids: list[str] = Field(default_factory=list)
    health_check_interval_seconds: int = 30
    ssl_termination: bool = True
    estimated_requests_per_second: float = 100.0
    estimated_data_processed_gb_month: float = 100.0


class LBSpecUpdateRequest(BaseModel):
    algorithm: LBAlgorithm | None = None
    target_component_ids: list[str] | None = None
    health_check_interval_seconds: int | None = None
    ssl_termination: bool | None = None
    estimated_requests_per_second: float | None = None
    estimated_data_processed_gb_month: float | None = None


class LBCostBreakdown(BaseModel):
    topology_component_id: str
    fixed_cost_monthly: float
    lcu_cost_monthly: float
    data_processing_cost_monthly: float
    total_monthly: float
