import '../core/network/api_client.dart';
import '../models/comparison_models.dart';
import '../models/dashboard_models.dart';
import '../models/project_models.dart';
import '../models/reference_models.dart';
import '../models/spec_models.dart';
import '../models/topology_models.dart';

class DataForgeRepository {
  DataForgeRepository() : _client = ApiClient.instance;

  final ApiClient _client;

  Future<List<ProjectSummary>> listProjects() async {
    final response = await _client.dio.get<dynamic>('/projects');
    final data = response.data as Map<String, dynamic>;
    return (data['projects'] as List<dynamic>? ?? [])
        .map((item) => ProjectSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectSummary> createProject({
    required String name,
    String description = '',
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/projects',
      data: {'name': name, 'description': description},
    );
    return ProjectSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TopologyModel>> listTopologies(String projectId) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/topology/all',
    );
    final data = response.data as Map<String, dynamic>;
    return (data['topologies'] as List<dynamic>? ?? [])
        .map((item) => TopologyModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TopologyModel> createTopology(
    String projectId,
    TopologyModel topology,
  ) async {
    final response = await _client.dio.post<dynamic>(
      '/projects/$projectId/topology/create',
      data: topology.toJson(),
    );
    return TopologyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TopologyModel> updateTopology(
    String projectId,
    String topologyId,
    TopologyModel topology,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '/projects/$projectId/topology/$topologyId',
      data: topology.toJson(),
    );
    return TopologyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TopologyModel> collapseTopology(String projectId) async {
    final response = await _client.dio.post<dynamic>(
      '/projects/$projectId/topology/collapse',
    );
    return TopologyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ComputeSpec> getComputeSpec(
    String projectId,
    String componentId,
  ) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/specs/compute/$componentId',
    );
    return ComputeSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ComputeSpec> saveComputeSpec(
    String projectId,
    String componentId,
    ComputeSpec spec,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '/projects/$projectId/specs/compute/$componentId',
      data: spec.toJson(),
    );
    return ComputeSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CacheSpec> getCacheSpec(String projectId, String componentId) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/specs/cache/$componentId',
    );
    return CacheSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CacheSpec> saveCacheSpec(
    String projectId,
    String componentId,
    CacheSpec spec,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '/projects/$projectId/specs/cache/$componentId',
      data: spec.toJson(),
    );
    return CacheSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LoadBalancerSpec> getLoadBalancerSpec(
    String projectId,
    String componentId,
  ) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/specs/lb/$componentId',
    );
    return LoadBalancerSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LoadBalancerSpec> saveLoadBalancerSpec(
    String projectId,
    String componentId,
    LoadBalancerSpec spec,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '/projects/$projectId/specs/lb/$componentId',
      data: spec.toJson(),
    );
    return LoadBalancerSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CdnSpec> getCdnSpec(String projectId, String componentId) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/specs/cdn/$componentId',
    );
    return CdnSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CdnSpec> saveCdnSpec(
    String projectId,
    String componentId,
    CdnSpec spec,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '/projects/$projectId/specs/cdn/$componentId',
      data: spec.toJson(),
    );
    return CdnSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<K8sClusterSpec> getK8sSpec(
    String projectId,
    String componentId,
  ) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/specs/k8s/$componentId',
    );
    return K8sClusterSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<K8sClusterSpec> saveK8sSpec(
    String projectId,
    String componentId,
    K8sClusterSpec spec,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '/projects/$projectId/specs/k8s/$componentId',
      data: spec.toJson(),
    );
    return K8sClusterSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DockerContainerSpec> getDockerSpec(
    String projectId,
    String componentId,
  ) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/specs/docker/$componentId',
    );
    return DockerContainerSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DockerContainerSpec> saveDockerSpec(
    String projectId,
    String componentId,
    DockerContainerSpec spec,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '/projects/$projectId/specs/docker/$componentId',
      data: spec.toJson(),
    );
    return DockerContainerSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DbModelSpec> getDbSpec(String projectId, String componentId) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/db/$componentId',
    );
    return DbModelSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DbModelSpec> saveDbSpec(
    String projectId,
    String componentId,
    DbModelSpec spec,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '/projects/$projectId/db/$componentId',
      data: spec.toJson(),
    );
    return DbModelSpec.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DbStorageProjection> getStorageProjection(
    String projectId,
    String componentId,
  ) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/db/$componentId/storage-projection',
    );
    return DbStorageProjection.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConsolidatedDashboard> getDashboard(String projectId) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/cost',
    );
    return ConsolidatedDashboard.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ConsolidatedDashboard> compareDatabase(
    String projectId,
    String alternateDatabaseId,
  ) async {
    final response = await _client.dio.post<dynamic>(
      '/projects/$projectId/cost/compare',
      data: {'alternate_database_id': alternateDatabaseId},
    );
    return ConsolidatedDashboard.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<TopologyComparison> compareTopologies({
    required String sourceProjectId,
    required String sourceTopologyId,
    required String targetProjectId,
    required String targetTopologyId,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/topologies/compare',
      data: {
        'source_project_id': sourceProjectId,
        'source_topology_id': sourceTopologyId,
        'target_project_id': targetProjectId,
        'target_topology_id': targetTopologyId,
      },
    );
    return TopologyComparison.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DatabaseReference>> listDatabases() async {
    final response = await _client.dio.get<dynamic>('/reference/databases');
    final data = response.data as Map<String, dynamic>;
    return (data['databases'] as List<dynamic>? ?? [])
        .map((item) => DatabaseReference.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReferenceOption>> listRegions() async {
    final response = await _client.dio.get<dynamic>('/reference/regions');
    final data = response.data as Map<String, dynamic>;
    return (data['regions'] as List<dynamic>? ?? [])
        .map((item) => ReferenceOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReferenceOption>> listCloudProviders() async {
    final response = await _client.dio.get<dynamic>(
      '/reference/cloud-providers',
    );
    final data = response.data as Map<String, dynamic>;
    return (data['providers'] as List<dynamic>? ?? [])
        .map((item) => ReferenceOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MemberRecord>> listMembers(String projectId) async {
    final response = await _client.dio.get<dynamic>(
      '/projects/$projectId/members',
    );
    final data = response.data as Map<String, dynamic>;
    return (data['members'] as List<dynamic>? ?? [])
        .map((item) => MemberRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MemberRecord> addMember({
    required String projectId,
    required String userId,
    required String role,
    required List<String> topologyAccess,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/projects/$projectId/members',
      data: {
        'user_id': userId,
        'role': role,
        'topology_access': topologyAccess,
      },
    );
    return MemberRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MemberRecord> shareTopologies({
    required String projectId,
    required String userId,
    required List<String> topologyIds,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/projects/$projectId/members/share-topologies',
      data: {'user_id': userId, 'topology_ids': topologyIds},
    );
    return MemberRecord.fromJson(response.data as Map<String, dynamic>);
  }
}
