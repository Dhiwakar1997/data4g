from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from dataforge.schemas.compute import ComputeSpec, ComputeSpecUpdateRequest
from dataforge.schemas.cache_spec import CacheSpec, CacheSpecUpdateRequest
from dataforge.schemas.lb_spec import LoadBalancerSpec, LBSpecUpdateRequest
from dataforge.schemas.cdn_spec import CDNSpec, CDNSpecUpdateRequest
from dataforge.schemas.k8s_spec import K8sClusterSpec, K8sSpecUpdateRequest
from dataforge.schemas.docker_spec import DockerContainerSpec, DockerSpecUpdateRequest
from dataforge.service.spec_service import SpecService

spec_router = APIRouter(prefix="/projects/{project_id}/specs", tags=["specs"])


# ── Compute ─────────────────────────────────────────────────────

@spec_router.put("/compute/{component_id}", response_model=ComputeSpec)
async def set_compute_spec(project_id: str, component_id: str, spec: ComputeSpec):
    service = SpecService()
    return await service.set_compute_spec(project_id, component_id, spec)


@spec_router.get("/compute/{component_id}", response_model=ComputeSpec)
async def get_compute_spec(project_id: str, component_id: str):
    service = SpecService()
    return await service.get_compute_spec(project_id, component_id)


@spec_router.patch("/compute/{component_id}", response_model=ComputeSpec)
async def update_compute_spec(project_id: str, component_id: str, req: ComputeSpecUpdateRequest):
    service = SpecService()
    return await service.update_compute_spec(project_id, component_id, req)


# ── Cache ───────────────────────────────────────────────────────

@spec_router.put("/cache/{component_id}", response_model=CacheSpec)
async def set_cache_spec(project_id: str, component_id: str, spec: CacheSpec):
    service = SpecService()
    return await service.set_cache_spec(project_id, component_id, spec)


@spec_router.get("/cache/{component_id}", response_model=CacheSpec)
async def get_cache_spec(project_id: str, component_id: str):
    service = SpecService()
    return await service.get_cache_spec(project_id, component_id)


@spec_router.patch("/cache/{component_id}", response_model=CacheSpec)
async def update_cache_spec(project_id: str, component_id: str, req: CacheSpecUpdateRequest):
    service = SpecService()
    return await service.update_cache_spec(project_id, component_id, req)


# ── Load Balancer ───────────────────────────────────────────────

@spec_router.put("/lb/{component_id}", response_model=LoadBalancerSpec)
async def set_lb_spec(project_id: str, component_id: str, spec: LoadBalancerSpec):
    service = SpecService()
    return await service.set_lb_spec(project_id, component_id, spec)


@spec_router.get("/lb/{component_id}", response_model=LoadBalancerSpec)
async def get_lb_spec(project_id: str, component_id: str):
    service = SpecService()
    return await service.get_lb_spec(project_id, component_id)


@spec_router.patch("/lb/{component_id}", response_model=LoadBalancerSpec)
async def update_lb_spec(project_id: str, component_id: str, req: LBSpecUpdateRequest):
    service = SpecService()
    return await service.update_lb_spec(project_id, component_id, req)


# ── CDN ─────────────────────────────────────────────────────────

@spec_router.put("/cdn/{component_id}", response_model=CDNSpec)
async def set_cdn_spec(project_id: str, component_id: str, spec: CDNSpec):
    service = SpecService()
    return await service.set_cdn_spec(project_id, component_id, spec)


@spec_router.get("/cdn/{component_id}", response_model=CDNSpec)
async def get_cdn_spec(project_id: str, component_id: str):
    service = SpecService()
    return await service.get_cdn_spec(project_id, component_id)


@spec_router.patch("/cdn/{component_id}", response_model=CDNSpec)
async def update_cdn_spec(project_id: str, component_id: str, req: CDNSpecUpdateRequest):
    service = SpecService()
    return await service.update_cdn_spec(project_id, component_id, req)


# ── Kubernetes ─────────────────────────────────────────────────

@spec_router.put("/k8s/{component_id}", response_model=K8sClusterSpec)
async def set_k8s_spec(project_id: str, component_id: str, spec: K8sClusterSpec):
    service = SpecService()
    return await service.set_k8s_spec(project_id, component_id, spec)


@spec_router.get("/k8s/{component_id}", response_model=K8sClusterSpec)
async def get_k8s_spec(project_id: str, component_id: str):
    service = SpecService()
    return await service.get_k8s_spec(project_id, component_id)


@spec_router.patch("/k8s/{component_id}", response_model=K8sClusterSpec)
async def update_k8s_spec(project_id: str, component_id: str, req: K8sSpecUpdateRequest):
    service = SpecService()
    return await service.update_k8s_spec(project_id, component_id, req)


# ── Docker ─────────────────────────────────────────────────────

@spec_router.put("/docker/{component_id}", response_model=DockerContainerSpec)
async def set_docker_spec(project_id: str, component_id: str, spec: DockerContainerSpec):
    service = SpecService()
    return await service.set_docker_spec(project_id, component_id, spec)


@spec_router.get("/docker/{component_id}", response_model=DockerContainerSpec)
async def get_docker_spec(project_id: str, component_id: str):
    service = SpecService()
    return await service.get_docker_spec(project_id, component_id)


@spec_router.patch("/docker/{component_id}", response_model=DockerContainerSpec)
async def update_docker_spec(project_id: str, component_id: str, req: DockerSpecUpdateRequest):
    service = SpecService()
    return await service.update_docker_spec(project_id, component_id, req)
