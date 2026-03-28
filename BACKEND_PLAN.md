# DataForge — Backend Plan

> Pydantic schemas, FastAPI routes, cost engine, and data flow for two-stage infrastructure modeling

---

## 1. Tech Stack

| Layer          | Technology                           |
|----------------|--------------------------------------|
| Framework      | FastAPI 0.115+                       |
| Validation     | Pydantic v2                          |
| Database       | MongoDB 7+ (Motor + Beanie)          |
| Async          | Python 3.11+ / asyncio               |
| MCP            | mcp Python SDK                       |
| Testing        | pytest + pytest-asyncio              |

---

## 2. Pydantic Schema Design

### 2.0 Shared Enums

```python
# backend/app/models/enums.py

from enum import Enum


class CloudProvider(str, Enum):
    AWS = "aws"
    GCP = "gcp"
    AZURE = "azure"
    SELF_HOSTED = "self_hosted"


class Region(str, Enum):
    US_EAST_1 = "us-east-1"
    US_WEST_2 = "us-west-2"
    EU_WEST_1 = "eu-west-1"
    AP_SOUTH_1 = "ap-south-1"
    AP_SOUTHEAST_1 = "ap-southeast-1"
    # extensible — full list loaded from pricing data


class DeploymentMode(str, Enum):
    SINGLE_INSTANCE = "single_instance"
    MULTI_TIER = "multi_tier"
    DISTRIBUTED = "distributed"


class ComponentType(str, Enum):
    COMPUTE = "compute"
    DATABASE = "database"
    CACHE = "cache"
    LOAD_BALANCER = "load_balancer"
    CDN = "cdn"
    CLIENT = "client"
    OBJECT_STORE = "object_store"
    MESSAGE_QUEUE = "message_queue"


class DatabaseId(str, Enum):
    # SQL
    POSTGRESQL = "postgresql"
    MYSQL = "mysql"
    ORACLE = "oracle"
    SQLSERVER = "sqlserver"
    MARIADB = "mariadb"
    COCKROACHDB = "cockroachdb"
    SQLITE = "sqlite"
    # Document / KV
    MONGODB = "mongodb"
    DYNAMODB = "dynamodb"
    CASSANDRA = "cassandra"
    COUCHDB = "couchdb"
    FIREBASE = "firebase"
    # In-Memory
    REDIS = "redis"
    VALKEY = "valkey"
    MEMCACHED = "memcached"
    DRAGONFLY = "dragonfly"
    # Graph
    NEO4J = "neo4j"
    NEPTUNE = "neptune"
    ARANGODB = "arangodb"
    DGRAPH = "dgraph"
    # Vector
    PINECONE = "pinecone"
    WEAVIATE = "weaviate"
    MILVUS = "milvus"
    QDRANT = "qdrant"
    CHROMADB = "chromadb"
    PGVECTOR = "pgvector"
    # Search
    ELASTICSEARCH = "elasticsearch"
    OPENSEARCH = "opensearch"
    # Time-Series
    INFLUXDB = "influxdb"
    TIMESCALEDB = "timescaledb"


class DatabaseCategory(str, Enum):
    SQL = "sql"
    DOCUMENT_KV = "document_kv"
    IN_MEMORY = "in_memory"
    GRAPH = "graph"
    VECTOR = "vector"
    SEARCH = "search"
    TIME_SERIES = "time_series"


class RelationshipType(str, Enum):
    ONE_TO_ONE = "1:1"
    ONE_TO_MANY = "1:N"
    MANY_TO_MANY = "N:M"


class FieldType(str, Enum):
    STRING = "string"
    TEXT = "text"
    INTEGER = "integer"
    FLOAT = "float"
    DECIMAL = "decimal"
    BOOLEAN = "boolean"
    DATE = "date"
    DATETIME = "datetime"
    TIMESTAMP = "timestamp"
    UUID = "uuid"
    JSON = "json"
    ARRAY = "array"
    BINARY = "binary"
    ENUM = "enum"
    VECTOR = "vector"
    GEOSPATIAL = "geospatial"
    REFERENCE = "reference"


class KeyType(str, Enum):
    PRIMARY = "primary"
    FOREIGN = "foreign"
    COMPOSITE_PRIMARY = "composite_primary"
    NONE = "none"


class IndexType(str, Enum):
    BTREE = "btree"
    HASH = "hash"
    GIN = "gin"
    GIST = "gist"
    FULLTEXT = "fulltext"
    VECTOR_HNSW = "vector_hnsw"
    VECTOR_IVFFLAT = "vector_ivfflat"


class GPUType(str, Enum):
    NONE = "none"
    T4 = "t4"
    A10G = "a10g"
    A100 = "a100"
    L4 = "l4"
    H100 = "h100"


class LBAlgorithm(str, Enum):
    ROUND_ROBIN = "round_robin"
    LEAST_CONNECTIONS = "least_connections"
    IP_HASH = "ip_hash"
    WEIGHTED = "weighted"


class CDNProvider(str, Enum):
    CLOUDFRONT = "cloudfront"
    CLOUDFLARE = "cloudflare"
    FASTLY = "fastly"
    AKAMAI = "akamai"
    NONE = "none"


class CacheEvictionPolicy(str, Enum):
    LRU = "lru"
    LFU = "lfu"
    TTL = "ttl"
    RANDOM = "random"
    ALLKEYS_LRU = "allkeys_lru"
```

---

### 2.1 Stage 1 — Topology Models

```python
# backend/app/models/topology.py

from pydantic import BaseModel, Field
from uuid import uuid4

from app.models.enums import (
    CloudProvider, ComponentType, DeploymentMode, Region,
)


class GeoLocation(BaseModel):
    """Geographic location for a component or client."""
    region: Region = Region.US_EAST_1
    availability_zones: int = Field(default=1, ge=1, le=6)
    description: str | None = None


class TopologyEdge(BaseModel):
    """Network connection between two topology nodes."""
    id: str = Field(default_factory=lambda: str(uuid4()))
    source_component_id: str
    target_component_id: str
    estimated_bandwidth_mbps: float = 100.0
    estimated_latency_ms: float = 1.0
    description: str | None = None


class TopologyComponent(BaseModel):
    """A high-level infrastructure component in the topology."""
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    type: ComponentType
    enabled: bool = True
    location: GeoLocation = GeoLocation()
    cloud_provider: CloudProvider = CloudProvider.AWS
    description: str | None = None
    tags: dict[str, str] = {}


class Topology(BaseModel):
    """Stage 1 output: the full infrastructure topology."""
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    deployment_mode: DeploymentMode = DeploymentMode.MULTI_TIER
    components: list[TopologyComponent] = []
    edges: list[TopologyEdge] = []
    base_user_count: int = Field(default=1000, ge=1)
    growth_targets: list[int] = [1_000, 10_000, 100_000, 1_000_000]

    def get_components_by_type(self, ctype: ComponentType) -> list[TopologyComponent]:
        return [c for c in self.components if c.type == ctype and c.enabled]

    def collapse_to_single_instance(self) -> "Topology":
        """Disable LB, CDN, and reduce to 1 compute node."""
        collapsed = self.model_copy(deep=True)
        for comp in collapsed.components:
            if comp.type in (ComponentType.LOAD_BALANCER, ComponentType.CDN):
                comp.enabled = False
        collapsed.deployment_mode = DeploymentMode.SINGLE_INSTANCE
        return collapsed
```

---

### 2.2 Stage 2.1 — Compute Spec Models

```python
# backend/app/models/compute.py

from pydantic import BaseModel, Field

from app.models.enums import CloudProvider, GPUType, Region


class GPUSpec(BaseModel):
    """GPU specification for a compute instance."""
    type: GPUType = GPUType.NONE
    count: int = Field(default=0, ge=0)
    vram_gb: float = 0.0


class AutoscalingConfig(BaseModel):
    """Autoscaling rules for compute instances."""
    enabled: bool = False
    min_instances: int = Field(default=1, ge=1)
    max_instances: int = Field(default=1, ge=1)
    target_cpu_utilization: float = Field(default=0.7, ge=0.1, le=1.0)
    target_memory_utilization: float = Field(default=0.8, ge=0.1, le=1.0)
    scale_up_cooldown_seconds: int = 300
    scale_down_cooldown_seconds: int = 300


class ComputeSpec(BaseModel):
    """
    Stage 2.1: Low-level compute specification for a single compute component.
    Tied to a TopologyComponent of type COMPUTE.
    """
    topology_component_id: str
    cpu_cores: int = Field(default=2, ge=1)
    ram_gb: float = Field(default=4.0, ge=0.5)
    gpu: GPUSpec = GPUSpec()
    instance_family: str = "general_purpose"   # e.g., "m5", "c7g", "n2-standard"
    instance_size: str = "medium"              # e.g., "small", "medium", "xlarge"
    os: str = "linux"
    storage_gb: float = Field(default=50.0, ge=10.0)
    cloud_provider: CloudProvider = CloudProvider.AWS
    region: Region = Region.US_EAST_1
    autoscaling: AutoscalingConfig = AutoscalingConfig()

    @property
    def effective_instance_count(self) -> int:
        if self.autoscaling.enabled:
            return self.autoscaling.min_instances
        return 1


class ComputeCostInput(BaseModel):
    """Input to the compute cost calculator."""
    spec: ComputeSpec
    hours_per_month: float = 730.0  # ~365.25 * 24 / 12
    reserved_instance: bool = False
    spot_instance: bool = False


class ComputeCostBreakdown(BaseModel):
    """Cost output for a single compute component."""
    topology_component_id: str
    instance_cost_monthly: float
    gpu_cost_monthly: float = 0.0
    storage_cost_monthly: float = 0.0
    total_monthly: float
    instance_description: str  # e.g., "2x m5.xlarge (4 vCPU, 16 GB)"
```

---

### 2.3 Stage 2.2 — DB Model Spec

```python
# backend/app/models/db_model.py

from pydantic import BaseModel, Field
from uuid import uuid4

from app.models.enums import (
    DatabaseId, FieldType, IndexType, KeyType, RelationshipType,
)


# ── Field & Key Definitions ──────────────────────────────────────────

class FieldKeyConfig(BaseModel):
    """Primary/foreign key configuration for a field."""
    key_type: KeyType = KeyType.NONE
    references_entity_id: str | None = None   # FK target entity
    references_field_id: str | None = None     # FK target field
    on_delete: str = "CASCADE"                 # CASCADE | SET_NULL | RESTRICT | NO_ACTION
    on_update: str = "CASCADE"


class EntityField(BaseModel):
    """A single field in an entity (column / property / node attribute)."""
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    type: FieldType
    required: bool = True
    unique: bool = False
    indexed: bool = False
    key: FieldKeyConfig = FieldKeyConfig()
    default_value: str | None = None
    enum_values: list[str] | None = None
    vector_dimensions: int | None = None
    avg_size_bytes: int = Field(default=64, ge=1)
    description: str | None = None


class EntityIndex(BaseModel):
    """Composite or specialized index on an entity."""
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    field_ids: list[str]
    type: IndexType = IndexType.BTREE
    unique: bool = False


# ── Entity ───────────────────────────────────────────────────────────

class Entity(BaseModel):
    """A table / collection / node type in the data model."""
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    fields: list[EntityField] = []
    indexes: list[EntityIndex] = []
    is_central: bool = False
    description: str | None = None

    @property
    def primary_key_fields(self) -> list[EntityField]:
        return [f for f in self.fields if f.key.key_type in (KeyType.PRIMARY, KeyType.COMPOSITE_PRIMARY)]

    @property
    def foreign_key_fields(self) -> list[EntityField]:
        return [f for f in self.fields if f.key.key_type == KeyType.FOREIGN]

    @property
    def avg_record_size_bytes(self) -> int:
        return sum(f.avg_size_bytes for f in self.fields) if self.fields else 256


# ── Relationship ─────────────────────────────────────────────────────

class Relationship(BaseModel):
    """Directed relationship between two entities with a ratio multiplier."""
    id: str = Field(default_factory=lambda: str(uuid4()))
    source_entity_id: str
    target_entity_id: str
    type: RelationshipType
    ratio: float = Field(ge=0.0, description="e.g., 1 User → 50 Orders means ratio=50")
    fk_field_id: str | None = None  # the FK field on the target entity
    description: str | None = None


# ── DB Model (the full schema for one database node) ─────────────────

class DBModelSpec(BaseModel):
    """
    Stage 2.2: Complete database schema for a single database component.
    Tied to a TopologyComponent of type DATABASE.
    """
    topology_component_id: str
    database_id: DatabaseId = DatabaseId.POSTGRESQL
    entities: list[Entity] = []
    relationships: list[Relationship] = []
    base_user_count: int = Field(default=1000, ge=1)

    def get_entity_by_id(self, entity_id: str) -> Entity | None:
        return next((e for e in self.entities if e.id == entity_id), None)

    def get_central_entity(self) -> Entity | None:
        return next((e for e in self.entities if e.is_central), None)


# ── Space Utilization ────────────────────────────────────────────────

class EntityStorageProjection(BaseModel):
    """Projected storage for a single entity."""
    entity_id: str
    entity_name: str
    record_count: int
    avg_record_size_bytes: int
    data_size_bytes: int
    index_overhead_bytes: int
    total_size_bytes: int


class DBStorageProjection(BaseModel):
    """Aggregated storage projection for the entire DB model."""
    topology_component_id: str
    database_id: DatabaseId
    per_entity: list[EntityStorageProjection]
    total_data_bytes: int
    total_index_bytes: int
    wal_journal_bytes: int
    total_storage_bytes: int
    total_records: int


class DBIOPSProjection(BaseModel):
    """Estimated IOPS for the DB."""
    read_iops: int
    write_iops: int
    total_iops: int
    read_write_ratio: float


class DBCostInput(BaseModel):
    """Input to the DB cost calculator."""
    spec: DBModelSpec
    storage: DBStorageProjection
    iops: DBIOPSProjection
    cloud_provider: str = "aws"
    region: str = "us-east-1"
    backup_retention_days: int = 7
    high_availability: bool = False
    read_replicas: int = 0


class DBCostBreakdown(BaseModel):
    """Cost output for a single database component."""
    topology_component_id: str
    database_id: DatabaseId
    instance_cost_monthly: float
    storage_cost_monthly: float
    iops_cost_monthly: float
    backup_cost_monthly: float
    license_cost_monthly: float = 0.0
    replica_cost_monthly: float = 0.0
    total_monthly: float
    tier_description: str  # e.g., "db.r6g.large (2 vCPU, 16 GB)"
```

---

### 2.4 Cache, LB, CDN Spec Models

```python
# backend/app/models/cache_spec.py

from pydantic import BaseModel, Field

from app.models.enums import CacheEvictionPolicy, DatabaseId


class CacheSpec(BaseModel):
    """Stage 2 spec for a cache component."""
    topology_component_id: str
    cache_database: DatabaseId = DatabaseId.REDIS
    memory_gb: float = Field(default=1.0, ge=0.25)
    eviction_policy: CacheEvictionPolicy = CacheEvictionPolicy.ALLKEYS_LRU
    ttl_seconds: int = 3600
    cluster_nodes: int = Field(default=1, ge=1)
    high_availability: bool = False


class CacheCostBreakdown(BaseModel):
    topology_component_id: str
    memory_cost_monthly: float
    cluster_overhead_monthly: float = 0.0
    total_monthly: float
```

```python
# backend/app/models/lb_spec.py

from pydantic import BaseModel, Field

from app.models.enums import LBAlgorithm


class LoadBalancerSpec(BaseModel):
    """Stage 2 spec for a load balancer component."""
    topology_component_id: str
    algorithm: LBAlgorithm = LBAlgorithm.ROUND_ROBIN
    target_component_ids: list[str] = []
    health_check_interval_seconds: int = 30
    ssl_termination: bool = True
    estimated_requests_per_second: float = 100.0
    estimated_data_processed_gb_month: float = 100.0


class LBCostBreakdown(BaseModel):
    topology_component_id: str
    fixed_cost_monthly: float
    lcu_cost_monthly: float
    data_processing_cost_monthly: float
    total_monthly: float
```

```python
# backend/app/models/cdn_spec.py

from pydantic import BaseModel, Field

from app.models.enums import CDNProvider


class CDNSpec(BaseModel):
    """Stage 2 spec for a CDN component."""
    topology_component_id: str
    provider: CDNProvider = CDNProvider.CLOUDFRONT
    estimated_data_transfer_gb_month: float = 100.0
    estimated_requests_million_month: float = 10.0
    cache_hit_ratio: float = Field(default=0.85, ge=0.0, le=1.0)
    custom_domain: bool = True
    ssl: bool = True


class CDNCostBreakdown(BaseModel):
    topology_component_id: str
    data_transfer_cost_monthly: float
    request_cost_monthly: float
    ssl_cost_monthly: float = 0.0
    total_monthly: float
```

---

### 2.5 Consolidated Dashboard Models

```python
# backend/app/models/dashboard.py

from pydantic import BaseModel

from app.models.enums import ComponentType, DatabaseId


class ComponentCostSummary(BaseModel):
    """Cost summary for one topology component."""
    topology_component_id: str
    component_name: str
    component_type: ComponentType
    total_monthly: float
    details: dict[str, float] = {}  # e.g., {"instance": 150.0, "storage": 30.0}


class CategoryCostSummary(BaseModel):
    """Cost aggregated by category."""
    category: str              # "compute", "storage", "network", "cache", "database"
    total_monthly: float
    percentage: float          # % of total


class GrowthProjection(BaseModel):
    """Cost at a specific user count."""
    user_count: int
    total_monthly: float
    per_component: list[ComponentCostSummary]


class EntityCostDetail(BaseModel):
    """Storage cost attributed to a single entity."""
    entity_id: str
    entity_name: str
    record_count: int
    storage_gb: float
    storage_cost_monthly: float
    percentage_of_db_cost: float


class OptimizationHint(BaseModel):
    """Suggestion to reduce cost."""
    category: str             # "caching", "compute", "storage", "architecture"
    message: str
    estimated_savings_monthly: float
    confidence: float         # 0.0 - 1.0


class ConsolidatedDashboard(BaseModel):
    """The top-level dashboard response combining all cost data."""
    project_id: str
    project_name: str
    deployment_mode: str
    base_user_count: int

    # Totals
    total_monthly_cost: float

    # Breakdowns
    per_component: list[ComponentCostSummary]
    per_category: list[CategoryCostSummary]
    per_entity_storage: list[EntityCostDetail]

    # Growth
    growth_projections: list[GrowthProjection]

    # Comparison (optional — populated when user selects alt DB)
    comparison_database: DatabaseId | None = None
    comparison_total_monthly: float | None = None
    comparison_delta: float | None = None

    # Hints
    optimization_hints: list[OptimizationHint] = []
```

---

## 3. Core Business Logic

### 3.1 Model Graph Engine (Enhanced)

Extends the existing `ModelGraph` to:
- Accept `DBModelSpec` as input (entities with PK/FK)
- Validate PK/FK referential integrity
- Calculate record counts via BFS from the central entity
- Calculate per-entity storage with index overhead (15-30% based on index count)
- Calculate IOPS from user count + read/write ratio

```python
# backend/app/core/model_graph.py (enhanced)

class ModelGraph:
    def __init__(self, db_spec: DBModelSpec): ...

    def validate_schema(self) -> list[str]:
        """Validate PK/FK referential integrity, central entity, connectivity."""

    def calculate_record_counts(self, user_count: int) -> dict[str, int]:
        """BFS from central entity using relationship ratios."""

    def calculate_storage(self, user_count: int) -> DBStorageProjection:
        """Per-entity storage with index overhead and WAL estimate."""

    def calculate_iops(self, user_count: int, rw_ratio: float = 0.8) -> DBIOPSProjection:
        """IOPS derived from user count and read/write ratio."""
```

### 3.2 Cost Aggregator

```python
# backend/app/core/cost_aggregator.py

class CostAggregator:
    """Aggregates per-component costs into the consolidated dashboard."""

    def aggregate(
        self,
        project_id: str,
        project_name: str,
        topology: Topology,
        compute_costs: list[ComputeCostBreakdown],
        db_costs: list[DBCostBreakdown],
        cache_costs: list[CacheCostBreakdown],
        lb_costs: list[LBCostBreakdown],
        cdn_costs: list[CDNCostBreakdown],
        entity_details: list[EntityCostDetail],
    ) -> ConsolidatedDashboard: ...

    def project_growth(
        self,
        topology: Topology,
        growth_targets: list[int],
    ) -> list[GrowthProjection]:
        """Recalculate costs at each growth target user count."""

    def generate_hints(
        self,
        dashboard: ConsolidatedDashboard,
    ) -> list[OptimizationHint]:
        """Analyze cost breakdown and suggest optimizations."""
```

---

## 4. API Routes

### 4.1 Project & Topology (Stage 1)

| Method | Endpoint                              | Description                       |
|--------|---------------------------------------|-----------------------------------|
| POST   | `/api/v1/projects`                    | Create project with topology      |
| GET    | `/api/v1/projects/{id}`               | Get project                       |
| PUT    | `/api/v1/projects/{id}`               | Update project                    |
| DELETE | `/api/v1/projects/{id}`               | Delete project                    |
| GET    | `/api/v1/projects`                    | List projects                     |
| POST   | `/api/v1/projects/{id}/topology`      | Set/update topology               |
| GET    | `/api/v1/projects/{id}/topology`      | Get topology                      |
| POST   | `/api/v1/projects/{id}/collapse`      | Collapse to single-instance mode  |

### 4.2 Component Specs (Stage 2)

| Method | Endpoint                                        | Description                        |
|--------|--------------------------------------------------|------------------------------------|
| PUT    | `/api/v1/projects/{id}/specs/compute/{cid}`      | Set compute spec for component     |
| GET    | `/api/v1/projects/{id}/specs/compute/{cid}`      | Get compute spec                   |
| PUT    | `/api/v1/projects/{id}/specs/database/{cid}`     | Set DB model spec for component    |
| GET    | `/api/v1/projects/{id}/specs/database/{cid}`     | Get DB model spec                  |
| PUT    | `/api/v1/projects/{id}/specs/cache/{cid}`        | Set cache spec for component       |
| PUT    | `/api/v1/projects/{id}/specs/lb/{cid}`           | Set LB spec for component          |
| PUT    | `/api/v1/projects/{id}/specs/cdn/{cid}`          | Set CDN spec for component         |

### 4.3 DB Schema Design (Stage 2.2 detail)

| Method | Endpoint                                              | Description                        |
|--------|-------------------------------------------------------|------------------------------------|
| POST   | `/api/v1/projects/{id}/db/{cid}/entities`             | Add entity to DB model             |
| PUT    | `/api/v1/projects/{id}/db/{cid}/entities/{eid}`       | Update entity                      |
| DELETE | `/api/v1/projects/{id}/db/{cid}/entities/{eid}`       | Remove entity                      |
| POST   | `/api/v1/projects/{id}/db/{cid}/entities/{eid}/fields`| Add field to entity                |
| PUT    | `/api/v1/projects/{id}/db/{cid}/fields/{fid}`         | Update field (PK/FK/index config)  |
| POST   | `/api/v1/projects/{id}/db/{cid}/relationships`        | Add relationship with ratio        |
| PUT    | `/api/v1/projects/{id}/db/{cid}/relationships/{rid}`  | Update relationship / ratio        |
| DELETE | `/api/v1/projects/{id}/db/{cid}/relationships/{rid}`  | Remove relationship                |
| GET    | `/api/v1/projects/{id}/db/{cid}/validate`             | Validate schema (PK/FK integrity)  |
| GET    | `/api/v1/projects/{id}/db/{cid}/storage-projection`   | Get storage utilization projection  |

### 4.4 Cost & Dashboard

| Method | Endpoint                                       | Description                              |
|--------|-------------------------------------------------|------------------------------------------|
| GET    | `/api/v1/projects/{id}/cost`                    | Get consolidated cost dashboard          |
| GET    | `/api/v1/projects/{id}/cost/breakdown`          | Detailed per-component breakdown         |
| GET    | `/api/v1/projects/{id}/cost/growth`             | Growth projections at target user counts |
| POST   | `/api/v1/projects/{id}/cost/compare`            | Compare cost with alternate DB           |
| GET    | `/api/v1/projects/{id}/cost/per-entity`         | Per-entity storage cost attribution      |
| GET    | `/api/v1/projects/{id}/cost/hints`              | Optimization suggestions                 |

### 4.5 Reference Data

| Method | Endpoint                          | Description                   |
|--------|-----------------------------------|-------------------------------|
| GET    | `/api/v1/databases`               | List all 28 supported DBs     |
| GET    | `/api/v1/databases/{db_id}`       | DB metadata + pricing tiers   |
| GET    | `/api/v1/databases/categories`    | List categories               |
| GET    | `/api/v1/instance-types`          | Available compute instances   |
| GET    | `/api/v1/regions`                 | Available regions + pricing   |

---

## 5. Data Flow: End-to-End Cost Calculation

```
1. User creates project
   └─► POST /api/v1/projects
       Returns: project_id

2. User designs topology (Stage 1)
   └─► POST /api/v1/projects/{id}/topology
       Body: { components: [...], edges: [...], deployment_mode: "multi_tier" }

3. User configures compute (Stage 2.1)
   └─► PUT /api/v1/projects/{id}/specs/compute/{cid}
       Body: { cpu_cores: 4, ram_gb: 16, autoscaling: { enabled: true, max: 5 } }

4. User designs DB schema (Stage 2.2)
   └─► PUT /api/v1/projects/{id}/specs/database/{cid}
       Body: { database_id: "postgresql", entities: [...], relationships: [...] }
       ├── Entities have fields with PK/FK definitions
       └── Relationships have ratios (1 User → 50 Orders → 200 Events)

5. User configures cache, LB, CDN
   └─► PUT /api/v1/projects/{id}/specs/cache/{cid}
   └─► PUT /api/v1/projects/{id}/specs/lb/{cid}
   └─► PUT /api/v1/projects/{id}/specs/cdn/{cid}

6. Backend calculates (on any spec change):
   ├── ModelGraph.calculate_record_counts(base_user_count)
   ├── ModelGraph.calculate_storage(user_count) → DBStorageProjection
   ├── ModelGraph.calculate_iops(user_count) → DBIOPSProjection
   ├── ComputeCostAdapter.estimate(compute_spec) → ComputeCostBreakdown
   ├── DBCostAdapter.estimate(db_cost_input) → DBCostBreakdown
   ├── CacheCostAdapter.estimate(cache_spec) → CacheCostBreakdown
   ├── LBCostAdapter.estimate(lb_spec) → LBCostBreakdown
   └── CDNCostAdapter.estimate(cdn_spec) → CDNCostBreakdown

7. CostAggregator.aggregate(...) → ConsolidatedDashboard
   └─► GET /api/v1/projects/{id}/cost
       Returns full dashboard with breakdowns, growth, hints
```

---

## 6. MongoDB Document Structure

```python
# backend/app/db/documents.py (enhanced)

class ProjectDocument(Document):
    name: str
    description: str = ""
    topology: Topology                  # Stage 1
    compute_specs: list[ComputeSpec] = []   # Stage 2.1
    db_specs: list[DBModelSpec] = []        # Stage 2.2
    cache_specs: list[CacheSpec] = []
    lb_specs: list[LoadBalancerSpec] = []
    cdn_specs: list[CDNSpec] = []
    created_at: datetime
    updated_at: datetime

    class Settings:
        name = "projects"
```

One document = one project = the entire topology + all specs. Single read to load, single write to save.

---

## 7. Implementation Phases

### Phase 1 — Foundation (Sprint 1-2)
- [ ] Pydantic schemas: `enums.py`, `topology.py`, `compute.py`, `db_model.py`
- [ ] MongoDB document model with Beanie
- [ ] Project CRUD routes
- [ ] Topology CRUD routes
- [ ] ModelGraph engine (BFS record counts, storage projection)

### Phase 2 — Cost Engine (Sprint 3-4)
- [ ] Compute cost calculator
- [ ] DB cost adapters: PostgreSQL, MySQL, MongoDB, DynamoDB (first 4)
- [ ] Cache cost calculator (Redis, Valkey)
- [ ] LB and CDN cost calculators
- [ ] CostAggregator → ConsolidatedDashboard
- [ ] Dashboard API routes

### Phase 3 — Remaining Adapters (Sprint 5-6)
- [ ] DB adapters: remaining 24 databases
- [ ] Sharding engine integration
- [ ] Schema export engine
- [ ] Growth projection engine
- [ ] Optimization hints engine

### Phase 4 — Advanced (Sprint 7-8)
- [ ] WebSocket real-time cost updates on spec change
- [ ] MCP server integration
- [ ] DB comparison endpoint
- [ ] Multi-region cost modeling
- [ ] Spot/reserved instance pricing

---

*Overall architecture → [BASE_PLAN.md](BASE_PLAN.md)*
*Frontend dashboard and UI → [FRONTEND_PLAN.md](FRONTEND_PLAN.md)*
