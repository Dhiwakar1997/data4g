# DataForge — Agent Build Guide

> **Stack: Python (FastAPI) + MongoDB + Flutter**
>
> The open-source data modelling & infrastructure cost planner. Design schemas, plan sharding, architect caching, and forecast cost as you scale — across 28 databases, exposed as an MCP server.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Tech Stack & Dependencies](#3-tech-stack--dependencies)
4. [Database Taxonomy & Classification](#4-database-taxonomy--classification)
5. [Backend: FastAPI Application](#5-backend-fastapi-application)
6. [MongoDB Data Layer](#6-mongodb-data-layer)
7. [Core Engine: Models & Graph](#7-core-engine-models--graph)
8. [Pricing Engine: 28 DB Adapters](#8-pricing-engine-28-db-adapters)
9. [Sharding Engine](#9-sharding-engine)
10. [Caching Engine](#10-caching-engine)
11. [Schema Export Engine](#11-schema-export-engine)
12. [API Routes & Contracts](#12-api-routes--contracts)
13. [WebSocket Real-Time Updates](#13-websocket-real-time-updates)
14. [MCP Server Integration](#14-mcp-server-integration)
15. [Frontend: Flutter Application](#15-frontend-flutter-application)
16. [State Management (Riverpod)](#16-state-management-riverpod)
17. [Flutter Screens & Widgets](#17-flutter-screens--widgets)
18. [Canvas: Interactive Data Modelling](#18-canvas-interactive-data-modelling)
19. [Data Flow: End-to-End](#19-data-flow-end-to-end)
20. [Testing Strategy](#20-testing-strategy)
21. [Docker & Deployment](#21-docker--deployment)
22. [Sprint Plan & Milestones](#22-sprint-plan--milestones)
23. [Open Source Launch Checklist](#23-open-source-launch-checklist)
24. [Conventions & Code Style](#24-conventions--code-style)

---

## 1. Project Overview

### What is DataForge?

DataForge lets developers and architects:

1. **Design data models visually** — drag-and-drop entities on a canvas, define fields, types, and relationships.
2. **Set record ratios** — define how sub-models relate to a central model (e.g., 1 User → 50 Orders → 200 Events).
3. **Choose a database** — pick from 28 databases across 7 categories (SQL, Document/KV, In-Memory, Graph, Vector, Search, Time-Series).
4. **Plan sharding** — configure shard keys and strategies per database, simulate data distribution, detect hot-spots.
5. **Design caching layers** — plan Redis/Valkey/Memcached/Dragonfly layers with TTLs, eviction policies, memory budgets.
6. **Forecast costs** — real-time cost projections (compute, storage, IOPS, backup, network) that change as user count grows.
7. **Compare databases** — side-by-side cost and capability comparisons across all 28 databases.
8. **Export schemas** — generate Prisma, Mongoose, Cypher, raw SQL DDL, DynamoDB JSON, Elasticsearch mappings.
9. **Run as MCP server** — expose all capabilities as MCP tools for AI assistants (Claude, Cursor, etc.).

### Core Principle

Every architectural decision (adding a field, changing a DB, picking a shard key) should immediately recalculate the cost projection. The cost is the constant heartbeat of the application.

### Distribution

- **pip**: `pip install dataforge` + `dataforge serve` — runs the API + MCP server locally.
- **Docker**: `docker compose up` — runs API + MongoDB + MCP server.
- **Flutter**: Web, macOS, Windows, Linux builds. Published to GitHub Releases.
- **MCP Registry**: Discoverable by AI assistants via tool registries.
- **License**: MIT.

---

## 2. Repository Structure

```
dataforge/
│
├── backend/                          # Python FastAPI backend
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                   # FastAPI app entry point
│   │   ├── config.py                 # Settings (MongoDB URI, etc.)
│   │   │
│   │   ├── models/                   # Pydantic models (request/response schemas)
│   │   │   ├── __init__.py
│   │   │   ├── entity.py             # Entity, Field, Relationship models
│   │   │   ├── project.py            # Project, ShardingConfig, CachingConfig
│   │   │   ├── cost.py               # CostBreakdown, CostEstimateInput, PricingTier
│   │   │   ├── sharding.py           # ShardDistribution, ShardSimulationResult
│   │   │   ├── caching.py            # CacheEstimate, CacheConfig
│   │   │   ├── export.py             # ExportRequest, ExportResult
│   │   │   └── database.py           # DatabaseConfig, DatabaseMetadata, DatabaseId enum
│   │   │
│   │   ├── db/                       # MongoDB data access layer
│   │   │   ├── __init__.py
│   │   │   ├── connection.py         # Motor async client setup
│   │   │   ├── repositories/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── project_repo.py   # Project CRUD
│   │   │   │   ├── template_repo.py  # Template CRUD
│   │   │   │   └── pricing_repo.py   # Pricing data access
│   │   │   └── indexes.py            # MongoDB index definitions
│   │   │
│   │   ├── core/                     # Core business logic
│   │   │   ├── __init__.py
│   │   │   ├── model_graph.py        # ModelGraph engine (DAG, ratio calc)
│   │   │   ├── ratio_calculator.py   # Record count projection from ratios
│   │   │   ├── storage_calculator.py # Total storage + IOPS estimation
│   │   │   └── validators.py         # Schema validation per DB type
│   │   │
│   │   ├── pricing/                  # 28 DB cost model adapters
│   │   │   ├── __init__.py
│   │   │   ├── base.py               # CostAdapter abstract base class
│   │   │   ├── registry.py           # Adapter registry (db_id → adapter)
│   │   │   ├── sql/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── postgresql.py
│   │   │   │   ├── mysql.py
│   │   │   │   ├── oracle.py
│   │   │   │   ├── sqlserver.py
│   │   │   │   ├── mariadb.py
│   │   │   │   ├── cockroachdb.py
│   │   │   │   └── sqlite.py
│   │   │   ├── nosql/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── mongodb_adapter.py
│   │   │   │   ├── dynamodb.py
│   │   │   │   ├── cassandra.py
│   │   │   │   ├── couchdb.py
│   │   │   │   └── firebase.py
│   │   │   ├── memory/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── redis_adapter.py
│   │   │   │   ├── valkey.py
│   │   │   │   ├── memcached.py
│   │   │   │   └── dragonfly.py
│   │   │   ├── graph/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── neo4j.py
│   │   │   │   ├── neptune.py
│   │   │   │   ├── arangodb.py
│   │   │   │   └── dgraph.py
│   │   │   ├── vector/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── pinecone.py
│   │   │   │   ├── weaviate.py
│   │   │   │   ├── milvus.py
│   │   │   │   ├── qdrant.py
│   │   │   │   ├── chromadb.py
│   │   │   │   └── pgvector.py
│   │   │   ├── search/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── elasticsearch.py
│   │   │   │   └── opensearch.py
│   │   │   └── timeseries/
│   │   │       ├── __init__.py
│   │   │       ├── influxdb.py
│   │   │       └── timescaledb.py
│   │   │
│   │   ├── sharding/                 # Shard simulation engine
│   │   │   ├── __init__.py
│   │   │   ├── simulator.py          # Distribution simulation
│   │   │   ├── hotspot_detector.py   # Hot-spot analysis
│   │   │   └── strategies.py         # Per-DB shard strategy definitions
│   │   │
│   │   ├── caching/                  # Cache planning engine
│   │   │   ├── __init__.py
│   │   │   ├── estimator.py          # Cache size & cost estimation
│   │   │   └── strategies.py         # Eviction policy recommendations
│   │   │
│   │   ├── export/                   # Schema export engine
│   │   │   ├── __init__.py
│   │   │   ├── base.py               # ExportEngine abstract base
│   │   │   ├── sql_ddl.py
│   │   │   ├── prisma.py
│   │   │   ├── mongoose.py
│   │   │   ├── cypher.py
│   │   │   ├── dynamodb_json.py
│   │   │   ├── elasticsearch_mapping.py
│   │   │   ├── vector_index.py
│   │   │   ├── cql.py                # Cassandra CQL
│   │   │   ├── influx_schema.py
│   │   │   └── registry.py           # Format → ExportEngine mapping
│   │   │
│   │   ├── routes/                   # FastAPI route modules
│   │   │   ├── __init__.py
│   │   │   ├── projects.py           # /api/v1/projects/*
│   │   │   ├── entities.py           # /api/v1/projects/{id}/entities/*
│   │   │   ├── relationships.py      # /api/v1/projects/{id}/relationships/*
│   │   │   ├── cost.py               # /api/v1/cost/*
│   │   │   ├── sharding.py           # /api/v1/sharding/*
│   │   │   ├── caching.py            # /api/v1/caching/*
│   │   │   ├── export.py             # /api/v1/export/*
│   │   │   ├── databases.py          # /api/v1/databases/*
│   │   │   ├── templates.py          # /api/v1/templates/*
│   │   │   └── ws.py                 # WebSocket endpoint
│   │   │
│   │   └── mcp/                      # MCP server integration
│   │       ├── __init__.py
│   │       ├── server.py             # MCP server setup
│   │       ├── tools/                # MCP tool handlers
│   │       │   ├── __init__.py
│   │       │   ├── create_model.py
│   │       │   ├── set_ratio.py
│   │       │   ├── estimate_cost.py
│   │       │   ├── compare_dbs.py
│   │       │   ├── plan_sharding.py
│   │       │   ├── configure_cache.py
│   │       │   ├── growth_forecast.py
│   │       │   └── export_schema.py
│   │       └── transports.py         # stdio + SSE transport setup
│   │
│   ├── data/
│   │   ├── pricing_tables/           # JSON pricing data per cloud provider
│   │   │   ├── aws_rds_postgresql.json
│   │   │   ├── aws_rds_mysql.json
│   │   │   ├── mongodb_atlas.json
│   │   │   ├── redis_cloud.json
│   │   │   ├── neo4j_aura.json
│   │   │   ├── pinecone.json
│   │   │   ├── elastic_cloud.json
│   │   │   └── ...                   # One file per DB/provider
│   │   └── templates/                # Pre-built project templates
│   │       ├── saas.json
│   │       ├── ecommerce.json
│   │       ├── social.json
│   │       ├── iot.json
│   │       └── ai_app.json
│   │
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── conftest.py               # Fixtures (test DB, test project)
│   │   ├── test_model_graph.py
│   │   ├── test_ratio_calculator.py
│   │   ├── test_pricing/
│   │   │   ├── test_postgresql.py
│   │   │   ├── test_mongodb.py
│   │   │   └── ...                   # One test file per adapter
│   │   ├── test_sharding.py
│   │   ├── test_caching.py
│   │   ├── test_export.py
│   │   ├── test_routes/
│   │   │   ├── test_projects.py
│   │   │   ├── test_cost.py
│   │   │   └── ...
│   │   └── test_mcp.py
│   │
│   ├── pyproject.toml                # Python project config (deps, build)
│   ├── requirements.txt              # Pinned dependencies
│   └── Dockerfile                    # Backend container
│
├── frontend/                         # Flutter application
│   ├── lib/
│   │   ├── main.dart                 # App entry point
│   │   ├── app.dart                  # MaterialApp / router setup
│   │   │
│   │   ├── config/
│   │   │   ├── theme.dart            # App theme (colors, typography)
│   │   │   ├── routes.dart           # GoRouter route definitions
│   │   │   └── constants.dart        # API base URL, etc.
│   │   │
│   │   ├── models/                   # Dart data classes (mirrors backend Pydantic)
│   │   │   ├── entity.dart
│   │   │   ├── field.dart
│   │   │   ├── relationship.dart
│   │   │   ├── project.dart
│   │   │   ├── cost_breakdown.dart
│   │   │   ├── pricing_tier.dart
│   │   │   ├── shard_config.dart
│   │   │   ├── shard_simulation.dart
│   │   │   ├── cache_config.dart
│   │   │   ├── database_config.dart
│   │   │   └── template.dart
│   │   │
│   │   ├── services/                 # API client layer
│   │   │   ├── api_client.dart       # Dio HTTP client setup
│   │   │   ├── project_service.dart
│   │   │   ├── cost_service.dart
│   │   │   ├── sharding_service.dart
│   │   │   ├── caching_service.dart
│   │   │   ├── export_service.dart
│   │   │   ├── database_service.dart
│   │   │   ├── template_service.dart
│   │   │   └── websocket_service.dart # WebSocket connection manager
│   │   │
│   │   ├── providers/                # Riverpod providers
│   │   │   ├── project_provider.dart
│   │   │   ├── canvas_provider.dart
│   │   │   ├── cost_provider.dart
│   │   │   ├── sharding_provider.dart
│   │   │   ├── caching_provider.dart
│   │   │   ├── database_provider.dart
│   │   │   └── template_provider.dart
│   │   │
│   │   ├── screens/                  # Full-page screens
│   │   │   ├── home_screen.dart
│   │   │   ├── project_screen.dart   # Main workspace (canvas + panels)
│   │   │   ├── comparison_screen.dart
│   │   │   ├── templates_screen.dart
│   │   │   └── settings_screen.dart
│   │   │
│   │   ├── widgets/                  # Reusable widgets
│   │   │   ├── canvas/
│   │   │   │   ├── entity_node.dart
│   │   │   │   ├── relationship_edge.dart
│   │   │   │   ├── canvas_view.dart
│   │   │   │   ├── canvas_toolbar.dart
│   │   │   │   └── minimap.dart
│   │   │   ├── panels/
│   │   │   │   ├── entity_editor_panel.dart
│   │   │   │   ├── relationship_editor_panel.dart
│   │   │   │   ├── shard_config_panel.dart
│   │   │   │   ├── cache_config_panel.dart
│   │   │   │   └── export_panel.dart
│   │   │   ├── dashboard/
│   │   │   │   ├── cost_breakdown_card.dart
│   │   │   │   ├── cost_donut_chart.dart
│   │   │   │   ├── growth_chart.dart
│   │   │   │   ├── growth_slider.dart
│   │   │   │   └── comparison_bars.dart
│   │   │   ├── database/
│   │   │   │   ├── db_selector.dart
│   │   │   │   ├── db_category_tabs.dart
│   │   │   │   └── db_info_card.dart
│   │   │   └── common/
│   │   │       ├── app_button.dart
│   │   │       ├── app_text_field.dart
│   │   │       ├── app_dropdown.dart
│   │   │       ├── app_slider.dart
│   │   │       ├── app_card.dart
│   │   │       ├── code_preview.dart
│   │   │       └── loading_indicator.dart
│   │   │
│   │   └── utils/
│   │       ├── formatters.dart       # Currency, bytes, number formatting
│   │       ├── colors.dart           # DB category colors
│   │       └── extensions.dart       # Dart extension methods
│   │
│   ├── test/
│   │   ├── widget_test.dart
│   │   ├── models/
│   │   ├── providers/
│   │   └── services/
│   │
│   ├── pubspec.yaml                  # Flutter dependencies
│   ├── analysis_options.yaml
│   └── web/                          # Web-specific assets
│       ├── index.html
│       └── favicon.png
│
├── docker/
│   ├── docker-compose.yml            # Backend + MongoDB + Frontend (web)
│   ├── docker-compose.dev.yml        # Dev overrides (hot reload, volumes)
│   └── nginx.conf                    # Reverse proxy for production
│
├── docs/
│   ├── README.md
│   ├── api.md                        # API reference (auto-generated from OpenAPI)
│   ├── architecture.md
│   ├── database-guide.md
│   └── mcp-integration.md
│
├── .github/
│   ├── workflows/
│   │   ├── backend-ci.yml            # Python lint + test
│   │   ├── frontend-ci.yml           # Flutter analyze + test
│   │   ├── release.yml               # Docker push + PyPI + GitHub Release
│   │   └── docs.yml                  # Deploy docs
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       ├── feature_request.md
│       └── database_request.md
│
├── README.md
├── CONTRIBUTING.md
├── LICENSE                           # MIT
├── Makefile                          # Top-level convenience commands
└── .env.example                      # Environment variable template
```

---

## 3. Tech Stack & Dependencies

### Backend (Python)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Framework | FastAPI 0.115+ | Async REST API + WebSocket + OpenAPI docs |
| ASGI Server | Uvicorn | Production ASGI server |
| Database | MongoDB 7+ | Project storage, templates, pricing data |
| ODM | Motor (async) + Beanie | Async MongoDB driver + ODM with Pydantic |
| Validation | Pydantic v2 | Request/response schema validation |
| MCP | mcp (Python SDK) | MCP server implementation |
| Testing | pytest + pytest-asyncio | Async test runner |
| Linting | Ruff | Fast Python linter + formatter |
| Type Checking | mypy | Static type analysis |
| Task Runner | Make | Dev commands (make dev, make test, etc.) |

**`pyproject.toml` (key dependencies):**

```toml
[project]
name = "dataforge"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.30.0",
    "motor>=3.6.0",
    "beanie>=1.27.0",
    "pydantic>=2.9.0",
    "pydantic-settings>=2.5.0",
    "websockets>=13.0",
    "mcp>=1.0.0",
    "httpx>=0.27.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.24.0",
    "pytest-cov>=5.0.0",
    "ruff>=0.7.0",
    "mypy>=1.12.0",
    "mongomock-motor>=0.0.34",
]

[project.scripts]
dataforge = "app.main:cli"

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "UP", "B", "SIM", "RUF"]

[tool.mypy]
python_version = "3.11"
strict = true
plugins = ["pydantic.mypy"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

### Frontend (Flutter)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Framework | Flutter 3.24+ | Cross-platform UI (web, macOS, Windows, Linux) |
| Language | Dart 3.5+ | Type-safe frontend language |
| State Management | Riverpod 2.x | Reactive state with providers |
| HTTP Client | Dio | API calls with interceptors |
| WebSocket | web_socket_channel | Real-time updates from backend |
| Routing | GoRouter | Declarative routing |
| Charts | fl_chart | Cost visualizations, growth curves |
| Canvas | Custom (GestureDetector + CustomPainter) | Interactive entity canvas |
| Code Highlighting | flutter_highlight | Schema export preview |
| Persistence | shared_preferences | Local settings cache |

**`pubspec.yaml` (key dependencies):**

```yaml
name: dataforge
description: Data model & infrastructure cost planner
version: 0.1.0

environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.24.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.0
  dio: ^5.7.0
  web_socket_channel: ^3.0.0
  go_router: ^14.3.0
  fl_chart: ^0.69.0
  flutter_highlight: ^0.8.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  uuid: ^4.5.0
  shared_preferences: ^2.3.0
  collection: ^1.18.0
  intl: ^0.19.0
  google_fonts: ^6.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  mockito: ^5.4.0
  mocktail: ^1.0.0
```

### Infrastructure

| Component | Technology |
|-----------|-----------|
| Container | Docker + Docker Compose |
| MongoDB | MongoDB 7 (docker: mongo:7) |
| Reverse Proxy | Nginx (production) |
| CI/CD | GitHub Actions |
| Docs | MkDocs / raw Markdown |

---

## 4. Database Taxonomy & Classification

DataForge classifies databases at two levels: a high-level SQL vs NoSQL split, and a detailed 7-category classification.

### High-Level: SQL vs NoSQL

```
┌──────────────────────────────────────────────────────────────┐
│ SQL (Relational)                                             │
│   PostgreSQL, MySQL, Oracle, SQL Server, MariaDB,            │
│   CockroachDB, SQLite                                        │
├──────────────────────────────────────────────────────────────┤
│ NoSQL (Non-Relational)                                       │
│   Document: MongoDB, CouchDB, Firebase/Firestore             │
│   Key-Value: DynamoDB                                        │
│   Wide-Column: Cassandra                                     │
│   In-Memory: Redis, Valkey, Memcached, Dragonfly             │
│   Graph: Neo4j, Neptune, ArangoDB, Dgraph                    │
│   Vector: Pinecone, Weaviate, Milvus, Qdrant, Chroma,       │
│           pgvector                                           │
│   Search: Elasticsearch, OpenSearch                          │
│   Time-Series: InfluxDB, TimescaleDB                         │
└──────────────────────────────────────────────────────────────┘
```

### Detailed 7-Category Classification

#### Category 1: Disk-Based SQL (Relational)

| Database | Rank | Managed Service | Pricing Model | Sharding | Cost @100K Users |
|----------|------|-----------------|---------------|----------|-----------------|
| Oracle DB | #1 | OCI Autonomous DB | OCPU hrs + storage + license | Native | $500–$2000+ |
| MySQL | #2 | RDS / PlanetScale | Instance hrs + storage | Vitess / ProxySQL | $150–$300 |
| SQL Server | #3 | Azure SQL / RDS | vCore/DTU + storage | Elastic pools | $250–$800 |
| PostgreSQL | #4 | RDS / Aurora / Supabase | Instance hrs + storage + IOPS | Citus / partitioning | $180–$350 |
| SQLite | #10 | Turso (LibSQL) | Free / rows read+written | None (embedded) | $0–$30 |
| MariaDB | #12 | SkySQL / RDS | Instance hrs + storage | Spider / MaxScale | $120–$280 |
| CockroachDB | #25 | CockroachCloud | Request Units + storage | Auto range-based | $200–$500 |

**Agent notes:** Schema = SQL DDL. Cost drivers: instance type, storage GB, IOPS, backup. Sharding is NOT native in most (except Oracle, CockroachDB). Export: raw DDL or Prisma.

#### Category 2: Document & Key-Value (NoSQL)

| Database | Rank | Managed Service | Pricing Model | Sharding | Cost @100K Users |
|----------|------|-----------------|---------------|----------|-----------------|
| MongoDB | #5 | Atlas | Cluster tier + storage + IOPS | Hash / Range keys | $250–$450 |
| DynamoDB | #14 | AWS (native) | RCU/WCU or on-demand | Partition key (auto) | $100–$400 |
| Cassandra | #15 | DataStax Astra | Read Units + storage | Partition key + vnodes | $200–$500 |
| Firebase | #16 | Google (native) | Doc reads/writes + storage | Automatic | $50–$300 |
| CouchDB | #28 | IBM Cloudant | Throughput + storage | Cluster sharding | $80–$250 |

**Agent notes:** Schema-less documents. MongoDB = BSON, export as Mongoose. DynamoDB = partition key + sort key, export as JSON table def. Cost drivers vary wildly across providers.

#### Category 3: In-Memory / Cache

| Database | Status | Managed Service | Pricing Model | Sharding | Cost @100K Users |
|----------|--------|-----------------|---------------|----------|-----------------|
| Redis | AGPL | Redis Cloud / ElastiCache | Memory GB/hr | Cluster (hash slots) | $70–$250 |
| Valkey | BSD-3 (LF fork) | ElastiCache (default) | Node + memory | Cluster (hash slots) | $55–$200 |
| Memcached | BSD | ElastiCache | Node + memory | Client-side hash | $50–$180 |
| Dragonfly | Source-avail. | Dragonfly Cloud | Instance + memory | Built-in cluster | $60–$220 |

**Agent notes:** Caching layer, not primary store. Cost = RAM. Valkey is recommended default (BSD, Redis-compatible). Memcached 8-12% cheaper. Dragonfly claims 25x throughput.

#### Category 4: Graph Databases

| Database | Rank | Managed Service | Pricing Model | Sharding | Cost @100K Users |
|----------|------|-----------------|---------------|----------|-----------------|
| Neo4j | #11 | AuraDB | GB-hour capacity | Fabric (enterprise) | $300–$600 |
| Neptune | #22 | AWS (native) | Instance hrs + I/O | Read replicas | $350–$700 |
| ArangoDB | #26 | ArangoGraph | Node size + storage | SmartGraphs | $200–$500 |
| Dgraph | #30 | Dgraph Cloud | Node + data transfer | Group-based | $150–$400 |

**Agent notes:** Schema = nodes + relationships. Export as Cypher. Cost driven by graph size and traversal depth. Expensive vs relational for same data volume.

#### Category 5: Vector Databases

| Database | Status | Managed Service | Pricing Model | Sharding | Cost @100K Users |
|----------|--------|-----------------|---------------|----------|-----------------|
| Pinecone | Proprietary | Pinecone | $0.33/GB + $8.25/1M reads | Namespace | $65–$400 |
| Weaviate | BSD-3 | Weaviate Cloud ($25+) | Storage-based tiers | Multi-tenant | $85–$350 |
| Milvus | Apache-2 | Zilliz ($0.15/CU/hr) | Compute Units | Segment auto | $65–$660 |
| Qdrant | Apache-2 | Qdrant Cloud ($25+, 1GB free) | Resource tiers | Collection shard | $25–$300 |
| ChromaDB | Apache-2 | Self-hosted | Free (OSS) | None | $0 (infra) |
| pgvector | PG ext. | Supabase / RDS | Same as PG | Same as PG | $180–$350 |

**Agent notes:** Cost depends on vector dimensions × vector count × QPS. Formula: `storage = vectors × dims × 4B`. Export: index config JSON. pgvector simplest if already on PG.

#### Category 6: Search Engines

| Database | Rank | Managed Service | Pricing Model | Sharding | Cost @100K Users |
|----------|------|-----------------|---------------|----------|-----------------|
| Elasticsearch | #9 | Elastic Cloud | Instance + storage + data | Index sharding | $200–$500 |
| OpenSearch | #20 | AWS OpenSearch | Instance + storage | Index sharding | $180–$400 |

#### Category 7: Time-Series

| Database | Rank | Managed Service | Pricing Model | Sharding | Cost @100K Users |
|----------|------|-----------------|---------------|----------|-----------------|
| InfluxDB | #13 | InfluxDB Cloud | Write + query + storage | Tag partitioning | $80–$300 |
| TimescaleDB | #21 | Timescale Cloud | Compute + storage | Hypertable chunks | $100–$350 |

---

## 5. Backend: FastAPI Application

### 5.1 Entry Point

```python
# backend/app/main.py

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.db.connection import init_db, close_db
from app.routes import (
    projects, entities, relationships, cost,
    sharding, caching, export, databases, templates, ws,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await close_db()


app = FastAPI(
    title="DataForge API",
    version="0.1.0",
    description="Data model & infrastructure cost planner API",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(projects.router, prefix="/api/v1/projects", tags=["Projects"])
app.include_router(entities.router, prefix="/api/v1/projects/{project_id}/entities", tags=["Entities"])
app.include_router(relationships.router, prefix="/api/v1/projects/{project_id}/relationships", tags=["Relationships"])
app.include_router(cost.router, prefix="/api/v1/cost", tags=["Cost"])
app.include_router(sharding.router, prefix="/api/v1/sharding", tags=["Sharding"])
app.include_router(caching.router, prefix="/api/v1/caching", tags=["Caching"])
app.include_router(export.router, prefix="/api/v1/export", tags=["Export"])
app.include_router(databases.router, prefix="/api/v1/databases", tags=["Databases"])
app.include_router(templates.router, prefix="/api/v1/templates", tags=["Templates"])
app.include_router(ws.router, prefix="/ws", tags=["WebSocket"])


@app.get("/health")
async def health():
    return {"status": "ok", "version": "0.1.0"}
```

### 5.2 Configuration

```python
# backend/app/config.py

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "DataForge"
    debug: bool = False
    mongodb_uri: str = "mongodb://localhost:27017"
    mongodb_db_name: str = "dataforge"
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8080"]
    mcp_transport: str = "stdio"  # "stdio" or "sse"

    class Config:
        env_file = ".env"
        env_prefix = "DATAFORGE_"


settings = Settings()
```

---

## 6. MongoDB Data Layer

### 6.1 Connection (Motor + Beanie)

```python
# backend/app/db/connection.py

from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from app.config import settings
from app.db.documents import ProjectDocument, TemplateDocument

_client: AsyncIOMotorClient | None = None

async def init_db() -> None:
    global _client
    _client = AsyncIOMotorClient(settings.mongodb_uri)
    await init_beanie(
        database=_client[settings.mongodb_db_name],
        document_models=[ProjectDocument, TemplateDocument],
    )

async def close_db() -> None:
    global _client
    if _client:
        _client.close()
```

### 6.2 Document Models (Beanie)

```python
# backend/app/db/documents.py

from datetime import datetime
from beanie import Document
from pydantic import Field as PydanticField
from app.models.entity import Entity, Relationship
from app.models.project import ShardingConfig, CachingConfig
from app.models.database import DatabaseId


class ProjectDocument(Document):
    name: str
    description: str = ""
    entities: list[Entity] = []
    relationships: list[Relationship] = []
    selected_database: DatabaseId = DatabaseId.POSTGRESQL
    sharding_config: ShardingConfig = ShardingConfig()
    caching_config: CachingConfig = CachingConfig()
    user_count: int = 1000
    growth_targets: list[int] = [1_000, 10_000, 100_000, 1_000_000]
    created_at: datetime = PydanticField(default_factory=datetime.utcnow)
    updated_at: datetime = PydanticField(default_factory=datetime.utcnow)

    class Settings:
        name = "projects"
        indexes = ["name", "selected_database", "created_at"]


class TemplateDocument(Document):
    name: str
    description: str
    category: str
    entities: list[Entity]
    relationships: list[Relationship]
    suggested_databases: list[DatabaseId]
    suggested_caching: CachingConfig | None = None

    class Settings:
        name = "templates"
        indexes = ["name", "category"]
```

**Why MongoDB for DataForge's own backend:** The project data is deeply nested (entities contain fields, relationships reference entities, configs are embedded). A single MongoDB document holds the entire project — one read to load, one write to save. No JOINs needed.

### 6.3 Repository Pattern

```python
# backend/app/db/repositories/project_repo.py

from datetime import datetime
from beanie import PydanticObjectId
from app.db.documents import ProjectDocument
from app.models.entity import Entity, Relationship


class ProjectRepository:

    async def create(self, name: str, description: str = "") -> ProjectDocument:
        project = ProjectDocument(name=name, description=description)
        await project.insert()
        return project

    async def get_by_id(self, project_id: str) -> ProjectDocument | None:
        return await ProjectDocument.get(PydanticObjectId(project_id))

    async def list_all(self, skip: int = 0, limit: int = 50) -> list[ProjectDocument]:
        return await ProjectDocument.find_all().skip(skip).limit(limit).to_list()

    async def update(self, project_id: str, **updates) -> ProjectDocument | None:
        project = await self.get_by_id(project_id)
        if not project:
            return None
        updates["updated_at"] = datetime.utcnow()
        await project.set(updates)
        return project

    async def delete(self, project_id: str) -> bool:
        project = await self.get_by_id(project_id)
        if not project:
            return False
        await project.delete()
        return True

    async def add_entity(self, project_id: str, entity: Entity) -> ProjectDocument | None:
        project = await self.get_by_id(project_id)
        if not project:
            return None
        project.entities.append(entity)
        project.updated_at = datetime.utcnow()
        await project.save()
        return project

    async def add_relationship(self, project_id: str, rel: Relationship) -> ProjectDocument | None:
        project = await self.get_by_id(project_id)
        if not project:
            return None
        project.relationships.append(rel)
        project.updated_at = datetime.utcnow()
        await project.save()
        return project
```

---

## 7. Core Engine: Models & Graph

### 7.1 Pydantic Models

```python
# backend/app/models/entity.py

from enum import Enum
from pydantic import BaseModel, Field
from uuid import uuid4


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


class EntityField(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    type: FieldType
    required: bool = True
    unique: bool = False
    indexed: bool = False
    default_value: str | None = None
    enum_values: list[str] | None = None
    vector_dimensions: int | None = None
    avg_size_bytes: int = 64
    description: str | None = None


class Entity(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    fields: list[EntityField] = []
    is_central: bool = False
    description: str | None = None

    @property
    def avg_record_size_bytes(self) -> int:
        return sum(f.avg_size_bytes for f in self.fields) if self.fields else 256


class RelationshipType(str, Enum):
    ONE_TO_ONE = "1:1"
    ONE_TO_MANY = "1:N"
    MANY_TO_MANY = "N:M"


class Relationship(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    source_entity_id: str
    target_entity_id: str
    type: RelationshipType
    ratio: float
    description: str | None = None
```

### 7.2 Model Graph Engine

```python
# backend/app/core/model_graph.py

from collections import deque
from dataclasses import dataclass
from app.models.entity import Entity, Relationship


@dataclass
class EntityProjection:
    entity_id: str
    entity_name: str
    record_count: int
    storage_bytes: int


@dataclass
class StorageSummary:
    total_bytes: int
    total_records: int
    per_entity: list[EntityProjection]


@dataclass
class IOPSSummary:
    total_read_iops: int
    total_write_iops: int


class ModelGraph:

    def __init__(self, entities: list[Entity], relationships: list[Relationship]):
        self._entities = {e.id: e for e in entities}
        self._relationships = relationships
        self._adjacency: dict[str, list[Relationship]] = {}
        for rel in relationships:
            self._adjacency.setdefault(rel.source_entity_id, []).append(rel)

    def get_central_entity(self) -> Entity | None:
        return next((e for e in self._entities.values() if e.is_central), None)

    def calculate_record_counts(self, user_count: int) -> dict[str, int]:
        """BFS from central entity. Each rel multiplies parent count by ratio."""
        central = self.get_central_entity()
        if not central:
            return {}
        counts: dict[str, int] = {central.id: user_count}
        visited: set[str] = {central.id}
        queue: deque[str] = deque([central.id])
        while queue:
            current_id = queue.popleft()
            for rel in self._adjacency.get(current_id, []):
                tid = rel.target_entity_id
                if tid not in visited:
                    counts[tid] = int(counts[current_id] * rel.ratio)
                    visited.add(tid)
                    queue.append(tid)
        return counts

    def calculate_storage(self, user_count: int) -> StorageSummary:
        counts = self.calculate_record_counts(user_count)
        projections = []
        total_bytes = total_records = 0
        for eid, count in counts.items():
            entity = self._entities[eid]
            size = count * entity.avg_record_size_bytes
            projections.append(EntityProjection(eid, entity.name, count, size))
            total_bytes += size
            total_records += count
        return StorageSummary(total_bytes, total_records, projections)

    def calculate_iops(self, user_count: int, rw_ratio: float = 0.8) -> IOPSSummary:
        ops_per_sec = int(user_count * 10 / 86400)
        return IOPSSummary(int(ops_per_sec * rw_ratio), int(ops_per_sec * (1 - rw_ratio)))

    def validate(self) -> list[str]:
        errors = []
        centrals = [e for e in self._entities.values() if e.is_central]
        if len(centrals) == 0:
            errors.append("No central entity defined.")
        elif len(centrals) > 1:
            errors.append(f"Multiple centrals: {[e.name for e in centrals]}")
        connected = set()
        for r in self._relationships:
            connected.update([r.source_entity_id, r.target_entity_id])
        for eid, e in self._entities.items():
            if eid not in connected and not e.is_central:
                errors.append(f"'{e.name}' is not connected to any entity.")
        return errors
```

---

## 8. Pricing Engine: 28 DB Adapters

### 8.1 Abstract Base

```python
# backend/app/pricing/base.py

from abc import ABC, abstractmethod
from app.models.database import DatabaseId, DatabaseCategory, DatabaseMetadata
from app.models.cost import CostBreakdown, CostEstimateInput, PricingTier, ShardingOption


class CostAdapter(ABC):
    @property
    @abstractmethod
    def db_id(self) -> DatabaseId: ...

    @property
    @abstractmethod
    def db_name(self) -> str: ...

    @property
    @abstractmethod
    def category(self) -> DatabaseCategory: ...

    @abstractmethod
    def estimate_cost(self, input: CostEstimateInput) -> CostBreakdown: ...

    @abstractmethod
    def get_available_tiers(self) -> list[PricingTier]: ...

    @abstractmethod
    def suggest_tier(self, input: CostEstimateInput) -> PricingTier: ...

    @abstractmethod
    def get_sharding_options(self) -> list[ShardingOption]: ...

    @abstractmethod
    def get_metadata(self) -> DatabaseMetadata: ...
```

### 8.2 Registry

```python
# backend/app/pricing/registry.py

from app.pricing.base import CostAdapter
from app.models.database import DatabaseId, DatabaseCategory

_adapters: dict[DatabaseId, CostAdapter] = {}

def register(adapter: CostAdapter) -> None:
    _adapters[adapter.db_id] = adapter

def get_adapter(db_id: DatabaseId) -> CostAdapter:
    if db_id not in _adapters:
        raise ValueError(f"No adapter for: {db_id}")
    return _adapters[db_id]

def get_all() -> list[CostAdapter]:
    return list(_adapters.values())

def get_by_category(cat: DatabaseCategory) -> list[CostAdapter]:
    return [a for a in _adapters.values() if a.category == cat]
```

### 8.3 Cost Calculation Formula

```
Monthly Cost = Compute + Storage + IOPS + Backup + Network + Cache + License

Where:
  Compute  = tier.price_per_month
  Storage  = total_GB × price_per_GB
  IOPS     = max(0, (total_IOPS - baseline)) × iops_price
  Backup   = total_GB × backup_price × retention/30
  Network  = data_transfer_GB × transfer_price
  Cache    = cache_memory_GB × cache_price (if external)
  License  = license_fee (Oracle, SQL Server)
```

**DB-specific variations:**
- **DynamoDB**: No instance. `read = readIOPS × 0.25/1M × 730h`, `write = writeIOPS × 1.25/1M × 730h`
- **Pinecone**: `storage = GB × 0.33`, `reads = monthly/1M × 8.25`
- **Neo4j AuraDB**: `cost = capacityGB × pricePerGBHour × 730`
- **Redis/Valkey**: `cost = memoryGB × pricePerGB`

### 8.4 Implementation Priority

Sprint 3: PostgreSQL, MySQL, MongoDB, DynamoDB
Sprint 4: Oracle, SQL Server, Cassandra, Neo4j, Pinecone, Redis
Sprint 5: Valkey, Memcached, Elasticsearch, Weaviate, Milvus, Qdrant
Sprint 6: All remaining 12

---

## 9. Sharding Engine

```python
# backend/app/sharding/simulator.py

import hashlib
from dataclasses import dataclass
from statistics import stdev
from app.models.sharding import ShardDistribution, ShardSimulationResult


class ShardSimulator:
    def __init__(self, num_shards: int, strategy: str = "hash"):
        self.num_shards = num_shards
        self.strategy = strategy

    def simulate(self, keys: list[str]) -> ShardSimulationResult:
        shard_counts = {i: 0 for i in range(self.num_shards)}
        for key in keys:
            sid = int(hashlib.md5(key.encode()).hexdigest(), 16) % self.num_shards
            shard_counts[sid] += 1

        total = len(keys)
        avg = total / self.num_shards
        sd = stdev(shard_counts.values()) if self.num_shards > 1 else 0
        risk = "high" if sd > avg * 0.5 else ("medium" if sd > avg * 0.2 else "low")

        distribution = [
            ShardDistribution(shard_id=sid, record_count=c, percentage=round(c/total*100, 2))
            for sid, c in shard_counts.items()
        ]
        recommendations = []
        if risk != "low":
            recommendations.append("Use a high-cardinality shard key.")
            recommendations.append("Avoid monotonic keys (timestamps, auto-increment).")

        return ShardSimulationResult(
            distribution=distribution, is_balanced=(risk == "low"),
            hot_spot_risk=risk, max_shard_records=max(shard_counts.values()),
            avg_shard_records=int(avg), standard_deviation=round(sd, 2),
            recommendations=recommendations,
        )
```

**Per-DB strategies:** MongoDB (hash/range keys), PG (Citus), MySQL (Vitess), Cassandra (partition key + vnodes), DynamoDB (partition key auto), Redis (CRC16 hash slots), Elasticsearch (index sharding), CockroachDB (auto range).

---

## 10. Caching Engine

```python
# backend/app/caching/estimator.py

CACHE_PRICES = {"redis": 30.0, "valkey": 24.0, "memcached": 22.0, "dragonfly": 26.0}

def estimate_cache(config, hot_data_bytes: int):
    if not config.enabled:
        return {"required_memory_mb": 0, "monthly_cost": 0}
    required_mb = (hot_data_bytes / config.cache_hit_ratio_target) / (1024**2)
    actual_mb = min(required_mb, config.max_memory_mb)
    cost = (actual_mb / 1024) * CACHE_PRICES.get(config.engine, 30.0)
    return {"required_memory_mb": round(required_mb, 1), "allocated_memory_mb": round(actual_mb, 1), "monthly_cost": round(cost, 2)}
```

---

## 11. Schema Export Engine

| Database(s) | Export Formats |
|-------------|---------------|
| PostgreSQL, MySQL, MariaDB, SQL Server, Oracle, CockroachDB, SQLite | `sql_ddl`, `prisma` |
| MongoDB | `mongoose` |
| DynamoDB | `dynamodb_json` |
| Cassandra | `cql` |
| Neo4j | `cypher` |
| Elasticsearch / OpenSearch | `elasticsearch_mapping` |
| Vector DBs | `vector_index` |
| InfluxDB | `influx_schema` |
| TimescaleDB | `sql_ddl` + hypertable |
| Redis / Valkey / Memcached / Dragonfly | `key_schema_doc` |

Each format has its own `ExportEngine` class in `backend/app/export/`.

---

## 12. API Routes & Contracts

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/projects` | Create project |
| `GET` | `/api/v1/projects` | List projects |
| `GET` | `/api/v1/projects/{id}` | Get project |
| `PATCH` | `/api/v1/projects/{id}` | Update project |
| `DELETE` | `/api/v1/projects/{id}` | Delete project |
| `POST` | `/api/v1/projects/{id}/entities` | Add entity |
| `PATCH` | `/api/v1/projects/{id}/entities/{eid}` | Update entity |
| `DELETE` | `/api/v1/projects/{id}/entities/{eid}` | Remove entity |
| `POST` | `/api/v1/projects/{id}/relationships` | Add relationship |
| `PATCH` | `/api/v1/projects/{id}/relationships/{rid}` | Update relationship |
| `DELETE` | `/api/v1/projects/{id}/relationships/{rid}` | Remove relationship |
| `POST` | `/api/v1/cost/estimate` | Estimate cost |
| `POST` | `/api/v1/cost/compare` | Compare DBs |
| `POST` | `/api/v1/cost/forecast` | Growth forecast |
| `POST` | `/api/v1/sharding/simulate` | Shard simulation |
| `GET` | `/api/v1/sharding/options/{db_id}` | Shard options |
| `POST` | `/api/v1/caching/estimate` | Cache estimate |
| `POST` | `/api/v1/export` | Export schema |
| `GET` | `/api/v1/export/formats/{db_id}` | Export formats |
| `GET` | `/api/v1/databases` | List all 28 DBs |
| `GET` | `/api/v1/databases/{db_id}` | DB metadata |
| `GET` | `/api/v1/databases/categories` | Categories |
| `GET` | `/api/v1/templates` | List templates |
| `POST` | `/api/v1/projects/{id}/apply-template/{tid}` | Apply template |
| `WS` | `/ws/{project_id}` | Real-time updates |

FastAPI auto-generates OpenAPI docs at `/docs` (Swagger) and `/redoc`.

---

## 13. WebSocket Real-Time Updates

```python
# backend/app/routes/ws.py

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import json

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        self._connections: dict[str, list[WebSocket]] = {}

    async def connect(self, project_id: str, ws: WebSocket):
        await ws.accept()
        self._connections.setdefault(project_id, []).append(ws)

    def disconnect(self, project_id: str, ws: WebSocket):
        if project_id in self._connections:
            self._connections[project_id].remove(ws)

    async def broadcast(self, project_id: str, event: str, data: dict):
        for ws in self._connections.get(project_id, []):
            await ws.send_text(json.dumps({"event": event, "data": data}))

manager = ConnectionManager()

@router.websocket("/{project_id}")
async def project_ws(ws: WebSocket, project_id: str):
    await manager.connect(project_id, ws)
    try:
        while True:
            msg = json.loads(await ws.receive_text())
            await manager.broadcast(project_id, msg.get("event", "update"), msg.get("data", {}))
    except WebSocketDisconnect:
        manager.disconnect(project_id, ws)
```

Flutter connects to `ws://localhost:8000/ws/{project_id}` and receives events like `cost_updated`, `entity_added`, `sharding_updated`.

---

## 14. MCP Server Integration

```python
# backend/app/mcp/server.py

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import TextContent
from app.mcp.tools import (
    create_model, set_ratio, estimate_cost, compare_dbs,
    plan_sharding, configure_cache, growth_forecast, export_schema,
)

TOOLS = [create_model.DEF, set_ratio.DEF, estimate_cost.DEF, compare_dbs.DEF,
         plan_sharding.DEF, configure_cache.DEF, growth_forecast.DEF, export_schema.DEF]
HANDLERS = {
    "create_model": create_model.handle, "set_ratio": set_ratio.handle,
    "estimate_cost": estimate_cost.handle, "compare_dbs": compare_dbs.handle,
    "plan_sharding": plan_sharding.handle, "configure_cache": configure_cache.handle,
    "growth_forecast": growth_forecast.handle, "export_schema": export_schema.handle,
}

def create_mcp_server() -> Server:
    server = Server("dataforge")

    @server.list_tools()
    async def list_tools():
        return TOOLS

    @server.call_tool()
    async def call_tool(name: str, arguments: dict):
        handler = HANDLERS.get(name)
        if not handler:
            return [TextContent(type="text", text=f"Unknown tool: {name}")]
        return [TextContent(type="text", text=await handler(arguments))]

    return server

async def run_stdio():
    server = create_mcp_server()
    async with stdio_server() as (read, write):
        await server.run(read, write, server.create_initialization_options())
```

**Claude Desktop config:**
```json
{
  "mcpServers": {
    "dataforge": {
      "command": "python",
      "args": ["-m", "app.mcp.server"],
      "cwd": "/path/to/dataforge/backend"
    }
  }
}
```

All 8 MCP tools: `create_model`, `set_ratio`, `estimate_cost`, `compare_dbs`, `plan_sharding`, `configure_cache`, `growth_forecast`, `export_schema`.

---

## 15. Frontend: Flutter Application

### 15.1 Entry Point

```dart
// frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() => runApp(const ProviderScope(child: DataForgeApp()));
```

### 15.2 Dart Models (Freezed)

All backend Pydantic models are mirrored as Dart `freezed` data classes with `json_serializable`. Key models: `Entity`, `EntityField`, `Relationship`, `Project`, `CostBreakdown`, `PricingTier`, `ShardConfig`, `CacheConfig`, `DatabaseConfig`.

### 15.3 API Client (Dio)

```dart
// frontend/lib/services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  static final instance = ApiClient._();
  late final Dio dio;
  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }
}
```

Service classes (`CostService`, `ProjectService`, `ShardingService`, etc.) wrap Dio calls to each API endpoint.

---

## 16. State Management (Riverpod)

**Key pattern:** `costBreakdownProvider` watches `currentProjectProvider`. When the project changes (DB, user count, entities), cost auto-recalculates.

```dart
final currentProjectProvider = StateNotifierProvider<ProjectNotifier, AsyncValue<Project?>>(
  (ref) => ProjectNotifier(ref.read(projectServiceProvider)),
);

final costBreakdownProvider = FutureProvider<CostBreakdown?>((ref) async {
  final project = ref.watch(currentProjectProvider).value;
  if (project == null) return null;
  return ref.read(costServiceProvider).estimateCost(
    projectId: project.id, database: project.selectedDatabase, userCount: project.userCount,
  );
});

final costComparisonProvider = FutureProvider.family<Map<String, dynamic>, String?>(
  (ref, category) async {
    final project = ref.watch(currentProjectProvider).value;
    if (project == null) return {};
    return ref.read(costServiceProvider).compareCosts(
      projectId: project.id, userCount: project.userCount, category: category,
    );
  },
);
```

---

## 17. Flutter Screens & Widgets

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│  AppBar: [Project Name] [DB Selector ▼] [User Count Slider] │
├─────────────────────────────────┬────────────────────────────┤
│                                 │  Right Panel (tabs):       │
│     Canvas (CustomPainter)      │  ├─ Entity Editor          │
│     Entity nodes + edges        │  ├─ Relationship Editor    │
│     Drag, pan, zoom             │  ├─ Shard Config           │
│                                 │  ├─ Cache Config           │
│                                 │  └─ Export                 │
├─────────────────────────────────┴────────────────────────────┤
│  Bottom Panel: Cost Dashboard                                │
│  [Donut] [Growth Line Chart] [DB Comparison Bars]            │
└──────────────────────────────────────────────────────────────┘
```

### Key Widgets

| Widget | Purpose |
|--------|---------|
| `CanvasView` | `InteractiveViewer` + `CustomPainter` for entity drag-and-drop |
| `EntityNode` | Rounded card — name, field count, record count badge |
| `RelationshipEdge` | Bezier curve with ratio label |
| `GrowthSlider` | Logarithmic slider (100 → 10M) |
| `CostDonutChart` | `fl_chart` PieChart — compute/storage/iops/backup |
| `GrowthChart` | `fl_chart` LineChart — cost vs users |
| `ComparisonBars` | Horizontal bars comparing DBs by category |
| `DbSelector` | Dropdown grouped by category |
| `EntityEditorPanel` | Form for fields (name, type, size, constraints) |
| `ShardConfigPanel` | Shard key selector, strategy, distribution chart |
| `CacheConfigPanel` | Engine selector, TTL, eviction, memory slider |
| `ExportPanel` | Format dropdown, code preview, copy/download |
| `CodePreview` | `flutter_highlight` syntax-highlighted preview |

---

## 18. Canvas: Interactive Data Modelling

Built with `InteractiveViewer` + `GestureDetector` + `CustomPainter` since Flutter has no React Flow equivalent.

Canvas state managed by `canvasProvider` (Riverpod): tracks node positions, selection, zoom. The `CanvasPainter` renders entity nodes as rounded rects and relationships as bezier curves with ratio labels. Nodes are draggable via `GestureDetector.onPanUpdate`.

Auto-layout places entities in a grid (3 columns, 280px spacing). Central model gets a blue border, selected nodes get green.

---

## 19. Data Flow: End-to-End

```
User Action (drag entity, slide user count, select DB)
  │
  ▼
Riverpod Provider (optimistic update)
  │
  ├──▶ Dio POST to FastAPI
  │
  ▼
FastAPI Route
  ├──▶ ProjectRepository → MongoDB read
  ├──▶ ModelGraph.calculate_storage(user_count)
  ├──▶ ModelGraph.calculate_iops(user_count)
  ├──▶ pricing.registry.get_adapter(db_id).estimate_cost(input)
  │
  ▼
JSON response → Riverpod update → Flutter UI rebuild
  ├── Cost Dashboard
  ├── Growth Chart
  ├── Comparison View
  └── Canvas (record count badges)
```

---

## 20. Testing Strategy

### Backend (pytest + pytest-asyncio)

- **Unit:** ModelGraph, ratio calculator, each pricing adapter, sharding simulator, cache estimator, export engines.
- **Integration:** Full cost pipeline (create project → add entities → estimate → compare). All 28 adapters return valid CostBreakdown. MCP tool chain.
- **Fixtures:** `mongomock-motor` for MongoDB mock. Standard "SaaS App" test project.

### Frontend (flutter test + mocktail)

- **Widget tests:** Each screen and panel renders correctly.
- **Provider tests:** State changes propagate correctly (mock API responses).
- **Model tests:** Freezed serialization round-trips correctly.

---

## 21. Docker & Deployment

```yaml
# docker/docker-compose.yml
version: "3.9"
services:
  mongodb:
    image: mongo:7
    ports: ["27017:27017"]
    volumes: [mongo-data:/data/db]

  backend:
    build: {context: ../backend}
    ports: ["8000:8000"]
    environment:
      DATAFORGE_MONGODB_URI: mongodb://mongodb:27017
      DATAFORGE_MONGODB_DB_NAME: dataforge
    depends_on: [mongodb]

  frontend:
    build: {context: ../frontend}
    ports: ["3000:80"]
    depends_on: [backend]

volumes:
  mongo-data:
```

**Makefile commands:** `make dev`, `make test`, `make lint`, `make docker-up`, `make docker-down`, `make seed-templates`.

---

## 22. Sprint Plan & Milestones

| Sprint | Weeks | Focus | Done When |
|--------|-------|-------|-----------|
| 1 | 1-2 | Scaffolding, FastAPI + MongoDB + Beanie, Flutter skeleton, Docker Compose, CI | Create project via API, see it in Flutter |
| 2 | 3 | ModelGraph engine, Flutter canvas (CustomPainter), entity/relationship editors | Visual data modelling with record counts |
| 3 | 4-5 | CostAdapter ABC, first 4 adapters (PG, MySQL, Mongo, Dynamo), cost dashboard | User count slider updates cost for 4 DBs |
| 4 | 6 | 6 more adapters, comparison view, growth forecast chart | Compare 10 DBs side-by-side |
| 5 | 7-8 | All remaining 18 adapters, pricing JSONs, DB metadata routes | All 28 DBs return valid costs |
| 6 | 9 | Sharding simulator, cache estimator, schema export, Flutter panels | Full shard/cache/export workflow |
| 7 | 10-11 | MCP server (Python SDK, stdio), 8 tools, WebSocket, Flutter WS client | Claude Desktop interacts with DataForge |
| 8 | 12 | MCP SSE, templates system, error handling | Templates work, MCP via stdio + SSE |
| 9 | 13-14 | UI polish, Flutter web/macOS/Windows/Linux builds, performance | Production-quality across platforms |
| 10 | 15-16 | PyPI publish, Docker Hub, GitHub Releases, docs, demo video, launch | Public repo, installable everywhere |

---

## 23. Open Source Launch Checklist

- [ ] MIT LICENSE
- [ ] README.md (screenshots, quickstart, architecture)
- [ ] CONTRIBUTING.md
- [ ] CODE_OF_CONDUCT.md
- [ ] CHANGELOG.md
- [ ] GitHub Issue Templates
- [ ] CI: backend-ci.yml, frontend-ci.yml, release.yml
- [ ] PyPI: `pip install dataforge`
- [ ] Docker Hub: `dataforge/dataforge:latest`
- [ ] Flutter web on GitHub Pages
- [ ] Desktop builds as GitHub Release assets
- [ ] MCP registry submission
- [ ] Demo video + blog post
- [ ] Launch: HN, Product Hunt, Reddit, X

---

## 24. Conventions & Code Style

### Backend (Python)

- Files: `snake_case.py`. Classes: `PascalCase`. Functions: `snake_case`. Constants: `SCREAMING_SNAKE`.
- Linter: Ruff (line-length 100). Types: mypy strict. Docstrings: Google style.

### Frontend (Dart/Flutter)

- Files: `snake_case.dart`. Classes: `PascalCase`. Variables: `camelCase`.
- Models: `freezed` + `json_serializable`. Linter: `flutter_lints`.

### Shared

- DB IDs: lowercase enum values (`postgresql`, `mongodb`, `neo4j`).
- API: JSON with `snake_case` keys (Python convention; Dart handles conversion).
- Git: Conventional Commits, feature branches, 1-review PRs.
- Errors: FastAPI `HTTPException`. Flutter `AsyncValue.error`. Adapters never throw — return zeros.

---

*This guide is the single source of truth for building DataForge. Backend agents: read Sections 5-14. Frontend agents: read Sections 15-18. Everyone: read Sections 1-4 and 19-24.*
