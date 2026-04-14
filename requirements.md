# Data4G — Refined Requirements

## Vision

A web platform that lets engineering teams **visualize their backend architecture**, **identify code-level scalability risks**, **simulate traffic and cost scenarios**, and **experiment with topology variations** — all powered by real codebase metadata ingested via MCP.

This is not a generic diagramming tool. The differentiator is that topologies are grounded in actual code: real endpoints, real DB schemas, real cache keys, real query patterns — synced from the developer's IDE via MCP.

---

## Core Domain Model

```
User -> Team (via invite) -> Projects -> Topologies -> Components
```

- **Project**: Maps 1:1 to a Git repository.
- **Topology**: Two kinds:
  - **Live topology** — read-only, synced from codebase via MCP. Single source of truth.
  - **Experimental topologies** — cloned from live, fully user-editable. Used for what-if scenarios.
- **Component**: A node in the topology (server, DB, cache, queue, etc.)

---

## Component Types

| # | Component | Key Metadata |
|---|-----------|-------------|
| 1 | **Server** (standalone / VM / K8s deployment) | Infra config (CPU, RAM, replicas, instance type) + list of endpoints |
| 2 | **Kubernetes Node** | Node pool config, resource limits, scheduling |
| 3 | **Database** | Data models, fields, types, relationships with ratios (e.g., user:post 1:200) |
| 4 | **Cache** | Cache key types, TTLs, endpoint associations |
| 5 | **Queue / Message Broker** | Producer endpoints, consumer services, partitions, queuing strategy |
| 6 | **CDN** | Origin config, caching rules, edge locations |
| 7 | **Load Balancer** | Algorithm (round-robin, weighted, etc.), health checks, backends |
| 8 | **API Gateway** | Rate limiting, auth config, routing rules |
| 9 | **Object Storage** | Buckets, access policies, lifecycle rules |
| 10 | **Cron / Scheduled Jobs** | Schedule, target endpoint/service, retry policy |
| 11 | **Third-party APIs / External Services** | URL, SLA expectations, fallback behavior |
| 12 | **Service Mesh / Sidecar Proxy** | Routing rules, circuit breaker config, mTLS |

---

## Four Core Capabilities

### 1. Visualization — Structured Architecture Diagram

- Auto-laid-out structured diagram (draw.io / Lucidchart style), NOT freeform canvas.
- Components are nodes; connections are directed arrows showing data/request flow.
- **Drill-down navigation**:
  - Click **Server** -> see list of all endpoints, each with its DB calls, cache calls, service dependencies.
  - Click **Database** -> Power BI-style model view: entities with fields, types, and relationship lines with ratios. View-only for live topology.
  - Click **Cache** -> see all cache key types, TTLs, which endpoints read/write each key.
  - Click **Queue** -> see producer endpoints, consumer services, partition config.

### 2. Code-Level Risk Analysis (via MCP)

- The MCP server walks through endpoints **one by one** and performs static code analysis.
- Detects scalability risks: poor DB queries, N+1 problems, missing pagination, unbounded fetches, full table scans, inefficient joins, missing indexes (heuristic), race conditions.
- Each endpoint gets a **risk score** and specific findings.
- **Dashboard view**: ranked list of high-risk endpoints with details, filterable by risk type and severity.
- Triggered by developer on-demand or via CI/CD pipeline.

### 3. Traffic & Cost Simulation

- **Theoretical modeling**: User inputs QPS at entry-point endpoints. System cascades traffic through the full dependency chain (Server A -> Server B -> DB C) with correct multipliers (e.g., 1 request = 2 DB queries + 1 cache lookup).
- **What-if analysis**: On experimental (cloned) topologies, users tweak predefined parameters per component type:
  - Servers: traffic multiplier, replica count, instance type
  - Database: replica count, read/write ratio, connection pool size
  - Cache: TTL values, memory allocation, eviction policy
  - Queue: partition count, consumer count, batch size
  - General: add/remove components, change connections
- **Full cascade**: Traffic simulation propagates through the entire dependency graph, not just single hops.
- **Cost estimation** across all component types:
  - Compute (server/pod instance costs based on config)
  - Database (storage based on model ratios + row projections)
  - Cache (memory sizing based on key count + TTL + value size)
  - Queue (throughput-based pricing)
  - Network/egress
- **Cost data source**: Daily sync from AWS/GCP/Azure pricing APIs, cached in our DB. Users select their cloud provider per project.
- **Comparison dashboard**: Compare cost, performance estimates, and risk scores between topologies side by side. Users navigate to individual topologies to edit, then return to compare.

### 4. Topology Experimentation

- Clone the live topology into an experimental topology with one click.
- Modify any component config, add/remove components, change connections.
- Each experimental topology can be independently simulated.
- **Comparison dashboard** compares metrics (NOT visual topology) across multiple topologies:
  - Cost projections
  - Performance estimates (latency, throughput, bottleneck predictions)
  - Risk scores
- Users can navigate from dashboard -> individual topology -> edit -> back to dashboard.

---

## MCP Server

### Data Flow

- **Dual-mode ingestion** (user can enable/disable each independently):
  1. **On-demand**: Developer triggers sync from their IDE (any MCP-compatible IDE).
  2. **Automated**: Runs in CI/CD pipeline on commit/push.
- Walks through endpoints one-by-one for code analysis.
- Syncs: endpoint metadata, DB model schemas, cache key definitions, service-to-service dependencies, queue producer/consumer mappings.

### Language Support (Day One — Equal Depth)

- Python (Django, Flask, FastAPI — SQLAlchemy, Django ORM)
- Node.js (Express, NestJS — Prisma, TypeORM, Sequelize)
- Go (Gin, Echo, net/http — GORM, sqlx)
- Java (Spring Boot — JPA/Hibernate, MyBatis)

### Standard Analysis Spec (All Languages)

- Endpoint detection (routes, handlers)
- DB query extraction and risk analysis (N+1, missing pagination, unbounded queries, full scans)
- ORM schema/model detection with relationships
- Cache key usage and TTL detection
- Service-to-service call detection
- Queue producer/consumer mapping

### Metadata Schema

- Versioned metadata with `last_synced_at` timestamps.
- Each sync produces a diff against previous state.
- Conflicts: latest sync wins (last-write-wins).

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Frontend | Flutter Web |
| Backend | Python FastAPI |
| Database | MongoDB |
| MCP Server | Standard MCP protocol (IDE-agnostic) |
| Diagram Rendering | TBD (Flutter graph/diagram library) |

---

## Auth & Collaboration

- **Auth**: Simple email/password signup.
- **Teams**: Invite links to share project access.
- **Collaboration model**: Async — no real-time co-editing.
- **Notifications**: "Updated X minutes ago" badge on next page load. No push/WebSocket notifications.

---

## Export & Sharing

- **File export**: Topology diagrams as PNG/SVG, simulation reports as PDF.
- **Shareable links**: Generate read-only links for topologies and comparison dashboards.

---

## Key Architectural Decisions

1. **Live vs. Experimental topology split** — ensures MCP-synced data is never accidentally modified by users.
2. **One project = one Git repo** — clear boundary. Microservice architectures use multiple projects.
3. **MCP as the bridge** — no manual data entry for the live topology. All metadata comes from code.
4. **Cascading simulation** — full dependency graph traversal, not isolated component simulation.
5. **MongoDB** — flexible schema accommodates varied component configs and MCP metadata structures.
6. **Daily cloud pricing sync** — accurate cost estimates without runtime API dependency.

---

## Open Items

1. **Flutter Web diagram library** — evaluate options for structured auto-layout (graphview, custom canvas with Dagre-style layout, etc.).
2. **Data model ratio detection** — auto-detect foreign keys from ORM; actual ratios (1:200) require manual input or sample data access. Current decision: auto-detect + user-editable.
3. **Cloud provider pricing API specifics** — which providers to support first and which pricing dimensions to model.
