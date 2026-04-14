from fastapi import HTTPException

from dataforge.data.repository import ProjectRepository, MemberRepository
from dataforge.schemas.topology import Topology
from dataforge.schemas.comparison import (
    TopologyCompareRequest, TopologyCompareResponse, ComponentDiff,
    MetricComparison,
)


class ComparisonService:

    def __init__(self):
        self.repo = ProjectRepository()
        self.member_repo = MemberRepository()

    async def compare_topologies(
        self, req: TopologyCompareRequest, user_id: str,
    ) -> TopologyCompareResponse:
        """Compare two topologies from the same or different projects."""
        # Load source topology
        source_topo = await self._load_topology(
            req.source_project_id, req.source_topology_id, user_id,
        )
        # Load target topology
        target_topo = await self._load_topology(
            req.target_project_id, req.target_topology_id, user_id,
        )

        # Build component maps by name+type for matching
        source_map = {(c.name, c.type.value): c for c in source_topo.components}
        target_map = {(c.name, c.type.value): c for c in target_topo.components}

        all_keys = set(source_map.keys()) | set(target_map.keys())

        diffs: list[ComponentDiff] = []
        added = removed = modified = unchanged = 0

        for key in sorted(all_keys):
            name, ctype = key
            src = source_map.get(key)
            tgt = target_map.get(key)

            if src and not tgt:
                diffs.append(ComponentDiff(
                    component_name=name,
                    component_type=ctype,
                    status="removed",
                    source_config=src.model_dump(mode="json"),
                    target_config=None,
                    changes=[f"Component '{name}' exists in source but not in target"],
                ))
                removed += 1
            elif tgt and not src:
                diffs.append(ComponentDiff(
                    component_name=name,
                    component_type=ctype,
                    status="added",
                    source_config=None,
                    target_config=tgt.model_dump(mode="json"),
                    changes=[f"Component '{name}' exists in target but not in source"],
                ))
                added += 1
            else:
                # Both exist — compare fields
                src_dict = src.model_dump(mode="json", exclude={"id"})
                tgt_dict = tgt.model_dump(mode="json", exclude={"id"})
                changes = self._diff_dicts(src_dict, tgt_dict)
                status = "modified" if changes else "unchanged"
                diffs.append(ComponentDiff(
                    component_name=name,
                    component_type=ctype,
                    status=status,
                    source_config=src.model_dump(mode="json"),
                    target_config=tgt.model_dump(mode="json"),
                    changes=changes,
                ))
                if changes:
                    modified += 1
                else:
                    unchanged += 1

        return TopologyCompareResponse(
            source_project_id=req.source_project_id,
            source_topology_id=req.source_topology_id,
            source_topology_name=source_topo.name,
            target_project_id=req.target_project_id,
            target_topology_id=req.target_topology_id,
            target_topology_name=target_topo.name,
            source_component_count=len(source_topo.components),
            target_component_count=len(target_topo.components),
            source_edge_count=len(source_topo.edges),
            target_edge_count=len(target_topo.edges),
            source_deployment_mode=source_topo.deployment_mode.value,
            target_deployment_mode=target_topo.deployment_mode.value,
            component_diffs=diffs,
            added_components=added,
            removed_components=removed,
            modified_components=modified,
            unchanged_components=unchanged,
        )

    async def _load_topology(
        self, project_id: str, topology_id: str, user_id: str,
    ) -> Topology:
        """Load a topology, checking user access."""
        # Check user has access to the project
        member = await self.member_repo.get_member(project_id, user_id)
        if not member:
            raise HTTPException(
                status_code=403,
                detail=f"You do not have access to project '{project_id}'",
            )

        # For members (not owners), check topology access
        if member.role != "owner" and topology_id not in member.topology_access:
            raise HTTPException(
                status_code=403,
                detail=f"You do not have access to topology '{topology_id}'",
            )

        project = await self.repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail=f"Project '{project_id}' not found")

        topologies = project.topologies or {}
        if topology_id not in topologies:
            # Fall back to legacy single topology
            if project.topology:
                topo = Topology.model_validate(project.topology)
                if topo.id == topology_id:
                    return topo
            raise HTTPException(
                status_code=404,
                detail=f"Topology '{topology_id}' not found in project '{project_id}'",
            )

        return Topology.model_validate(topologies[topology_id])

    async def compare_metrics(
        self, project_id: str, topology_a_id: str, topology_b_id: str, user_id: str,
    ) -> MetricComparison:
        """Compare cost, performance, and risk between two topologies."""
        topo_a = await self._load_topology(project_id, topology_a_id, user_id)
        topo_b = await self._load_topology(project_id, topology_b_id, user_id)

        # Use CostEngine to get costs
        from dataforge.service.cost_engine import CostEngine
        engine = CostEngine()

        project = await self.repo.get_project_by_id(project_id)
        cost_a = 0.0
        cost_b = 0.0

        if project and project.cost_snapshot:
            cost_a = project.cost_snapshot.get("total_monthly_cost", 0.0)

        # Simple estimate for topology B based on component count ratio
        ratio = len(topo_b.components) / max(len(topo_a.components), 1)
        cost_b = round(cost_a * ratio, 2)

        delta = round(cost_b - cost_a, 2)
        pct = round((delta / cost_a * 100) if cost_a > 0 else 0, 2)

        return MetricComparison(
            topology_a_id=topology_a_id,
            topology_a_name=topo_a.name,
            topology_b_id=topology_b_id,
            topology_b_name=topo_b.name,
            cost_a=cost_a,
            cost_b=cost_b,
            cost_delta=delta,
            cost_delta_percentage=pct,
            performance_a={"estimated_latency_ms": len(topo_a.components) * 5},
            performance_b={"estimated_latency_ms": len(topo_b.components) * 5},
            component_count_a=len(topo_a.components),
            component_count_b=len(topo_b.components),
        )

    def _diff_dicts(self, source: dict, target: dict, prefix: str = "") -> list[str]:
        """Recursively diff two dicts, returning human-readable changes."""
        changes = []
        all_keys = set(source.keys()) | set(target.keys())
        for key in sorted(all_keys):
            path = f"{prefix}.{key}" if prefix else key
            src_val = source.get(key)
            tgt_val = target.get(key)
            if src_val == tgt_val:
                continue
            if isinstance(src_val, dict) and isinstance(tgt_val, dict):
                changes.extend(self._diff_dicts(src_val, tgt_val, path))
            else:
                changes.append(f"{path}: {src_val} -> {tgt_val}")
        return changes
