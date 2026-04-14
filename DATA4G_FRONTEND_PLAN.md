# Data4G --- Frontend Implementation Plan

> Detailed plan for evolving the existing Flutter Web frontend to meet the Data4G requirements.

---

## 1. Current Frontend Structure

```
frontend/lib/
├── main.dart                                    # App entry, env init, ProviderScope
├── app/
│   ├── app.dart                                 # MaterialApp.router, dark theme
│   └── router.dart                              # GoRouter: /, /auth, /workspace/:section
├── core/
│   ├── config/app_environment.dart              # .env loading (local/cloud)
│   ├── network/api_client.dart                  # Dio singleton with JWT interceptor
│   ├── storage/session_storage.dart             # SharedPreferences (tokens, userId)
│   ├── theme/app_theme.dart                     # Cosmic dark theme, colors, fonts
│   ├── utils/formatting.dart                    # money(), compactNumber(), formatBytes()
│   └── widgets/cosmic_scaffold.dart             # Gradient background, grid, particles
├── features/
│   ├── landing/landing_screen.dart              # Marketing page with CTA
│   ├── auth/
│   │   ├── auth_controller.dart                 # AuthState + AuthController (Riverpod)
│   │   └── auth_screen.dart                     # Login/signup forms
│   ├── workspace/
│   │   ├── workspace_controller.dart            # WorkspaceState (projects, topologies, specs, dashboard)
│   │   └── workspace_screen.dart                # Header + body + footer, section switching
│   ├── topology/topology_canvas_view.dart       # Freeform canvas, draggable nodes, Bezier edges
│   ├── specs/spec_editor_view.dart              # Tabbed spec editors (compute, cache, LB, etc.)
│   ├── dashboard/dashboard_view.dart            # Cost charts (pie, line, bars), entity table, hints
│   ├── compare/compare_view.dart                # Topology + database comparison UI
│   └── settings/settings_view.dart              # Project info, members, access control
├── models/
│   ├── auth_models.dart                         # AuthSession, SignupResult, LoginPayload
│   ├── project_models.dart                      # ProjectSummary, MemberRecord, ProjectRole
│   ├── topology_models.dart                     # TopologyComponent, TopologyEdge, TopologyModel
│   ├── spec_models.dart                         # All spec models (Compute, Cache, LB, CDN, K8s, Docker, DB)
│   ├── dashboard_models.dart                    # ConsolidatedDashboard, GrowthProjection, Hints
│   ├── comparison_models.dart                   # ComponentDiff, TopologyComparison
│   └── reference_models.dart                    # DatabaseReference, ReferenceOption
└── data/
    ├── auth_repository.dart                     # Auth API calls (signup, login, verify)
    ├── dataforge_repository.dart                # All dataforge API calls
    └── demo_data.dart                           # Hardcoded demo data for offline/demo mode
```

---

## 2. Target Frontend Structure (New / Modified Files)

Files marked with `[NEW]` are entirely new. Files marked with `[MOD]` require modifications. Files marked with `[KEEP]` are unchanged.

```
frontend/lib/
├── main.dart                                    [KEEP]
├── app/
│   ├── app.dart                                 [KEEP]
│   └── router.dart                              [MOD] Add new routes for drill-down views
├── core/
│   ├── config/app_environment.dart              [KEEP]
│   ├── network/api_client.dart                  [KEEP]
│   ├── storage/session_storage.dart             [MOD] Add team storage
│   ├── theme/app_theme.dart                     [MOD] Add risk severity colors, new component colors
│   ├── utils/formatting.dart                    [MOD] Add risk score formatting
│   └── widgets/
│       ├── cosmic_scaffold.dart                 [KEEP]
│       └── auto_layout_engine.dart              [NEW] Dagre-style structured layout
├── features/
│   ├── landing/landing_screen.dart              [MOD] Update branding Data4G, add MCP section
│   ├── auth/
│   │   ├── auth_controller.dart                 [KEEP]
│   │   └── auth_screen.dart                     [KEEP]
│   ├── workspace/
│   │   ├── workspace_controller.dart            [MOD] Add risk, traffic, MCP state
│   │   └── workspace_screen.dart                [MOD] Add Risk tab, rename sections
│   ├── topology/
│   │   ├── topology_canvas_view.dart            [MOD] Replace freeform with auto-layout
│   │   ├── topology_node_widget.dart            [NEW] Redesigned component node for auto-layout
│   │   └── topology_edge_painter.dart           [NEW] Edge rendering for structured layout
│   ├── drilldown/                               [NEW] --- Drill-down views
│   │   ├── server_drilldown_view.dart           [NEW] Server -> endpoint list with details
│   │   ├── database_drilldown_view.dart         [NEW] Database -> Power BI-style model view
│   │   ├── cache_drilldown_view.dart            [NEW] Cache -> key types, TTLs, endpoint usage
│   │   └── queue_drilldown_view.dart            [NEW] Queue -> producers, consumers, partitions
│   ├── risk/                                    [NEW] --- Risk analysis UI
│   │   ├── risk_dashboard_view.dart             [NEW] Risk overview with scores and distribution
│   │   ├── risk_endpoint_list.dart              [NEW] Ranked endpoint list by risk score
│   │   └── risk_finding_detail.dart             [NEW] Individual finding with code snippet
│   ├── traffic/                                 [NEW] --- Traffic simulation UI
│   │   ├── traffic_simulation_view.dart         [NEW] QPS input, cascade visualization
│   │   └── bottleneck_view.dart                 [NEW] Bottleneck identification display
│   ├── specs/spec_editor_view.dart              [MOD] Add editors for new component types
│   ├── dashboard/dashboard_view.dart            [MOD] Add risk scores, traffic metrics
│   ├── compare/compare_view.dart                [MOD] Add metric comparison (cost, perf, risk)
│   ├── settings/settings_view.dart              [MOD] Add team management, invite links
│   ├── teams/                                   [NEW] --- Team management
│   │   ├── team_screen.dart                     [NEW] Team CRUD, member list
│   │   └── invite_screen.dart                   [NEW] Invite link generation, join flow
│   ├── export/                                  [NEW] --- Export UI
│   │   └── export_dialog.dart                   [NEW] Format selection, download trigger
│   └── share/                                   [NEW] --- Shareable links
│       ├── share_dialog.dart                    [NEW] Generate share link UI
│       └── shared_view.dart                     [NEW] Read-only view for shared links (no auth)
├── models/
│   ├── auth_models.dart                         [KEEP]
│   ├── project_models.dart                      [MOD] Add git_repo_url, team_id
│   ├── topology_models.dart                     [MOD] Add TopologyType, cloned_from, sync metadata
│   ├── spec_models.dart                         [MOD] Add 5 new spec models
│   ├── dashboard_models.dart                    [MOD] Add risk score fields
│   ├── comparison_models.dart                   [MOD] Add MetricComparison model
│   ├── reference_models.dart                    [KEEP]
│   ├── endpoint_models.dart                     [NEW] EndpointMetadata, ServerEndpointRegistry
│   ├── risk_models.dart                         [NEW] RiskFinding, RiskDashboard, EndpointRiskSummary
│   ├── traffic_models.dart                      [NEW] TrafficInput, TrafficSimulationResult
│   ├── team_models.dart                         [NEW] Team, TeamInvite
│   ├── mcp_models.dart                          [NEW] MCPSyncStatus, MCPSyncHistory
│   ├── export_models.dart                       [NEW] ExportRequest, ExportResponse
│   └── share_models.dart                        [NEW] ShareLink
└── data/
    ├── auth_repository.dart                     [KEEP]
    ├── dataforge_repository.dart                [MOD] Add all new API calls
    ├── team_repository.dart                     [NEW] Team API calls
    └── demo_data.dart                           [MOD] Add demo data for new features
```

---

## 3. Routing Changes --- `app/router.dart` [MOD]

### Current Routes
```
/                           -> LandingScreen
/auth?mode=signin|signup    -> AuthScreen
/workspace/:section         -> WorkspaceScreen (topology, specs, dashboard, compare, settings)
```

### New Routes
```
/                                          -> LandingScreen
/auth?mode=signin|signup                   -> AuthScreen
/workspace/:section                        -> WorkspaceScreen
    section values: topology, specs, dashboard, compare, risk, traffic, settings

# Drill-down routes (nested under workspace context)
/workspace/topology/server/:componentId    -> ServerDrilldownView
/workspace/topology/database/:componentId  -> DatabaseDrilldownView
/workspace/topology/cache/:componentId     -> CacheDrilldownView
/workspace/topology/queue/:componentId     -> QueueDrilldownView

# Team routes
/teams                                     -> TeamScreen (list/create)
/teams/:teamId                             -> TeamScreen (detail)
/teams/join/:inviteToken                   -> InviteScreen (join flow)

# Shared read-only views (no auth required)
/shared/:shareToken                        -> SharedView
```

---

## 4. Major UI Changes

### 4.1 Topology Canvas Overhaul --- Freeform to Structured Auto-Layout

**Current behavior:** Nodes are freely draggable on a 2200x1400 canvas. Users manually position components. Edges are Bezier curves between node centers.

**Target behavior:** Auto-laid-out structured diagram (draw.io / Lucidchart style) with:
- Automatic node positioning using a Dagre-style layered graph layout algorithm
- Nodes arranged in logical layers (clients -> gateways -> servers -> databases/caches)
- Directed arrows showing data/request flow direction
- Click any component to drill down

#### Implementation: `core/widgets/auto_layout_engine.dart` [NEW]

```dart
/// Dagre-style layered graph layout for topology visualization.
class AutoLayoutEngine {
  /// Takes components and edges, returns positioned nodes.
  LayoutResult computeLayout({
    required List<TopologyComponent> components,
    required List<TopologyEdge> edges,
    double nodeWidth = 180,
    double nodeHeight = 80,
    double horizontalSpacing = 60,
    double verticalSpacing = 80,
  });
}

class LayoutResult {
  final Map<String, Offset> nodePositions;  // componentId -> (x, y)
  final List<LayoutEdge> edges;             // Routed edge paths
}

class LayoutEdge {
  final String sourceId;
  final String targetId;
  final List<Offset> waypoints;  // Control points for smooth routing
}
```

**Layout algorithm approach:**
1. **Layer assignment:** Assign each component to a layer based on type hierarchy:
   - Layer 0: Client, CDN
   - Layer 1: Load Balancer, API Gateway
   - Layer 2: Server (Compute), Service Mesh, Cron
   - Layer 3: Database, Cache, Queue, Object Storage
   - Layer 4: Third-party APIs
2. **Ordering within layers:** Minimize edge crossings using barycenter heuristic
3. **Coordinate assignment:** Position nodes with uniform spacing per layer
4. **Edge routing:** Route edges through layers with orthogonal or smooth curves

**Key differences from current canvas:**
- Remove free drag-to-reposition (nodes stay in computed positions)
- Add zoom/pan via InteractiveViewer (keep this)
- Add click-to-drill-down (replace click-to-inspect)
- Live topologies render as completely read-only (no add/remove/connect)
- Experimental topologies allow add/remove components and connections (re-layout on change)

#### Changes to `topology_canvas_view.dart` [MOD]

```dart
// REMOVE: Manual drag state, onPanUpdate handlers for node repositioning
// REMOVE: Direct position storage in component tags (canvas_x, canvas_y)
// REMOVE: Inspector panel (replaced by drill-down navigation)

// ADD: AutoLayoutEngine integration
// ADD: Click handler -> navigate to drill-down route
// ADD: Live/Experimental badge and mode indicator
// ADD: "Clone to Experiment" button (visible on live topologies)
// ADD: Component add/remove toolbar (visible only on experimental topologies)

// KEEP: InteractiveViewer for zoom/pan
// KEEP: Edge rendering (but switch to waypoint-based routing)
// KEEP: Component type color coding
// KEEP: Deployment mode selector (experimental only)
```

---

### 4.2 Drill-Down Views [NEW]

#### Server Drill-Down --- `features/drilldown/server_drilldown_view.dart`

```
+-----------------------------------------------------------------------+
|  < Back to Topology          Server: api-server                        |
+-----------------------------------------------------------------------+
|                                                                         |
|  Infra: 4 vCPU | 16GB RAM | m5.xlarge | us-east-1 | 3 replicas        |
|                                                                         |
|  --- Endpoints (24 total) -------------------------------------------- |
|                                                                         |
|  +-------------------------------------------------------------------+ |
|  | GET /api/v1/users           Risk: 2.1  [LOW]                      | |
|  |   DB: SELECT users (paginated)                                    | |
|  |   Cache: GET user:{id}:profile (TTL: 3600s)                      | |
|  +-------------------------------------------------------------------+ |
|  | GET /api/v1/users/{id}/orders  Risk: 7.8  [HIGH]                  | |
|  |   DB: SELECT orders WHERE user_id=? (NO PAGINATION)              | |
|  |   DB: SELECT order_items WHERE order_id IN (?) (N+1)             | |
|  |   Cache: none                                                     | |
|  |   Service: payment-service GET /api/v1/payments                   | |
|  |   Findings: N+1 query, Missing pagination                        | |
|  +-------------------------------------------------------------------+ |
|  | POST /api/v1/orders          Risk: 3.5  [MEDIUM]                  | |
|  |   DB: INSERT orders                                               | |
|  |   Queue: PRODUCE order_events                                     | |
|  |   Service: inventory-service POST /api/v1/reserve                 | |
|  +-------------------------------------------------------------------+ |
|  | ...                                                                | |
|                                                                         |
|  Sort: [Risk Score v] [Path] [Method]   Filter: [All Types v]          |
+-----------------------------------------------------------------------+
```

**Key features:**
- List all endpoints with their risk score and severity badge
- Expand endpoint to see: DB calls, cache calls, service calls, queue interactions
- Risk findings inline with recommendations
- Sort by risk score, path, method
- Filter by risk type

#### Database Drill-Down --- `features/drilldown/database_drilldown_view.dart`

Power BI-style entity-relationship view:

```
+-----------------------------------------------------------------------+
|  < Back to Topology          Database: main-db (PostgreSQL)            |
+-----------------------------------------------------------------------+
|                                                                         |
|  +-------------+     1:N (50)     +--------------+    1:N (4)          |
|  |   User      |---------------->|    Order      |----------->+-------+|
|  |-------------|                  |--------------|            |OrderIt||
|  | id     UUID |                  | id      UUID |            |-------||
|  | email  STR  |                  | user_id UUID |            | id    ||
|  | name   STR  |                  | total   DEC  |            | qty   ||
|  | created DT  |                  | status  ENUM |            | price ||
|  +-------------+                  +--------------+            +-------+|
|        |                                                                |
|        | 1:N (200)                                                      |
|        v                                                                |
|  +-------------+                                                        |
|  |   Event     |                                                        |
|  |-------------|                                                        |
|  | id     UUID |     Storage Projection:                                |
|  | user_id UUID|     User:    1,000 rows   x 256B =    250 KB          |
|  | type   ENUM |     Order:  50,000 rows   x 192B =   9.2 MB          |
|  | data   JSON |     Event: 200,000 rows   x 320B =  61.0 MB          |
|  +-------------+     Total:                           70.5 MB          |
|                                                                         |
|  [View-only for live topology]                                          |
+-----------------------------------------------------------------------+
```

**Key features:**
- Entity cards with field name, type, PK/FK indicators
- Relationship lines with type labels and ratio values
- Auto-layout for entity positions (separate layout from topology)
- Storage projection sidebar
- View-only for live topologies; editable for experimental (links to spec editor)

#### Cache Drill-Down --- `features/drilldown/cache_drilldown_view.dart`

```
+-----------------------------------------------------------------------+
|  < Back to Topology          Cache: redis-primary (Redis)              |
+-----------------------------------------------------------------------+
|                                                                         |
|  Memory: 4GB | Nodes: 3 | Eviction: LRU | HA: Yes                     |
|                                                                         |
|  --- Cache Key Types ------------------------------------------------- |
|                                                                         |
|  +-------------------------------------------------------------------+ |
|  | Pattern: user:{id}:profile                 TTL: 3600s             | |
|  | Used in:                                                          | |
|  |   GET /api/v1/users/{id}          (READ)                         | |
|  |   PUT /api/v1/users/{id}          (WRITE + INVALIDATE)           | |
|  +-------------------------------------------------------------------+ |
|  | Pattern: order:{id}:summary                TTL: 1800s             | |
|  | Used in:                                                          | |
|  |   GET /api/v1/orders/{id}         (READ)                         | |
|  |   POST /api/v1/orders/{id}/pay    (INVALIDATE)                   | |
|  +-------------------------------------------------------------------+ |
|  | Pattern: feed:{user_id}:page:{n}           TTL: 300s              | |
|  | Used in:                                                          | |
|  |   GET /api/v1/feed                (READ)                         | |
|  +-------------------------------------------------------------------+ |
|                                                                         |
+-----------------------------------------------------------------------+
```

#### Queue Drill-Down --- `features/drilldown/queue_drilldown_view.dart`

```
+-----------------------------------------------------------------------+
|  < Back to Topology          Queue: order-events (Kafka)               |
+-----------------------------------------------------------------------+
|                                                                         |
|  Partitions: 6 | Strategy: Round-robin | Retention: 7 days            |
|                                                                         |
|  --- Producers --------------------------------------------------------|
|  POST /api/v1/orders          -> order.created                         |
|  PUT /api/v1/orders/{id}/pay  -> order.paid                            |
|  DELETE /api/v1/orders/{id}   -> order.cancelled                       |
|                                                                         |
|  --- Consumers --------------------------------------------------------|
|  notification-service         <- order.created, order.paid             |
|  analytics-service            <- order.created, order.paid, order.cancelled |
|  inventory-service            <- order.created, order.cancelled        |
|                                                                         |
+-----------------------------------------------------------------------+
```

---

### 4.3 Risk Analysis UI [NEW] --- `features/risk/`

#### Risk Dashboard --- `risk_dashboard_view.dart`

```
+-----------------------------------------------------------------------+
|  Risk Analysis                          Last scan: 5 minutes ago       |
|                                         [Scan Now]                     |
+-----------------------------------------------------------------------+
|                                                                         |
|  +------------------+  +--------------------------------------------+ |
|  | Overall Score     |  | Risk Distribution                         | |
|  |                   |  |                                            | |
|  |     6.2 / 10     |  | Critical  ███░░░░░░░░░░░░░░  3            | |
|  |     [HIGH]       |  | High      █████████░░░░░░░░  8            | |
|  |                   |  | Medium    ████████████░░░░░  12           | |
|  | 47 endpoints     |  | Low       █████░░░░░░░░░░░░  5            | |
|  | 28 findings      |  | Info      ██░░░░░░░░░░░░░░░  2            | |
|  +------------------+  +--------------------------------------------+ |
|                                                                         |
|  +-------------------------------------------------------------------+ |
|  | Risk by Type                                                      | |
|  |                                                                   | |
|  |  N+1 Queries:          8                                          | |
|  |  Missing Pagination:   6                                          | |
|  |  Unbounded Fetch:      5                                          | |
|  |  Full Table Scan:      4                                          | |
|  |  Missing Index:        3                                          | |
|  |  Race Condition:       2                                          | |
|  +-------------------------------------------------------------------+ |
|                                                                         |
|  --- High-Risk Endpoints (sorted by score) --------------------------- |
|                                                                         |
|  [Endpoint list with expandable risk details - see risk_endpoint_list]  |
|                                                                         |
|  Filter: [All Severities v] [All Risk Types v]  Sort: [Score v]        |
+-----------------------------------------------------------------------+
```

#### Risk Endpoint List --- `risk_endpoint_list.dart`

Reusable widget showing ranked endpoints:

```dart
class RiskEndpointList extends ConsumerWidget {
  // Props: list of EndpointRiskSummary, filters, sort order
  // Renders: expandable cards per endpoint
  //   - Header: method badge, path, risk score pill, finding count
  //   - Expanded: list of RiskFinding cards with severity, message, recommendation
  //   - Click-through to source file (if available)
}
```

#### Risk Finding Detail --- `risk_finding_detail.dart`

```dart
class RiskFindingDetail extends StatelessWidget {
  // Props: RiskFinding
  // Renders:
  //   - Severity badge (colored: critical=red, high=orange, medium=yellow, low=blue)
  //   - Risk type label
  //   - Message (human-readable description)
  //   - Source file + line reference
  //   - Code snippet (if available, with syntax highlighting)
  //   - Recommendation text
}
```

---

### 4.4 Traffic Simulation UI [NEW] --- `features/traffic/`

#### Traffic Simulation View --- `traffic_simulation_view.dart`

```
+-----------------------------------------------------------------------+
|  Traffic Simulation                                                    |
+-----------------------------------------------------------------------+
|                                                                         |
|  --- Entry Points (set QPS per endpoint) ------------------------------ |
|                                                                         |
|  GET  /api/v1/users           [----*---------] 500 req/s               |
|  GET  /api/v1/users/{id}      [------*-------] 1000 req/s              |
|  POST /api/v1/orders          [--*-----------] 200 req/s               |
|  GET  /api/v1/feed            [--------*-----] 2000 req/s              |
|                                                                         |
|  Total Entry QPS: 3,700 req/s              [Run Simulation]            |
|                                                                         |
|  --- Cascade Results ------------------------------------------------- |
|                                                                         |
|  +--------------------+   +--------------------+   +-----------------+ |
|  | api-server         |   | main-db            |   | redis-cache     | |
|  | 3,700 req/s        |-->| 8,200 queries/s    |   | 4,500 ops/s     | |
|  | Capacity: OK       |   | Capacity: WARNING  |   | Capacity: OK    | |
|  +--------------------+   +--------------------+   +-----------------+ |
|           |                                                             |
|           v                                                             |
|  +--------------------+   +--------------------+                        |
|  | payment-service    |   | order-events       |                        |
|  | 200 req/s          |   | 200 msg/s          |                        |
|  | Capacity: OK       |   | Capacity: OK       |                        |
|  +--------------------+   +--------------------+                        |
|                                                                         |
|  --- Bottlenecks ----------------------------------------------------- |
|  ! main-db: 8,200 queries/s exceeds estimated capacity (5,000 IOPS)   |
|    Recommendation: Add read replicas or cache frequently-read queries  |
|                                                                         |
|  --- Estimated Cost at This Traffic ---------------------------------- |
|  Total: $3,847/mo (+$2,600 vs. current base estimate)                  |
+-----------------------------------------------------------------------+
```

**Key features:**
- Slider or input per entry-point endpoint for QPS
- "Run Simulation" triggers POST to `/simulate/traffic`
- Results show per-component load with capacity status (OK/WARNING/CRITICAL)
- Visual cascade showing traffic flow and multipliers
- Bottleneck identification with recommendations
- Cost estimate at the simulated traffic level

---

### 4.5 Workspace Screen Changes [MOD]

#### Header Navigation Tabs

**Current:** Topology | Specs | Dashboard | Compare | Settings

**New:** Topology | Specs | Risk | Traffic | Dashboard | Compare | Settings

#### Live vs. Experimental Topology Indicator

Add a prominent badge/chip in the workspace header:

```dart
// In workspace header, next to topology selector:
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  decoration: BoxDecoration(
    color: topology.isLive ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: topology.isLive ? Colors.green : Colors.orange),
  ),
  child: Text(
    topology.isLive ? "LIVE" : "EXPERIMENTAL",
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
  ),
)
```

#### Topology Selector Enhancement

Add "Clone to Experiment" button next to topology dropdown when viewing a live topology:

```dart
if (selectedTopology?.topologyType == TopologyType.live)
  ElevatedButton.icon(
    icon: Icon(Icons.science),
    label: Text("Clone to Experiment"),
    onPressed: () => _cloneToExperimental(),
  )
```

#### Footer Enhancement

**Current:** Total monthly cost | Base users | Mode | Topologies count | Data source

**New:** Total monthly cost | Risk Score | Base users | Mode | Last MCP Sync | Data source

---

### 4.6 Spec Editor Changes [MOD] --- `features/specs/spec_editor_view.dart`

#### Add New Spec Editor Tabs

**Current tabs:** Compute | Cache | Load Balancer | CDN | K8s | Docker | Database

**New tabs:** Compute | Cache | Load Balancer | CDN | K8s | Docker | Database | API Gateway | Cron Jobs | Object Storage | Service Mesh | Third-party APIs

#### New Spec Editor Panels

**API Gateway Panel:**
- Rate limiting config (toggle, req/s, burst, window)
- Auth type dropdown (JWT, API Key, OAuth2, None)
- Routing rules table (path pattern, target component, methods)
- CORS toggle, request logging toggle
- Estimated req/s input

**Cron Job Panel:**
- Cron expression input with preview (e.g., "Every 6 hours")
- Target service/endpoint selector
- Retry policy config (max retries, backoff)
- Timeout input
- Estimated duration and compute cost per run

**Object Storage Panel:**
- Provider dropdown
- Storage estimate (GB) slider
- Request estimate slider
- Egress estimate slider
- Access policy dropdown
- Versioning toggle
- Lifecycle rules editor

**Service Mesh Panel:**
- mTLS toggle
- Circuit breaker config (threshold, recovery timeout, half-open requests)
- Retry policy config
- Load balancing algorithm dropdown
- Observability toggle
- Sidecar resource requests

**Third-party API Panel:**
- URL input
- SLA uptime percentage
- Expected latency input
- Fallback behavior dropdown (circuit breaker, cache fallback, error)
- Estimated calls/month
- Cost model (per-call or subscription)

---

### 4.7 Dashboard Changes [MOD] --- `features/dashboard/dashboard_view.dart`

**Add to existing dashboard:**

1. **Risk Score Card** (new, alongside Total Cost):
```
+------------------+
| Risk Score       |
|     6.2 / 10     |
|     [HIGH]       |
| 28 findings      |
+------------------+
```

2. **Risk in Growth Projection:** Add risk score trend line to growth chart (does risk increase with scale?).

3. **Traffic Simulation Summary Card** (if simulation has been run):
```
+---------------------------+
| Traffic Simulation        |
| Entry QPS: 3,700          |
| Bottlenecks: 1            |
| Est. Cost at QPS: $3,847  |
+---------------------------+
```

---

### 4.8 Compare View Changes [MOD] --- `features/compare/compare_view.dart`

**Current:** Structural diff (added/removed/modified components) + database cost comparison.

**Target:** Metric comparison dashboard.

```
+-----------------------------------------------------------------------+
|  Topology Comparison                                                   |
+-----------------------------------------------------------------------+
|  Topology A: [Core Platform (Live) v]                                  |
|  Topology B: [Scaled Platform (Experimental) v]                        |
+-----------------------------------------------------------------------+
|                                                                         |
|  +-------------------------------------------------------------------+ |
|  | Metric              | Topology A      | Topology B    | Delta     | |
|  |---------------------|-----------------|---------------|-----------|  |
|  | Monthly Cost        | $1,247          | $3,847        | +$2,600   | |
|  | Risk Score          | 6.2             | 4.1           | -2.1      | |
|  | Components          | 8               | 12            | +4        | |
|  | Est. Max QPS        | 1,000           | 5,000         | +4,000    | |
|  | Bottlenecks         | 3               | 1             | -2        | |
|  | DB Storage (proj.)  | 70 MB           | 70 MB         | --        | |
|  +-------------------------------------------------------------------+ |
|                                                                         |
|  +-------------------------------------------------------------------+ |
|  | Cost Comparison (Bar Chart)                                       | |
|  |                                                                   | |
|  |  Compute   |████████    |  |██████████████████|                   | |
|  |  Database  |█████████   |  |█████████         |                   | |
|  |  Cache     |████        |  |████████████      |                   | |
|  |  LB        |██          |  |████              |                   | |
|  |                                                                   | |
|  |  [Blue = Topology A]  [Orange = Topology B]                       | |
|  +-------------------------------------------------------------------+ |
|                                                                         |
|  Navigate: [Open Topology A] [Open Topology B]                         |
+-----------------------------------------------------------------------+
```

---

### 4.9 Settings Changes [MOD] --- `features/settings/settings_view.dart`

**Add:**
- **Git Repository** section: Display linked repo URL, last MCP sync time, sync mode config
- **Team Management** section: Team name, invite link generation button, member list
- **MCP Configuration** section: Enable/disable auto-sync, sync frequency, language/framework selection

**Add to existing Member Card:**
- Invite link generation (instead of only user-ID-based member addition)

---

### 4.10 Team Management [NEW] --- `features/teams/`

#### Team Screen --- `team_screen.dart`

```
+-----------------------------------------------------------------------+
|  Teams                                              [Create Team]      |
+-----------------------------------------------------------------------+
|                                                                         |
|  +-------------------------------------------------------------------+ |
|  | Backend Engineering                                                | |
|  | 5 members | 3 projects                                            | |
|  | Owner: you                              [Manage] [Invite]          | |
|  +-------------------------------------------------------------------+ |
|  | Platform Team                                                      | |
|  | 8 members | 7 projects                                            | |
|  | Member                                  [View]                     | |
|  +-------------------------------------------------------------------+ |
|                                                                         |
+-----------------------------------------------------------------------+
```

#### Invite Screen --- `invite_screen.dart`

For generating invite links:
```
+-----------------------------------------------------------------------+
|  Invite to: Backend Engineering                                        |
+-----------------------------------------------------------------------+
|                                                                         |
|  Share this link with your team:                                       |
|  +-------------------------------------------------------------------+ |
|  | https://data4g.example.com/teams/join/abc123def456  [Copy]        | |
|  +-------------------------------------------------------------------+ |
|                                                                         |
|  Max uses: [Unlimited v]                                               |
|  Expires: [30 days v]                                                  |
|                                                                         |
|  [Generate New Link]                                                   |
+-----------------------------------------------------------------------+
```

For joining via invite link (unauthenticated users redirected to signup first):
```
+-----------------------------------------------------------------------+
|  You've been invited to join:                                          |
|  Backend Engineering                                                   |
|                                                                         |
|  [Join Team]    [Decline]                                              |
+-----------------------------------------------------------------------+
```

---

### 4.11 Export & Share [NEW]

#### Export Dialog --- `features/export/export_dialog.dart`

Modal dialog triggered from workspace header:

```
+---------------------------------------+
|  Export Topology                       |
+---------------------------------------+
|                                        |
|  Format: ( ) PNG  (o) SVG  ( ) PDF    |
|                                        |
|  [x] Include component specs          |
|  [x] Include cost summary             |
|  [ ] Include risk analysis            |
|                                        |
|  [Cancel]           [Export]           |
+---------------------------------------+
```

#### Share Dialog --- `features/share/share_dialog.dart`

```
+---------------------------------------+
|  Share Topology                        |
+---------------------------------------+
|                                        |
|  Anyone with this link can view:       |
|  +-----------------------------------+|
|  | https://data4g.example.com/       ||
|  | shared/xyz789...  [Copy]          ||
|  +-----------------------------------+|
|                                        |
|  Expires: [30 days v]                  |
|                                        |
|  [Revoke]           [Done]            |
+---------------------------------------+
```

#### Shared View --- `features/share/shared_view.dart`

Read-only view rendered when accessing `/shared/:token`:
- No auth required
- Shows topology diagram (auto-layout, non-interactive)
- Shows cost dashboard (read-only)
- Branded header: "Shared via Data4G"
- No edit controls, no navigation to other features

---

## 5. Model Changes

### 5.1 `models/topology_models.dart` [MOD]

```dart
// Add enum:
enum TopologyType { live, experimental }

// Add to TopologyModel:
class TopologyModel {
  // ... existing fields ...
  final TopologyType topologyType;    // NEW
  final String? clonedFrom;           // NEW: ID of source live topology
  final DateTime? lastSyncedAt;       // NEW: For live topologies
  final int syncVersion;              // NEW
  
  bool get isLive => topologyType == TopologyType.live;
  bool get isExperimental => topologyType == TopologyType.experimental;
}
```

### 5.2 `models/endpoint_models.dart` [NEW]

```dart
class EndpointMetadata {
  final String id;
  final String path;
  final String httpMethod;
  final String handlerFunction;
  final String sourceFile;
  final List<DBCallMetadata> dbCalls;
  final List<CacheCallMetadata> cacheCalls;
  final List<ServiceCallMetadata> serviceCalls;
  final List<QueueInteraction> queueInteractions;
  final double riskScore;
  final List<String> riskFindings;
}

class DBCallMetadata {
  final String queryType;       // SELECT, INSERT, UPDATE, DELETE
  final String targetEntity;
  final bool isPaginated;
  final String? estimatedRowsAffected;
}

class CacheCallMetadata {
  final String operation;       // GET, SET, DELETE, INVALIDATE
  final String keyPattern;
  final int? ttlSeconds;
}

class ServiceCallMetadata {
  final String targetService;
  final String targetEndpoint;
  final String httpMethod;
  final bool isAsync;
}

class QueueInteraction {
  final String role;            // producer, consumer
  final String queueName;
  final String? messageType;
}

class ServerEndpointRegistry {
  final String topologyComponentId;
  final List<EndpointMetadata> endpoints;
  final DateTime? lastSyncedAt;
  final int syncVersion;
}
```

### 5.3 `models/risk_models.dart` [NEW]

```dart
enum RiskSeverity { critical, high, medium, low, info }
enum RiskType { nPlusOne, missingPagination, unboundedFetch, fullTableScan, missingIndex, inefficientJoin, raceCondition }

class RiskFinding {
  final String id;
  final String endpointId;
  final String endpointPath;
  final RiskType riskType;
  final RiskSeverity severity;
  final String message;
  final String sourceFile;
  final String? codeSnippet;
  final String recommendation;
  final DateTime detectedAt;
}

class EndpointRiskSummary {
  final String endpointId;
  final String endpointPath;
  final String httpMethod;
  final double overallRiskScore;
  final int findingCount;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final List<RiskFinding> findings;
}

class RiskDashboard {
  final String projectId;
  final String topologyId;
  final int totalEndpoints;
  final int analyzedEndpoints;
  final double overallRiskScore;
  final Map<String, int> riskDistribution;
  final List<EndpointRiskSummary> topRisks;
  final Map<String, int> riskByType;
  final DateTime? lastAnalyzedAt;
}
```

### 5.4 `models/traffic_models.dart` [NEW]

```dart
class EntryPointTraffic {
  final String endpointId;
  final double requestsPerSecond;
}

class TrafficInput {
  final List<EntryPointTraffic> entryPoints;
}

class ComponentTrafficLoad {
  final String componentId;
  final String componentName;
  final String componentType;
  final double totalRequestsPerSecond;
  final List<TrafficSource> breakdown;
}

class TrafficSource {
  final String sourceEndpointId;
  final String sourceEndpointPath;
  final double requestsPerSecond;
  final double multiplier;
}

class TrafficSimulationResult {
  final String topologyId;
  final double entryPointTotalQps;
  final List<ComponentTrafficLoad> perComponentLoad;
  final List<String> bottleneckComponents;
  final double estimatedTotalLatencyMs;
}
```

### 5.5 `models/spec_models.dart` [MOD]

**Add 5 new spec classes** (matching backend schemas):

```dart
class APIGatewaySpec { ... }
class CronJobSpec { ... }
class ObjectStorageSpec { ... }
class ServiceMeshSpec { ... }
class ThirdPartyAPISpec { ... }
```

### 5.6 `models/team_models.dart` [NEW]

```dart
class Team {
  final String teamId;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;
}

class TeamInvite {
  final String inviteId;
  final String teamId;
  final String inviteToken;
  final int? maxUses;
  final int useCount;
  final DateTime? expiresAt;
  final bool isActive;
}
```

### 5.7 `models/project_models.dart` [MOD]

```dart
class ProjectSummary {
  // ... existing fields ...
  final String? gitRepoUrl;      // NEW
  final String? teamId;          // NEW
  final String cloudProvider;    // NEW
  final DateTime? lastMcpSyncAt; // NEW
}
```

---

## 6. Repository / API Client Changes

### 6.1 `data/dataforge_repository.dart` [MOD]

**Add new API calls:**

```dart
// --- Topology ---
Future<TopologyModel> cloneTopology(String projectId, String topologyId);
  // POST /projects/{pid}/topology/{tid}/clone

// --- Endpoints (MCP-sourced) ---
Future<ServerEndpointRegistry> getEndpoints(String projectId, String componentId);
  // GET /projects/{pid}/endpoints/{componentId}

// --- Risk ---
Future<RiskDashboard> getRiskDashboard(String projectId);
  // GET /projects/{pid}/risk
Future<List<EndpointRiskSummary>> getRiskEndpoints(String projectId);
  // GET /projects/{pid}/risk/endpoints
Future<void> triggerRiskAnalysis(String projectId);
  // POST /projects/{pid}/risk/analyze

// --- Traffic Simulation ---
Future<TrafficSimulationResult> simulateTraffic(String projectId, TrafficInput input);
  // POST /projects/{pid}/simulate/traffic

// --- New Specs ---
Future<APIGatewaySpec> getApiGatewaySpec(String projectId, String componentId);
Future<void> setApiGatewaySpec(String projectId, String componentId, APIGatewaySpec spec);
// ... same pattern for Cron, ObjectStorage, ServiceMesh, ThirdParty

// --- Export ---
Future<String> exportTopology(String projectId, String topologyId, String format);
  // POST /projects/{pid}/export -> returns download URL

// --- Share ---
Future<String> createShareLink(String resourceType, String resourceId);
  // POST /share -> returns share URL
Future<Map<String, dynamic>> resolveShareLink(String token);
  // GET /share/{token}
```

### 6.2 `data/team_repository.dart` [NEW]

```dart
class TeamRepository {
  Future<List<Team>> listTeams();
  Future<Team> createTeam(String name);
  Future<Team> getTeam(String teamId);
  Future<void> updateTeam(String teamId, String name);
  Future<void> deleteTeam(String teamId);
  Future<TeamInvite> generateInvite(String teamId, {int? maxUses, int? expiresInDays});
  Future<void> joinTeam(String inviteToken);
  Future<void> removeMember(String teamId, String userId);
}
```

---

## 7. State Management Changes

### 7.1 WorkspaceController [MOD]

**Add to WorkspaceState:**

```dart
class WorkspaceState {
  // ... existing fields ...
  
  // NEW: Risk analysis
  final RiskDashboard? riskDashboard;
  final bool isRiskLoading;
  
  // NEW: Traffic simulation
  final TrafficSimulationResult? trafficResult;
  final bool isTrafficLoading;
  
  // NEW: Endpoint registries (MCP-sourced)
  final Map<String, ServerEndpointRegistry> endpointRegistries;
  
  // NEW: MCP sync status
  final DateTime? lastMcpSyncAt;
  final String? mcpSyncStatus;
  
  // NEW: New spec types
  final Map<String, APIGatewaySpec> apiGatewaySpecs;
  final Map<String, CronJobSpec> cronSpecs;
  final Map<String, ObjectStorageSpec> objectStorageSpecs;
  final Map<String, ServiceMeshSpec> serviceMeshSpecs;
  final Map<String, ThirdPartyAPISpec> thirdPartySpecs;
}
```

**Add methods:**

```dart
// Risk
Future<void> loadRiskDashboard();
Future<void> triggerRiskAnalysis();

// Traffic
Future<void> runTrafficSimulation(TrafficInput input);

// Endpoints
Future<void> loadEndpoints(String componentId);

// Topology
Future<void> cloneToExperimental(String topologyId);

// New specs
Future<void> loadApiGatewaySpec(String componentId);
Future<void> saveApiGatewaySpec(String componentId, APIGatewaySpec spec);
// ... same for other new spec types
```

---

## 8. Theme Changes --- `core/theme/app_theme.dart` [MOD]

### New Colors

```dart
// Risk severity colors
static const riskCritical = Color(0xFFFF1744);   // Red
static const riskHigh = Color(0xFFFF9100);        // Orange
static const riskMedium = Color(0xFFFFEA00);      // Yellow
static const riskLow = Color(0xFF2979FF);         // Blue
static const riskInfo = Color(0xFF69F0AE);        // Green

// New component type colors (additions to existing palette)
static const apiGatewayColor = Color(0xFFE040FB);  // Purple-pink
static const cronJobColor = Color(0xFF7C4DFF);      // Deep purple
static const thirdPartyColor = Color(0xFF00E5FF);   // Cyan
static const serviceMeshColor = Color(0xFF76FF03);   // Light green
static const k8sNodeColor = Color(0xFFFF6E40);       // Deep orange

// Topology type badges
static const liveBadgeColor = Color(0xFF00E676);     // Green
static const experimentalBadgeColor = Color(0xFFFF9100); // Orange
```

---

## 9. Demo Data Changes --- `data/demo_data.dart` [MOD]

**Add demo data for:**
- Risk dashboard (sample findings, scores, distributions)
- Traffic simulation result (sample cascade with bottleneck)
- Endpoint registries (sample endpoints with DB/cache/service calls)
- New spec types (API Gateway, Cron, etc.)
- Live and experimental topology examples
- Team with members

---

## 10. Implementation Phases (Frontend)

### Phase 1 --- Foundation Alignment (Weeks 1-3)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 1.1 | Add TopologyType enum and model fields | `models/topology_models.dart` | Critical |
| 1.2 | Add live/experimental badge to workspace header | `features/workspace/workspace_screen.dart` | Critical |
| 1.3 | Add "Clone to Experiment" button | `features/workspace/workspace_screen.dart` | Critical |
| 1.4 | Block edit controls when viewing live topology | `features/topology/`, `features/specs/` | Critical |
| 1.5 | Add new component type enums and colors | `models/topology_models.dart`, `core/theme/` | High |
| 1.6 | Add 5 new spec models | `models/spec_models.dart` | High |
| 1.7 | Add git_repo_url, team_id to ProjectSummary | `models/project_models.dart` | High |
| 1.8 | Update router with new routes | `app/router.dart` | Medium |
| 1.9 | Update demo data with new features | `data/demo_data.dart` | Medium |

### Phase 2 --- New Models & Repository (Weeks 3-5)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 2.1 | Create endpoint_models.dart | `models/endpoint_models.dart` | Critical |
| 2.2 | Create risk_models.dart | `models/risk_models.dart` | Critical |
| 2.3 | Create traffic_models.dart | `models/traffic_models.dart` | Critical |
| 2.4 | Create team_models.dart | `models/team_models.dart` | High |
| 2.5 | Create export_models.dart, share_models.dart | `models/` | Medium |
| 2.6 | Add new API calls to dataforge_repository.dart | `data/dataforge_repository.dart` | Critical |
| 2.7 | Create team_repository.dart | `data/team_repository.dart` | High |
| 2.8 | Update workspace controller with new state | `features/workspace/workspace_controller.dart` | Critical |

### Phase 3 --- Structured Auto-Layout (Weeks 5-8)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 3.1 | Implement AutoLayoutEngine (Dagre-style) | `core/widgets/auto_layout_engine.dart` | Critical |
| 3.2 | Create TopologyNodeWidget (redesigned for auto-layout) | `features/topology/topology_node_widget.dart` | Critical |
| 3.3 | Create TopologyEdgePainter (waypoint-based) | `features/topology/topology_edge_painter.dart` | Critical |
| 3.4 | Refactor topology_canvas_view.dart to use auto-layout | `features/topology/topology_canvas_view.dart` | Critical |
| 3.5 | Add click-to-drill-down navigation | `features/topology/topology_canvas_view.dart` | High |
| 3.6 | Add component add/remove for experimental topologies | `features/topology/topology_canvas_view.dart` | High |

### Phase 4 --- Drill-Down Views (Weeks 8-11)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 4.1 | Server drill-down (endpoint list with details) | `features/drilldown/server_drilldown_view.dart` | Critical |
| 4.2 | Database drill-down (Power BI-style model view) | `features/drilldown/database_drilldown_view.dart` | Critical |
| 4.3 | Cache drill-down (key types, TTLs, endpoint usage) | `features/drilldown/cache_drilldown_view.dart` | High |
| 4.4 | Queue drill-down (producers, consumers, partitions) | `features/drilldown/queue_drilldown_view.dart` | High |

### Phase 5 --- Risk Analysis UI (Weeks 11-13)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 5.1 | Risk dashboard view | `features/risk/risk_dashboard_view.dart` | Critical |
| 5.2 | Risk endpoint list (ranked, expandable) | `features/risk/risk_endpoint_list.dart` | Critical |
| 5.3 | Risk finding detail card | `features/risk/risk_finding_detail.dart` | High |
| 5.4 | Add Risk tab to workspace navigation | `features/workspace/workspace_screen.dart` | High |
| 5.5 | Add risk severity colors to theme | `core/theme/app_theme.dart` | Medium |

### Phase 6 --- Traffic Simulation UI (Weeks 13-15)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 6.1 | Traffic simulation view (QPS input, run, results) | `features/traffic/traffic_simulation_view.dart` | Critical |
| 6.2 | Bottleneck visualization | `features/traffic/bottleneck_view.dart` | High |
| 6.3 | Add Traffic tab to workspace navigation | `features/workspace/workspace_screen.dart` | High |
| 6.4 | Add traffic summary to dashboard | `features/dashboard/dashboard_view.dart` | Medium |

### Phase 7 --- New Spec Editors (Weeks 15-17)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 7.1 | API Gateway spec editor panel | `features/specs/spec_editor_view.dart` | High |
| 7.2 | Cron Job spec editor panel | `features/specs/spec_editor_view.dart` | High |
| 7.3 | Object Storage spec editor panel | `features/specs/spec_editor_view.dart` | High |
| 7.4 | Service Mesh spec editor panel | `features/specs/spec_editor_view.dart` | Medium |
| 7.5 | Third-party API spec editor panel | `features/specs/spec_editor_view.dart` | Medium |

### Phase 8 --- Comparison, Teams, Export & Sharing (Weeks 17-20)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 8.1 | Metric comparison view (cost, perf, risk) | `features/compare/compare_view.dart` | High |
| 8.2 | Team management screen | `features/teams/team_screen.dart` | High |
| 8.3 | Invite link generation and join flow | `features/teams/invite_screen.dart` | High |
| 8.4 | Export dialog (PNG/SVG/PDF) | `features/export/export_dialog.dart` | Medium |
| 8.5 | Share dialog and shared view | `features/share/` | Medium |
| 8.6 | Update settings with Git repo and MCP config | `features/settings/settings_view.dart` | Medium |
| 8.7 | Add risk score to dashboard view | `features/dashboard/dashboard_view.dart` | Medium |

### Phase 9 --- Polish (Weeks 20-23)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 9.1 | Update landing page with Data4G branding and MCP section | `features/landing/landing_screen.dart` | Medium |
| 9.2 | "Updated X minutes ago" notification badge | `features/workspace/workspace_screen.dart` | Low |
| 9.3 | Keyboard shortcuts for common actions | Various | Low |
| 9.4 | Responsive layout testing and fixes | Various | Low |
| 9.5 | End-to-end demo data for all new features | `data/demo_data.dart` | Low |

---

## 11. Dependencies (pubspec.yaml)

### New Dependencies Needed

```yaml
dependencies:
  # Existing (keep all)
  flutter_riverpod: ^2.6.1
  go_router: ^14.8.1
  dio: ^5.8.0+1
  fl_chart: ^0.69.2
  flutter_dotenv: ^5.2.1
  google_fonts: ^6.2.1
  shared_preferences: ^2.3.5
  uuid: ^4.5.1
  
  # New
  graphview: ^1.2.0              # Graph layout algorithm (or custom Dagre implementation)
  flutter_syntax_view: ^4.0.0    # Code snippet syntax highlighting (risk findings)
  url_launcher: ^6.2.0           # Open external links (Git repo, shared links)
  share_plus: ^7.2.0             # Native share (for shareable links)
  screenshot: ^2.3.0             # Widget-to-image capture (PNG/SVG export)
  pdf: ^3.10.0                   # PDF generation (simulation reports)
```

**Note:** The `graphview` package may or may not fit the structured layout needs. Evaluate against custom Dagre implementation. The auto-layout engine may need to be built from scratch for optimal control.

---

*Overall architecture --> [DATA4G_BASE.md](DATA4G_BASE.md)*
*Backend implementation plan --> [DATA4G_BACKEND_PLAN.md](DATA4G_BACKEND_PLAN.md)*
