from fastapi import APIRouter

from dataforge.schemas.db_model import (
    DBModelSpec, DBModelSpecUpdateRequest,
    Entity, EntityCreateRequest, EntityUpdateRequest,
    EntityField, FieldCreateRequest, FieldUpdateRequest,
    Relationship, RelationshipCreateRequest, RelationshipUpdateRequest,
    DBStorageProjection,
)
from dataforge.schemas.topology import Topology
from dataforge.service.db_schema_service import DBSchemaService
from dataforge.service.model_graph import ModelGraph
from dataforge.data.repository import ProjectRepository

db_schema_router = APIRouter(
    prefix="/projects/{project_id}/db/{component_id}",
    tags=["db-schema"],
)


# ── DB model spec ───────────────────────────────────────────────

@db_schema_router.put("", response_model=DBModelSpec)
async def set_db_spec(project_id: str, component_id: str, spec: DBModelSpec):
    service = DBSchemaService()
    return await service.set_db_spec(project_id, component_id, spec)


@db_schema_router.get("", response_model=DBModelSpec)
async def get_db_spec(project_id: str, component_id: str):
    service = DBSchemaService()
    return await service.get_db_spec(project_id, component_id)


@db_schema_router.patch("", response_model=DBModelSpec)
async def update_db_spec(project_id: str, component_id: str, req: DBModelSpecUpdateRequest):
    service = DBSchemaService()
    return await service.update_db_spec(project_id, component_id, req)


# ── Entities ────────────────────────────────────────────────────

@db_schema_router.post("/entities", response_model=Entity)
async def add_entity(project_id: str, component_id: str, req: EntityCreateRequest):
    service = DBSchemaService()
    return await service.add_entity(project_id, component_id, req)


@db_schema_router.put("/entities/{entity_id}", response_model=Entity)
async def update_entity(
    project_id: str, component_id: str, entity_id: str, req: EntityUpdateRequest,
):
    service = DBSchemaService()
    return await service.update_entity(project_id, component_id, entity_id, req)


@db_schema_router.delete("/entities/{entity_id}")
async def delete_entity(project_id: str, component_id: str, entity_id: str):
    service = DBSchemaService()
    await service.delete_entity(project_id, component_id, entity_id)
    return {"message": "Entity deleted", "entity_id": entity_id}


# ── Fields ──────────────────────────────────────────────────────

@db_schema_router.post("/entities/{entity_id}/fields", response_model=EntityField)
async def add_field(project_id: str, component_id: str, entity_id: str, req: FieldCreateRequest):
    service = DBSchemaService()
    return await service.add_field(project_id, component_id, entity_id, req)


@db_schema_router.put("/entities/{entity_id}/fields/{field_id}", response_model=EntityField)
async def update_field(
    project_id: str, component_id: str, entity_id: str, field_id: str, req: FieldUpdateRequest,
):
    service = DBSchemaService()
    return await service.update_field(project_id, component_id, entity_id, field_id, req)


@db_schema_router.delete("/entities/{entity_id}/fields/{field_id}")
async def delete_field(project_id: str, component_id: str, entity_id: str, field_id: str):
    service = DBSchemaService()
    await service.delete_field(project_id, component_id, entity_id, field_id)
    return {"message": "Field deleted", "field_id": field_id}


# ── Relationships ───────────────────────────────────────────────

@db_schema_router.post("/relationships", response_model=Relationship)
async def add_relationship(project_id: str, component_id: str, req: RelationshipCreateRequest):
    service = DBSchemaService()
    return await service.add_relationship(project_id, component_id, req)


@db_schema_router.put("/relationships/{rel_id}", response_model=Relationship)
async def update_relationship(
    project_id: str, component_id: str, rel_id: str, req: RelationshipUpdateRequest,
):
    service = DBSchemaService()
    return await service.update_relationship(project_id, component_id, rel_id, req)


@db_schema_router.delete("/relationships/{rel_id}")
async def delete_relationship(project_id: str, component_id: str, rel_id: str):
    service = DBSchemaService()
    await service.delete_relationship(project_id, component_id, rel_id)
    return {"message": "Relationship deleted", "relationship_id": rel_id}


# ── Validation & Projections ───────────────────────────────────

@db_schema_router.get("/validate")
async def validate_schema(project_id: str, component_id: str):
    service = DBSchemaService()
    errors = await service.validate_schema(project_id, component_id)
    return {"valid": len(errors) == 0, "errors": errors}


@db_schema_router.get("/storage-projection", response_model=DBStorageProjection)
async def get_storage_projection(project_id: str, component_id: str):
    schema_service = DBSchemaService()
    spec = await schema_service.get_db_spec(project_id, component_id)

    repo = ProjectRepository()
    project = await repo.get_project_by_id(project_id)
    user_count = 1000
    if project and project.topology:
        topology = Topology.model_validate(project.topology)
        user_count = topology.base_user_count

    graph = ModelGraph(spec)
    return graph.calculate_storage(user_count)
