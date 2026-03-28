from pydantic import BaseModel, Field

from dataforge.schemas.enums import CloudProvider, GPUType, Region


class GPUSpec(BaseModel):
    type: GPUType = GPUType.NONE
    count: int = Field(default=0, ge=0)
    vram_gb: float = 0.0


class AutoscalingConfig(BaseModel):
    enabled: bool = False
    min_instances: int = Field(default=1, ge=1)
    max_instances: int = Field(default=1, ge=1)
    target_cpu_utilization: float = Field(default=0.7, ge=0.1, le=1.0)
    target_memory_utilization: float = Field(default=0.8, ge=0.1, le=1.0)
    scale_up_cooldown_seconds: int = 300
    scale_down_cooldown_seconds: int = 300


class ComputeSpec(BaseModel):
    topology_component_id: str
    cpu_cores: int = Field(default=2, ge=1)
    ram_gb: float = Field(default=4.0, ge=0.5)
    gpu: GPUSpec = Field(default_factory=GPUSpec)
    instance_family: str = "general_purpose"
    instance_size: str = "medium"
    os: str = "linux"
    storage_gb: float = Field(default=50.0, ge=10.0)
    cloud_provider: CloudProvider = CloudProvider.AWS
    region: Region = Region.US_EAST_1
    autoscaling: AutoscalingConfig = Field(default_factory=AutoscalingConfig)

    @property
    def effective_instance_count(self) -> int:
        if self.autoscaling.enabled:
            return self.autoscaling.min_instances
        return 1


class ComputeSpecUpdateRequest(BaseModel):
    cpu_cores: int | None = Field(default=None, ge=1)
    ram_gb: float | None = Field(default=None, ge=0.5)
    gpu: GPUSpec | None = None
    instance_family: str | None = None
    instance_size: str | None = None
    os: str | None = None
    storage_gb: float | None = Field(default=None, ge=10.0)
    cloud_provider: CloudProvider | None = None
    region: Region | None = None
    autoscaling: AutoscalingConfig | None = None


class ComputeCostInput(BaseModel):
    spec: ComputeSpec
    hours_per_month: float = 730.0
    reserved_instance: bool = False
    spot_instance: bool = False


class ComputeCostBreakdown(BaseModel):
    topology_component_id: str
    instance_cost_monthly: float
    gpu_cost_monthly: float = 0.0
    storage_cost_monthly: float = 0.0
    total_monthly: float
    instance_description: str
