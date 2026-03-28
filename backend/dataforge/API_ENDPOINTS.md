# DataForge — API Endpoints

> All endpoints are prefixed with `/api/v1` when mounted in the main FastAPI app.

---

## 1. Projects

Base path: `/projects`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/projects` | Create a new project. Returns `project_id`, name, timestamps. |
| GET | `/projects` | List all projects. Supports `?skip=0&limit=50` pagination. |
| GET | `/projects/{project_id}` | Get a single project by ID. |
| PUT | `/projects/{project_id}` | Update project name and/or description. |
| DELETE | `/projects/{project_id}` | Soft-delete a project. |

---

## 2. Topology (Stage 1)

Base path: `/projects/{project_id}/topology`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/projects/{project_id}/topology` | Create/set the topology. Accepts components, edges, deployment mode, base user count, growth targets. |
| GET | `/projects/{project_id}/topology` | Get the current topology for a project. |
| PUT | `/projects/{project_id}/topology` | Partial update — only send fields you want to change. |
| POST | `/projects/{project_id}/topology/collapse` | Collapse topology to single-instance mode. Disables LB and CDN components. |

---

## 3. Component Specs (Stage 2.1)

Base path: `/projects/{project_id}/specs`

### Compute

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/projects/{project_id}/specs/compute/{component_id}` | Set the full compute spec for a topology component. Includes CPU cores, RAM, GPU, autoscaling config. |
| GET | `/projects/{project_id}/specs/compute/{component_id}` | Get the compute spec for a component. |
| PATCH | `/projects/{project_id}/specs/compute/{component_id}` | Partial update — only send fields you want to change. |

### Cache

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/projects/{project_id}/specs/cache/{component_id}` | Set cache spec. Includes cache DB type (Redis/Valkey/etc), memory, eviction policy, cluster nodes. |
| GET | `/projects/{project_id}/specs/cache/{component_id}` | Get cache spec for a component. |
| PATCH | `/projects/{project_id}/specs/cache/{component_id}` | Partial update of cache spec. |

### Load Balancer

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/projects/{project_id}/specs/lb/{component_id}` | Set LB spec. Includes algorithm, targets, SSL, estimated RPS and data volume. |
| GET | `/projects/{project_id}/specs/lb/{component_id}` | Get LB spec for a component. |
| PATCH | `/projects/{project_id}/specs/lb/{component_id}` | Partial update of LB spec. |

### CDN

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/projects/{project_id}/specs/cdn/{component_id}` | Set CDN spec. Includes provider, estimated transfer/requests, cache hit ratio. |
| GET | `/projects/{project_id}/specs/cdn/{component_id}` | Get CDN spec for a component. |
| PATCH | `/projects/{project_id}/specs/cdn/{component_id}` | Partial update of CDN spec. |

---

## 4. DB Schema Design (Stage 2.2)

Base path: `/projects/{project_id}/db/{component_id}`

### DB Model Spec

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/projects/{project_id}/db/{component_id}` | Set the full DB model spec. Includes database type, entities, relationships, base user count. |
| GET | `/projects/{project_id}/db/{component_id}` | Get the DB model spec. |
| PATCH | `/projects/{project_id}/db/{component_id}` | Update database type or base user count. |

### Entities

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/projects/{project_id}/db/{component_id}/entities` | Add a new entity (table/collection). Accepts name, fields, indexes, is_central flag. |
| PUT | `/projects/{project_id}/db/{component_id}/entities/{entity_id}` | Update an entity's name, fields, indexes, or central status. |
| DELETE | `/projects/{project_id}/db/{component_id}/entities/{entity_id}` | Delete an entity and all its relationships. |

### Fields

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/projects/{project_id}/db/{component_id}/entities/{entity_id}/fields` | Add a field to an entity. Supports PK/FK config, type, size, constraints. |
| PUT | `/projects/{project_id}/db/{component_id}/entities/{entity_id}/fields/{field_id}` | Update a field's type, PK/FK config, constraints, avg size. |
| DELETE | `/projects/{project_id}/db/{component_id}/entities/{entity_id}/fields/{field_id}` | Delete a field from an entity. |

### Relationships

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/projects/{project_id}/db/{component_id}/relationships` | Add a relationship between two entities. Includes type (1:1, 1:N, N:M), ratio, FK reference. |
| PUT | `/projects/{project_id}/db/{component_id}/relationships/{rel_id}` | Update relationship type, ratio, or FK binding. |
| DELETE | `/projects/{project_id}/db/{component_id}/relationships/{rel_id}` | Delete a relationship. |

### Validation & Projections

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/projects/{project_id}/db/{component_id}/validate` | Validate schema integrity — checks central entity, PK/FK references, connectivity. Returns `{valid: bool, errors: [...]}`. |
| GET | `/projects/{project_id}/db/{component_id}/storage-projection` | Calculate storage projection. Returns per-entity record counts, data size, index overhead, WAL estimate, total. |

---

## 5. Cost & Dashboard

Base path: `/projects/{project_id}/cost`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/projects/{project_id}/cost` | Get the consolidated cost dashboard. Includes total cost, per-component breakdown, per-category breakdown, per-entity storage costs, growth projections, and optimization hints. |
| GET | `/projects/{project_id}/cost/growth` | Get cost projections at each growth target user count. |
| POST | `/projects/{project_id}/cost/compare` | Compare current cost with an alternate database. Send `{"alternate_database_id": "mysql"}`. Returns dashboard with `comparison_delta`. |
| GET | `/projects/{project_id}/cost/per-entity` | Get per-entity storage cost attribution. Shows which tables/collections cost the most. |
| GET | `/projects/{project_id}/cost/hints` | Get optimization suggestions (e.g., add cache, use reserved instances). |
| GET | `/projects/{project_id}/cost/compute/{component_id}` | Get detailed compute cost breakdown for a specific component. |
| GET | `/projects/{project_id}/cost/database/{component_id}` | Get detailed DB cost breakdown (instance, storage, IOPS, backup, license). |
| GET | `/projects/{project_id}/cost/cache/{component_id}` | Get detailed cache cost breakdown for a specific component. |

---

## 6. Reference Data

Base path: `/reference`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/reference/databases` | List all 30 supported databases with ID, name, and category. |
| GET | `/reference/databases/{db_id}` | Get detailed metadata for a specific database (managed services, sharding, export format). |
| GET | `/reference/databases/categories` | List the 7 database categories (SQL, Document/KV, In-Memory, Graph, Vector, Search, Time-Series). |
| GET | `/reference/regions` | List all available cloud regions. |
| GET | `/reference/cloud-providers` | List supported cloud providers (AWS, GCP, Azure, Self-Hosted). |

---

## Endpoint Summary

| Category | Count |
|----------|-------|
| Projects | 5 |
| Topology | 4 |
| Compute Specs | 3 |
| Cache Specs | 3 |
| LB Specs | 3 |
| CDN Specs | 3 |
| DB Model Spec | 3 |
| Entities | 3 |
| Fields | 3 |
| Relationships | 3 |
| Validation & Projections | 2 |
| Cost & Dashboard | 8 |
| Reference Data | 5 |
| **Total** | **48** |

---

## Architecture Notes

- **Pattern**: Route → Service → Repository → Model (matches existing `users/` module)
- **DB Session**: Injected via `Depends(get_db)` from `core.db_client`
- **Validation**: All request/response models use Pydantic v2
- **IDs**: Generated with ULID (`proj_` prefix for projects, UUID v4 for entities/fields/components)
- **Soft Delete**: Projects use `is_deleted` flag, not hard delete
- **Cost Caching**: Dashboard results are cached in `project.cost_snapshot` for quick reads
- **JSON Columns**: Topology, specs, and cost snapshots stored as JSON in the Project table for single-read access
