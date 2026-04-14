import '../core/utils/formatting.dart';

class GeoLocation {
  const GeoLocation({
    required this.region,
    required this.availabilityZones,
    this.description,
  });

  final String region;
  final int availabilityZones;
  final String? description;

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      region: json['region'] as String? ?? 'us-east-1',
      availabilityZones: json['availability_zones'] as int? ?? 1,
      description: json['description'] as String?,
    );
  }

  factory GeoLocation.defaultValue() {
    return const GeoLocation(region: 'us-east-1', availabilityZones: 1);
  }

  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'availability_zones': availabilityZones,
      'description': description,
    };
  }

  GeoLocation copyWith({
    String? region,
    int? availabilityZones,
    String? description,
  }) {
    return GeoLocation(
      region: region ?? this.region,
      availabilityZones: availabilityZones ?? this.availabilityZones,
      description: description ?? this.description,
    );
  }
}

enum CloudProvider { aws, gcp, azure, selfHosted }

extension CloudProviderX on CloudProvider {
  String get value => switch (this) {
    CloudProvider.aws => 'aws',
    CloudProvider.gcp => 'gcp',
    CloudProvider.azure => 'azure',
    CloudProvider.selfHosted => 'self_hosted',
  };

  String get label => titleCase(value);

  static CloudProvider fromValue(String? value) {
    return CloudProvider.values.firstWhere(
      (provider) => provider.value == value,
      orElse: () => CloudProvider.aws,
    );
  }
}

enum DeploymentMode { singleInstance, multiTier, distributed }

extension DeploymentModeX on DeploymentMode {
  String get value => switch (this) {
    DeploymentMode.singleInstance => 'single_instance',
    DeploymentMode.multiTier => 'multi_tier',
    DeploymentMode.distributed => 'distributed',
  };

  String get label => switch (this) {
    DeploymentMode.singleInstance => 'Single Instance',
    DeploymentMode.multiTier => 'Multi Tier',
    DeploymentMode.distributed => 'Distributed',
  };

  static DeploymentMode fromValue(String? value) {
    return DeploymentMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => DeploymentMode.multiTier,
    );
  }
}

enum TopologyType { live, experimental }

extension TopologyTypeX on TopologyType {
  String get value => switch (this) {
    TopologyType.live => 'live',
    TopologyType.experimental => 'experimental',
  };

  String get label => switch (this) {
    TopologyType.live => 'Live',
    TopologyType.experimental => 'Experimental',
  };

  static TopologyType fromValue(String? value) {
    return TopologyType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TopologyType.live,
    );
  }
}

enum ComponentType {
  compute,
  database,
  cache,
  loadBalancer,
  cdn,
  client,
  objectStore,
  messageQueue,
  apiGateway,
  cronJob,
  serviceMesh,
  thirdPartyApi,
}

extension ComponentTypeX on ComponentType {
  String get value => switch (this) {
    ComponentType.compute => 'compute',
    ComponentType.database => 'database',
    ComponentType.cache => 'cache',
    ComponentType.loadBalancer => 'load_balancer',
    ComponentType.cdn => 'cdn',
    ComponentType.client => 'client',
    ComponentType.objectStore => 'object_store',
    ComponentType.messageQueue => 'message_queue',
    ComponentType.apiGateway => 'api_gateway',
    ComponentType.cronJob => 'cron_job',
    ComponentType.serviceMesh => 'service_mesh',
    ComponentType.thirdPartyApi => 'third_party_api',
  };

  String get label => switch (this) {
    ComponentType.compute => 'Server',
    ComponentType.database => 'Database',
    ComponentType.cache => 'Cache',
    ComponentType.loadBalancer => 'Load Balancer',
    ComponentType.cdn => 'CDN',
    ComponentType.client => 'Client',
    ComponentType.objectStore => 'Storage',
    ComponentType.messageQueue => 'Queue',
    ComponentType.apiGateway => 'API Gateway',
    ComponentType.cronJob => 'Cron Job',
    ComponentType.serviceMesh => 'Service Mesh',
    ComponentType.thirdPartyApi => 'Third-party API',
  };

  static ComponentType fromValue(String? value) {
    return ComponentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ComponentType.compute,
    );
  }
}

class TopologyComponent {
  const TopologyComponent({
    required this.id,
    required this.name,
    required this.type,
    required this.enabled,
    required this.location,
    required this.cloudProvider,
    required this.description,
    required this.tags,
  });

  final String id;
  final String name;
  final ComponentType type;
  final bool enabled;
  final GeoLocation location;
  final CloudProvider cloudProvider;
  final String? description;
  final Map<String, String> tags;

  double get canvasX => double.tryParse(tags['canvas_x'] ?? '') ?? 240;
  double get canvasY => double.tryParse(tags['canvas_y'] ?? '') ?? 200;

  factory TopologyComponent.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as Map<String, dynamic>? ?? {};
    return TopologyComponent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: ComponentTypeX.fromValue(json['type'] as String?),
      enabled: json['enabled'] as bool? ?? true,
      location: GeoLocation.fromJson(
        json['location'] as Map<String, dynamic>? ?? const {},
      ),
      cloudProvider: CloudProviderX.fromValue(
        json['cloud_provider'] as String?,
      ),
      description: json['description'] as String?,
      tags: rawTags.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'enabled': enabled,
      'location': location.toJson(),
      'cloud_provider': cloudProvider.value,
      'description': description,
      'tags': tags,
    };
  }

  TopologyComponent copyWith({
    String? name,
    ComponentType? type,
    bool? enabled,
    GeoLocation? location,
    CloudProvider? cloudProvider,
    String? description,
    Map<String, String>? tags,
  }) {
    return TopologyComponent(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      location: location ?? this.location,
      cloudProvider: cloudProvider ?? this.cloudProvider,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }

  TopologyComponent withCanvasPosition(double x, double y) {
    return copyWith(tags: {...tags, 'canvas_x': '$x', 'canvas_y': '$y'});
  }
}

class TopologyEdge {
  const TopologyEdge({
    required this.id,
    required this.sourceComponentId,
    required this.targetComponentId,
    required this.estimatedBandwidthMbps,
    required this.estimatedLatencyMs,
    this.description,
  });

  final String id;
  final String sourceComponentId;
  final String targetComponentId;
  final double estimatedBandwidthMbps;
  final double estimatedLatencyMs;
  final String? description;

  factory TopologyEdge.fromJson(Map<String, dynamic> json) {
    return TopologyEdge(
      id: json['id'] as String? ?? '',
      sourceComponentId: json['source_component_id'] as String? ?? '',
      targetComponentId: json['target_component_id'] as String? ?? '',
      estimatedBandwidthMbps:
          (json['estimated_bandwidth_mbps'] as num?)?.toDouble() ?? 100,
      estimatedLatencyMs:
          (json['estimated_latency_ms'] as num?)?.toDouble() ?? 1,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_component_id': sourceComponentId,
      'target_component_id': targetComponentId,
      'estimated_bandwidth_mbps': estimatedBandwidthMbps,
      'estimated_latency_ms': estimatedLatencyMs,
      'description': description,
    };
  }
}

class TopologyModel {
  const TopologyModel({
    required this.id,
    required this.name,
    required this.deploymentMode,
    required this.components,
    required this.edges,
    required this.baseUserCount,
    required this.growthTargets,
    this.topologyType = TopologyType.live,
    this.clonedFrom,
    this.lastSyncedAt,
    this.syncVersion,
  });

  final String id;
  final String name;
  final DeploymentMode deploymentMode;
  final List<TopologyComponent> components;
  final List<TopologyEdge> edges;
  final int baseUserCount;
  final List<int> growthTargets;
  final TopologyType topologyType;
  final String? clonedFrom;
  final String? lastSyncedAt;
  final int? syncVersion;

  bool get isLive => topologyType == TopologyType.live;
  bool get isExperimental => topologyType == TopologyType.experimental;

  factory TopologyModel.fromJson(Map<String, dynamic> json) {
    return TopologyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      deploymentMode: DeploymentModeX.fromValue(
        json['deployment_mode'] as String?,
      ),
      components: (json['components'] as List<dynamic>? ?? [])
          .map(
            (item) => TopologyComponent.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      edges: (json['edges'] as List<dynamic>? ?? [])
          .map((item) => TopologyEdge.fromJson(item as Map<String, dynamic>))
          .toList(),
      baseUserCount: json['base_user_count'] as int? ?? 1000,
      growthTargets:
          (json['growth_targets'] as List<dynamic>? ??
                  const [1000, 10000, 100000, 1000000])
              .map((item) => (item as num).toInt())
              .toList(),
      topologyType: TopologyTypeX.fromValue(
        json['topology_type'] as String?,
      ),
      clonedFrom: json['cloned_from'] as String?,
      lastSyncedAt: json['last_synced_at'] as String?,
      syncVersion: json['sync_version'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deployment_mode': deploymentMode.value,
      'components': components.map((item) => item.toJson()).toList(),
      'edges': edges.map((item) => item.toJson()).toList(),
      'base_user_count': baseUserCount,
      'growth_targets': growthTargets,
      'topology_type': topologyType.value,
      'cloned_from': clonedFrom,
      'last_synced_at': lastSyncedAt,
      'sync_version': syncVersion,
    };
  }

  TopologyModel copyWith({
    String? name,
    DeploymentMode? deploymentMode,
    List<TopologyComponent>? components,
    List<TopologyEdge>? edges,
    int? baseUserCount,
    List<int>? growthTargets,
    TopologyType? topologyType,
    String? clonedFrom,
    String? lastSyncedAt,
    int? syncVersion,
  }) {
    return TopologyModel(
      id: id,
      name: name ?? this.name,
      deploymentMode: deploymentMode ?? this.deploymentMode,
      components: components ?? this.components,
      edges: edges ?? this.edges,
      baseUserCount: baseUserCount ?? this.baseUserCount,
      growthTargets: growthTargets ?? this.growthTargets,
      topologyType: topologyType ?? this.topologyType,
      clonedFrom: clonedFrom ?? this.clonedFrom,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }
}
