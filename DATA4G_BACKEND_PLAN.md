# Data4G --- Backend Implementation Plan

> Detailed plan for evolving the existing FastAPI backend to meet the Data4G requirements.

---

## 1. Current Backend Structure

```
backend/
├── main.py                          # FastAPI app, CORS, Beanie init, router mounts
├── requirements.txt                 # Dependencies
├── .env.dev                         # Dev config
├── core/
│   ├── config.py                    # Settings singleton (.env loading)
│   ├── db_client.py                 # Motor + Beanie initialization
│   ├── middleware.py                # JWT verification
│   ├── access_control.py           # Project/topology authorization
│   ├── utils.py                    # Misc helpers
│   └── schemas/__init__.py         # BaseResponse wrapper
├── users/
│   ├── route/auth_route.py         # Signup, login, verify, password reset, Google OAuth
│   ├── route/user_route.py         # User CRUD, search
│   ├── service/user_service.py     # Auth logic, email, token generation
│   ├── data/model.py               # User Beanie document
│   ├── data/repository.py          # User CRUD operations
│   └── data/schema.py              # Request/response Pydantic models
└── dataforge/
    ├── route/
    │   ├── project_route.py        # Project CRUD
    │   ├── topology_route.py       # Topology CRUD (legacy + multi)
    │   ├── spec_route.py           # Compute/Cache/LB/CDN/K8s/Docker specs
    │   ├── db_schema_route.py      # DB model, entities, fields, relationships
    │   ├── cost_route.py           # Dashboard, growth, compare, hints
    │   ├── reference_route.py      # Databases, regions, providers (hardcoded)
    │   ├── membership_route.py     # Add/remove members, share topologies
    │   └── comparison_route.py     # Topology structural comparison
    ├── service/
    │   ├── project_service.py      # Project lifecycle
    │   ├── topology_service.py     # Topology CRUD + collapse
    │   ├── spec_service.py         # Generic spec CRUD (all types)
    │   ├── db_schema_service.py    # Entity/field/relationship CRUD + validation
    │   ├── model_graph.py          # BFS record propagation, storage/IOPS projection
    │   ├── cost_engine.py          # Hardcoded pricing, dashboard aggregation
    │   ├── membership_service.py   # Member management
    │   └── comparison_service.py   # Topology structural diff
    ├── data/
    │   ├── model.py                # Project + ProjectMember Beanie documents
    │   └── repository.py           # Project + Member CRUD
    └── schemas/
        ├── enums.py                # All enums (30 DBs, component types, field types, etc.)
        ├── topology.py             # TopologyComponent, TopologyEdge, Topology
        ├── project.py              # Project request/response
        ├── compute.py              # ComputeSpec, GPU, Autoscaling, Cost
        ├── cache_spec.py           # CacheSpec, CacheCost
        ├── lb_spec.py              # LoadBalancerSpec, LBCost
        ├── cdn_spec.py             # CDNSpec, CDNCost
        ├── db_model.py             # Entity, Field, Relationship, DBModelSpec, Storage/IOPS
        ├── dashboard.py            # ConsolidatedDashboard, ComponentCost, GrowthProjection
        ├── k8s_spec.py             # K8s cluster, containers, HPA, service
        ├── docker_spec.py          # Docker container, ports, volumes, health check
        ├── membership.py           # Member request/response
        └── comparison.py           # TopologyCompareRequest/Response
```

---

## 2. Target Backend Structure (New / Modified Files)

Files marked with `[NEW]` are entirely new. Files marked with `[MOD]` require modifications. Files marked with `[KEEP]` are unchanged.

```
backend/
├── main.py                                    [MOD] Add new routers, rename app
├── requirements.txt                           [MOD] Add bcrypt, httpx, apscheduler
├── .env.dev                                   [MOD] Add pricing API keys, MCP config
├── core/
│   ├── config.py                              [MOD] Add pricing, MCP, team settings
│   ├── db_client.py                           [MOD] Register new Beanie documents
│   ├── middleware.py                          [KEEP]
│   ├── access_control.py                     [MOD] Add team-level access, live topology guards
│   ├── utils.py                              [KEEP]
│   └── schemas/__init__.py                   [KEEP]
├── users/
│   ├── route/auth_route.py                   [KEEP]
│   ├── route/user_route.py                   [KEEP]
│   ├── service/user_service.py               [MOD] SHA256 -> bcrypt password hashing
│   ├── data/model.py                         [KEEP]
│   ├── data/repository.py                    [KEEP]
│   └── data/schema.py                        [KEEP]
├── teams/                                     [NEW] --- Team & invite system
│   ├── __init__.py
│   ├── route/team_route.py                   [NEW] Team CRUD, invite link generation
│   ├── service/team_service.py               [NEW] Team lifecycle, invite validation
│   ├── data/model.py                         [NEW] Team + TeamInvite Beanie documents
│   ├── data/repository.py                    [NEW] Team + Invite CRUD
│   └── data/schema.py                        [NEW] Team request/response models
├── dataforge/
│   ├── route/
│   │   ├── project_route.py                  [MOD] Add git_repo_url, team binding
│   │   ├── topology_route.py                 [MOD] Add live/experimental type, clone endpoint
│   │   ├── spec_route.py                     [MOD] Add API Gateway, Cron, ServiceMesh, ObjectStore specs
│   │   ├── db_schema_route.py                [KEEP]
│   │   ├── cost_route.py                     [MOD] Add traffic simulation endpoints
│   │   ├── reference_route.py                [MOD] Move to DB-backed pricing data
│   │   ├── membership_route.py               [KEEP]
│   │   ├── comparison_route.py               [MOD] Add metric comparison (cost, perf, risk)
│   │   ├── risk_route.py                     [NEW] Risk analysis dashboard endpoints
│   │   ├── mcp_route.py                      [NEW] MCP ingestion webhook endpoints
│   │   ├── export_route.py                   [NEW] PNG/SVG/PDF export endpoints
│   │   └── share_route.py                    [NEW] Shareable link generation/resolution
│   ├── service/
│   │   ├── project_service.py                [MOD] Git repo binding, team association
│   │   ├── topology_service.py               [MOD] Live/experimental split, clone logic
│   │   ├── spec_service.py                   [MOD] Add new spec types
│   │   ├── db_schema_service.py              [KEEP]
│   │   ├── model_graph.py                    [KEEP]
│   │   ├── cost_engine.py                    [MOD] Pricing-table-driven, traffic cascading
│   │   ├── membership_service.py             [KEEP]
│   │   ├── comparison_service.py             [MOD] Add metric comparison
│   │   ├── risk_engine.py                    [NEW] Risk scoring and aggregation
│   │   ├── traffic_simulator.py              [NEW] Cascading traffic model
│   │   ├── mcp_ingestion_service.py          [NEW] Process MCP sync payloads
│   │   ├── pricing_sync_service.py           [NEW] Daily cloud pricing API sync
│   │   ├── export_service.py                 [NEW] Diagram/report generation
│   │   └── share_service.py                  [NEW] Token-based shareable links
│   ├── data/
│   │   ├── model.py                          [MOD] Add new documents (see below)
│   │   └── repository.py                     [MOD] Add new repository classes
│   └── schemas/
│       ├── enums.py                          [MOD] Add new component types, topology types
│       ├── topology.py                       [MOD] Add topology_type field (live/experimental)
│       ├── project.py                        [MOD] Add git_repo_url, team_id
│       ├── compute.py                        [KEEP]
│       ├── cache_spec.py                     [KEEP]
│       ├── lb_spec.py                        [KEEP]
│       ├── cdn_spec.py                       [KEEP]
│       ├── db_model.py                       [KEEP]
│       ├── dashboard.py                      [MOD] Add risk scores to dashboard
│       ├── k8s_spec.py                       [KEEP]
│       ├── docker_spec.py                    [KEEP]
│       ├── membership.py                     [KEEP]
│       ├── comparison.py                     [MOD] Add metric comparison models
│       ├── api_gateway_spec.py               [NEW] API Gateway spec + cost
│       ├── cron_spec.py                      [NEW] Cron/Scheduled Jobs spec
│       ├── object_storage_spec.py            [NEW] Object Storage spec + cost
│       ├── service_mesh_spec.py              [NEW] Service Mesh spec
│       ├── third_party_spec.py               [NEW] Third-party API spec
│       ├── endpoint_metadata.py              [NEW] Per-endpoint metadata (MCP-sourced)
│       ├── risk.py                           [NEW] Risk score, findings, dashboard
│       ├── traffic.py                        [NEW] Traffic simulation input/output
│       ├── mcp.py                            [NEW] MCP sync payload schemas
│       ├── export.py                         [NEW] Export request/response
│       └── share.py                          [NEW] Shareable link models
└── mcp_server/                                [NEW] --- Standalone MCP server package
    ├── __init__.py
    ├── server.py                              [NEW] MCP protocol server entry point
    ├── analyzers/
    │   ├── __init__.py
    │   ├── base.py                            [NEW] Abstract analyzer interface
    │   ├── python_analyzer.py                 [NEW] Django/Flask/FastAPI analysis
    │   ├── nodejs_analyzer.py                 [NEW] Express/NestJS analysis
    │   ├── go_analyzer.py                     [NEW] Gin/Echo/net/http analysis
    │   └── java_analyzer.py                   [NEW] Spring Boot analysis
    ├── detectors/
    │   ├── __init__.py
    │   ├── base.py                            [NEW] Abstract risk detector interface
    │   ├── n_plus_one.py                      [NEW] N+1 query detection
    │   ├── pagination.py                      [NEW] Missing pagination detection
    │   ├── unbounded_fetch.py                 [NEW] Unbounded query detection
    │   ├── full_scan.py                       [NEW] Full table scan detection
    │   ├── missing_index.py                   [NEW] Missing index heuristic
    │   └── race_condition.py                  [NEW] Race condition detection
    └── schemas/
        ├── __init__.py
        └── metadata.py                        [NEW] MCP metadata wire format
```

---

## 3. Detailed Changes by Area

### 3.1 Enums & Shared Types --- `schemas/enums.py` [MOD]

**Add new enums:**

```python
class TopologyType(str, Enum):
    LIVE = "live"             # MCP-synced, read-only
    EXPERIMENTAL = "experimental"  # Cloned from live, editable

class ComponentType(str, Enum):
    # Existing:
    COMPUTE = "compute"
    DATABASE = "database"
    CACHE = "cache"
    LOAD_BALANCER = "load_balancer"
    CDN = "cdn"
    CLIENT = "client"
    OBJECT_STORE = "object_store"
    MESSAGE_QUEUE = "message_queue"
    # New:
    API_GATEWAY = "api_gateway"
    CRON_JOB = "cron_job"
    THIRD_PARTY_API = "third_party_api"
    SERVICE_MESH = "service_mesh"
    KUBERNETES_NODE = "kubernetes_node"

class RiskSeverity(str, Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"

class RiskType(str, Enum):
    N_PLUS_ONE = "n_plus_one"
    MISSING_PAGINATION = "missing_pagination"
    UNBOUNDED_FETCH = "unbounded_fetch"
    FULL_TABLE_SCAN = "full_table_scan"
    MISSING_INDEX = "missing_index"
    INEFFICIENT_JOIN = "inefficient_join"
    RACE_CONDITION = "race_condition"

class SyncMode(str, Enum):
    ON_DEMAND = "on_demand"
    CI_CD = "ci_cd"
```

---

### 3.2 Topology Model --- `schemas/topology.py` [MOD]

**Add `topology_type` and `cloned_from` fields:**

```python
class Topology(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    topology_type: TopologyType = TopologyType.EXPERIMENTAL
    cloned_from: str | None = None  # ID of live topology this was cloned from
    deployment_mode: DeploymentMode = DeploymentMode.MULTI_TIER
    components: list[TopologyComponent] = []
    edges: list[TopologyEdge] = []
    base_user_count: int = Field(default=1000, ge=1)
    growth_targets: list[int] = [1_000, 10_000, 100_000, 1_000_000]
    last_synced_at: datetime | None = None  # For live topologies
    sync_version: int = 0                    # Incremented on each MCP sync
```

**Add clone endpoint in `topology_route.py`:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/projects/{pid}/topology/{tid}/clone` | Clone live -> experimental topology |

**Add access guard:** Live topologies reject all mutation requests (400 "Live topology is read-only. Clone to experiment.").

---

### 3.3 Project Model --- `schemas/project.py` [MOD]

**Add fields:**

```python
class ProjectCreateRequest(BaseModel):
    name: str
    description: str = ""
    git_repo_url: str | None = None     # Git repository URL (1:1 mapping)
    team_id: str | None = None          # Team this project belongs to
    cloud_provider: CloudProvider = CloudProvider.AWS  # Default cloud provider for pricing
```

**In Project document (`data/model.py`):**

```python
class Project(Document):
    # ... existing fields ...
    git_repo_url: str | None = None
    team_id: str | None = None
    cloud_provider: CloudProvider = CloudProvider.AWS
    mcp_config: dict = {}          # MCP sync configuration
    last_mcp_sync_at: datetime | None = None
```

---

### 3.4 New Component Type Schemas [NEW]

#### `schemas/api_gateway_spec.py`

```python
class RateLimitConfig(BaseModel):
    enabled: bool = True
    requests_per_second: int = 100
    burst_size: int = 200
    window_seconds: int = 60

class AuthConfig(BaseModel):
    type: str = "jwt"            # jwt, api_key, oauth2, none
    provider: str | None = None  # Auth0, Cognito, custom

class RoutingRule(BaseModel):
    path_pattern: str            # e.g., "/api/v1/users/*"
    target_component_id: str     # Component to route to
    methods: list[str] = ["GET", "POST", "PUT", "DELETE"]
    strip_prefix: bool = False

class APIGatewaySpec(BaseModel):
    topology_component_id: str
    rate_limiting: RateLimitConfig = RateLimitConfig()
    auth_config: AuthConfig = AuthConfig()
    routing_rules: list[RoutingRule] = []
    cors_enabled: bool = True
    request_logging: bool = True
    estimated_requests_per_second: float = 100.0

class APIGatewayCostBreakdown(BaseModel):
    topology_component_id: str
    request_cost_monthly: float
    data_transfer_cost_monthly: float
    total_monthly: float
```

#### `schemas/cron_spec.py`

```python
class CronSchedule(BaseModel):
    cron_expression: str         # e.g., "0 */6 * * *"
    timezone: str = "UTC"

class CronJobSpec(BaseModel):
    topology_component_id: str
    schedule: CronSchedule
    target_service_component_id: str | None = None
    target_endpoint: str | None = None
    retry_policy: dict = {"max_retries": 3, "backoff_seconds": 60}
    timeout_seconds: int = 300
    estimated_duration_seconds: int = 30
    estimated_compute_cost_per_run: float = 0.01
```

#### `schemas/object_storage_spec.py`

```python
class LifecycleRule(BaseModel):
    name: str
    transition_days: int = 30
    transition_storage_class: str = "GLACIER"
    expiration_days: int | None = None

class ObjectStorageSpec(BaseModel):
    topology_component_id: str
    provider: CloudProvider = CloudProvider.AWS
    estimated_storage_gb: float = 100.0
    estimated_requests_per_month: int = 100_000
    estimated_egress_gb_month: float = 50.0
    access_policy: str = "private"    # private, public-read, custom
    versioning_enabled: bool = False
    lifecycle_rules: list[LifecycleRule] = []

class ObjectStorageCostBreakdown(BaseModel):
    topology_component_id: str
    storage_cost_monthly: float
    request_cost_monthly: float
    egress_cost_monthly: float
    total_monthly: float
```

#### `schemas/service_mesh_spec.py`

```python
class CircuitBreakerConfig(BaseModel):
    enabled: bool = True
    failure_threshold: int = 5
    recovery_timeout_seconds: int = 30
    half_open_requests: int = 3

class ServiceMeshSpec(BaseModel):
    topology_component_id: str
    mtls_enabled: bool = True
    circuit_breaker: CircuitBreakerConfig = CircuitBreakerConfig()
    retry_policy: dict = {"max_retries": 3, "per_try_timeout_seconds": 5}
    load_balancing_algorithm: str = "round_robin"
    observability_enabled: bool = True
    sidecar_cpu_request: str = "100m"
    sidecar_memory_request: str = "128Mi"
```

#### `schemas/third_party_spec.py`

```python
class ThirdPartyAPISpec(BaseModel):
    topology_component_id: str
    url: str = ""
    sla_uptime_percentage: float = 99.9
    expected_latency_ms: float = 200.0
    fallback_behavior: str = "circuit_breaker"  # circuit_breaker, cache_fallback, error
    estimated_calls_per_month: int = 100_000
    cost_per_call: float = 0.0                   # If pay-per-call API
    monthly_subscription_cost: float = 0.0       # If subscription-based
```

---

### 3.5 Endpoint Metadata Schema [NEW] --- `schemas/endpoint_metadata.py`

This is the core MCP-sourced data for server components.

```python
class DBCallMetadata(BaseModel):
    query_type: str              # SELECT, INSERT, UPDATE, DELETE
    target_entity: str           # Table/collection name
    is_paginated: bool = False
    estimated_rows_affected: str | None = None  # "unbounded", "1", "N"
    raw_query_pattern: str | None = None

class CacheCallMetadata(BaseModel):
    operation: str               # GET, SET, DELETE, INVALIDATE
    key_pattern: str             # e.g., "user:{id}:profile"
    ttl_seconds: int | None = None

class ServiceCallMetadata(BaseModel):
    target_service: str          # Service name
    target_endpoint: str         # Endpoint path
    http_method: str = "GET"
    is_async: bool = False       # Sync call or via queue

class QueueInteraction(BaseModel):
    role: str                    # "producer" or "consumer"
    queue_name: str
    message_type: str | None = None

class EndpointMetadata(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    path: str                    # e.g., "/api/v1/users/{id}"
    http_method: str             # GET, POST, PUT, DELETE, PATCH
    handler_function: str        # e.g., "get_user_by_id"
    source_file: str             # e.g., "app/routes/users.py:42"
    db_calls: list[DBCallMetadata] = []
    cache_calls: list[CacheCallMetadata] = []
    service_calls: list[ServiceCallMetadata] = []
    queue_interactions: list[QueueInteraction] = []
    estimated_response_time_ms: float | None = None
    risk_score: float = 0.0
    risk_findings: list[str] = []

class ServerEndpointRegistry(BaseModel):
    """All endpoints for a single server component. MCP-populated."""
    topology_component_id: str
    endpoints: list[EndpointMetadata] = []
    last_synced_at: datetime | None = None
    sync_version: int = 0
```

---

### 3.6 Risk Analysis Schema [NEW] --- `schemas/risk.py`

```python
class RiskFinding(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    endpoint_id: str
    endpoint_path: str
    risk_type: RiskType
    severity: RiskSeverity
    message: str                 # Human-readable description
    source_file: str             # File and line
    code_snippet: str | None = None
    recommendation: str = ""
    detected_at: datetime = Field(default_factory=datetime.utcnow)

class EndpointRiskSummary(BaseModel):
    endpoint_id: str
    endpoint_path: str
    http_method: str
    overall_risk_score: float    # 0.0 - 10.0
    finding_count: int
    critical_count: int
    high_count: int
    medium_count: int
    findings: list[RiskFinding] = []

class RiskDashboard(BaseModel):
    project_id: str
    topology_id: str
    total_endpoints: int
    analyzed_endpoints: int
    overall_risk_score: float    # Weighted average
    risk_distribution: dict[str, int]  # severity -> count
    top_risks: list[EndpointRiskSummary]  # Sorted by score desc
    risk_by_type: dict[str, int]           # risk_type -> count
    last_analyzed_at: datetime | None = None
```

---

### 3.7 Traffic Simulation Schema [NEW] --- `schemas/traffic.py`

```python
class TrafficInput(BaseModel):
    """User-provided QPS at entry-point endpoints."""
    entry_points: list[EntryPointTraffic]

class EntryPointTraffic(BaseModel):
    endpoint_id: str
    requests_per_second: float

class ComponentTrafficLoad(BaseModel):
    """Calculated traffic load on a component after cascade."""
    component_id: str
    component_name: str
    component_type: ComponentType
    total_requests_per_second: float
    breakdown: list[TrafficSource]  # Where traffic comes from

class TrafficSource(BaseModel):
    source_endpoint_id: str
    source_endpoint_path: str
    requests_per_second: float
    multiplier: float            # e.g., 1 request = 3 DB queries -> multiplier=3

class TrafficSimulationResult(BaseModel):
    topology_id: str
    entry_point_total_qps: float
    per_component_load: list[ComponentTrafficLoad]
    bottleneck_components: list[str]  # Components exceeding capacity
    estimated_total_latency_ms: float
    cascade_graph: dict  # JSON-serializable dependency graph with traffic
```

---

### 3.8 MCP Ingestion Schema [NEW] --- `schemas/mcp.py`

```python
class MCPSyncPayload(BaseModel):
    """Payload received from MCP server on each sync."""
    project_id: str
    sync_mode: SyncMode
    language: str                  # python, nodejs, go, java
    framework: str                 # fastapi, django, express, etc.
    orm: str | None = None         # sqlalchemy, prisma, gorm, etc.
    git_commit_sha: str | None = None
    synced_at: datetime = Field(default_factory=datetime.utcnow)

    # Metadata sections
    endpoints: list[EndpointMetadata] = []
    db_models: list[MCPEntityDefinition] = []
    cache_keys: list[MCPCacheKeyDefinition] = []
    service_dependencies: list[MCPServiceDependency] = []
    queue_mappings: list[MCPQueueMapping] = []
    risk_findings: list[RiskFinding] = []

class MCPEntityDefinition(BaseModel):
    entity_name: str
    fields: list[MCPFieldDefinition]
    relationships: list[MCPRelationshipDefinition] = []

class MCPFieldDefinition(BaseModel):
    name: str
    type: str
    is_primary_key: bool = False
    is_foreign_key: bool = False
    references: str | None = None   # "EntityName.field_name"
    is_indexed: bool = False
    is_nullable: bool = True

class MCPRelationshipDefinition(BaseModel):
    source_entity: str
    target_entity: str
    type: str                      # "1:1", "1:N", "N:M"
    foreign_key_field: str | None = None

class MCPCacheKeyDefinition(BaseModel):
    key_pattern: str               # e.g., "user:{id}:profile"
    ttl_seconds: int | None = None
    used_in_endpoints: list[str] = []  # Endpoint paths

class MCPServiceDependency(BaseModel):
    source_service: str
    target_service: str
    communication_type: str        # "http", "grpc", "queue"

class MCPQueueMapping(BaseModel):
    queue_name: str
    producer_endpoints: list[str]  # Endpoint paths
    consumer_services: list[str]   # Service names
    partition_count: int | None = None

class MCPSyncResult(BaseModel):
    sync_id: str
    status: str                    # "success", "partial", "failed"
    endpoints_synced: int
    entities_synced: int
    risk_findings_count: int
    diff_summary: dict             # What changed since last sync
    synced_at: datetime
```

---

### 3.9 Export & Share Schemas [NEW]

#### `schemas/export.py`

```python
class ExportRequest(BaseModel):
    topology_id: str
    format: str                    # "png", "svg", "pdf"
    include_specs: bool = False
    include_cost_summary: bool = False

class ExportResponse(BaseModel):
    download_url: str
    format: str
    generated_at: datetime
    expires_at: datetime           # Temporary URL expiry
```

#### `schemas/share.py`

```python
class ShareLinkCreateRequest(BaseModel):
    resource_type: str             # "topology", "dashboard", "comparison"
    resource_id: str
    expires_in_days: int = 30

class ShareLinkResponse(BaseModel):
    share_token: str
    share_url: str
    resource_type: str
    expires_at: datetime
    created_at: datetime
```

---

### 3.10 Team System [NEW] --- `teams/`

#### `teams/data/model.py`

```python
class Team(Document):
    team_id: str                   # ULID with "team_" prefix
    name: str
    owner_id: str                  # User who created the team
    member_ids: list[str] = []     # User IDs
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

    class Settings:
        name = "teams"

class TeamInvite(Document):
    invite_id: str                 # ULID
    team_id: str
    invited_by: str                # User ID
    invite_token: str              # Unique token for the invite link
    max_uses: int | None = None    # None = unlimited
    use_count: int = 0
    expires_at: datetime | None = None
    created_at: datetime
    is_active: bool = True

    class Settings:
        name = "team_invites"
```

#### `teams/route/team_route.py`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/teams` | Create team |
| GET | `/teams` | List user's teams |
| GET | `/teams/{team_id}` | Get team details |
| PUT | `/teams/{team_id}` | Update team name |
| DELETE | `/teams/{team_id}` | Delete team (owner only) |
| POST | `/teams/{team_id}/invite` | Generate invite link |
| POST | `/teams/join/{invite_token}` | Join team via invite link |
| DELETE | `/teams/{team_id}/members/{user_id}` | Remove member |

---

### 3.11 New API Routes Summary

#### Risk Analysis --- `route/risk_route.py` [NEW]

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/projects/{pid}/risk` | Get risk dashboard for project |
| GET | `/projects/{pid}/risk/endpoints` | List all endpoints with risk scores |
| GET | `/projects/{pid}/risk/endpoints/{eid}` | Get risk details for endpoint |
| GET | `/projects/{pid}/risk/by-type/{risk_type}` | Filter findings by risk type |
| POST | `/projects/{pid}/risk/analyze` | Trigger on-demand risk analysis |

#### MCP Ingestion --- `route/mcp_route.py` [NEW]

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/projects/{pid}/mcp/sync` | Receive MCP sync payload |
| GET | `/projects/{pid}/mcp/status` | Get last sync status |
| GET | `/projects/{pid}/mcp/history` | List sync history |
| GET | `/projects/{pid}/mcp/diff/{sync_id}` | Get diff for a specific sync |

#### Export --- `route/export_route.py` [NEW]

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/projects/{pid}/export` | Generate export (PNG/SVG/PDF) |
| GET | `/exports/{export_id}` | Download generated export |

#### Shareable Links --- `route/share_route.py` [NEW]

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/share` | Create shareable link |
| GET | `/share/{token}` | Resolve shareable link (public, no auth) |
| DELETE | `/share/{token}` | Revoke shareable link |

#### Traffic Simulation --- added to `route/cost_route.py` [MOD]

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/projects/{pid}/simulate/traffic` | Run traffic cascade simulation |
| GET | `/projects/{pid}/simulate/bottlenecks` | Get bottleneck analysis |

---

### 3.12 Service Changes

#### `service/cost_engine.py` [MOD] --- Pricing Table Migration

**Current:** Hardcoded pricing constants in the class body.

**Target:** Load pricing from MongoDB `cloud_pricing` collection, synced daily.

```python
# New: PricingSyncService (scheduled daily)
class PricingSyncService:
    async def sync_aws_pricing(self) -> int:
        """Fetch from AWS Pricing API, upsert into cloud_pricing collection."""

    async def sync_gcp_pricing(self) -> int:
        """Fetch from GCP Cloud Billing API."""

    async def sync_azure_pricing(self) -> int:
        """Fetch from Azure Retail Prices API."""

    async def get_price(self, provider: str, service: str, region: str, sku: str) -> float:
        """Look up a specific price from the local cache."""
```

**CostEngine changes:**
- Replace all hardcoded `COMPUTE_COST_PER_VCPU_HOUR = 0.05` etc. with `await pricing.get_price(...)`.
- Add `_calc_api_gateway_cost()`, `_calc_object_storage_cost()` methods.
- Add traffic-aware cost calculation (QPS-based scaling).

#### `service/traffic_simulator.py` [NEW]

```python
class TrafficSimulator:
    """Cascades traffic through the dependency graph."""

    def __init__(self, topology: Topology, endpoint_registry: dict[str, ServerEndpointRegistry]):
        self.topology = topology
        self.endpoints = endpoint_registry
        self._build_dependency_graph()

    def _build_dependency_graph(self):
        """Build directed graph of component dependencies from endpoint metadata."""

    def simulate(self, entry_points: list[EntryPointTraffic]) -> TrafficSimulationResult:
        """
        For each entry-point endpoint at given QPS:
        1. Look up the endpoint's DB calls, cache calls, service calls
        2. Multiply: 1 request = N db calls + M cache calls + K service calls
        3. Follow service calls to downstream endpoints, repeat
        4. Aggregate total load per component
        5. Identify bottlenecks (load > capacity)
        """

    def _cascade_endpoint(self, endpoint: EndpointMetadata, qps: float, visited: set) -> dict:
        """Recursive cascade through one endpoint's dependencies."""

    def identify_bottlenecks(self, result: TrafficSimulationResult) -> list[str]:
        """Components where load exceeds configured capacity."""
```

#### `service/risk_engine.py` [NEW]

```python
class RiskEngine:
    """Aggregates risk findings from MCP into a dashboard."""

    def calculate_endpoint_risk_score(self, findings: list[RiskFinding]) -> float:
        """Weighted score: critical=10, high=7, medium=4, low=1."""

    def build_dashboard(self, project_id: str, topology_id: str) -> RiskDashboard:
        """Aggregate all endpoint risks into a dashboard."""

    def get_endpoints_by_risk(self, min_score: float = 0.0) -> list[EndpointRiskSummary]:
        """Ranked list of risky endpoints."""

    def filter_by_type(self, risk_type: RiskType) -> list[RiskFinding]:
        """All findings of a specific type."""
```

#### `service/mcp_ingestion_service.py` [NEW]

```python
class MCPIngestionService:
    """Processes MCP sync payloads and updates the live topology."""

    async def process_sync(self, payload: MCPSyncPayload) -> MCPSyncResult:
        """
        1. Validate payload against project
        2. Diff against current state
        3. Upsert endpoint metadata
        4. Upsert DB model entities/fields/relationships
        5. Upsert cache key definitions
        6. Update live topology components/edges
        7. Store risk findings
        8. Update last_synced_at
        9. Return diff summary
        """

    async def _diff_endpoints(self, current: list, incoming: list) -> dict:
        """Compute added/modified/removed endpoints."""

    async def _update_live_topology(self, project_id: str, payload: MCPSyncPayload):
        """Auto-generate/update topology components from MCP metadata."""
```

#### `service/comparison_service.py` [MOD]

**Add metric comparison (not just structural diff):**

```python
class MetricComparison(BaseModel):
    topology_a_id: str
    topology_a_name: str
    topology_b_id: str
    topology_b_name: str
    cost_a: float
    cost_b: float
    cost_delta: float
    cost_delta_percentage: float
    risk_score_a: float
    risk_score_b: float
    performance_a: dict          # Estimated latency, throughput
    performance_b: dict
    component_count_a: int
    component_count_b: int

async def compare_metrics(
    self, project_id: str,
    topology_a_id: str,
    topology_b_id: str
) -> MetricComparison:
    """Compare cost, performance, and risk between two topologies."""
```

---

### 3.13 Password Hashing Fix --- `users/service/user_service.py` [MOD]

**Current (insecure):**
```python
def _hash_password(self, password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()
```

**Target:**
```python
import bcrypt

def _hash_password(self, password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def _verify_password(self, password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())
```

Add `bcrypt` to `requirements.txt`. Existing users will need a password reset on first login after migration (or implement dual-check during transition).

---

### 3.14 MongoDB Document Changes --- `data/model.py` [MOD]

**New documents to register in `db_client.py`:**

```python
# Add to init_db() document_models list:
from teams.data.model import Team, TeamInvite
from dataforge.data.model import (
    Project, ProjectMember,
    EndpointRegistry,      # NEW: Per-server endpoint metadata
    RiskReport,            # NEW: Risk analysis results
    CloudPricing,          # NEW: Cached pricing data
    ShareLink,             # NEW: Shareable link tokens
    MCPSyncLog,            # NEW: MCP sync history
)
```

**New document models:**

```python
class EndpointRegistry(Document):
    project_id: str
    topology_id: str
    component_id: str
    endpoints: list[dict] = []     # Serialized EndpointMetadata
    last_synced_at: datetime | None = None
    sync_version: int = 0
    class Settings:
        name = "endpoint_registries"

class RiskReport(Document):
    project_id: str
    topology_id: str
    findings: list[dict] = []       # Serialized RiskFinding
    overall_score: float = 0.0
    analyzed_at: datetime
    class Settings:
        name = "risk_reports"

class CloudPricing(Document):
    provider: str                    # aws, gcp, azure
    service: str                     # ec2, rds, elasticache, etc.
    region: str
    sku: str
    price_per_unit: float
    unit: str                        # "hour", "GB-month", "request"
    last_updated: datetime
    class Settings:
        name = "cloud_pricing"
        indexes = [
            [("provider", 1), ("service", 1), ("region", 1), ("sku", 1)]
        ]

class ShareLink(Document):
    share_token: str                 # Unique token
    resource_type: str               # topology, dashboard, comparison
    resource_id: str
    project_id: str
    created_by: str                  # User ID
    expires_at: datetime | None = None
    created_at: datetime
    is_active: bool = True
    class Settings:
        name = "share_links"

class MCPSyncLog(Document):
    project_id: str
    sync_mode: str
    sync_id: str
    status: str
    endpoints_synced: int
    entities_synced: int
    risk_findings_count: int
    diff_summary: dict = {}
    synced_at: datetime
    class Settings:
        name = "mcp_sync_logs"
```

---

### 3.15 Requirements.txt Changes [MOD]

**Add:**
```
bcrypt>=4.1.0           # Secure password hashing (replace SHA256)
httpx>=0.27.0           # Async HTTP client for pricing API sync
apscheduler>=3.10.0     # Scheduled jobs (daily pricing sync)
pillow>=10.0.0          # Image generation for PNG export
svgwrite>=1.4.0         # SVG generation for diagram export
weasyprint>=61.0        # PDF generation for reports
mcp>=1.0.0              # MCP Python SDK (for MCP server)
tree-sitter>=0.21.0     # Code parsing for static analysis
```

---

## 4. MCP Server Implementation Plan

The MCP server is a **standalone package** (`mcp_server/`) that can run:
1. Inside the developer's IDE as an MCP server
2. In a CI/CD pipeline as a CLI tool

### 4.1 Architecture

```
mcp_server/
├── server.py               # MCP protocol entry point
├── analyzers/
│   ├── base.py             # Abstract LanguageAnalyzer interface
│   ├── python_analyzer.py  # Python (Django/Flask/FastAPI)
│   ├── nodejs_analyzer.py  # Node.js (Express/NestJS)
│   ├── go_analyzer.py      # Go (Gin/Echo)
│   └── java_analyzer.py    # Java (Spring Boot)
├── detectors/
│   ├── base.py             # Abstract RiskDetector interface
│   ├── n_plus_one.py       # Detects N+1 query patterns
│   ├── pagination.py       # Detects missing pagination
│   ├── unbounded_fetch.py  # Detects unbounded fetches
│   ├── full_scan.py        # Detects full table scans
│   ├── missing_index.py    # Heuristic for missing indexes
│   └── race_condition.py   # Detects race conditions
└── schemas/
    └── metadata.py         # Wire format (matches backend schemas)
```

### 4.2 Analyzer Interface

```python
class LanguageAnalyzer(ABC):
    """Base class for language-specific code analyzers."""

    @abstractmethod
    def detect_framework(self, project_root: str) -> str | None:
        """Detect which framework is used (e.g., 'fastapi', 'django')."""

    @abstractmethod
    def extract_endpoints(self, project_root: str) -> list[EndpointMetadata]:
        """Extract all HTTP endpoints with their handlers."""

    @abstractmethod
    def extract_db_models(self, project_root: str) -> list[MCPEntityDefinition]:
        """Extract ORM model definitions."""

    @abstractmethod
    def extract_cache_keys(self, project_root: str) -> list[MCPCacheKeyDefinition]:
        """Extract cache key patterns and TTLs."""

    @abstractmethod
    def extract_service_dependencies(self, project_root: str) -> list[MCPServiceDependency]:
        """Detect service-to-service calls."""

    @abstractmethod
    def extract_queue_mappings(self, project_root: str) -> list[MCPQueueMapping]:
        """Detect queue producer/consumer patterns."""
```

### 4.3 Risk Detector Interface

```python
class RiskDetector(ABC):
    """Base class for risk detection rules."""

    @abstractmethod
    def detect(self, endpoint: EndpointMetadata, source_code: str) -> list[RiskFinding]:
        """Analyze an endpoint's code for this specific risk pattern."""

    @property
    @abstractmethod
    def risk_type(self) -> RiskType: ...

    @property
    @abstractmethod
    def description(self) -> str: ...
```

### 4.4 Python Analyzer (Example Detail)

```python
class PythonAnalyzer(LanguageAnalyzer):
    """Analyzes Python projects (Django, Flask, FastAPI)."""

    def detect_framework(self, project_root: str) -> str | None:
        # Check imports in main files, requirements.txt, pyproject.toml
        # Return: "fastapi", "django", "flask", or None

    def extract_endpoints(self, project_root: str) -> list[EndpointMetadata]:
        # FastAPI: Parse @app.get/@router.post decorators
        # Django: Parse urlpatterns + view functions
        # Flask: Parse @app.route decorators
        # For each endpoint:
        #   - Walk AST of handler function
        #   - Find ORM calls (db_calls)
        #   - Find cache calls (redis.get/set patterns)
        #   - Find HTTP client calls (service_calls)
        #   - Find queue publish calls (queue_interactions)

    def extract_db_models(self, project_root: str) -> list[MCPEntityDefinition]:
        # SQLAlchemy: Parse class(Base) definitions, Column types, ForeignKey refs
        # Django ORM: Parse class(models.Model) definitions, field types, ForeignKey
```

---

## 5. Implementation Phases (Backend)

### Phase 1 --- Foundation (Weeks 1-3)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 1.1 | Add `TopologyType` enum and `topology_type` field to Topology schema | `schemas/enums.py`, `schemas/topology.py` | Critical |
| 1.2 | Add live topology mutation guard (reject edits on live topologies) | `service/topology_service.py`, `route/topology_route.py` | Critical |
| 1.3 | Add clone endpoint (live -> experimental) | `service/topology_service.py`, `route/topology_route.py` | Critical |
| 1.4 | Add `git_repo_url`, `team_id`, `cloud_provider` to Project | `schemas/project.py`, `data/model.py` | High |
| 1.5 | Add 4 new component types to `ComponentType` enum | `schemas/enums.py` | High |
| 1.6 | Create 5 new spec schemas (API Gateway, Cron, Object Storage, Service Mesh, Third-party) | `schemas/api_gateway_spec.py`, etc. | High |
| 1.7 | Add new spec CRUD to `spec_service.py` and `spec_route.py` | `service/spec_service.py`, `route/spec_route.py` | High |
| 1.8 | Fix password hashing SHA256 -> bcrypt | `users/service/user_service.py`, `requirements.txt` | Medium |
| 1.9 | Create Team module (model, repository, service, route) | `teams/*` | Medium |

### Phase 2 --- MCP Server (Weeks 4-7)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 2.1 | Create MCP server scaffold with protocol handler | `mcp_server/server.py` | Critical |
| 2.2 | Implement `LanguageAnalyzer` base + Python analyzer | `mcp_server/analyzers/` | Critical |
| 2.3 | Implement endpoint metadata schema | `schemas/endpoint_metadata.py` | Critical |
| 2.4 | Create MCP ingestion service + route | `service/mcp_ingestion_service.py`, `route/mcp_route.py` | Critical |
| 2.5 | Create EndpointRegistry document model | `data/model.py` | Critical |
| 2.6 | Implement live topology auto-generation from MCP data | `service/mcp_ingestion_service.py` | High |
| 2.7 | Implement Node.js analyzer | `mcp_server/analyzers/nodejs_analyzer.py` | High |
| 2.8 | Implement Go analyzer | `mcp_server/analyzers/go_analyzer.py` | High |
| 2.9 | Implement Java analyzer | `mcp_server/analyzers/java_analyzer.py` | High |
| 2.10 | MCP metadata versioning and diff computation | `service/mcp_ingestion_service.py` | Medium |

### Phase 3 --- Risk Analysis (Weeks 8-10)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 3.1 | Create risk schemas (RiskFinding, RiskDashboard, etc.) | `schemas/risk.py` | Critical |
| 3.2 | Implement `RiskDetector` base + N+1 detector | `mcp_server/detectors/` | Critical |
| 3.3 | Implement remaining detectors (pagination, unbounded, full scan, index, race) | `mcp_server/detectors/` | High |
| 3.4 | Create RiskEngine service | `service/risk_engine.py` | High |
| 3.5 | Create risk dashboard API routes | `route/risk_route.py` | High |
| 3.6 | Store risk findings in MongoDB | `data/model.py` (RiskReport document) | Medium |

### Phase 4 --- Traffic & Cost Simulation (Weeks 11-14)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 4.1 | Create traffic simulation schemas | `schemas/traffic.py` | Critical |
| 4.2 | Implement TrafficSimulator (dependency graph traversal) | `service/traffic_simulator.py` | Critical |
| 4.3 | Add traffic simulation routes | `route/cost_route.py` | Critical |
| 4.4 | Create CloudPricing document + PricingSyncService | `data/model.py`, `service/pricing_sync_service.py` | High |
| 4.5 | Refactor CostEngine to use pricing tables instead of hardcoded values | `service/cost_engine.py` | High |
| 4.6 | Add cost calculators for new component types | `service/cost_engine.py` | Medium |
| 4.7 | Set up APScheduler for daily pricing sync | `main.py`, `service/pricing_sync_service.py` | Medium |
| 4.8 | Implement metric comparison (cost + performance + risk) | `service/comparison_service.py` | Medium |

### Phase 5 --- Export, Sharing & Polish (Weeks 15-17)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 5.1 | Create export service (PNG via Pillow, SVG via svgwrite) | `service/export_service.py` | Medium |
| 5.2 | Create PDF report generation (WeasyPrint) | `service/export_service.py` | Medium |
| 5.3 | Create ShareLink model + service | `data/model.py`, `service/share_service.py` | Medium |
| 5.4 | Create export and share routes | `route/export_route.py`, `route/share_route.py` | Medium |
| 5.5 | Add risk scores to ConsolidatedDashboard | `schemas/dashboard.py`, `service/cost_engine.py` | Low |
| 5.6 | Remove legacy single-topology routes (backward compat cleanup) | `route/topology_route.py`, `service/topology_service.py` | Low |

---

## 6. API Endpoint Summary (Complete)

### Existing (48 endpoints) --- preserved with modifications noted

### New Endpoints (26 total)

| Category | Count | Endpoints |
|----------|-------|-----------|
| Teams | 8 | CRUD + invite + join + remove member |
| MCP Ingestion | 4 | Sync, status, history, diff |
| Risk Analysis | 5 | Dashboard, endpoints list, endpoint detail, by-type, trigger |
| Traffic Simulation | 2 | Simulate, bottlenecks |
| Topology Clone | 1 | Clone live -> experimental |
| Export | 2 | Generate, download |
| Shareable Links | 3 | Create, resolve, revoke |
| New Spec Types | ~15 | CRUD for API Gateway, Cron, Object Storage, Service Mesh, Third-party (3 each) |

**Total: ~89 endpoints** (48 existing + ~26 new routes + ~15 new spec endpoints)

---

*Overall architecture --> [DATA4G_BASE.md](DATA4G_BASE.md)*
*Frontend implementation plan --> [DATA4G_FRONTEND_PLAN.md](DATA4G_FRONTEND_PLAN.md)*
