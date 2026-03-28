from pydantic import BaseModel, Field
from uuid import uuid4

from dataforge.schemas.enums import (
    CloudProvider, ComponentType, DeploymentMode, Region,
)


class GeoLocation(BaseModel):
    region: Region = Region.US_EAST_1
    availability_zones: int = Field(default=1, ge=1, le=6)
    description: str | None = None


class TopologyEdge(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    source_component_id: str
    target_component_id: str
    estimated_bandwidth_mbps: float = 100.0
    estimated_latency_ms: float = 1.0
    description: str | None = None


class TopologyComponent(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    type: ComponentType
    enabled: bool = True
    location: GeoLocation = Field(default_factory=GeoLocation)
    cloud_provider: CloudProvider = CloudProvider.AWS
    description: str | None = None
    tags: dict[str, str] = Field(default_factory=dict)


class TopologyCreateRequest(BaseModel):
    name: str
    deployment_mode: DeploymentMode = DeploymentMode.MULTI_TIER
    components: list[TopologyComponent] = Field(default_factory=list)
    edges: list[TopologyEdge] = Field(default_factory=list)
    base_user_count: int = Field(default=1000, ge=1)
    growth_targets: list[int] = Field(
        default_factory=lambda: [1_000, 10_000, 100_000, 1_000_000]
    )


class TopologyUpdateRequest(BaseModel):
    name: str | None = None
    deployment_mode: DeploymentMode | None = None
    components: list[TopologyComponent] | None = None
    edges: list[TopologyEdge] | None = None
    base_user_count: int | None = Field(default=None, ge=1)
    growth_targets: list[int] | None = None


class Topology(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    deployment_mode: DeploymentMode = DeploymentMode.MULTI_TIER
    components: list[TopologyComponent] = Field(default_factory=list)
    edges: list[TopologyEdge] = Field(default_factory=list)
    base_user_count: int = Field(default=1000, ge=1)
    growth_targets: list[int] = Field(
        default_factory=lambda: [1_000, 10_000, 100_000, 1_000_000]
    )

    def get_components_by_type(self, ctype: ComponentType) -> list[TopologyComponent]:
        return [c for c in self.components if c.type == ctype and c.enabled]

    def collapse_to_single_instance(self) -> "Topology":
        collapsed = self.model_copy(deep=True)
        for comp in collapsed.components:
            if comp.type in (ComponentType.LOAD_BALANCER, ComponentType.CDN):
                comp.enabled = False
        collapsed.deployment_mode = DeploymentMode.SINGLE_INSTANCE
        return collapsed


class TopologyListResponse(BaseModel):
    topologies: list[Topology]
    total: int
