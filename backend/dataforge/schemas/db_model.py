from pydantic import BaseModel, Field
from uuid import uuid4

from dataforge.schemas.enums import (
    DatabaseId, FieldType, IndexType, KeyType, RelationshipType,
)


# ── Field & key definitions ─────────────────────────────────────

class FieldKeyConfig(BaseModel):
    key_type: KeyType = KeyType.NONE
    references_entity_id: str | None = None
    references_field_id: str | None = None
    on_delete: str = "CASCADE"
    on_update: str = "CASCADE"


class EntityField(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    type: FieldType
    required: bool = True
    unique: bool = False
    indexed: bool = False
    key: FieldKeyConfig = Field(default_factory=FieldKeyConfig)
    default_value: str | None = None
    enum_values: list[str] | None = None
    vector_dimensions: int | None = None
    avg_size_bytes: int = Field(default=64, ge=1)
    description: str | None = None


class EntityIndex(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    field_ids: list[str]
    type: IndexType = IndexType.BTREE
    unique: bool = False


# ── Entity ──────────────────────────────────────────────────────

class Entity(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    fields: list[EntityField] = Field(default_factory=list)
    indexes: list[EntityIndex] = Field(default_factory=list)
    is_central: bool = False
    description: str | None = None

    @property
    def primary_key_fields(self) -> list[EntityField]:
        return [
            f for f in self.fields
            if f.key.key_type in (KeyType.PRIMARY, KeyType.COMPOSITE_PRIMARY)
        ]

    @property
    def foreign_key_fields(self) -> list[EntityField]:
        return [f for f in self.fields if f.key.key_type == KeyType.FOREIGN]

    @property
    def avg_record_size_bytes(self) -> int:
        return sum(f.avg_size_bytes for f in self.fields) if self.fields else 256


# ── Relationship ────────────────────────────────────────────────

class Relationship(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    source_entity_id: str
    target_entity_id: str
    type: RelationshipType
    ratio: float = Field(ge=0.0)
    fk_field_id: str | None = None
    description: str | None = None


# ── Request schemas ─────────────────────────────────────────────

class EntityCreateRequest(BaseModel):
    name: str
    fields: list[EntityField] = Field(default_factory=list)
    indexes: list[EntityIndex] = Field(default_factory=list)
    is_central: bool = False
    description: str | None = None


class EntityUpdateRequest(BaseModel):
    name: str | None = None
    fields: list[EntityField] | None = None
    indexes: list[EntityIndex] | None = None
    is_central: bool | None = None
    description: str | None = None


class FieldCreateRequest(BaseModel):
    name: str
    type: FieldType
    required: bool = True
    unique: bool = False
    indexed: bool = False
    key: FieldKeyConfig = Field(default_factory=FieldKeyConfig)
    default_value: str | None = None
    enum_values: list[str] | None = None
    vector_dimensions: int | None = None
    avg_size_bytes: int = Field(default=64, ge=1)
    description: str | None = None


class FieldUpdateRequest(BaseModel):
    name: str | None = None
    type: FieldType | None = None
    required: bool | None = None
    unique: bool | None = None
    indexed: bool | None = None
    key: FieldKeyConfig | None = None
    default_value: str | None = None
    enum_values: list[str] | None = None
    vector_dimensions: int | None = None
    avg_size_bytes: int | None = Field(default=None, ge=1)
    description: str | None = None


class RelationshipCreateRequest(BaseModel):
    source_entity_id: str
    target_entity_id: str
    type: RelationshipType
    ratio: float = Field(ge=0.0)
    fk_field_id: str | None = None
    description: str | None = None


class RelationshipUpdateRequest(BaseModel):
    type: RelationshipType | None = None
    ratio: float | None = Field(default=None, ge=0.0)
    fk_field_id: str | None = None
    description: str | None = None


# ── DB model spec ───────────────────────────────────────────────

class DBModelSpec(BaseModel):
    topology_component_id: str
    database_id: DatabaseId = DatabaseId.POSTGRESQL
    entities: list[Entity] = Field(default_factory=list)
    relationships: list[Relationship] = Field(default_factory=list)
    base_user_count: int = Field(default=1000, ge=1)

    def get_entity_by_id(self, entity_id: str) -> Entity | None:
        return next((e for e in self.entities if e.id == entity_id), None)

    def get_central_entity(self) -> Entity | None:
        return next((e for e in self.entities if e.is_central), None)


class DBModelSpecUpdateRequest(BaseModel):
    database_id: DatabaseId | None = None
    base_user_count: int | None = Field(default=None, ge=1)


# ── Storage & IOPS projections ──────────────────────────────────

class EntityStorageProjection(BaseModel):
    entity_id: str
    entity_name: str
    record_count: int
    avg_record_size_bytes: int
    data_size_bytes: int
    index_overhead_bytes: int
    total_size_bytes: int


class DBStorageProjection(BaseModel):
    topology_component_id: str
    database_id: DatabaseId
    per_entity: list[EntityStorageProjection]
    total_data_bytes: int
    total_index_bytes: int
    wal_journal_bytes: int
    total_storage_bytes: int
    total_records: int


class DBIOPSProjection(BaseModel):
    read_iops: int
    write_iops: int
    total_iops: int
    read_write_ratio: float


# ── Cost models ─────────────────────────────────────────────────

class DBCostInput(BaseModel):
    spec: DBModelSpec
    storage: DBStorageProjection
    iops: DBIOPSProjection
    cloud_provider: str = "aws"
    region: str = "us-east-1"
    backup_retention_days: int = 7
    high_availability: bool = False
    read_replicas: int = 0


class DBCostBreakdown(BaseModel):
    topology_component_id: str
    database_id: DatabaseId
    instance_cost_monthly: float
    storage_cost_monthly: float
    iops_cost_monthly: float
    backup_cost_monthly: float
    license_cost_monthly: float = 0.0
    replica_cost_monthly: float = 0.0
    total_monthly: float
    tier_description: str
