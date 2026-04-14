from pydantic import BaseModel

from dataforge.schemas.enums import ComponentType


class EntryPointTraffic(BaseModel):
    endpoint_id: str
    requests_per_second: float


class TrafficInput(BaseModel):
    entry_points: list[EntryPointTraffic]


class TrafficSource(BaseModel):
    source_endpoint_id: str
    source_endpoint_path: str
    requests_per_second: float
    multiplier: float = 1.0


class ComponentTrafficLoad(BaseModel):
    component_id: str
    component_name: str
    component_type: ComponentType
    total_requests_per_second: float
    breakdown: list[TrafficSource] = []


class TrafficSimulationResult(BaseModel):
    topology_id: str
    entry_point_total_qps: float
    per_component_load: list[ComponentTrafficLoad] = []
    bottleneck_components: list[str] = []
    estimated_total_latency_ms: float = 0.0
    cascade_graph: dict = {}
