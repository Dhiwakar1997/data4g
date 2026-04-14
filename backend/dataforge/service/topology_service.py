from uuid import uuid4

from fastapi import HTTPException

from dataforge.data.repository import ProjectRepository
from dataforge.data.model import Project
from dataforge.schemas.topology import (
    Topology, TopologyCreateRequest, TopologyUpdateRequest, TopologyListResponse,
)
from dataforge.schemas.enums import DeploymentMode, TopologyType


class TopologyService:

    def __init__(self):
        self.repo = ProjectRepository()

    # ── Legacy single topology (backward compat) ────────────────

    async def set_topology(self, project_id: str, req: TopologyCreateRequest) -> Topology:
        project = await self._get_or_404(project_id)
        topology = Topology(
            name=req.name,
            deployment_mode=req.deployment_mode,
            components=req.components,
            edges=req.edges,
            base_user_count=req.base_user_count,
            growth_targets=req.growth_targets,
        )
        project.topology = topology.model_dump(mode="json")

        # Also store in the multi-topology map
        topologies = project.topologies or {}
        topologies[topology.id] = topology.model_dump(mode="json")
        project.topologies = topologies

        await self.repo.update_project(project)
        return topology

    async def get_topology(self, project_id: str) -> Topology:
        project = await self._get_or_404(project_id)
        if not project.topology:
            raise HTTPException(status_code=404, detail="Topology not configured yet")
        return Topology.model_validate(project.topology)

    async def update_topology(self, project_id: str, req: TopologyUpdateRequest) -> Topology:
        project = await self._get_or_404(project_id)
        if not project.topology:
            raise HTTPException(status_code=404, detail="Topology not configured yet")

        topology = Topology.model_validate(project.topology)

        if req.name is not None:
            topology.name = req.name
        if req.deployment_mode is not None:
            topology.deployment_mode = req.deployment_mode
        if req.components is not None:
            topology.components = req.components
        if req.edges is not None:
            topology.edges = req.edges
        if req.base_user_count is not None:
            topology.base_user_count = req.base_user_count
        if req.growth_targets is not None:
            topology.growth_targets = req.growth_targets

        project.topology = topology.model_dump(mode="json")

        # Sync to multi-topology map
        topologies = project.topologies or {}
        topologies[topology.id] = topology.model_dump(mode="json")
        project.topologies = topologies

        await self.repo.update_project(project)
        return topology

    async def collapse_topology(self, project_id: str) -> Topology:
        project = await self._get_or_404(project_id)
        if not project.topology:
            raise HTTPException(status_code=404, detail="Topology not configured yet")

        topology = Topology.model_validate(project.topology)
        collapsed = topology.collapse_to_single_instance()
        project.topology = collapsed.model_dump(mode="json")

        topologies = project.topologies or {}
        topologies[collapsed.id] = collapsed.model_dump(mode="json")
        project.topologies = topologies

        await self.repo.update_project(project)
        return collapsed

    # ── Multi-topology CRUD ─────────────────────────────────────

    async def create_topology(self, project_id: str, req: TopologyCreateRequest) -> Topology:
        """Create a new topology within the project."""
        project = await self._get_or_404(project_id)
        topology = Topology(
            name=req.name,
            topology_type=req.topology_type,
            deployment_mode=req.deployment_mode,
            components=req.components,
            edges=req.edges,
            base_user_count=req.base_user_count,
            growth_targets=req.growth_targets,
        )
        topologies = project.topologies or {}
        topologies[topology.id] = topology.model_dump(mode="json")
        project.topologies = topologies

        # If no default topology set, use this one
        if not project.topology:
            project.topology = topology.model_dump(mode="json")

        await self.repo.update_project(project)
        return topology

    async def list_topologies(self, project_id: str) -> TopologyListResponse:
        """List all topologies in a project."""
        project = await self._get_or_404(project_id)
        topologies = project.topologies or {}
        items = [Topology.model_validate(t) for t in topologies.values()]
        return TopologyListResponse(topologies=items, total=len(items))

    async def get_topology_by_id(self, project_id: str, topology_id: str) -> Topology:
        """Get a specific topology by ID."""
        project = await self._get_or_404(project_id)
        topologies = project.topologies or {}
        if topology_id not in topologies:
            raise HTTPException(status_code=404, detail="Topology not found")
        return Topology.model_validate(topologies[topology_id])

    async def update_topology_by_id(
        self, project_id: str, topology_id: str, req: TopologyUpdateRequest,
    ) -> Topology:
        """Update a specific topology by ID."""
        project = await self._get_or_404(project_id)
        topologies = project.topologies or {}
        if topology_id not in topologies:
            raise HTTPException(status_code=404, detail="Topology not found")

        topology = Topology.model_validate(topologies[topology_id])

        # Guard: live topologies are read-only
        if topology.topology_type == TopologyType.LIVE:
            raise HTTPException(
                status_code=400,
                detail="Live topology is read-only. Clone to experiment.",
            )

        if req.name is not None:
            topology.name = req.name
        if req.deployment_mode is not None:
            topology.deployment_mode = req.deployment_mode
        if req.components is not None:
            topology.components = req.components
        if req.edges is not None:
            topology.edges = req.edges
        if req.base_user_count is not None:
            topology.base_user_count = req.base_user_count
        if req.growth_targets is not None:
            topology.growth_targets = req.growth_targets

        topologies[topology_id] = topology.model_dump(mode="json")
        project.topologies = topologies
        await self.repo.update_project(project)
        return topology

    async def delete_topology(self, project_id: str, topology_id: str):
        """Delete a topology from the project."""
        project = await self._get_or_404(project_id)
        topologies = project.topologies or {}
        if topology_id not in topologies:
            raise HTTPException(status_code=404, detail="Topology not found")

        topology = Topology.model_validate(topologies[topology_id])
        if topology.topology_type == TopologyType.LIVE:
            raise HTTPException(
                status_code=400,
                detail="Live topology is read-only. Clone to experiment.",
            )

        del topologies[topology_id]
        project.topologies = topologies
        await self.repo.update_project(project)

    # ── Clone ───────────────────────────────────────────────────

    async def clone_topology(self, project_id: str, topology_id: str) -> Topology:
        """Clone a live topology into an experimental one."""
        project = await self._get_or_404(project_id)
        topologies = project.topologies or {}
        if topology_id not in topologies:
            raise HTTPException(status_code=404, detail="Topology not found")

        source = Topology.model_validate(topologies[topology_id])
        cloned = source.model_copy(deep=True)
        cloned.id = str(uuid4())
        cloned.name = f"{source.name} (clone)"
        cloned.topology_type = TopologyType.EXPERIMENTAL
        cloned.cloned_from = topology_id

        topologies[cloned.id] = cloned.model_dump(mode="json")
        project.topologies = topologies
        await self.repo.update_project(project)
        return cloned

    # ── Helpers ──────────────────────────────────────────────────

    async def _get_or_404(self, project_id: str) -> Project:
        project = await self.repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")
        return project
