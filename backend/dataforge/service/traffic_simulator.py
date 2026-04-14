from dataforge.schemas.topology import Topology
from dataforge.schemas.endpoint_metadata import ServerEndpointRegistry, EndpointMetadata
from dataforge.schemas.traffic import (
    EntryPointTraffic, TrafficSource, ComponentTrafficLoad, TrafficSimulationResult,
)
from dataforge.schemas.enums import ComponentType


class TrafficSimulator:
    """Cascades traffic through the dependency graph."""

    def __init__(
        self,
        topology: Topology,
        endpoint_registry: dict[str, ServerEndpointRegistry],
    ):
        self.topology = topology
        self.endpoints = endpoint_registry
        self._component_map = {c.id: c for c in topology.components}
        self._dep_graph: dict[str, list[str]] = {}
        self._build_dependency_graph()

    def _build_dependency_graph(self):
        """Build directed graph from topology edges."""
        for edge in self.topology.edges:
            self._dep_graph.setdefault(edge.source_component_id, []).append(
                edge.target_component_id
            )

    def simulate(self, entry_points: list[EntryPointTraffic]) -> TrafficSimulationResult:
        component_loads: dict[str, float] = {}
        component_sources: dict[str, list[TrafficSource]] = {}

        for ep in entry_points:
            # Find which component owns this endpoint
            owner_component_id = self._find_endpoint_owner(ep.endpoint_id)
            if not owner_component_id:
                continue

            # Cascade through dependency graph
            self._cascade(
                owner_component_id, ep.requests_per_second,
                ep.endpoint_id, "", component_loads, component_sources, set(),
            )

        total_qps = sum(ep.requests_per_second for ep in entry_points)
        per_component: list[ComponentTrafficLoad] = []

        for cid, load in component_loads.items():
            comp = self._component_map.get(cid)
            if not comp:
                continue
            per_component.append(ComponentTrafficLoad(
                component_id=cid,
                component_name=comp.name,
                component_type=comp.type,
                total_requests_per_second=round(load, 2),
                breakdown=component_sources.get(cid, []),
            ))

        per_component.sort(key=lambda c: c.total_requests_per_second, reverse=True)
        bottlenecks = self._identify_bottlenecks(per_component)

        return TrafficSimulationResult(
            topology_id=self.topology.id,
            entry_point_total_qps=total_qps,
            per_component_load=per_component,
            bottleneck_components=bottlenecks,
            estimated_total_latency_ms=self._estimate_latency(per_component),
            cascade_graph=self._dep_graph,
        )

    def _cascade(
        self,
        component_id: str,
        qps: float,
        source_endpoint_id: str,
        source_path: str,
        loads: dict[str, float],
        sources: dict[str, list[TrafficSource]],
        visited: set,
    ):
        if component_id in visited:
            return
        visited.add(component_id)

        loads[component_id] = loads.get(component_id, 0) + qps
        sources.setdefault(component_id, []).append(TrafficSource(
            source_endpoint_id=source_endpoint_id,
            source_endpoint_path=source_path,
            requests_per_second=qps,
            multiplier=1.0,
        ))

        # Follow edges to downstream components
        for downstream_id in self._dep_graph.get(component_id, []):
            # Endpoints in this component may call downstream multiple times
            registry = self.endpoints.get(component_id)
            multiplier = 1.0
            if registry:
                for ep in registry.endpoints:
                    db_calls = len(ep.db_calls)
                    cache_calls = len(ep.cache_calls)
                    service_calls = len(ep.service_calls)
                    total_calls = db_calls + cache_calls + service_calls
                    if total_calls > 0:
                        multiplier = max(multiplier, total_calls)

            downstream_qps = qps * multiplier
            self._cascade(
                downstream_id, downstream_qps,
                source_endpoint_id, source_path,
                loads, sources, visited.copy(),
            )

    def _find_endpoint_owner(self, endpoint_id: str) -> str | None:
        for cid, registry in self.endpoints.items():
            for ep in registry.endpoints:
                if ep.id == endpoint_id:
                    return cid
        return None

    def _identify_bottlenecks(self, loads: list[ComponentTrafficLoad]) -> list[str]:
        """Components where load is disproportionately high."""
        if not loads:
            return []
        avg_load = sum(c.total_requests_per_second for c in loads) / len(loads)
        threshold = max(avg_load * 3, 1000)
        return [c.component_id for c in loads if c.total_requests_per_second > threshold]

    def _estimate_latency(self, loads: list[ComponentTrafficLoad]) -> float:
        """Rough latency estimate based on component types."""
        latency = 0.0
        for comp_load in loads:
            if comp_load.component_type == ComponentType.DATABASE:
                latency += 5.0
            elif comp_load.component_type == ComponentType.CACHE:
                latency += 1.0
            elif comp_load.component_type == ComponentType.COMPUTE:
                latency += 10.0
            elif comp_load.component_type == ComponentType.LOAD_BALANCER:
                latency += 0.5
            elif comp_load.component_type == ComponentType.API_GATEWAY:
                latency += 2.0
        return round(latency, 2)
