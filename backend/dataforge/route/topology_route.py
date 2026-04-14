from fastapi import APIRouter, Depends

from core.middleware import verify_access_token
from dataforge.schemas.topology import (
    Topology, TopologyCreateRequest, TopologyUpdateRequest, TopologyListResponse,
)
from dataforge.service.topology_service import TopologyService

topology_router = APIRouter(prefix="/projects/{project_id}/topology", tags=["topology"])


# ── Legacy single topology endpoints (backward compat) ────────

@topology_router.post("", response_model=Topology)
async def set_topology(project_id: str, req: TopologyCreateRequest):
    service = TopologyService()
    return await service.set_topology(project_id, req)


@topology_router.get("", response_model=Topology)
async def get_topology(project_id: str):
    service = TopologyService()
    return await service.get_topology(project_id)


@topology_router.put("", response_model=Topology)
async def update_topology(project_id: str, req: TopologyUpdateRequest):
    service = TopologyService()
    return await service.update_topology(project_id, req)


@topology_router.post("/collapse", response_model=Topology)
async def collapse_topology(project_id: str):
    service = TopologyService()
    return await service.collapse_topology(project_id)


# ── Multi-topology endpoints ──────────────────────────────────

@topology_router.get("/all", response_model=TopologyListResponse)
async def list_topologies(project_id: str):
    service = TopologyService()
    return await service.list_topologies(project_id)


@topology_router.post("/create", response_model=Topology)
async def create_topology(project_id: str, req: TopologyCreateRequest):
    service = TopologyService()
    return await service.create_topology(project_id, req)


@topology_router.get("/{topology_id}", response_model=Topology)
async def get_topology_by_id(project_id: str, topology_id: str):
    service = TopologyService()
    return await service.get_topology_by_id(project_id, topology_id)


@topology_router.put("/{topology_id}", response_model=Topology)
async def update_topology_by_id(project_id: str, topology_id: str, req: TopologyUpdateRequest):
    service = TopologyService()
    return await service.update_topology_by_id(project_id, topology_id, req)


@topology_router.delete("/{topology_id}")
async def delete_topology(project_id: str, topology_id: str):
    service = TopologyService()
    await service.delete_topology(project_id, topology_id)
    return {"message": "Topology deleted", "topology_id": topology_id}


@topology_router.post("/{topology_id}/clone", response_model=Topology)
async def clone_topology(project_id: str, topology_id: str):
    service = TopologyService()
    return await service.clone_topology(project_id, topology_id)
