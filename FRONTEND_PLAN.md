# DataForge — Frontend Plan

> Flutter application: topology canvas, component editors, and consolidated cost dashboard

---

## 1. Tech Stack

| Layer              | Technology                                      |
|--------------------|--------------------------------------------------|
| Framework          | Flutter 3.24+ (Web, macOS, Windows, Linux)       |
| Language           | Dart 3.5+                                        |
| State Management   | Riverpod 2.x                                     |
| HTTP Client        | Dio (with interceptors)                          |
| WebSocket          | web_socket_channel                               |
| Routing            | GoRouter                                         |
| Charts             | fl_chart                                         |
| Canvas             | CustomPainter + GestureDetector                  |
| Code Preview       | flutter_highlight                                |
| Data Classes       | freezed + json_serializable                      |

---

## 2. Screen Map

```
/                       → HomeScreen (project list)
/project/:id            → ProjectScreen (main workspace)
/project/:id/topology   → TopologyCanvas (Stage 1)
/project/:id/specs      → SpecEditorScreen (Stage 2)
/project/:id/dashboard  → CostDashboardScreen
/project/:id/compare    → ComparisonScreen
/templates              → TemplatesScreen
/settings               → SettingsScreen
```

The **ProjectScreen** is the primary workspace with a tab/panel layout:

```
┌─────────────────────────────────────────────────────────────┐
│  Toolbar: [Topology] [Specs] [Dashboard] [Export] [Compare] │
├────────────────────────┬────────────────────────────────────┤
│                        │                                    │
│   Canvas / Editor      │   Side Panel                       │
│   (main content area)  │   (context-sensitive)              │
│                        │                                    │
│                        │   - Component editor               │
│                        │   - Entity field editor             │
│                        │   - Cost summary card               │
│                        │                                    │
├────────────────────────┴────────────────────────────────────┤
│  Bottom Bar: Total Cost: $X,XXX/mo  │  Users: 100K  │ Mode │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Stage 1 — Topology Canvas

### 3.1 Components

| Widget                 | Purpose                                           |
|------------------------|---------------------------------------------------|
| `TopologyCanvas`       | Main canvas with pan/zoom via `InteractiveViewer`  |
| `ComponentNode`        | Draggable node representing a topology component   |
| `EdgeLine`             | Curved line between connected components            |
| `ComponentToolbar`     | Drag-to-add palette (Compute, DB, Cache, LB, CDN) |
| `MiniMap`              | Thumbnail overview for large topologies             |
| `DeploymentModeToggle` | Switch between single / multi-tier / distributed   |

### 3.2 Interactions

- **Drag from palette** → adds a `TopologyComponent` to the canvas
- **Drag node** → repositions; snaps to grid
- **Connect nodes** → drag from port to port, creates `TopologyEdge`
- **Click node** → opens side panel with component type editor
- **Toggle collapse** → calls `/collapse` endpoint, disables LB/CDN nodes visually
- **Right-click** → context menu: duplicate, delete, configure

### 3.3 Node Visual Design

Each component type has a distinct icon and color:

| Type           | Icon      | Color     |
|----------------|-----------|-----------|
| Compute        | CPU chip  | Blue      |
| Database       | Cylinder  | Green     |
| Cache          | Lightning | Orange    |
| Load Balancer  | Balance   | Purple    |
| CDN            | Globe     | Teal      |
| Client         | User      | Gray      |
| Object Store   | Bucket    | Amber     |
| Message Queue  | Arrow     | Pink      |

Disabled (collapsed) nodes render as semi-transparent with a dashed border.

---

## 4. Stage 2 — Spec Editor Panels

### 4.1 Compute Spec Panel (Stage 2.1)

Opened when a Compute node is selected.

```
┌─ Compute: api-server ────────────────────┐
│                                           │
│  CPU Cores:    [──●──────] 4              │
│  RAM (GB):     [────●────] 16             │
│  GPU:          [None ▼]                   │
│                                           │
│  Instance:     [m5 ▼] . [xlarge ▼]       │
│  OS:           [Linux ▼]                  │
│  Storage:      [────●────] 100 GB         │
│                                           │
│  ── Autoscaling ──                        │
│  [✓] Enabled                              │
│  Min:  [1]  Max:  [5]                     │
│  Target CPU:  [──●──] 70%                 │
│                                           │
│  Est. Cost: $156.40/mo                    │
└───────────────────────────────────────────┘
```

### 4.2 DB Schema Editor (Stage 2.2)

Opened when a Database node is selected. This is the richest editor.

```
┌─ Database: main-db (PostgreSQL) ─────────────────────┐
│                                                       │
│  [PostgreSQL ▼]  Region: [us-east-1 ▼]               │
│                                                       │
│  ── Entities ──                                       │
│  ┌─ User (central) ─────────────────────────────┐     │
│  │  user_id    UUID      PK  indexed             │     │
│  │  email      STRING    UQ  indexed             │     │
│  │  name       STRING                            │     │
│  │  created_at DATETIME                          │     │
│  │  [+ Add Field]                                │     │
│  └───────────────────────────────────────────────┘     │
│  ┌─ Order ───────────────────────────────────────┐     │
│  │  order_id   UUID      PK  indexed             │     │
│  │  user_id    UUID      FK→User.user_id         │     │
│  │  total      DECIMAL                           │     │
│  │  status     ENUM                              │     │
│  │  [+ Add Field]                                │     │
│  └───────────────────────────────────────────────┘     │
│  [+ Add Entity]                                       │
│                                                       │
│  ── Relationships ──                                  │
│  User ──(1:N, ratio=50)──► Order                      │
│  Order ──(1:N, ratio=4)──► OrderItem                  │
│  [+ Add Relationship]                                 │
│                                                       │
│  ── Storage Projection ──                             │
│  User:      1,000 rows ×  256B =    250 KB           │
│  Order:    50,000 rows ×  192B =   9.2 MB            │
│  OrderItem:200,000 rows × 128B =  24.4 MB            │
│  Indexes:                           5.1 MB            │
│  Total:                            39.0 MB            │
│                                                       │
│  Est. DB Cost: $183.50/mo                             │
└───────────────────────────────────────────────────────┘
```

**Key interactions:**
- Click a field → edit type, PK/FK config, size, constraints
- FK dropdown → shows entities + their PK fields for reference
- Ratio slider → adjust relationship ratio, storage recalculates live
- "central" badge toggle on entity header

### 4.3 Cache / LB / CDN Panels

Simpler editors following the same side-panel pattern:

- **Cache**: memory slider, eviction policy dropdown, TTL input, cluster nodes
- **Load Balancer**: algorithm dropdown, target components multi-select, SSL toggle
- **CDN**: provider dropdown, estimated transfer/requests, cache hit ratio slider

Each panel shows an `Est. Cost: $XX.XX/mo` line that updates in real time.

---

## 5. Consolidated Cost Dashboard

The dashboard is the primary output of DataForge — accessible via the Dashboard tab.

### 5.1 Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌─ Total Cost ──────────┐  ┌─ Cost by Component (Donut) ────┐ │
│  │                        │  │                                │ │
│  │   $1,247.30 /mo       │  │     ┌────┐                     │ │
│  │                        │  │    /      \   ● Compute 42%    │ │
│  │   ▲ 12% vs last save  │  │   |  $1.2K |  ● Database 31%  │ │
│  │                        │  │    \      /   ● Cache    8%    │ │
│  └────────────────────────┘  │     └────┘    ● LB       5%   │ │
│                               │              ● CDN      4%    │ │
│                               │              ● Network 10%    │ │
│                               └────────────────────────────────┘ │
│                                                                 │
│  ┌─ Cost by Category (Horizontal Bars) ────────────────────────┐ │
│  │  Compute   ████████████████████████░░░░░░  $524.00          │ │
│  │  Storage   ████████████░░░░░░░░░░░░░░░░░░  $287.30          │ │
│  │  Network   ████████░░░░░░░░░░░░░░░░░░░░░░  $186.00          │ │
│  │  Cache     ████░░░░░░░░░░░░░░░░░░░░░░░░░░  $100.00          │ │
│  │  Licensing ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░   $50.00          │ │
│  │  Backup    █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   $30.00          │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─ Growth Projection (Line Chart) ────────────────────────────┐ │
│  │                                                              │ │
│  │  $50K ┤                                          ╱           │ │
│  │       │                                       ╱              │ │
│  │  $10K ┤                              ╱─────╱                 │ │
│  │       │                     ╱───────╱                        │ │
│  │   $1K ┤          ╱─────────╱                                 │ │
│  │       │  ───────╱                                            │ │
│  │       ┼──────┼──────┼──────┼──────┼──────┼                   │ │
│  │      1K    10K    50K   100K   500K     1M  users            │ │
│  │                                                              │ │
│  │  [Growth Slider: ──────────●────── 100K users ]              │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─ Per-Entity Storage Cost ───────────────────────────────────┐ │
│  │  Entity        Records    Storage    Cost/mo    % of DB     │ │
│  │  ─────────────────────────────────────────────────────────  │ │
│  │  Events       5,000,000   1.2 GB    $24.00     52%         │ │
│  │  Orders         50,000   9.2 MB     $8.40      18%         │ │
│  │  Users           1,000    250 KB     $2.10       5%         │ │
│  │  ...                                                        │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─ Optimization Hints ────────────────────────────────────────┐ │
│  │  💡 Add Redis cache → est. -$47/mo (reduce DB read IOPS)   │ │
│  │  💡 Switch to reserved instances → est. -$94/mo             │ │
│  │  💡 Events table dominates storage — consider TTL/archival  │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Dashboard Widgets

| Widget                  | Data Source                        | Chart Type      |
|-------------------------|------------------------------------|-----------------|
| `TotalCostCard`         | `dashboard.total_monthly_cost`     | Big number       |
| `CostDonutChart`        | `dashboard.per_component`          | Donut (fl_chart) |
| `CategoryBarsChart`     | `dashboard.per_category`           | Horizontal bars  |
| `GrowthLineChart`       | `dashboard.growth_projections`     | Line (fl_chart)  |
| `GrowthSlider`          | Controls `base_user_count`         | Slider           |
| `EntityStorageTable`    | `dashboard.per_entity_storage`     | Data table       |
| `OptimizationHintsList` | `dashboard.optimization_hints`     | Card list        |
| `ComparisonDeltaCard`   | `dashboard.comparison_*`           | Delta indicator  |

---

## 6. State Management (Riverpod)

### 6.1 Provider Architecture

```
                    ┌──────────────────────┐
                    │  topologyProvider     │  ← Stage 1 state
                    └──────────┬───────────┘
                               │ depends on
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
  ┌──────────────────┐ ┌────────────┐ ┌──────────────────┐
  │ computeSpecsProvider│ dbSpecsProvider│ cacheSpecsProvider│ ← Stage 2
  └────────┬─────────┘ └─────┬──────┘ └────────┬─────────┘
           │                 │                  │
           └────────┬────────┘──────────────────┘
                    ▼
           ┌──────────────────┐
           │  dashboardProvider │  ← Consolidated cost
           └──────────────────┘
```

### 6.2 Key Providers

```dart
// providers/topology_provider.dart
final topologyProvider = StateNotifierProvider<TopologyNotifier, Topology>(...);

// providers/compute_specs_provider.dart
final computeSpecsProvider = StateNotifierProvider<ComputeSpecsNotifier, Map<String, ComputeSpec>>(...);

// providers/db_specs_provider.dart
final dbSpecsProvider = StateNotifierProvider<DBSpecsNotifier, Map<String, DBModelSpec>>(...);

// providers/cache_specs_provider.dart
final cacheSpecsProvider = StateNotifierProvider<CacheSpecsNotifier, Map<String, CacheSpec>>(...);

// providers/dashboard_provider.dart
final dashboardProvider = FutureProvider<ConsolidatedDashboard>((ref) async {
  // Watches topology + all specs
  // Calls GET /api/v1/projects/{id}/cost
  // Returns consolidated dashboard
});

// providers/growth_provider.dart
final userCountProvider = StateProvider<int>((ref) => 1000);
final growthProjectionsProvider = FutureProvider<List<GrowthProjection>>(...);
```

### 6.3 Real-Time Updates

WebSocket connection to `/ws/projects/{id}`:
- Backend sends `cost_updated` event whenever any spec changes
- Frontend `dashboardProvider` invalidates and refetches
- Growth chart and per-entity table update live

---

## 7. Dart Data Classes

Mirror the backend Pydantic models using `freezed`:

```dart
// models/topology.dart
@freezed
class TopologyComponent with _$TopologyComponent {
  const factory TopologyComponent({
    required String id,
    required String name,
    required ComponentType type,
    @Default(true) bool enabled,
    required GeoLocation location,
    required CloudProvider cloudProvider,
    String? description,
  }) = _TopologyComponent;

  factory TopologyComponent.fromJson(Map<String, dynamic> json) =>
      _$TopologyComponentFromJson(json);
}

// models/compute_spec.dart
@freezed
class ComputeSpec with _$ComputeSpec { ... }

// models/db_model_spec.dart
@freezed
class DBModelSpec with _$DBModelSpec { ... }
@freezed
class Entity with _$Entity { ... }
@freezed
class EntityField with _$EntityField { ... }
@freezed
class Relationship with _$Relationship { ... }

// models/dashboard.dart
@freezed
class ConsolidatedDashboard with _$ConsolidatedDashboard { ... }
@freezed
class ComponentCostSummary with _$ComponentCostSummary { ... }
@freezed
class GrowthProjection with _$GrowthProjection { ... }
@freezed
class EntityCostDetail with _$EntityCostDetail { ... }
@freezed
class OptimizationHint with _$OptimizationHint { ... }
```

---

## 8. Component Hierarchy

```
App
├── HomeScreen
│   └── ProjectCard (list)
│
├── ProjectScreen
│   ├── ProjectToolbar (tab switcher)
│   ├── MainContent (switches based on active tab)
│   │   ├── TopologyCanvas
│   │   │   ├── InteractiveViewer
│   │   │   │   ├── ComponentNode (per component)
│   │   │   │   └── EdgeLine (per edge)
│   │   │   ├── ComponentToolbar (palette)
│   │   │   └── MiniMap
│   │   │
│   │   ├── SpecEditorView
│   │   │   ├── ComputeSpecPanel
│   │   │   ├── DBSchemaEditor
│   │   │   │   ├── EntityCard (per entity)
│   │   │   │   │   ├── FieldRow (per field)
│   │   │   │   │   └── AddFieldButton
│   │   │   │   ├── RelationshipEditor
│   │   │   │   └── StorageProjectionCard
│   │   │   ├── CacheSpecPanel
│   │   │   ├── LBSpecPanel
│   │   │   └── CDNSpecPanel
│   │   │
│   │   ├── CostDashboard
│   │   │   ├── TotalCostCard
│   │   │   ├── CostDonutChart
│   │   │   ├── CategoryBarsChart
│   │   │   ├── GrowthLineChart
│   │   │   ├── GrowthSlider
│   │   │   ├── EntityStorageTable
│   │   │   ├── OptimizationHintsList
│   │   │   └── ComparisonDeltaCard
│   │   │
│   │   ├── ExportView
│   │   │   ├── FormatSelector
│   │   │   └── CodePreview
│   │   │
│   │   └── ComparisonView
│   │       ├── DBSelector (side-by-side)
│   │       └── ComparisonBars
│   │
│   ├── SidePanel (context-sensitive)
│   │   └── (renders the appropriate spec editor)
│   │
│   └── BottomBar
│       ├── TotalCostIndicator
│       ├── UserCountDisplay
│       └── DeploymentModeIndicator
│
├── TemplatesScreen
│   └── TemplateCard (list)
│
└── SettingsScreen
```

---

## 9. Key User Flows

### 9.1 New Project Flow

1. HomeScreen → "New Project" → name + optional template
2. TopologyCanvas opens with default components (Compute + DB + Client)
3. User drags additional components (Cache, LB, CDN) from palette
4. User connects components with edges
5. Clicks a component → side panel opens with spec editor
6. Configures compute, DB schema, cache
7. Dashboard tab shows live cost as specs are set

### 9.2 DB Schema Design Flow

1. Select Database node on canvas
2. Side panel → DB Schema Editor
3. Add entities (User, Order, Event, etc.)
4. Add fields to each entity, set PK/FK
5. Add relationships with ratios
6. Storage projection updates live below
7. Dashboard donut updates via WebSocket

### 9.3 Cost Exploration Flow

1. Dashboard tab → see total cost + breakdowns
2. Drag growth slider → see cost at different user counts
3. Click "Compare" → select alternate DB → see cost delta
4. Review optimization hints → apply suggestions
5. Export → download schema or cost report

---

## 10. Implementation Phases

### Phase 1 — Foundation (Sprint 1-2)
- [ ] Project scaffolding (GoRouter, Riverpod, Dio)
- [ ] Dart data classes with freezed (mirror backend Pydantic)
- [ ] API client service layer
- [ ] HomeScreen with project CRUD
- [ ] Basic ProjectScreen shell with tabs

### Phase 2 — Topology Canvas (Sprint 3-4)
- [ ] TopologyCanvas with InteractiveViewer
- [ ] ComponentNode (drag, drop, connect)
- [ ] EdgeLine rendering
- [ ] ComponentToolbar palette
- [ ] Deployment mode toggle
- [ ] MiniMap

### Phase 3 — Spec Editors (Sprint 5-6)
- [ ] ComputeSpecPanel (sliders, dropdowns)
- [ ] DBSchemaEditor (entity/field/relationship CRUD)
- [ ] PK/FK visual editor
- [ ] Relationship ratio slider with live storage recalc
- [ ] CacheSpecPanel, LBSpecPanel, CDNSpecPanel

### Phase 4 — Dashboard (Sprint 7-8)
- [ ] TotalCostCard
- [ ] CostDonutChart (fl_chart)
- [ ] CategoryBarsChart
- [ ] GrowthLineChart + GrowthSlider
- [ ] EntityStorageTable
- [ ] OptimizationHintsList
- [ ] ComparisonView (side-by-side DB swap)
- [ ] WebSocket integration for live updates

### Phase 5 — Polish (Sprint 9-10)
- [ ] Export view (schema + cost report)
- [ ] Templates screen
- [ ] Dark mode
- [ ] Responsive layout (desktop + web)
- [ ] Keyboard shortcuts
- [ ] Undo/redo on canvas

---

*Overall architecture → [BASE_PLAN.md](BASE_PLAN.md)*
*Backend schemas and API design → [BACKEND_PLAN.md](BACKEND_PLAN.md)*
