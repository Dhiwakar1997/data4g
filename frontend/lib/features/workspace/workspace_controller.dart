import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_environment.dart';
import '../../data/dataforge_repository.dart';
import '../../data/demo_data.dart';
import '../../models/comparison_models.dart';
import '../../models/dashboard_models.dart';
import '../../models/endpoint_models.dart';
import '../../models/project_models.dart';
import '../../models/reference_models.dart';
import '../../models/risk_models.dart';
import '../../models/spec_models.dart';
import '../../models/topology_models.dart';
import '../../models/traffic_models.dart';
import '../auth/auth_controller.dart';

const _workspaceUnset = Object();

class WorkspaceState {
  const WorkspaceState({
    required this.isLoading,
    required this.usingDemoData,
    required this.projects,
    required this.selectedProjectId,
    required this.topologies,
    required this.selectedTopologyId,
    required this.selectedComponentId,
    required this.databases,
    required this.regions,
    required this.cloudProviders,
    required this.dashboard,
    required this.comparison,
    required this.members,
    required this.computeSpecs,
    required this.cacheSpecs,
    required this.loadBalancerSpecs,
    required this.cdnSpecs,
    required this.dbSpecs,
    required this.storageProjections,
    required this.k8sSpecs,
    required this.dockerSpecs,
    required this.errorMessage,
    required this.infoMessage,
    required this.riskDashboard,
    required this.isRiskLoading,
    required this.trafficResult,
    required this.isTrafficLoading,
    required this.endpointRegistries,
    required this.apiGatewaySpecs,
    required this.cronJobSpecs,
    required this.objectStorageSpecs,
    required this.serviceMeshSpecs,
    required this.thirdPartyApiSpecs,
    required this.lastMcpSyncAt,
  });

  final bool isLoading;
  final bool usingDemoData;
  final List<ProjectSummary> projects;
  final String? selectedProjectId;
  final List<TopologyModel> topologies;
  final String? selectedTopologyId;
  final String? selectedComponentId;
  final List<DatabaseReference> databases;
  final List<ReferenceOption> regions;
  final List<ReferenceOption> cloudProviders;
  final ConsolidatedDashboard? dashboard;
  final TopologyComparison? comparison;
  final List<MemberRecord> members;
  final Map<String, ComputeSpec> computeSpecs;
  final Map<String, CacheSpec> cacheSpecs;
  final Map<String, LoadBalancerSpec> loadBalancerSpecs;
  final Map<String, CdnSpec> cdnSpecs;
  final Map<String, DbModelSpec> dbSpecs;
  final Map<String, DbStorageProjection> storageProjections;
  final Map<String, K8sClusterSpec> k8sSpecs;
  final Map<String, DockerContainerSpec> dockerSpecs;
  final String? errorMessage;
  final String? infoMessage;
  final RiskDashboard? riskDashboard;
  final bool isRiskLoading;
  final TrafficSimulationResult? trafficResult;
  final bool isTrafficLoading;
  final Map<String, ServerEndpointRegistry> endpointRegistries;
  final Map<String, APIGatewaySpec> apiGatewaySpecs;
  final Map<String, CronJobSpec> cronJobSpecs;
  final Map<String, ObjectStorageSpec> objectStorageSpecs;
  final Map<String, ServiceMeshSpec> serviceMeshSpecs;
  final Map<String, ThirdPartyAPISpec> thirdPartyApiSpecs;
  final String? lastMcpSyncAt;

  factory WorkspaceState.initial() {
    return const WorkspaceState(
      isLoading: false,
      usingDemoData: false,
      projects: [],
      selectedProjectId: null,
      topologies: [],
      selectedTopologyId: null,
      selectedComponentId: null,
      databases: [],
      regions: [],
      cloudProviders: [],
      dashboard: null,
      comparison: null,
      members: [],
      computeSpecs: {},
      cacheSpecs: {},
      loadBalancerSpecs: {},
      cdnSpecs: {},
      dbSpecs: {},
      storageProjections: {},
      k8sSpecs: {},
      dockerSpecs: {},
      errorMessage: null,
      infoMessage: null,
      riskDashboard: null,
      isRiskLoading: false,
      trafficResult: null,
      isTrafficLoading: false,
      endpointRegistries: {},
      apiGatewaySpecs: {},
      cronJobSpecs: {},
      objectStorageSpecs: {},
      serviceMeshSpecs: {},
      thirdPartyApiSpecs: {},
      lastMcpSyncAt: null,
    );
  }

  ProjectSummary? get selectedProject {
    for (final project in projects) {
      if (project.projectId == selectedProjectId) {
        return project;
      }
    }
    return null;
  }

  TopologyModel? get selectedTopology {
    for (final topology in topologies) {
      if (topology.id == selectedTopologyId) {
        return topology;
      }
    }
    return null;
  }

  TopologyComponent? get selectedComponent {
    final topology = selectedTopology;
    if (topology == null) {
      return null;
    }
    for (final component in topology.components) {
      if (component.id == selectedComponentId) {
        return component;
      }
    }
    return null;
  }

  WorkspaceState copyWith({
    bool? isLoading,
    bool? usingDemoData,
    List<ProjectSummary>? projects,
    Object? selectedProjectId = _workspaceUnset,
    List<TopologyModel>? topologies,
    Object? selectedTopologyId = _workspaceUnset,
    Object? selectedComponentId = _workspaceUnset,
    List<DatabaseReference>? databases,
    List<ReferenceOption>? regions,
    List<ReferenceOption>? cloudProviders,
    Object? dashboard = _workspaceUnset,
    Object? comparison = _workspaceUnset,
    List<MemberRecord>? members,
    Map<String, ComputeSpec>? computeSpecs,
    Map<String, CacheSpec>? cacheSpecs,
    Map<String, LoadBalancerSpec>? loadBalancerSpecs,
    Map<String, CdnSpec>? cdnSpecs,
    Map<String, DbModelSpec>? dbSpecs,
    Map<String, DbStorageProjection>? storageProjections,
    Map<String, K8sClusterSpec>? k8sSpecs,
    Map<String, DockerContainerSpec>? dockerSpecs,
    Object? errorMessage = _workspaceUnset,
    Object? infoMessage = _workspaceUnset,
    bool clearError = false,
    bool clearInfo = false,
    Object? riskDashboard = _workspaceUnset,
    bool? isRiskLoading,
    Object? trafficResult = _workspaceUnset,
    bool? isTrafficLoading,
    Map<String, ServerEndpointRegistry>? endpointRegistries,
    Map<String, APIGatewaySpec>? apiGatewaySpecs,
    Map<String, CronJobSpec>? cronJobSpecs,
    Map<String, ObjectStorageSpec>? objectStorageSpecs,
    Map<String, ServiceMeshSpec>? serviceMeshSpecs,
    Map<String, ThirdPartyAPISpec>? thirdPartyApiSpecs,
    Object? lastMcpSyncAt = _workspaceUnset,
  }) {
    return WorkspaceState(
      isLoading: isLoading ?? this.isLoading,
      usingDemoData: usingDemoData ?? this.usingDemoData,
      projects: projects ?? this.projects,
      selectedProjectId: selectedProjectId == _workspaceUnset
          ? this.selectedProjectId
          : selectedProjectId as String?,
      topologies: topologies ?? this.topologies,
      selectedTopologyId: selectedTopologyId == _workspaceUnset
          ? this.selectedTopologyId
          : selectedTopologyId as String?,
      selectedComponentId: selectedComponentId == _workspaceUnset
          ? this.selectedComponentId
          : selectedComponentId as String?,
      databases: databases ?? this.databases,
      regions: regions ?? this.regions,
      cloudProviders: cloudProviders ?? this.cloudProviders,
      dashboard: dashboard == _workspaceUnset
          ? this.dashboard
          : dashboard as ConsolidatedDashboard?,
      comparison: comparison == _workspaceUnset
          ? this.comparison
          : comparison as TopologyComparison?,
      members: members ?? this.members,
      computeSpecs: computeSpecs ?? this.computeSpecs,
      cacheSpecs: cacheSpecs ?? this.cacheSpecs,
      loadBalancerSpecs: loadBalancerSpecs ?? this.loadBalancerSpecs,
      cdnSpecs: cdnSpecs ?? this.cdnSpecs,
      dbSpecs: dbSpecs ?? this.dbSpecs,
      storageProjections: storageProjections ?? this.storageProjections,
      k8sSpecs: k8sSpecs ?? this.k8sSpecs,
      dockerSpecs: dockerSpecs ?? this.dockerSpecs,
      errorMessage: clearError
          ? null
          : errorMessage == _workspaceUnset
          ? this.errorMessage
          : errorMessage as String?,
      infoMessage: clearInfo
          ? null
          : infoMessage == _workspaceUnset
          ? this.infoMessage
          : infoMessage as String?,
      riskDashboard: riskDashboard == _workspaceUnset
          ? this.riskDashboard
          : riskDashboard as RiskDashboard?,
      isRiskLoading: isRiskLoading ?? this.isRiskLoading,
      trafficResult: trafficResult == _workspaceUnset
          ? this.trafficResult
          : trafficResult as TrafficSimulationResult?,
      isTrafficLoading: isTrafficLoading ?? this.isTrafficLoading,
      endpointRegistries: endpointRegistries ?? this.endpointRegistries,
      apiGatewaySpecs: apiGatewaySpecs ?? this.apiGatewaySpecs,
      cronJobSpecs: cronJobSpecs ?? this.cronJobSpecs,
      objectStorageSpecs: objectStorageSpecs ?? this.objectStorageSpecs,
      serviceMeshSpecs: serviceMeshSpecs ?? this.serviceMeshSpecs,
      thirdPartyApiSpecs: thirdPartyApiSpecs ?? this.thirdPartyApiSpecs,
      lastMcpSyncAt: lastMcpSyncAt == _workspaceUnset
          ? this.lastMcpSyncAt
          : lastMcpSyncAt as String?,
    );
  }
}

class WorkspaceController extends StateNotifier<WorkspaceState> {
  WorkspaceController(this._ref, this._repository)
    : super(WorkspaceState.initial()) {
    loadWorkspace();
  }

  final Ref _ref;
  final DataForgeRepository _repository;
  final Uuid _uuid = const Uuid();

  Future<void> loadWorkspace({String? preferredProjectId}) async {
    final authState = _ref.read(authControllerProvider);
    if (!authState.initialized) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);

    if (!authState.isAuthenticated) {
      _loadDemo(
        infoMessage:
            'Previewing demo workspace. Sign in to persist projects, members, and cost changes.',
      );
      return;
    }

    try {
      final projects = await _repository.listProjects();
      final databases = await _repository.listDatabases();
      final regions = await _repository.listRegions();
      final cloudProviders = await _repository.listCloudProviders();

      if (projects.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          usingDemoData: false,
          projects: projects,
          selectedProjectId: null,
          topologies: const [],
          databases: databases,
          regions: regions,
          cloudProviders: cloudProviders,
          infoMessage:
              'Create your first project to start shaping environments.',
        );
        return;
      }

      final selectedProjectId =
          preferredProjectId ??
          authState.lastProjectId ??
          projects.first.projectId;

      await _loadProject(
        selectedProjectId,
        projects: projects,
        databases: databases,
        regions: regions,
        cloudProviders: cloudProviders,
      );
    } catch (_) {
      if (AppEnvironment.useMockFallback) {
        _loadDemo(
          infoMessage:
              'Could not reach the API, so the UI is showing seeded sample data for now.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load DataForge projects right now.',
        );
      }
    }
  }

  Future<void> selectProject(String projectId) async {
    if (state.usingDemoData) {
      await _ref
          .read(authControllerProvider.notifier)
          .rememberProject(projectId);
      state = state.copyWith(selectedProjectId: projectId, clearInfo: true);
      return;
    }

    await _loadProject(
      projectId,
      projects: state.projects,
      databases: state.databases,
      regions: state.regions,
      cloudProviders: state.cloudProviders,
    );
  }

  Future<void> createProject(String name, {String description = ''}) async {
    if (state.usingDemoData) {
      final newProject = ProjectSummary(
        projectId: 'proj_${_uuid.v4()}',
        ownerId: _ref.read(authControllerProvider).userId ?? 'user_demo',
        name: name,
        description: description,
        topologyCount: 1,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      final topology = _buildDefaultTopology('Primary Topology');
      state = state.copyWith(
        projects: [...state.projects, newProject],
        selectedProjectId: newProject.projectId,
        topologies: [topology],
        selectedTopologyId: topology.id,
        selectedComponentId: null,
        infoMessage: 'Created a demo project. Sign in to save it to the API.',
      );
      return;
    }

    final project = await _repository.createProject(
      name: name,
      description: description,
    );
    final topology = await _repository.createTopology(
      project.projectId,
      _buildDefaultTopology('Primary Topology'),
    );

    final projects = [...state.projects, project];
    state = state.copyWith(
      projects: projects,
      selectedProjectId: project.projectId,
      topologies: [topology],
      selectedTopologyId: topology.id,
      selectedComponentId: null,
      dashboard: null,
      members: const [],
      clearError: true,
      infoMessage: 'Project created. You can now shape its topologies.',
    );
    await _ref
        .read(authControllerProvider.notifier)
        .rememberProject(project.projectId);
  }

  Future<void> selectTopology(String topologyId) async {
    state = state.copyWith(
      selectedTopologyId: topologyId,
      selectedComponentId: null,
      clearInfo: true,
    );
  }

  Future<void> createTopology(String name) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }

    final topology = _buildDefaultTopology(name);
    if (state.usingDemoData) {
      final updated = [...state.topologies, topology];
      state = state.copyWith(
        topologies: updated,
        selectedTopologyId: topology.id,
        selectedComponentId: null,
        infoMessage: 'Added a new topology in demo mode.',
      );
      return;
    }

    final created = await _repository.createTopology(projectId, topology);
    state = state.copyWith(
      topologies: [...state.topologies, created],
      selectedTopologyId: created.id,
      selectedComponentId: null,
      infoMessage: 'Topology created for the active project.',
    );
  }

  Future<void> setDeploymentMode(DeploymentMode mode) async {
    final topology = state.selectedTopology;
    if (topology == null) {
      return;
    }
    await _persistTopology(topology.copyWith(deploymentMode: mode));
  }

  Future<void> collapseActiveTopology() async {
    final topology = state.selectedTopology;
    if (topology == null) {
      return;
    }

    final collapsedComponents = topology.components
        .map(
          (component) =>
              component.type == ComponentType.loadBalancer ||
                  component.type == ComponentType.cdn
              ? component.copyWith(enabled: false)
              : component,
        )
        .toList();

    await _persistTopology(
      topology.copyWith(
        deploymentMode: DeploymentMode.singleInstance,
        components: collapsedComponents,
      ),
    );
  }

  Future<void> selectComponent(String? componentId) async {
    state = state.copyWith(selectedComponentId: componentId, clearInfo: true);
    final component = state.selectedComponent;
    if (component != null) {
      await _ensureComponentDetails(component);
    }
  }

  Future<void> updateSelectedComponent({
    String? name,
    String? description,
    CloudProvider? cloudProvider,
    String? region,
  }) async {
    final topology = state.selectedTopology;
    final component = state.selectedComponent;
    if (topology == null || component == null) {
      return;
    }

    final updatedComponent = component.copyWith(
      name: name,
      description: description,
      cloudProvider: cloudProvider,
      location: region == null
          ? component.location
          : component.location.copyWith(region: region),
    );

    final updatedComponents = topology.components
        .map((item) => item.id == component.id ? updatedComponent : item)
        .toList();

    await _persistTopology(topology.copyWith(components: updatedComponents));
  }

  Future<void> addComponent(ComponentType type) async {
    final topology = state.selectedTopology;
    if (topology == null) {
      return;
    }

    final x = 220 + (topology.components.length * 90);
    final y = 160 + (topology.components.length.isEven ? 110 : 220);
    final component = TopologyComponent(
      id: 'cmp_${_uuid.v4()}',
      name:
          '${type.label} ${topology.components.where((item) => item.type == type).length + 1}',
      type: type,
      enabled: true,
      location: GeoLocation.defaultValue(),
      cloudProvider: CloudProvider.aws,
      description: '${type.label} component',
      tags: {'canvas_x': '$x', 'canvas_y': '$y'},
    );

    await _persistTopology(
      topology.copyWith(components: [...topology.components, component]),
    );
    await selectComponent(component.id);
  }

  Future<void> removeSelectedComponent() async {
    final topology = state.selectedTopology;
    final component = state.selectedComponent;
    if (topology == null || component == null) {
      return;
    }

    final components = topology.components
        .where((item) => item.id != component.id)
        .toList();
    final edges = topology.edges
        .where(
          (item) =>
              item.sourceComponentId != component.id &&
              item.targetComponentId != component.id,
        )
        .toList();

    await _persistTopology(
      topology.copyWith(components: components, edges: edges),
    );
    state = state.copyWith(selectedComponentId: null);
  }

  Future<void> updateComponentPosition(
    String componentId,
    Offset position,
  ) async {
    final topology = state.selectedTopology;
    if (topology == null) {
      return;
    }

    final updated = topology.components
        .map(
          (component) => component.id == componentId
              ? component.withCanvasPosition(position.dx, position.dy)
              : component,
        )
        .toList();

    await _persistTopology(
      topology.copyWith(components: updated),
      silent: true,
    );
  }

  Future<void> connectSelectedTo(String targetComponentId) async {
    final topology = state.selectedTopology;
    final sourceComponentId = state.selectedComponentId;
    if (topology == null || sourceComponentId == null) {
      return;
    }
    if (sourceComponentId == targetComponentId) {
      return;
    }

    final exists = topology.edges.any(
      (edge) =>
          edge.sourceComponentId == sourceComponentId &&
          edge.targetComponentId == targetComponentId,
    );
    if (exists) {
      return;
    }

    final edge = TopologyEdge(
      id: 'edge_${_uuid.v4()}',
      sourceComponentId: sourceComponentId,
      targetComponentId: targetComponentId,
      estimatedBandwidthMbps: 100,
      estimatedLatencyMs: 2,
      description: 'New connection',
    );

    await _persistTopology(topology.copyWith(edges: [...topology.edges, edge]));
  }

  Future<void> saveComputeSpec(ComputeSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }
    if (!state.usingDemoData) {
      await _repository.saveComputeSpec(
        projectId,
        spec.topologyComponentId,
        spec,
      );
    }
    state = state.copyWith(
      computeSpecs: {...state.computeSpecs, spec.topologyComponentId: spec},
      infoMessage: 'Compute profile updated.',
    );
    await refreshDashboard();
  }

  Future<void> saveCacheSpec(CacheSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }
    if (!state.usingDemoData) {
      await _repository.saveCacheSpec(
        projectId,
        spec.topologyComponentId,
        spec,
      );
    }
    state = state.copyWith(
      cacheSpecs: {...state.cacheSpecs, spec.topologyComponentId: spec},
      infoMessage: 'Cache profile updated.',
    );
    await refreshDashboard();
  }

  Future<void> saveLoadBalancerSpec(LoadBalancerSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }
    if (!state.usingDemoData) {
      await _repository.saveLoadBalancerSpec(
        projectId,
        spec.topologyComponentId,
        spec,
      );
    }
    state = state.copyWith(
      loadBalancerSpecs: {
        ...state.loadBalancerSpecs,
        spec.topologyComponentId: spec,
      },
      infoMessage: 'Traffic routing rules updated.',
    );
    await refreshDashboard();
  }

  Future<void> saveCdnSpec(CdnSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }
    if (!state.usingDemoData) {
      await _repository.saveCdnSpec(projectId, spec.topologyComponentId, spec);
    }
    state = state.copyWith(
      cdnSpecs: {...state.cdnSpecs, spec.topologyComponentId: spec},
      infoMessage: 'CDN settings refreshed.',
    );
    await refreshDashboard();
  }

  Future<void> saveDbSpec(DbModelSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }
    DbStorageProjection? projection;
    if (!state.usingDemoData) {
      await _repository.saveDbSpec(projectId, spec.topologyComponentId, spec);
      projection = await _repository.getStorageProjection(
        projectId,
        spec.topologyComponentId,
      );
    } else {
      projection = DemoDataFactory.storageProjection(spec.topologyComponentId);
    }

    state = state.copyWith(
      dbSpecs: {...state.dbSpecs, spec.topologyComponentId: spec},
      storageProjections: {
        ...state.storageProjections,
        spec.topologyComponentId: projection,
      },
      infoMessage: 'Database structure updated.',
    );
    await refreshDashboard();
  }

  Future<void> saveK8sSpec(K8sClusterSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }
    if (!state.usingDemoData) {
      await _repository.saveK8sSpec(projectId, spec.topologyComponentId, spec);
    }
    state = state.copyWith(
      k8sSpecs: {...state.k8sSpecs, spec.topologyComponentId: spec},
      infoMessage: 'Kubernetes settings updated.',
    );
  }

  Future<void> saveDockerSpec(DockerContainerSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }
    if (!state.usingDemoData) {
      await _repository.saveDockerSpec(
        projectId,
        spec.topologyComponentId,
        spec,
      );
    }
    state = state.copyWith(
      dockerSpecs: {...state.dockerSpecs, spec.topologyComponentId: spec},
      infoMessage: 'Container settings updated.',
    );
  }

  // --- New Spec Save Methods ---

  Future<void> saveApiGatewaySpec(APIGatewaySpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;
    if (!state.usingDemoData) {
      await _repository.saveApiGatewaySpec(
        projectId, spec.topologyComponentId, spec,
      );
    }
    state = state.copyWith(
      apiGatewaySpecs: {
        ...state.apiGatewaySpecs, spec.topologyComponentId: spec,
      },
      infoMessage: 'API Gateway spec updated.',
    );
    await refreshDashboard();
  }

  Future<void> saveCronJobSpec(CronJobSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;
    if (!state.usingDemoData) {
      await _repository.saveCronJobSpec(
        projectId, spec.topologyComponentId, spec,
      );
    }
    state = state.copyWith(
      cronJobSpecs: {
        ...state.cronJobSpecs, spec.topologyComponentId: spec,
      },
      infoMessage: 'Cron job spec updated.',
    );
    await refreshDashboard();
  }

  Future<void> saveObjectStorageSpec(ObjectStorageSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;
    if (!state.usingDemoData) {
      await _repository.saveObjectStorageSpec(
        projectId, spec.topologyComponentId, spec,
      );
    }
    state = state.copyWith(
      objectStorageSpecs: {
        ...state.objectStorageSpecs, spec.topologyComponentId: spec,
      },
      infoMessage: 'Object storage spec updated.',
    );
    await refreshDashboard();
  }

  Future<void> saveServiceMeshSpec(ServiceMeshSpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;
    if (!state.usingDemoData) {
      await _repository.saveServiceMeshSpec(
        projectId, spec.topologyComponentId, spec,
      );
    }
    state = state.copyWith(
      serviceMeshSpecs: {
        ...state.serviceMeshSpecs, spec.topologyComponentId: spec,
      },
      infoMessage: 'Service mesh spec updated.',
    );
    await refreshDashboard();
  }

  Future<void> saveThirdPartyApiSpec(ThirdPartyAPISpec spec) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;
    if (!state.usingDemoData) {
      await _repository.saveThirdPartyApiSpec(
        projectId, spec.topologyComponentId, spec,
      );
    }
    state = state.copyWith(
      thirdPartyApiSpecs: {
        ...state.thirdPartyApiSpecs, spec.topologyComponentId: spec,
      },
      infoMessage: 'Third-party API spec updated.',
    );
    await refreshDashboard();
  }

  // --- Risk ---

  Future<void> loadRiskDashboard() async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;

    state = state.copyWith(isRiskLoading: true);
    try {
      final risk = await _loadOrFallback<RiskDashboard>(
        load: () => _repository.getRiskDashboard(projectId),
        fallback: () => DemoDataFactory.riskDashboard(),
      );
      state = state.copyWith(riskDashboard: risk, isRiskLoading: false);
    } catch (_) {
      state = state.copyWith(
        isRiskLoading: false,
        errorMessage: 'Unable to load risk analysis.',
      );
    }
  }

  Future<void> triggerRiskAnalysis() async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;

    if (!state.usingDemoData) {
      await _repository.triggerRiskAnalysis(projectId);
    }
    await loadRiskDashboard();
  }

  // --- Traffic ---

  Future<void> runTrafficSimulation(TrafficInput input) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;

    state = state.copyWith(isTrafficLoading: true);
    try {
      final result = await _loadOrFallback<TrafficSimulationResult>(
        load: () => _repository.simulateTraffic(projectId, input),
        fallback: () => DemoDataFactory.trafficSimulationResult(),
      );
      state = state.copyWith(trafficResult: result, isTrafficLoading: false);
    } catch (_) {
      state = state.copyWith(
        isTrafficLoading: false,
        errorMessage: 'Traffic simulation failed.',
      );
    }
  }

  // --- Endpoints ---

  Future<void> loadEndpointRegistry(String componentId) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;

    if (state.endpointRegistries.containsKey(componentId)) return;

    final registry = await _loadOrFallback<ServerEndpointRegistry>(
      load: () => _repository.getEndpointRegistry(projectId, componentId),
      fallback: () => DemoDataFactory.endpointRegistry(componentId),
    );
    state = state.copyWith(
      endpointRegistries: {
        ...state.endpointRegistries, componentId: registry,
      },
    );
  }

  // --- Topology Clone ---

  Future<void> cloneToExperimental(String topologyId) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;

    if (state.usingDemoData) {
      final source = state.topologies.firstWhere((t) => t.id == topologyId);
      final cloned = TopologyModel(
        id: 'topo_${_uuid.v4()}',
        name: '${source.name} (Experimental)',
        deploymentMode: source.deploymentMode,
        components: source.components,
        edges: source.edges,
        baseUserCount: source.baseUserCount,
        growthTargets: source.growthTargets,
        topologyType: TopologyType.experimental,
        clonedFrom: source.id,
      );
      state = state.copyWith(
        topologies: [...state.topologies, cloned],
        selectedTopologyId: cloned.id,
        infoMessage: 'Cloned topology for experimentation.',
      );
      return;
    }

    final cloned = await _repository.cloneTopology(projectId, topologyId);
    state = state.copyWith(
      topologies: [...state.topologies, cloned],
      selectedTopologyId: cloned.id,
      infoMessage: 'Cloned topology for experimentation.',
    );
  }

  // --- Scan sync (agent-driven ingestion) ---
  //
  // Humans no longer trigger ingestion from the UI — an AI agent running
  // `data4g-mcp` locally is the only path that writes. This helper just
  // pulls the latest sync status so the workspace can surface "last sync"
  // and any active sessions.

  Future<void> syncFromMcp() async {
    final projectId = state.selectedProjectId;
    if (projectId == null) return;

    if (state.usingDemoData) {
      state = state.copyWith(
        lastMcpSyncAt: DateTime.now().toIso8601String(),
        infoMessage: 'Scan sync simulated in demo mode.',
      );
      return;
    }

    try {
      final status = await _repository.fetchScanStatus(projectId);
      final lastAt = status.lastSync?.syncedAt.toIso8601String();
      state = state.copyWith(
        lastMcpSyncAt: lastAt ?? state.lastMcpSyncAt,
        infoMessage: status.lastSync == null
            ? 'No scans yet — sync from your AI agent to populate the live topology.'
            : 'Last scan: ${status.lastSync!.endpointsSynced} endpoints, '
                '${status.lastSync!.riskFindingsCount} risks.',
      );
      await loadWorkspace(preferredProjectId: projectId);
    } catch (err) {
      state = state.copyWith(
        errorMessage: 'Failed to refresh scan status: $err',
      );
    }
  }

  Future<void> refreshDashboard() async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }

    if (state.usingDemoData) {
      state = state.copyWith(dashboard: DemoDataFactory.dashboard());
      return;
    }

    try {
      final dashboard = await _repository.getDashboard(projectId);
      state = state.copyWith(dashboard: dashboard);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Dashboard data is temporarily unavailable.',
      );
    }
  }

  Future<void> compareDatabase(String alternateDatabaseId) async {
    final projectId = state.selectedProjectId;
    final dashboard = state.dashboard;
    if (projectId == null || dashboard == null) {
      return;
    }

    if (state.usingDemoData) {
      final comparisonTotal = switch (alternateDatabaseId) {
        'mysql' => 1188.2,
        'mongodb' => 1324.6,
        'pgvector' => 1399.8,
        _ => 1247.3,
      };
      state = state.copyWith(
        dashboard: dashboard.copyWith(
          comparisonDatabase: alternateDatabaseId,
          comparisonTotalMonthly: comparisonTotal,
          comparisonDelta: comparisonTotal - dashboard.totalMonthlyCost,
        ),
      );
      return;
    }

    final compared = await _repository.compareDatabase(
      projectId,
      alternateDatabaseId,
    );
    state = state.copyWith(dashboard: compared);
  }

  Future<void> compareTopologies({
    required String sourceProjectId,
    required String sourceTopologyId,
    required String targetProjectId,
    required String targetTopologyId,
  }) async {
    if (state.usingDemoData) {
      state = state.copyWith(comparison: DemoDataFactory.comparison());
      return;
    }

    final comparison = await _repository.compareTopologies(
      sourceProjectId: sourceProjectId,
      sourceTopologyId: sourceTopologyId,
      targetProjectId: targetProjectId,
      targetTopologyId: targetTopologyId,
    );
    state = state.copyWith(comparison: comparison);
  }

  Future<void> addMember({
    required String userId,
    required ProjectRole role,
    required List<String> topologyAccess,
  }) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }

    if (state.usingDemoData) {
      final member = MemberRecord(
        projectId: projectId,
        userId: userId,
        role: role,
        topologyAccess: topologyAccess,
        addedBy: _ref.read(authControllerProvider).userId ?? 'user_demo',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = state.copyWith(
        members: [...state.members, member],
        infoMessage: 'Member added in demo mode.',
      );
      return;
    }

    final member = await _repository.addMember(
      projectId: projectId,
      userId: userId,
      role: role.value,
      topologyAccess: topologyAccess,
    );
    state = state.copyWith(
      members: [...state.members, member],
      infoMessage: 'Project member added.',
    );
  }

  Future<void> shareTopologyAccess({
    required String userId,
    required List<String> topologyIds,
  }) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }

    if (state.usingDemoData) {
      final updatedMembers = state.members.map((member) {
        if (member.userId != userId) {
          return member;
        }
        return member.copyWith(topologyAccess: topologyIds);
      }).toList();
      state = state.copyWith(
        members: updatedMembers,
        infoMessage: 'Shared topology access in demo mode.',
      );
      return;
    }

    final updated = await _repository.shareTopologies(
      projectId: projectId,
      userId: userId,
      topologyIds: topologyIds,
    );

    final members = state.members.map((member) {
      return member.userId == userId ? updated : member;
    }).toList();
    state = state.copyWith(
      members: members,
      infoMessage: 'Topology access updated.',
    );
  }

  Future<void> _loadProject(
    String projectId, {
    required List<ProjectSummary> projects,
    required List<DatabaseReference> databases,
    required List<ReferenceOption> regions,
    required List<ReferenceOption> cloudProviders,
  }) async {
    final topologies = await _repository.listTopologies(projectId);
    final dashboard = await _repository.getDashboard(projectId);
    List<MemberRecord> members = const [];
    try {
      members = await _repository.listMembers(projectId);
    } catch (_) {
      members = const [];
    }

    final selectedTopologyId = topologies.isNotEmpty
        ? (state.selectedTopologyId != null &&
                  topologies.any((item) => item.id == state.selectedTopologyId)
              ? state.selectedTopologyId
              : topologies.first.id)
        : null;

    state = state.copyWith(
      isLoading: false,
      usingDemoData: false,
      projects: projects,
      selectedProjectId: projectId,
      topologies: topologies,
      selectedTopologyId: selectedTopologyId,
      selectedComponentId: null,
      databases: databases,
      regions: regions,
      cloudProviders: cloudProviders,
      dashboard: dashboard,
      members: members,
      comparison: null,
      clearError: true,
      clearInfo: true,
    );
    await _ref.read(authControllerProvider.notifier).rememberProject(projectId);
  }

  Future<void> _persistTopology(
    TopologyModel topology, {
    bool silent = false,
  }) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }

    final updatedTopologies = state.topologies
        .map((item) => item.id == topology.id ? topology : item)
        .toList();

    state = state.copyWith(
      topologies: updatedTopologies,
      selectedTopologyId: topology.id,
      infoMessage: silent ? state.infoMessage : 'Topology updated.',
    );

    if (!state.usingDemoData) {
      try {
        await _repository.updateTopology(projectId, topology.id, topology);
        await refreshDashboard();
      } catch (_) {
        state = state.copyWith(
          errorMessage: 'Unable to persist the latest topology change.',
        );
      }
    }
  }

  Future<void> _ensureComponentDetails(TopologyComponent component) async {
    final projectId = state.selectedProjectId;
    if (projectId == null) {
      return;
    }

    if (component.type == ComponentType.compute) {
      if (!state.computeSpecs.containsKey(component.id)) {
        final computeSpec = await _loadOrFallback<ComputeSpec>(
          load: () => _repository.getComputeSpec(projectId, component.id),
          fallback: () => DemoDataFactory.computeSpec(component.id),
        );
        final k8sSpec = await _loadOrFallback<K8sClusterSpec>(
          load: () => _repository.getK8sSpec(projectId, component.id),
          fallback: () => DemoDataFactory.k8sSpec(component.id),
        );
        final dockerSpec = await _loadOrFallback<DockerContainerSpec>(
          load: () => _repository.getDockerSpec(projectId, component.id),
          fallback: () => DemoDataFactory.dockerSpec(component.id),
        );
        state = state.copyWith(
          computeSpecs: {...state.computeSpecs, component.id: computeSpec},
          k8sSpecs: {...state.k8sSpecs, component.id: k8sSpec},
          dockerSpecs: {...state.dockerSpecs, component.id: dockerSpec},
        );
      }
      return;
    }

    if (component.type == ComponentType.database) {
      if (!state.dbSpecs.containsKey(component.id)) {
        final dbSpec = await _loadOrFallback<DbModelSpec>(
          load: () => _repository.getDbSpec(projectId, component.id),
          fallback: () => DemoDataFactory.dbSpec(component.id),
        );
        final storageProjection = await _loadOrFallback<DbStorageProjection>(
          load: () => _repository.getStorageProjection(projectId, component.id),
          fallback: () => DemoDataFactory.storageProjection(component.id),
        );
        state = state.copyWith(
          dbSpecs: {...state.dbSpecs, component.id: dbSpec},
          storageProjections: {
            ...state.storageProjections,
            component.id: storageProjection,
          },
        );
      }
      return;
    }

    if (component.type == ComponentType.cache &&
        !state.cacheSpecs.containsKey(component.id)) {
      final spec = await _loadOrFallback<CacheSpec>(
        load: () => _repository.getCacheSpec(projectId, component.id),
        fallback: () => DemoDataFactory.cacheSpec(component.id),
      );
      state = state.copyWith(
        cacheSpecs: {...state.cacheSpecs, component.id: spec},
      );
      return;
    }

    if (component.type == ComponentType.loadBalancer &&
        !state.loadBalancerSpecs.containsKey(component.id)) {
      final spec = await _loadOrFallback<LoadBalancerSpec>(
        load: () => _repository.getLoadBalancerSpec(projectId, component.id),
        fallback: () => DemoDataFactory.loadBalancerSpec(component.id),
      );
      state = state.copyWith(
        loadBalancerSpecs: {...state.loadBalancerSpecs, component.id: spec},
      );
      return;
    }

    if (component.type == ComponentType.cdn &&
        !state.cdnSpecs.containsKey(component.id)) {
      final spec = await _loadOrFallback<CdnSpec>(
        load: () => _repository.getCdnSpec(projectId, component.id),
        fallback: () => DemoDataFactory.cdnSpec(component.id),
      );
      state = state.copyWith(cdnSpecs: {...state.cdnSpecs, component.id: spec});
      return;
    }

    if (component.type == ComponentType.apiGateway &&
        !state.apiGatewaySpecs.containsKey(component.id)) {
      final spec = await _loadOrFallback<APIGatewaySpec>(
        load: () => _repository.getApiGatewaySpec(projectId, component.id),
        fallback: () => DemoDataFactory.apiGatewaySpec(component.id),
      );
      state = state.copyWith(
        apiGatewaySpecs: {...state.apiGatewaySpecs, component.id: spec},
      );
      return;
    }

    if (component.type == ComponentType.cronJob &&
        !state.cronJobSpecs.containsKey(component.id)) {
      final spec = await _loadOrFallback<CronJobSpec>(
        load: () => _repository.getCronJobSpec(projectId, component.id),
        fallback: () => DemoDataFactory.cronJobSpec(component.id),
      );
      state = state.copyWith(
        cronJobSpecs: {...state.cronJobSpecs, component.id: spec},
      );
      return;
    }

    if (component.type == ComponentType.objectStore &&
        !state.objectStorageSpecs.containsKey(component.id)) {
      final spec = await _loadOrFallback<ObjectStorageSpec>(
        load: () => _repository.getObjectStorageSpec(projectId, component.id),
        fallback: () => DemoDataFactory.objectStorageSpec(component.id),
      );
      state = state.copyWith(
        objectStorageSpecs: {...state.objectStorageSpecs, component.id: spec},
      );
      return;
    }

    if (component.type == ComponentType.serviceMesh &&
        !state.serviceMeshSpecs.containsKey(component.id)) {
      final spec = await _loadOrFallback<ServiceMeshSpec>(
        load: () => _repository.getServiceMeshSpec(projectId, component.id),
        fallback: () => DemoDataFactory.serviceMeshSpec(component.id),
      );
      state = state.copyWith(
        serviceMeshSpecs: {...state.serviceMeshSpecs, component.id: spec},
      );
      return;
    }

    if (component.type == ComponentType.thirdPartyApi &&
        !state.thirdPartyApiSpecs.containsKey(component.id)) {
      final spec = await _loadOrFallback<ThirdPartyAPISpec>(
        load: () => _repository.getThirdPartyApiSpec(projectId, component.id),
        fallback: () => DemoDataFactory.thirdPartyApiSpec(component.id),
      );
      state = state.copyWith(
        thirdPartyApiSpecs: {...state.thirdPartyApiSpecs, component.id: spec},
      );
    }
  }

  Future<T> _loadOrFallback<T>({
    required Future<T> Function() load,
    required T Function() fallback,
  }) async {
    if (state.usingDemoData) {
      return fallback();
    }
    try {
      return await load();
    } catch (_) {
      return fallback();
    }
  }

  void _loadDemo({String? infoMessage}) {
    final projects = DemoDataFactory.projects();
    final topologies = DemoDataFactory.topologies();
    state = state.copyWith(
      isLoading: false,
      usingDemoData: true,
      projects: projects,
      selectedProjectId: projects.first.projectId,
      topologies: topologies,
      selectedTopologyId: topologies.first.id,
      selectedComponentId: 'cmp_api',
      databases: DemoDataFactory.databases(),
      regions: DemoDataFactory.regions(),
      cloudProviders: DemoDataFactory.cloudProviders(),
      dashboard: DemoDataFactory.dashboard(),
      comparison: DemoDataFactory.comparison(),
      members: DemoDataFactory.members(),
      computeSpecs: {'cmp_api': DemoDataFactory.computeSpec('cmp_api')},
      cacheSpecs: {'cmp_cache': DemoDataFactory.cacheSpec('cmp_cache')},
      loadBalancerSpecs: {'cmp_lb': DemoDataFactory.loadBalancerSpec('cmp_lb')},
      cdnSpecs: {'cmp_cdn': DemoDataFactory.cdnSpec('cmp_cdn')},
      dbSpecs: {'cmp_db': DemoDataFactory.dbSpec('cmp_db')},
      storageProjections: {
        'cmp_db': DemoDataFactory.storageProjection('cmp_db'),
      },
      k8sSpecs: {'cmp_api': DemoDataFactory.k8sSpec('cmp_api')},
      dockerSpecs: {'cmp_api': DemoDataFactory.dockerSpec('cmp_api')},
      errorMessage: null,
      infoMessage: infoMessage,
    );
  }

  TopologyModel _buildDefaultTopology(String name) {
    final clientId = 'cmp_${_uuid.v4()}';
    final computeId = 'cmp_${_uuid.v4()}';
    final databaseId = 'cmp_${_uuid.v4()}';
    final cacheId = 'cmp_${_uuid.v4()}';

    return TopologyModel(
      id: 'topo_${_uuid.v4()}',
      name: name,
      deploymentMode: DeploymentMode.multiTier,
      baseUserCount: 1000,
      growthTargets: const [1000, 10000, 100000, 1000000],
      components: [
        TopologyComponent(
          id: clientId,
          name: 'Client',
          type: ComponentType.client,
          enabled: true,
          location: GeoLocation.defaultValue(),
          cloudProvider: CloudProvider.aws,
          description: 'Client entry point',
          tags: const {'canvas_x': '140', 'canvas_y': '240'},
        ),
        TopologyComponent(
          id: computeId,
          name: 'App Server',
          type: ComponentType.compute,
          enabled: true,
          location: GeoLocation.defaultValue(),
          cloudProvider: CloudProvider.aws,
          description: 'Primary compute tier',
          tags: const {'canvas_x': '460', 'canvas_y': '210'},
        ),
        TopologyComponent(
          id: databaseId,
          name: 'Main Database',
          type: ComponentType.database,
          enabled: true,
          location: GeoLocation.defaultValue(),
          cloudProvider: CloudProvider.aws,
          description: 'Primary persistence layer',
          tags: const {'canvas_x': '780', 'canvas_y': '260'},
        ),
        TopologyComponent(
          id: cacheId,
          name: 'Cache',
          type: ComponentType.cache,
          enabled: true,
          location: GeoLocation.defaultValue(),
          cloudProvider: CloudProvider.aws,
          description: 'Low-latency cache layer',
          tags: const {'canvas_x': '780', 'canvas_y': '90'},
        ),
      ],
      edges: [
        TopologyEdge(
          id: 'edge_${_uuid.v4()}',
          sourceComponentId: clientId,
          targetComponentId: computeId,
          estimatedBandwidthMbps: 100,
          estimatedLatencyMs: 20,
        ),
        TopologyEdge(
          id: 'edge_${_uuid.v4()}',
          sourceComponentId: computeId,
          targetComponentId: databaseId,
          estimatedBandwidthMbps: 100,
          estimatedLatencyMs: 2,
        ),
        TopologyEdge(
          id: 'edge_${_uuid.v4()}',
          sourceComponentId: computeId,
          targetComponentId: cacheId,
          estimatedBandwidthMbps: 100,
          estimatedLatencyMs: 1,
        ),
      ],
    );
  }
}

final dataForgeRepositoryProvider = Provider<DataForgeRepository>((ref) {
  return DataForgeRepository();
});

final workspaceControllerProvider =
    StateNotifierProvider<WorkspaceController, WorkspaceState>((ref) {
      ref.read(authControllerProvider);
      return WorkspaceController(ref, ref.watch(dataForgeRepositoryProvider));
    });
