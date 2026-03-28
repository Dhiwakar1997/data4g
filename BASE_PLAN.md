# DataForge — Base Plan

> Two-stage infrastructure modeling & cost estimation architecture

---

## 1. Vision

DataForge models infrastructure in **two stages** — a high-level topology design followed by low-level component specification — so that architects can start broad, drill down, and see costs recalculate at every decision point.

---

## 2. Two-Stage Modeling Overview

```
 STAGE 1 — Topology (high-level)              STAGE 2 — Specification (low-level)
┌──────────────────────────────┐      ┌──────────────────────────────────────┐
│  Compute  ←→  Storage        │      │  2.1  Compute Spec                   │
│    ↕            ↕             │      │       - vCPU cores, RAM, GPU         │
│  Cache    ←→  Database       │      │       - instance family / tier        │
│    ↕                          │      │       - autoscaling rules             │
│  Load Balancer                │  ──► │                                      │
│    ↕                          │      │  2.2  DB Model Spec                  │
│  CDN                          │      │       - table/collection schemas      │
│    ↕                          │      │       - PK / FK / index definitions   │
│  Client (with location)      │      │       - relational ratios (1:N, N:M)  │
│                               │      │       - space utilization per entity   │
│  (collapsible to single      │      │       - IOPS / throughput estimation   │
│   instance deployment)       │      │                                      │
└──────────────────────────────┘      └──────────────────────────────────────┘
         │                                          │
         └──────────────┬───────────────────────────┘
                        ▼
              ┌──────────────────┐
              │  Cost Engine     │
              │  (per-component) │
              └────────┬─────────┘
                       ▼
              ┌──────────────────┐
              │  Consolidated    │
              │  Dashboard       │
              └──────────────────┘
```

---

## 3. Stage 1 — High-Level Topology

### 3.1 Component Catalog

| Component       | Description                                                       | Collapsible |
|-----------------|-------------------------------------------------------------------|-------------|
| **Compute**     | Application servers / containers / serverless functions            | Yes — collapses to single process |
| **Database**    | Primary data store (any of the 28 supported DBs)                  | Yes — embedded SQLite / local Mongo |
| **Cache**       | In-memory layer (Redis, Valkey, Memcached, Dragonfly)             | Yes — in-process LRU |
| **Load Balancer** | Traffic distribution across compute instances                   | Yes — removed when single instance |
| **CDN**         | Static asset and API edge caching                                 | Yes — direct origin serving |
| **Client**      | End-user access point with geographic location(s)                 | Always present |
| **Object Store** | Blob / file storage (S3, GCS, Azure Blob)                       | Optional |
| **Message Queue** | Async event bus (Kafka, SQS, RabbitMQ)                          | Optional |

### 3.2 Topology Graph

- Each component is a **node** on the topology canvas.
- **Edges** represent network connections (latency, bandwidth).
- A **location** property on each node determines region-aware cost.
- The entire topology can **collapse** to a single-instance deployment (dev/local mode) where compute, DB, and cache run in one process.

### 3.3 Stage 1 Outputs

1. List of active infrastructure components
2. Region/location assignments
3. Network topology (which components talk to which)
4. Deployment mode: `single_instance | multi_tier | distributed`

---

## 4. Stage 2 — Low-Level Specification

### 4.1 Compute Spec (Stage 2.1)

For each compute node from Stage 1:

| Property            | Description                                  |
|---------------------|----------------------------------------------|
| `cpu_cores`         | Number of vCPUs                              |
| `ram_gb`            | Memory in GB                                 |
| `gpu_type`          | GPU model (optional, e.g., T4, A100)         |
| `gpu_count`         | Number of GPUs                               |
| `instance_family`   | Cloud instance family (e.g., m5, c7g, n2)    |
| `instance_size`     | Specific size (e.g., xlarge, 2xlarge)         |
| `os`                | Operating system                             |
| `min_instances`     | Minimum instance count (autoscaling floor)    |
| `max_instances`     | Maximum instance count (autoscaling ceiling)  |
| `target_utilization`| CPU/memory target for autoscaling trigger     |

### 4.2 DB Model Spec (Stage 2.2)

For each database node from Stage 1:

**Schema Definition:**
- Entities (tables / collections / nodes)
- Fields with types, sizes, constraints
- Primary keys and foreign keys
- Indexes (single, composite, unique)

**Relational Ratios:**
- Central entity (e.g., User) with a base record count
- Child entities linked via `1:1`, `1:N`, `N:M` relationships
- Ratio multiplier propagates record counts through the entity graph

**Space Utilization:**
- `record_count = parent_count * ratio`
- `entity_storage = record_count * avg_record_size`
- `index_overhead = estimated 15-30% of data size`
- `total_db_storage = sum(entity_storage) + index_overhead + WAL/journal`

**IOPS / Throughput:**
- Read/write ratio per entity
- Operations per second derived from user count

### 4.3 Stage 2 Outputs

1. Per-component hardware specification
2. Per-entity record counts and storage projections
3. Total DB storage with index overhead
4. IOPS requirements
5. **Cost input parameters** ready for the pricing engine

---

## 5. Cost Engine

### 5.1 Per-Component Cost

Each Stage 2 spec feeds into a cost calculator:

```
Component Cost = f(spec, cloud_provider, region, pricing_tier)
```

| Component      | Cost Drivers                                          |
|----------------|-------------------------------------------------------|
| Compute        | instance_type * hours * count + GPU surcharge         |
| Database       | instance + storage_GB + IOPS + backup + license       |
| Cache          | memory_GB * price_per_GB                              |
| Load Balancer  | fixed fee + LCU/hour + data_processed_GB              |
| CDN            | data_transfer_GB * per_GB_price + requests            |
| Object Store   | storage_GB + requests + data_transfer                 |
| Message Queue  | messages * per_message_price + throughput              |
| Network        | inter-region transfer + NAT + VPN                     |

### 5.2 Consolidated Dashboard

The dashboard aggregates all per-component costs:

- **Total monthly estimate** (sum of all components)
- **Cost breakdown by component** (donut chart)
- **Cost breakdown by category** (compute vs storage vs network)
- **Growth projection** (cost at 1K, 10K, 100K, 1M users)
- **Per-entity storage cost** (which tables cost the most)
- **Comparison view** (swap DB or cloud provider, see delta)
- **Optimization hints** (e.g., "cache reduces DB IOPS cost by ~40%")

---

## 6. Data Flow

```
User designs topology (Stage 1)
    │
    ▼
User specifies components (Stage 2)
    │
    ├── 2.1 Compute specs → Compute cost calculator
    │
    ├── 2.2 DB schema + ratios → Storage calculator → DB cost calculator
    │
    ├── Cache config → Cache cost calculator
    │
    ├── LB config → LB cost calculator
    │
    ├── CDN config → CDN cost calculator
    │
    └── Client locations → Network cost calculator
         │
         ▼
    Cost Engine aggregates all
         │
         ▼
    Consolidated Dashboard renders
```

---

## 7. Collapsible Single-Instance Mode

When the deployment mode is `single_instance`:

- Compute → 1 node, no autoscaling
- Database → embedded (SQLite) or local instance
- Cache → in-process dictionary / local Redis
- Load Balancer → removed (cost = $0)
- CDN → removed (cost = $0)
- Client → localhost

This lets developers estimate the cost of a minimal deployment and progressively scale up.

---

## 8. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Pydantic v2 for all schemas | Type safety, validation, JSON serialization, OpenAPI generation |
| Two-stage modeling | Separates "what do I need" from "how big does it need to be" |
| Collapsible topology | Same model works for a $5/mo hobby project and a $50K/mo production system |
| Ratio-based record projection | One number (user_count) drives all entity sizes through the relationship graph |
| Per-component cost isolation | Each component has its own cost adapter — swap implementations without touching others |
| Region-aware pricing | Same spec costs differently in us-east-1 vs ap-south-1 |

---

## 9. File Structure (New)

```
dataforge/
├── backend/
│   ├── app/
│   │   ├── models/              # Pydantic schemas (see BACKEND_PLAN.md)
│   │   │   ├── topology.py      # Stage 1: high-level components
│   │   │   ├── compute.py       # Stage 2.1: compute specs
│   │   │   ├── db_model.py      # Stage 2.2: DB schema + ratios
│   │   │   ├── cost.py          # Cost breakdown models
│   │   │   ├── dashboard.py     # Consolidated dashboard response
│   │   │   ├── entity.py        # Entity / field / relationship
│   │   │   ├── database.py      # Database config + metadata
│   │   │   ├── sharding.py      # Shard config models
│   │   │   ├── caching.py       # Cache config models
│   │   │   └── export.py        # Schema export models
│   │   ├── core/                # Business logic engines
│   │   ├── pricing/             # 28 DB cost adapters
│   │   ├── routes/              # FastAPI endpoints
│   │   └── ...
│   └── ...
├── frontend/                    # Flutter app (see FRONTEND_PLAN.md)
└── ...
```

---

*Detailed backend schemas and API design → [BACKEND_PLAN.md](BACKEND_PLAN.md)*
*Frontend dashboard and UI components → [FRONTEND_PLAN.md](FRONTEND_PLAN.md)*
