from pydantic import BaseModel

from dataforge.schemas.enums import CloudProvider


class LifecycleRule(BaseModel):
    name: str
    transition_days: int = 30
    transition_storage_class: str = "GLACIER"
    expiration_days: int | None = None


class ObjectStorageSpec(BaseModel):
    topology_component_id: str
    provider: CloudProvider = CloudProvider.AWS
    estimated_storage_gb: float = 100.0
    estimated_requests_per_month: int = 100_000
    estimated_egress_gb_month: float = 50.0
    access_policy: str = "private"
    versioning_enabled: bool = False
    lifecycle_rules: list[LifecycleRule] = []


class ObjectStorageSpecUpdateRequest(BaseModel):
    provider: CloudProvider | None = None
    estimated_storage_gb: float | None = None
    estimated_requests_per_month: int | None = None
    estimated_egress_gb_month: float | None = None
    access_policy: str | None = None
    versioning_enabled: bool | None = None
    lifecycle_rules: list[LifecycleRule] | None = None


class ObjectStorageCostBreakdown(BaseModel):
    topology_component_id: str
    storage_cost_monthly: float
    request_cost_monthly: float
    egress_cost_monthly: float
    total_monthly: float
