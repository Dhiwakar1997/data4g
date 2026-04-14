from fastapi import HTTPException

from dataforge.data.repository import ProjectRepository
from dataforge.data.model import Project
from dataforge.schemas.compute import ComputeSpec, ComputeSpecUpdateRequest
from dataforge.schemas.cache_spec import CacheSpec, CacheSpecUpdateRequest
from dataforge.schemas.lb_spec import LoadBalancerSpec, LBSpecUpdateRequest
from dataforge.schemas.cdn_spec import CDNSpec, CDNSpecUpdateRequest
from dataforge.schemas.k8s_spec import K8sClusterSpec, K8sSpecUpdateRequest
from dataforge.schemas.docker_spec import DockerContainerSpec, DockerSpecUpdateRequest
from dataforge.schemas.api_gateway_spec import APIGatewaySpec, APIGatewaySpecUpdateRequest
from dataforge.schemas.cron_spec import CronJobSpec, CronJobSpecUpdateRequest
from dataforge.schemas.object_storage_spec import ObjectStorageSpec, ObjectStorageSpecUpdateRequest
from dataforge.schemas.service_mesh_spec import ServiceMeshSpec, ServiceMeshSpecUpdateRequest
from dataforge.schemas.third_party_spec import ThirdPartyAPISpec, ThirdPartyAPISpecUpdateRequest


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

    # ── API Gateway ─────────────────────────────────────────────

    async def set_api_gateway_spec(self, project_id: str, component_id: str, spec: APIGatewaySpec) -> APIGatewaySpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.api_gateway_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.api_gateway_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_api_gateway_spec(self, project_id: str, component_id: str) -> APIGatewaySpec:
        project = await self._get_or_404(project_id)
        specs = project.api_gateway_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="API Gateway spec not found for this component")
        return APIGatewaySpec.model_validate(specs[component_id])

    async def update_api_gateway_spec(self, project_id: str, component_id: str, req: APIGatewaySpecUpdateRequest) -> APIGatewaySpec:
        project = await self._get_or_404(project_id)
        specs = project.api_gateway_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="API Gateway spec not found for this component")
        current = APIGatewaySpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.api_gateway_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── Cron Job ───────────────────────────────────────────────

    async def set_cron_spec(self, project_id: str, component_id: str, spec: CronJobSpec) -> CronJobSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.cron_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.cron_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_cron_spec(self, project_id: str, component_id: str) -> CronJobSpec:
        project = await self._get_or_404(project_id)
        specs = project.cron_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Cron spec not found for this component")
        return CronJobSpec.model_validate(specs[component_id])

    async def update_cron_spec(self, project_id: str, component_id: str, req: CronJobSpecUpdateRequest) -> CronJobSpec:
        project = await self._get_or_404(project_id)
        specs = project.cron_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Cron spec not found for this component")
        current = CronJobSpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.cron_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── Object Storage ─────────────────────────────────────────

    async def set_object_storage_spec(self, project_id: str, component_id: str, spec: ObjectStorageSpec) -> ObjectStorageSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.object_storage_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.object_storage_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_object_storage_spec(self, project_id: str, component_id: str) -> ObjectStorageSpec:
        project = await self._get_or_404(project_id)
        specs = project.object_storage_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Object Storage spec not found for this component")
        return ObjectStorageSpec.model_validate(specs[component_id])

    async def update_object_storage_spec(self, project_id: str, component_id: str, req: ObjectStorageSpecUpdateRequest) -> ObjectStorageSpec:
        project = await self._get_or_404(project_id)
        specs = project.object_storage_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Object Storage spec not found for this component")
        current = ObjectStorageSpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.object_storage_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── Service Mesh ───────────────────────────────────────────

    async def set_service_mesh_spec(self, project_id: str, component_id: str, spec: ServiceMeshSpec) -> ServiceMeshSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.service_mesh_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.service_mesh_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_service_mesh_spec(self, project_id: str, component_id: str) -> ServiceMeshSpec:
        project = await self._get_or_404(project_id)
        specs = project.service_mesh_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Service Mesh spec not found for this component")
        return ServiceMeshSpec.model_validate(specs[component_id])

    async def update_service_mesh_spec(self, project_id: str, component_id: str, req: ServiceMeshSpecUpdateRequest) -> ServiceMeshSpec:
        project = await self._get_or_404(project_id)
        specs = project.service_mesh_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Service Mesh spec not found for this component")
        current = ServiceMeshSpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.service_mesh_specs = specs
        await self.repo.update_project(project)
        return updated

    # ── Third-Party API ────────────────────────────────────────

    async def set_third_party_spec(self, project_id: str, component_id: str, spec: ThirdPartyAPISpec) -> ThirdPartyAPISpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.third_party_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.third_party_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_third_party_spec(self, project_id: str, component_id: str) -> ThirdPartyAPISpec:
        project = await self._get_or_404(project_id)
        specs = project.third_party_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Third-party API spec not found for this component")
        return ThirdPartyAPISpec.model_validate(specs[component_id])

    async def update_third_party_spec(self, project_id: str, component_id: str, req: ThirdPartyAPISpecUpdateRequest) -> ThirdPartyAPISpec:
        project = await self._get_or_404(project_id)
        specs = project.third_party_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Third-party API spec not found for this component")
        current = ThirdPartyAPISpec.model_validate(specs[component_id])
        update_data = req.model_dump(exclude_none=True)
        updated = current.model_copy(update=update_data)
        specs[component_id] = updated.model_dump(mode="json")
        project.third_party_specs = specs
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
