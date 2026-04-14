# Data4G --- Consolidated Architecture Document

> A code-aware infrastructure visualization, risk analysis, and cost simulation platform powered by MCP.

---

## 1. Problem Statement

Engineering teams today face a set of recurring challenges when designing, scaling, and maintaining backend architectures:

1. **Architecture is invisible.** Backend systems grow organically --- services, databases, caches, queues, and gateways are added over months or years, but there is no single artifact that shows how they connect, what each endpoint does, or where data flows. Architecture diagrams go stale within weeks of being drawn.

2. **Scalability risks hide in code.** N+1 queries, missing pagination, unbounded fetches, full table scans, and race conditions are invisible until production traffic exposes them. By then, the cost is downtime and fire-fighting.

3. **Cost estimation is guesswork.** Teams cannot answer "What will this architecture cost at 100K users?" without provisioning real infrastructure. There is no way to model how traffic cascades through the dependency chain (1 API request = 3 DB queries + 1 cache lookup + 1 queue publish) and project costs at scale.

4. **Experimentation is expensive.** Trying a different database, adding a cache layer, or switching from a monolith to microservices requires real infrastructure changes. There is no sandbox to compare topology variations side by side before committing.

---

## 2. Solution --- Data4G

Data4G is a web platform that solves all four problems by grounding infrastructure visualization in **actual code metadata**, ingested from the developer's IDE and CI/CD pipeline via the **Model Context Protocol (MCP)**.

### What makes Data4G different from generic diagramming tools

- Topologies are built from **real codebase data**: real endpoints, real DB schemas, real cache keys, real query patterns --- not hand-drawn boxes.
- A **live topology** stays in sync with the codebase (read-only, MCP-synced). Users create **experimental topologies** (cloned from live) to test what-if scenarios.
- **Code-level risk analysis** walks through every endpoint and detects scalability anti-patterns via static analysis.
- **Traffic simulation** cascades QPS through the full dependency graph with correct multipliers, not just single-hop estimates.
- **Cost estimation** uses daily-synced cloud pricing data to project costs at any scale.

---

## 3. Core Domain Model

```
User --> Team (via invite) --> Projects --> Topologies --> Components
```

| Concept               | Description                                                                 |
|-----------------------|-----------------------------------------------------------------------------|
| **User**              | Individual account (email/password signup)                                  |
| **Team**              | Group of users sharing project access via invite links                      |
| **Project**           | Maps 1:1 to a Git repository                                               |
| **Live Topology**     | Read-only topology synced from codebase via MCP. Single source of truth.    |
| **Experimental Topology** | Cloned from live, fully user-editable. Used for what-if scenarios.     |
| **Component**         | A node in the topology (server, DB, cache, queue, gateway, etc.)            |
| **Edge**              | A directed connection between components showing data/request flow           |

---

## 4. Component Types (12)

| #  | Component                        | Key Metadata                                                        |
|----|----------------------------------|---------------------------------------------------------------------|
| 1  | **Server** (standalone/VM/K8s)   | Infra config (CPU, RAM, replicas, instance type) + endpoint list    |
| 2  | **Kubernetes Node**              | Node pool config, resource limits, scheduling                       |
| 3  | **Database**                     | Data models, fields, types, relationships with ratios (e.g. 1:200) |
| 4  | **Cache**                        | Cache key types, TTLs, endpoint associations                        |
| 5  | **Queue / Message Broker**       | Producer endpoints, consumer services, partitions, strategy         |
| 6  | **CDN**                          | Origin config, caching rules, edge locations                        |
| 7  | **Load Balancer**                | Algorithm, health checks, backends                                  |
| 8  | **API Gateway**                  | Rate limiting, auth config, routing rules                           |
| 9  | **Object Storage**               | Buckets, access policies, lifecycle rules                           |
| 10 | **Cron / Scheduled Jobs**        | Schedule, target endpoint/service, retry policy                     |
| 11 | **Third-party APIs / External**  | URL, SLA expectations, fallback behavior                            |
| 12 | **Service Mesh / Sidecar Proxy** | Routing rules, circuit breaker config, mTLS                        |

---

## 5. Four Core Capabilities

### 5.1 Visualization --- Structured Architecture Diagram

- **Auto-laid-out** structured diagram (draw.io / Lucidchart style), NOT freeform canvas.
- Components are nodes; connections are directed arrows showing data/request flow.
- **Drill-down navigation:**
  - Click **Server** --> list of all endpoints, each with its DB calls, cache calls, service dependencies.
  - Click **Database** --> Power BI-style model view: entities with fields, types, relationship lines with ratios. View-only for live topology.
  - Click **Cache** --> all cache key types, TTLs, which endpoints read/write each key.
  - Click **Queue** --> producer endpoints, consumer services, partition config.

### 5.2 Code-Level Risk Analysis (via MCP)

- MCP server walks through endpoints **one by one** performing static code analysis.
- Detects: N+1 queries, missing pagination, unbounded fetches, full table scans, inefficient joins, missing indexes (heuristic), race conditions.
- Each endpoint gets a **risk score** and specific findings.
- **Dashboard view:** ranked list of high-risk endpoints, filterable by risk type and severity.
- Triggered on-demand by developer or via CI/CD pipeline.

### 5.3 Traffic & Cost Simulation

- **Theoretical modeling:** User inputs QPS at entry-point endpoints. System cascades traffic through the full dependency chain with correct multipliers.
- **What-if analysis** on experimental topologies:
  - Servers: traffic multiplier, replica count, instance type
  - Database: replica count, read/write ratio, connection pool size
  - Cache: TTL values, memory allocation, eviction policy
  - Queue: partition count, consumer count, batch size
  - General: add/remove components, change connections
- **Full cascade:** Traffic simulation propagates through the entire dependency graph.
- **Cost estimation** across all component types: compute, database storage, cache memory, queue throughput, network/egress.
- **Cost data source:** Daily sync from AWS/GCP/Azure pricing APIs, cached in DB.
- **Comparison dashboard:** Compare cost, performance estimates, and risk scores between topologies.

### 5.4 Topology Experimentation

- Clone live topology into experimental topology with one click.
- Modify any component config, add/remove components, change connections.
- Each experimental topology can be independently simulated.
- **Comparison dashboard** compares metrics (NOT visual topology) across multiple topologies:
  - Cost projections
  - Performance estimates (latency, throughput, bottleneck predictions)
  - Risk scores

---

## 6. MCP Server Architecture

### 6.1 Data Flow

```
Developer's IDE (any MCP-compatible)          CI/CD Pipeline
         |                                          |
         | On-demand trigger                        | Automated on commit/push
         v                                          v
    +-------------------------------------------------+
    |              MCP Server                          |
    |                                                  |
    |  1. Walk endpoints one-by-one                    |
    |  2. Static code analysis per endpoint            |
    |  3. Extract: endpoint metadata, DB schemas,      |
    |     cache keys, service dependencies,            |
    |     queue producer/consumer mappings              |
    |  4. Compute risk scores                          |
    |  5. Produce versioned metadata diff               |
    +-------------------------------------------------+
                         |
                         | HTTPS / MCP Protocol
                         v
    +-------------------------------------------------+
    |            Data4G Backend (FastAPI)               |
    |                                                  |
    |  - Upsert live topology                          |
    |  - Store endpoint-level metadata                 |
    |  - Store risk analysis results                   |
    |  - Update last_synced_at                         |
    +-------------------------------------------------+
```

### 6.2 Language Support (Day One --- Equal Depth)

| Language   | Frameworks                          | ORMs / Data Access              |
|------------|-------------------------------------|---------------------------------|
| Python     | Django, Flask, FastAPI              | SQLAlchemy, Django ORM          |
| Node.js    | Express, NestJS                     | Prisma, TypeORM, Sequelize      |
| Go         | Gin, Echo, net/http                 | GORM, sqlx                      |
| Java       | Spring Boot                         | JPA/Hibernate, MyBatis          |

### 6.3 Standard Analysis Spec (All Languages)

1. Endpoint detection (routes, handlers)
2. DB query extraction and risk analysis (N+1, missing pagination, unbounded queries, full scans)
3. ORM schema/model detection with relationships
4. Cache key usage and TTL detection
5. Service-to-service call detection
6. Queue producer/consumer mapping

### 6.4 Metadata Schema

- Versioned metadata with `last_synced_at` timestamps.
- Each sync produces a diff against previous state.
- Conflict resolution: last-write-wins.

---

## 7. High-Level System Architecture

```
+------------------+      +------------------+      +------------------+
|                  |      |                  |      |                  |
|  Flutter Web     | <--> |  FastAPI Backend  | <--> |    MongoDB       |
|  (Frontend)      |      |  (Python)        |      |                  |
|                  |      |                  |      |                  |
+------------------+      +--------+---------+      +------------------+
                                   |
                          +--------+---------+
                          |                  |
                          |  MCP Server      |
                          |  (Protocol)      |
                          |                  |
                          +--------+---------+
                                   |
                    +--------------+---------------+
                    |              |               |
              Developer IDE   CI/CD Pipeline   Cloud Pricing
              (VS Code, etc)  (GitHub Actions)  APIs (daily sync)
```

### 7.1 Tech Stack

| Layer              | Choice                                     |
|--------------------|--------------------------------------------|
| Frontend           | Flutter Web (Dart)                         |
| State Management   | Riverpod 2.x                               |
| Backend            | Python FastAPI                             |
| Database           | MongoDB (Motor + Beanie ODM)               |
| MCP Server         | Standard MCP protocol (IDE-agnostic)       |
| Diagram Rendering  | Flutter graph/diagram library (TBD)        |
| Charts             | fl_chart                                   |
| HTTP Client        | Dio (frontend), httpx (backend)            |
| Auth               | JWT (access + refresh tokens)              |
| Routing            | GoRouter (frontend)                        |

---

## 8. Auth & Collaboration

| Feature            | Implementation                                                    |
|--------------------|-------------------------------------------------------------------|
| Auth               | Email/password signup with JWT tokens                             |
| Teams              | Invite links to share project access                              |
| Collaboration      | Async --- no real-time co-editing                                 |
| Notifications      | "Updated X minutes ago" badge on next page load (no push/WS)     |
| Roles              | Owner (full access) and Member (scoped topology access)           |

---

## 9. Export & Sharing

| Feature             | Format                                      |
|---------------------|---------------------------------------------|
| Topology diagrams   | PNG / SVG export                            |
| Simulation reports  | PDF export                                  |
| Shareable links     | Read-only links for topologies & dashboards |

---

## 10. Key Architectural Decisions

| # | Decision                              | Rationale                                                                         |
|---|---------------------------------------|-----------------------------------------------------------------------------------|
| 1 | Live vs. Experimental topology split  | MCP-synced data is never accidentally modified by users                           |
| 2 | One project = one Git repo            | Clear boundary. Microservice architectures use multiple projects                  |
| 3 | MCP as the bridge                     | No manual data entry for live topology. All metadata comes from code              |
| 4 | Cascading simulation                  | Full dependency graph traversal, not isolated component simulation                |
| 5 | MongoDB                               | Flexible schema for varied component configs and MCP metadata                     |
| 6 | Daily cloud pricing sync              | Accurate cost estimates without runtime API calls                                 |
| 7 | Structured auto-layout diagrams       | Consistent, readable diagrams vs. freeform canvas that drifts                     |
| 8 | 12 component types                    | Covers the full spectrum of modern backend infrastructure                         |
| 9 | Four-language MCP support at launch   | Covers the majority of backend codebases in production today                      |

---

## 11. Current Codebase vs. New Requirements --- Gap Analysis

### 11.1 What Exists Today (DataForge)

The current codebase implements a **two-stage infrastructure cost estimation tool** (manual topology design + spec configuration):

**Backend (FastAPI + MongoDB):**
- User auth (email/password, optional Google OAuth, JWT tokens)
- Project CRUD with soft-delete
- Multi-topology support (create, list, update, delete, collapse)
- Component specs: Compute, Cache, LB, CDN, K8s, Docker
- DB schema editor with entities, fields, relationships, BFS record propagation
- Cost engine with hardcoded pricing constants
- Consolidated dashboard (per-component, per-category, growth projections, hints)
- Topology comparison (cross-project)
- Member management (owner/member roles, topology-level access control)
- Reference data (30 databases, regions, cloud providers)

**Frontend (Flutter Web + Riverpod):**
- Landing page, auth screens (login/signup/verification)
- Workspace shell with header/footer/section navigation
- Freeform topology canvas (draggable nodes, Bezier edge rendering)
- Spec editor views for all component types
- Cost dashboard with charts (pie, line, progress bars)
- Comparison view (topology + database)
- Settings/member management UI
- Demo data fallback mode
- Cosmic dark theme

### 11.2 What Must Change (Data4G Requirements)

| Area                        | Gap                                                                                           | Severity |
|-----------------------------|-----------------------------------------------------------------------------------------------|----------|
| **Live vs. Experimental**   | No concept of live (MCP-synced, read-only) vs experimental (cloned, editable) topologies     | Critical |
| **MCP Server**              | Entirely missing. No code ingestion, no endpoint metadata, no risk analysis                  | Critical |
| **Risk Analysis Engine**    | No static code analysis, no risk scoring, no risk dashboard                                  | Critical |
| **Traffic Simulation**      | No cascading traffic model through dependency graph with multipliers                         | Critical |
| **Structured Auto-Layout**  | Current canvas is freeform drag-and-drop; needs auto-laid-out structured diagrams            | High     |
| **Drill-Down Navigation**   | No click-to-explore: server->endpoints, DB->Power BI model view, cache->key usage           | High     |
| **New Component Types**     | Missing: API Gateway, Cron/Scheduled Jobs, Third-party APIs, Service Mesh/Sidecar            | High     |
| **Endpoint Metadata**       | Servers have no endpoint-level data (DB calls, cache calls, service deps per endpoint)       | High     |
| **Team / Invite System**    | Only direct user-ID member addition; no invite links, no team entity                         | Medium   |
| **Cloud Pricing Sync**      | Hardcoded pricing; needs daily sync from AWS/GCP/Azure pricing APIs                          | Medium   |
| **Export**                   | No PNG/SVG/PDF export capability                                                             | Medium   |
| **Shareable Links**         | No read-only link generation for topologies or dashboards                                    | Medium   |
| **Password Security**       | SHA256 hashing; must migrate to bcrypt/Argon2                                                | Medium   |
| **Git Repo Binding**        | Projects not linked to Git repos; need repo URL and MCP sync config                         | Medium   |
| **Comparison Dashboard**    | Current comparison is structural diff; needs metric comparison (cost, perf, risk)            | Low      |

### 11.3 What Can Be Preserved

- FastAPI project structure (routes/services/repositories/models)
- MongoDB document model (with extensions)
- All Pydantic schemas for existing component types (extend, don't replace)
- User auth flow (fix password hashing, add invite links)
- Cost engine (refactor from hardcoded to pricing-table-driven)
- Frontend: Riverpod state management, GoRouter, Dio API client, theme system, auth flow
- Frontend: All existing model classes (extend with new fields)
- Frontend: Dashboard charts, comparison UI shell, settings UI

---

## 12. Implementation Roadmap (High Level)

### Phase 1 --- Foundation Alignment (Weeks 1-3)
- Rename DataForge -> Data4G across codebase
- Add live vs. experimental topology model
- Add 4 new component types (API Gateway, Cron, Third-party API, Service Mesh)
- Bind projects to Git repositories
- Fix password hashing (SHA256 -> bcrypt)
- Add team entity and invite link system

### Phase 2 --- MCP Server Core (Weeks 4-7)
- MCP server scaffold with standard protocol
- Python analyzer (FastAPI/Django/Flask endpoint detection, SQLAlchemy/Django ORM schema extraction)
- Node.js analyzer (Express/NestJS, Prisma/TypeORM/Sequelize)
- Go analyzer (Gin/Echo, GORM/sqlx)
- Java analyzer (Spring Boot, JPA/Hibernate)
- Dual-mode ingestion (IDE on-demand + CI/CD automated)
- Live topology sync pipeline

### Phase 3 --- Risk Analysis Engine (Weeks 8-10)
- Static analysis framework (per-endpoint code walking)
- Risk detectors: N+1, missing pagination, unbounded fetches, full scans, missing indexes
- Risk scoring algorithm
- Risk dashboard API and frontend UI

### Phase 4 --- Traffic & Cost Simulation (Weeks 11-14)
- Cascading traffic model (dependency graph traversal with multipliers)
- Endpoint-level metadata integration (DB calls, cache calls per endpoint)
- Cloud pricing API daily sync (AWS, GCP, Azure)
- Pricing-table-driven cost engine (replace hardcoded constants)
- Traffic simulation UI (QPS input, cascade visualization)

### Phase 5 --- Visualization Overhaul (Weeks 15-17)
- Replace freeform canvas with structured auto-layout engine
- Drill-down navigation (server->endpoints, DB->model view, cache->keys, queue->producers/consumers)
- Live topology read-only rendering
- Experimental topology editing UI

### Phase 6 --- Experimentation & Comparison (Weeks 18-20)
- One-click clone (live -> experimental)
- Metric comparison dashboard (cost, performance, risk across topologies)
- What-if parameter tweaking UI

### Phase 7 --- Export, Sharing & Polish (Weeks 21-23)
- PNG/SVG diagram export
- PDF simulation report export
- Shareable read-only link generation
- Notifications ("Updated X minutes ago")
- End-to-end testing and performance optimization

---

*Detailed backend implementation plan --> [DATA4G_BACKEND_PLAN.md](DATA4G_BACKEND_PLAN.md)*
*Detailed frontend implementation plan --> [DATA4G_FRONTEND_PLAN.md](DATA4G_FRONTEND_PLAN.md)*
