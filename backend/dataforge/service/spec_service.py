from fastapi import HTTPException

from dataforge.data.repository import ProjectRepository
from dataforge.data.model import Project
from dataforge.schemas.compute import ComputeSpec, ComputeSpecUpdateRequest
from dataforge.schemas.cache_spec import CacheSpec, CacheSpecUpdateRequest
from dataforge.schemas.lb_spec import LoadBalancerSpec, LBSpecUpdateRequest
from dataforge.schemas.cdn_spec import CDNSpec, CDNSpecUpdateRequest
from dataforge.schemas.k8s_spec import K8sClusterSpec, K8sSpecUpdateRequest
from dataforge.schemas.docker_spec import DockerContainerSpec, DockerSpecUpdateRequest


class SpecService:
    """Manages Stage 2.1 specs: compute, cache, LB, CDN per topology component."""

    def __init__(self):
        self.repo = ProjectRepository()

    # ── Compute ─────────────────────────────────────────────────

    async def set_compute_spec(self, project_id: str, component_id: str, spec: ComputeSpec) -> ComputeSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.compute_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.compute_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_compute_spec(self, project_id: str, component_id: str) -> ComputeSpec:
        project = await self._get_or_404(project_id)
        specs = project.compute_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Compute spec not found for this component")
        return ComputeSpec.model_validate(specs[component_id])

    async def update_compute_spec(
        self, project_id: str, component_id: str, req: ComputeSpecUpdateRequest,
    ) -> ComputeSpec:
        project = await self._get_or_404(project_id)
        specs = project.compute_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Compute spec not found for this component")

        current = ComputeSpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.compute_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── Cache ───────────────────────────────────────────────────

    async def set_cache_spec(self, project_id: str, component_id: str, spec: CacheSpec) -> CacheSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.cache_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.cache_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_cache_spec(self, project_id: str, component_id: str) -> CacheSpec:
        project = await self._get_or_404(project_id)
        specs = project.cache_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Cache spec not found for this component")
        return CacheSpec.model_validate(specs[component_id])

    async def update_cache_spec(
        self, project_id: str, component_id: str, req: CacheSpecUpdateRequest,
    ) -> CacheSpec:
        project = await self._get_or_404(project_id)
        specs = project.cache_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Cache spec not found for this component")

        current = CacheSpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.cache_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── Load Balancer ───────────────────────────────────────────

    async def set_lb_spec(self, project_id: str, component_id: str, spec: LoadBalancerSpec) -> LoadBalancerSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.lb_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.lb_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_lb_spec(self, project_id: str, component_id: str) -> LoadBalancerSpec:
        project = await self._get_or_404(project_id)
        specs = project.lb_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="LB spec not found for this component")
        return LoadBalancerSpec.model_validate(specs[component_id])

    async def update_lb_spec(
        self, project_id: str, component_id: str, req: LBSpecUpdateRequest,
    ) -> LoadBalancerSpec:
        project = await self._get_or_404(project_id)
        specs = project.lb_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="LB spec not found for this component")

        current = LoadBalancerSpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.lb_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── CDN ─────────────────────────────────────────────────────

    async def set_cdn_spec(self, project_id: str, component_id: str, spec: CDNSpec) -> CDNSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.cdn_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.cdn_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_cdn_spec(self, project_id: str, component_id: str) -> CDNSpec:
        project = await self._get_or_404(project_id)
        specs = project.cdn_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="CDN spec not found for this component")
        return CDNSpec.model_validate(specs[component_id])

    async def update_cdn_spec(
        self, project_id: str, component_id: str, req: CDNSpecUpdateRequest,
    ) -> CDNSpec:
        project = await self._get_or_404(project_id)
        specs = project.cdn_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="CDN spec not found for this component")

        current = CDNSpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.cdn_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── Kubernetes ──────────────────────────────────────────────

    async def set_k8s_spec(self, project_id: str, component_id: str, spec: K8sClusterSpec) -> K8sClusterSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.k8s_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.k8s_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_k8s_spec(self, project_id: str, component_id: str) -> K8sClusterSpec:
        project = await self._get_or_404(project_id)
        specs = project.k8s_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="K8s spec not found for this component")
        return K8sClusterSpec.model_validate(specs[component_id])

    async def update_k8s_spec(
        self, project_id: str, component_id: str, req: K8sSpecUpdateRequest,
    ) -> K8sClusterSpec:
        project = await self._get_or_404(project_id)
        specs = project.k8s_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="K8s spec not found for this component")

        current = K8sClusterSpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.k8s_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── Docker ───────────────────────────────────────────────────

    async def set_docker_spec(self, project_id: str, component_id: str, spec: DockerContainerSpec) -> DockerContainerSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.docker_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.docker_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_docker_spec(self, project_id: str, component_id: str) -> DockerContainerSpec:
        project = await self._get_or_404(project_id)
        specs = project.docker_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Docker spec not found for this component")
        return DockerContainerSpec.model_validate(specs[component_id])

    async def update_docker_spec(
        self, project_id: str, component_id: str, req: DockerSpecUpdateRequest,
    ) -> DockerContainerSpec:
        project = await self._get_or_404(project_id)
        specs = project.docker_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Docker spec not found for this component")

        current = DockerContainerSpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.docker_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── Helpers ─────────────────────────────────────────────────

    async def _get_or_404(self, project_id: str) -> Project:
        project = await self.repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")
        return project

    def _validate_component_exists(self, project: Project, component_id: str):
        """Ensure the component_id exists in the project's topology."""
        if not project.topology:
            raise HTTPException(status_code=400, detail="Topology not configured yet")
        components = project.topology.get("components", [])
        ids = [c["id"] for c in components]
        if component_id not in ids:
            raise HTTPException(
                status_code=404,
                detail=f"Component '{component_id}' not found in topology",
            )
