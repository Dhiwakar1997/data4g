from pydantic import BaseModel, Field

from dataforge.schemas.enums import CDNProvider


class CDNSpec(BaseModel):
    topology_component_id: str
    provider: CDNProvider = CDNProvider.CLOUDFRONT
    estimated_data_transfer_gb_month: float = 100.0
    estimated_requests_million_month: float = 10.0
    cache_hit_ratio: float = Field(default=0.85, ge=0.0, le=1.0)
    custom_domain: bool = True
    ssl: bool = True


class CDNSpecUpdateRequest(BaseModel):
    provider: CDNProvider | None = None
    estimated_data_transfer_gb_month: float | None = None
    estimated_requests_million_month: float | None = None
    cache_hit_ratio: float | None = Field(default=None, ge=0.0, le=1.0)
    custom_domain: bool | None = None
    ssl: bool | None = None


class CDNCostBreakdown(BaseModel):
    topology_component_id: str
    data_transfer_cost_monthly: float
    request_cost_monthly: float
    ssl_cost_monthly: float = 0.0
    total_monthly: float
