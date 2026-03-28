from pydantic import BaseModel, Field

from dataforge.schemas.enums import CacheEvictionPolicy, DatabaseId


class CacheSpec(BaseModel):
    topology_component_id: str
    cache_database: DatabaseId = DatabaseId.REDIS
    memory_gb: float = Field(default=1.0, ge=0.25)
    eviction_policy: CacheEvictionPolicy = CacheEvictionPolicy.ALLKEYS_LRU
    ttl_seconds: int = 3600
    cluster_nodes: int = Field(default=1, ge=1)
    high_availability: bool = False


class CacheSpecUpdateRequest(BaseModel):
    cache_database: DatabaseId | None = None
    memory_gb: float | None = Field(default=None, ge=0.25)
    eviction_policy: CacheEvictionPolicy | None = None
    ttl_seconds: int | None = None
    cluster_nodes: int | None = Field(default=None, ge=1)
    high_availability: bool | None = None


class CacheCostBreakdown(BaseModel):
    topology_component_id: str
    memory_cost_monthly: float
    cluster_overhead_monthly: float = 0.0
    total_monthly: float
