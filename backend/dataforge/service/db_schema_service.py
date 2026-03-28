from uuid import uuid4
from fastapi import HTTPException

from dataforge.data.repository import ProjectRepository
from dataforge.data.model import Project
from dataforge.schemas.db_model import (
    DBModelSpec, DBModelSpecUpdateRequest,
    Entity, EntityCreateRequest, EntityUpdateRequest,
    EntityField, FieldCreateRequest, FieldUpdateRequest,
    Relationship, RelationshipCreateRequest, RelationshipUpdateRequest,
)
from dataforge.schemas.enums import DatabaseId


class DBSchemaService:
    """Manages Stage 2.2: database schema design (entities, fields, relationships)."""

    def __init__(self):
        self.repo = ProjectRepository()

    # ── DB model spec CRUD ──────────────────────────────────────

    async def set_db_spec(self, project_id: str, component_id: str, spec: DBModelSpec) -> DBModelSpec:
        project = await self._get_or_404(project_id)
        self._validate_component_exists(project, component_id)
        specs = project.db_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.db_specs = specs
        await self.repo.update_project(project)
        return spec

    async def get_db_spec(self, project_id: str, component_id: str) -> DBModelSpec:
        project = await self._get_or_404(project_id)
        specs = project.db_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="DB spec not found for this component")
        return DBModelSpec.model_validate(specs[component_id])

    async def update_db_spec(
        self, project_id: str, component_id: str, req: DBModelSpecUpdateRequest,
    ) -> DBModelSpec:
        spec = await self.get_db_spec(project_id, component_id)
        if req.database_id is not None:
            spec.database_id = req.database_id
        if req.base_user_count is not None:
            spec.base_user_count = req.base_user_count
        return await self._save_db_spec(project_id, component_id, spec)

    # ── Entity CRUD ─────────────────────────────────────────────

    async def add_entity(self, project_id: str, component_id: str, req: EntityCreateRequest) -> Entity:
        spec = await self.get_db_spec(project_id, component_id)
        entity = Entity(
            id=str(uuid4()),
            name=req.name,
            fields=req.fields,
            indexes=req.indexes,
            is_central=req.is_central,
            description=req.description,
        )
        spec.entities.append(entity)
        await self._save_db_spec(project_id, component_id, spec)
        return entity

    async def update_entity(
        self, project_id: str, component_id: str, entity_id: str, req: EntityUpdateRequest,
    ) -> Entity:
        spec = await self.get_db_spec(project_id, component_id)
        entity = self._find_entity_or_404(spec, entity_id)

        if req.name is not None:
            entity.name = req.name
        if req.fields is not None:
            entity.fields = req.fields
        if req.indexes is not None:
            entity.indexes = req.indexes
        if req.is_central is not None:
            entity.is_central = req.is_central
        if req.description is not None:
            entity.description = req.description

        await self._save_db_spec(project_id, component_id, spec)
        return entity

    async def delete_entity(self, project_id: str, component_id: str, entity_id: str):
        spec = await self.get_db_spec(project_id, component_id)
        self._find_entity_or_404(spec, entity_id)
        spec.entities = [e for e in spec.entities if e.id != entity_id]
        # Also remove relationships referencing this entity
        spec.relationships = [
            r for r in spec.relationships
            if r.source_entity_id != entity_id and r.target_entity_id != entity_id
        ]
        await self._save_db_spec(project_id, component_id, spec)

    # ── Field CRUD ──────────────────────────────────────────────

    async def add_field(
        self, project_id: str, component_id: str, entity_id: str, req: FieldCreateRequest,
    ) -> EntityField:
        spec = await self.get_db_spec(project_id, component_id)
        entity = self._find_entity_or_404(spec, entity_id)

        field = EntityField(
            id=str(uuid4()),
            name=req.name,
            type=req.type,
            required=req.required,
            unique=req.unique,
            indexed=req.indexed,
            key=req.key,
            default_value=req.default_value,
            enum_values=req.enum_values,
            vector_dimensions=req.vector_dimensions,
            avg_size_bytes=req.avg_size_bytes,
            description=req.description,
        )
        entity.fields.append(field)
        await self._save_db_spec(project_id, component_id, spec)
        return field

    async def update_field(
        self, project_id: str, component_id: str, entity_id: str,
        field_id: str, req: FieldUpdateRequest,
    ) -> EntityField:
        spec = await self.get_db_spec(project_id, component_id)
        entity = self._find_entity_or_404(spec, entity_id)
        field = next((f for f in entity.fields if f.id == field_id), None)
        if not field:
            raise HTTPException(status_code=404, detail="Field not found")

        update_data = req.model_dump(exclude_none=True)
        for key, value in update_data.items():
            setattr(field, key, value)

        await self._save_db_spec(project_id, component_id, spec)
        return field

    async def delete_field(
        self, project_id: str, component_id: str, entity_id: str, field_id: str,
    ):
        spec = await self.get_db_spec(project_id, component_id)
        entity = self._find_entity_or_404(spec, entity_id)
        entity.fields = [f for f in entity.fields if f.id != field_id]
        await self._save_db_spec(project_id, component_id, spec)

    # ── Relationship CRUD ───────────────────────────────────────

    async def add_relationship(
        self, project_id: str, component_id: str, req: RelationshipCreateRequest,
    ) -> Relationship:
        spec = await self.get_db_spec(project_id, component_id)
        # Validate that both entities exist
        self._find_entity_or_404(spec, req.source_entity_id)
        self._find_entity_or_404(spec, req.target_entity_id)

        rel = Relationship(
            id=str(uuid4()),
            source_entity_id=req.source_entity_id,
            target_entity_id=req.target_entity_id,
            type=req.type,
            ratio=req.ratio,
            fk_field_id=req.fk_field_id,
            description=req.description,
        )
        spec.relationships.append(rel)
        await self._save_db_spec(project_id, component_id, spec)
        return rel

    async def update_relationship(
        self, project_id: str, component_id: str, rel_id: str,
        req: RelationshipUpdateRequest,
    ) -> Relationship:
        spec = await self.get_db_spec(project_id, component_id)
        rel = next((r for r in spec.relationships if r.id == rel_id), None)
        if not rel:
            raise HTTPException(status_code=404, detail="Relationship not found")

        if req.type is not None:
            rel.type = req.type
        if req.ratio is not None:
            rel.ratio = req.ratio
        if req.fk_field_id is not None:
            rel.fk_field_id = req.fk_field_id
        if req.description is not None:
            rel.description = req.description

        await self._save_db_spec(project_id, component_id, spec)
        return rel

    async def delete_relationship(self, project_id: str, component_id: str, rel_id: str):
        spec = await self.get_db_spec(project_id, component_id)
        spec.relationships = [r for r in spec.relationships if r.id != rel_id]
        await self._save_db_spec(project_id, component_id, spec)

    # ── Validation ──────────────────────────────────────────────

    async def validate_schema(self, project_id: str, component_id: str) -> list[str]:
        spec = await self.get_db_spec(project_id, component_id)
        from dataforge.service.model_graph import ModelGraph
        graph = ModelGraph(spec)
        return graph.validate()

    # ── Helpers ─────────────────────────────────────────────────

    async def _save_db_spec(self, project_id: str, component_id: str, spec: DBModelSpec) -> DBModelSpec:
        project = await self._get_or_404(project_id)
        specs = project.db_specs or {}
        specs[component_id] = spec.model_dump(mode="json")
        project.db_specs = specs
        await self.repo.update_project(project)
        return spec

    async def _get_or_404(self, project_id: str) -> Project:
        project = await self.repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")
        return project

    def _validate_component_exists(self, project: Project, component_id: str):
        if not project.topology:
            raise HTTPException(status_code=400, detail="Topology not configured yet")
        components = project.topology.get("components", [])
        ids = [c["id"] for c in components]
        if component_id not in ids:
            raise HTTPException(
                status_code=404,
                detail=f"Component '{component_id}' not found in topology",
            )

    def _find_entity_or_404(self, spec: DBModelSpec, entity_id: str) -> Entity:
        entity = spec.get_entity_by_id(entity_id)
        if not entity:
            raise HTTPException(status_code=404, detail="Entity not found")
        return entity
