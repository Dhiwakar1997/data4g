class ComputeSpec {
  const ComputeSpec({
    required this.topologyComponentId,
    required this.cpuCores,
    required this.ramGb,
    required this.gpuType,
    required this.gpuCount,
    required this.gpuVramGb,
    required this.instanceFamily,
    required this.instanceSize,
    required this.os,
    required this.storageGb,
    required this.cloudProvider,
    required this.region,
    required this.autoscalingEnabled,
    required this.minInstances,
    required this.maxInstances,
    required this.targetCpuUtilization,
    required this.targetMemoryUtilization,
  });

  final String topologyComponentId;
  final int cpuCores;
  final double ramGb;
  final String gpuType;
  final int gpuCount;
  final double gpuVramGb;
  final String instanceFamily;
  final String instanceSize;
  final String os;
  final double storageGb;
  final String cloudProvider;
  final String region;
  final bool autoscalingEnabled;
  final int minInstances;
  final int maxInstances;
  final double targetCpuUtilization;
  final double targetMemoryUtilization;

  factory ComputeSpec.fromJson(Map<String, dynamic> json) {
    final gpu = json['gpu'] as Map<String, dynamic>? ?? const {};
    final autoscaling =
        json['autoscaling'] as Map<String, dynamic>? ?? const {};
    return ComputeSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      cpuCores: json['cpu_cores'] as int? ?? 2,
      ramGb: (json['ram_gb'] as num?)?.toDouble() ?? 4,
      gpuType: gpu['type'] as String? ?? 'none',
      gpuCount: gpu['count'] as int? ?? 0,
      gpuVramGb: (gpu['vram_gb'] as num?)?.toDouble() ?? 0,
      instanceFamily: json['instance_family'] as String? ?? 'general_purpose',
      instanceSize: json['instance_size'] as String? ?? 'medium',
      os: json['os'] as String? ?? 'linux',
      storageGb: (json['storage_gb'] as num?)?.toDouble() ?? 50,
      cloudProvider: json['cloud_provider'] as String? ?? 'aws',
      region: json['region'] as String? ?? 'us-east-1',
      autoscalingEnabled: autoscaling['enabled'] as bool? ?? false,
      minInstances: autoscaling['min_instances'] as int? ?? 1,
      maxInstances: autoscaling['max_instances'] as int? ?? 1,
      targetCpuUtilization:
          (autoscaling['target_cpu_utilization'] as num?)?.toDouble() ?? 0.7,
      targetMemoryUtilization:
          (autoscaling['target_memory_utilization'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'cpu_cores': cpuCores,
      'ram_gb': ramGb,
      'gpu': {'type': gpuType, 'count': gpuCount, 'vram_gb': gpuVramGb},
      'instance_family': instanceFamily,
      'instance_size': instanceSize,
      'os': os,
      'storage_gb': storageGb,
      'cloud_provider': cloudProvider,
      'region': region,
      'autoscaling': {
        'enabled': autoscalingEnabled,
        'min_instances': minInstances,
        'max_instances': maxInstances,
        'target_cpu_utilization': targetCpuUtilization,
        'target_memory_utilization': targetMemoryUtilization,
      },
    };
  }

  ComputeSpec copyWith({
    int? cpuCores,
    double? ramGb,
    String? gpuType,
    int? gpuCount,
    double? gpuVramGb,
    String? instanceFamily,
    String? instanceSize,
    String? os,
    double? storageGb,
    String? cloudProvider,
    String? region,
    bool? autoscalingEnabled,
    int? minInstances,
    int? maxInstances,
    double? targetCpuUtilization,
    double? targetMemoryUtilization,
  }) {
    return ComputeSpec(
      topologyComponentId: topologyComponentId,
      cpuCores: cpuCores ?? this.cpuCores,
      ramGb: ramGb ?? this.ramGb,
      gpuType: gpuType ?? this.gpuType,
      gpuCount: gpuCount ?? this.gpuCount,
      gpuVramGb: gpuVramGb ?? this.gpuVramGb,
      instanceFamily: instanceFamily ?? this.instanceFamily,
      instanceSize: instanceSize ?? this.instanceSize,
      os: os ?? this.os,
      storageGb: storageGb ?? this.storageGb,
      cloudProvider: cloudProvider ?? this.cloudProvider,
      region: region ?? this.region,
      autoscalingEnabled: autoscalingEnabled ?? this.autoscalingEnabled,
      minInstances: minInstances ?? this.minInstances,
      maxInstances: maxInstances ?? this.maxInstances,
      targetCpuUtilization: targetCpuUtilization ?? this.targetCpuUtilization,
      targetMemoryUtilization:
          targetMemoryUtilization ?? this.targetMemoryUtilization,
    );
  }
}

class CacheSpec {
  const CacheSpec({
    required this.topologyComponentId,
    required this.cacheDatabase,
    required this.memoryGb,
    required this.evictionPolicy,
    required this.ttlSeconds,
    required this.clusterNodes,
    required this.highAvailability,
  });

  final String topologyComponentId;
  final String cacheDatabase;
  final double memoryGb;
  final String evictionPolicy;
  final int ttlSeconds;
  final int clusterNodes;
  final bool highAvailability;

  factory CacheSpec.fromJson(Map<String, dynamic> json) {
    return CacheSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      cacheDatabase: json['cache_database'] as String? ?? 'redis',
      memoryGb: (json['memory_gb'] as num?)?.toDouble() ?? 1,
      evictionPolicy: json['eviction_policy'] as String? ?? 'allkeys_lru',
      ttlSeconds: json['ttl_seconds'] as int? ?? 3600,
      clusterNodes: json['cluster_nodes'] as int? ?? 1,
      highAvailability: json['high_availability'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'cache_database': cacheDatabase,
      'memory_gb': memoryGb,
      'eviction_policy': evictionPolicy,
      'ttl_seconds': ttlSeconds,
      'cluster_nodes': clusterNodes,
      'high_availability': highAvailability,
    };
  }

  CacheSpec copyWith({
    String? cacheDatabase,
    double? memoryGb,
    String? evictionPolicy,
    int? ttlSeconds,
    int? clusterNodes,
    bool? highAvailability,
  }) {
    return CacheSpec(
      topologyComponentId: topologyComponentId,
      cacheDatabase: cacheDatabase ?? this.cacheDatabase,
      memoryGb: memoryGb ?? this.memoryGb,
      evictionPolicy: evictionPolicy ?? this.evictionPolicy,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
      clusterNodes: clusterNodes ?? this.clusterNodes,
      highAvailability: highAvailability ?? this.highAvailability,
    );
  }
}

class LoadBalancerSpec {
  const LoadBalancerSpec({
    required this.topologyComponentId,
    required this.algorithm,
    required this.targetComponentIds,
    required this.healthCheckIntervalSeconds,
    required this.sslTermination,
    required this.estimatedRequestsPerSecond,
    required this.estimatedDataProcessedGbMonth,
  });

  final String topologyComponentId;
  final String algorithm;
  final List<String> targetComponentIds;
  final int healthCheckIntervalSeconds;
  final bool sslTermination;
  final double estimatedRequestsPerSecond;
  final double estimatedDataProcessedGbMonth;

  factory LoadBalancerSpec.fromJson(Map<String, dynamic> json) {
    return LoadBalancerSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'round_robin',
      targetComponentIds: (json['target_component_ids'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      healthCheckIntervalSeconds:
          json['health_check_interval_seconds'] as int? ?? 30,
      sslTermination: json['ssl_termination'] as bool? ?? true,
      estimatedRequestsPerSecond:
          (json['estimated_requests_per_second'] as num?)?.toDouble() ?? 100,
      estimatedDataProcessedGbMonth:
          (json['estimated_data_processed_gb_month'] as num?)?.toDouble() ??
          100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'algorithm': algorithm,
      'target_component_ids': targetComponentIds,
      'health_check_interval_seconds': healthCheckIntervalSeconds,
      'ssl_termination': sslTermination,
      'estimated_requests_per_second': estimatedRequestsPerSecond,
      'estimated_data_processed_gb_month': estimatedDataProcessedGbMonth,
    };
  }

  LoadBalancerSpec copyWith({
    String? algorithm,
    List<String>? targetComponentIds,
    int? healthCheckIntervalSeconds,
    bool? sslTermination,
    double? estimatedRequestsPerSecond,
    double? estimatedDataProcessedGbMonth,
  }) {
    return LoadBalancerSpec(
      topologyComponentId: topologyComponentId,
      algorithm: algorithm ?? this.algorithm,
      targetComponentIds: targetComponentIds ?? this.targetComponentIds,
      healthCheckIntervalSeconds:
          healthCheckIntervalSeconds ?? this.healthCheckIntervalSeconds,
      sslTermination: sslTermination ?? this.sslTermination,
      estimatedRequestsPerSecond:
          estimatedRequestsPerSecond ?? this.estimatedRequestsPerSecond,
      estimatedDataProcessedGbMonth:
          estimatedDataProcessedGbMonth ?? this.estimatedDataProcessedGbMonth,
    );
  }
}

class CdnSpec {
  const CdnSpec({
    required this.topologyComponentId,
    required this.provider,
    required this.estimatedDataTransferGbMonth,
    required this.estimatedRequestsMillionMonth,
    required this.cacheHitRatio,
    required this.customDomain,
    required this.ssl,
  });

  final String topologyComponentId;
  final String provider;
  final double estimatedDataTransferGbMonth;
  final double estimatedRequestsMillionMonth;
  final double cacheHitRatio;
  final bool customDomain;
  final bool ssl;

  factory CdnSpec.fromJson(Map<String, dynamic> json) {
    return CdnSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      provider: json['provider'] as String? ?? 'cloudfront',
      estimatedDataTransferGbMonth:
          (json['estimated_data_transfer_gb_month'] as num?)?.toDouble() ?? 100,
      estimatedRequestsMillionMonth:
          (json['estimated_requests_million_month'] as num?)?.toDouble() ?? 10,
      cacheHitRatio: (json['cache_hit_ratio'] as num?)?.toDouble() ?? 0.85,
      customDomain: json['custom_domain'] as bool? ?? true,
      ssl: json['ssl'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'provider': provider,
      'estimated_data_transfer_gb_month': estimatedDataTransferGbMonth,
      'estimated_requests_million_month': estimatedRequestsMillionMonth,
      'cache_hit_ratio': cacheHitRatio,
      'custom_domain': customDomain,
      'ssl': ssl,
    };
  }

  CdnSpec copyWith({
    String? provider,
    double? estimatedDataTransferGbMonth,
    double? estimatedRequestsMillionMonth,
    double? cacheHitRatio,
    bool? customDomain,
    bool? ssl,
  }) {
    return CdnSpec(
      topologyComponentId: topologyComponentId,
      provider: provider ?? this.provider,
      estimatedDataTransferGbMonth:
          estimatedDataTransferGbMonth ?? this.estimatedDataTransferGbMonth,
      estimatedRequestsMillionMonth:
          estimatedRequestsMillionMonth ?? this.estimatedRequestsMillionMonth,
      cacheHitRatio: cacheHitRatio ?? this.cacheHitRatio,
      customDomain: customDomain ?? this.customDomain,
      ssl: ssl ?? this.ssl,
    );
  }
}

class FieldKeyConfig {
  const FieldKeyConfig({
    required this.keyType,
    this.referencesEntityId,
    this.referencesFieldId,
    this.onDelete,
    this.onUpdate,
  });

  final String keyType;
  final String? referencesEntityId;
  final String? referencesFieldId;
  final String? onDelete;
  final String? onUpdate;

  factory FieldKeyConfig.fromJson(Map<String, dynamic> json) {
    return FieldKeyConfig(
      keyType: json['key_type'] as String? ?? 'none',
      referencesEntityId: json['references_entity_id'] as String?,
      referencesFieldId: json['references_field_id'] as String?,
      onDelete: json['on_delete'] as String? ?? 'CASCADE',
      onUpdate: json['on_update'] as String? ?? 'CASCADE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key_type': keyType,
      'references_entity_id': referencesEntityId,
      'references_field_id': referencesFieldId,
      'on_delete': onDelete,
      'on_update': onUpdate,
    };
  }
}

class EntityFieldModel {
  const EntityFieldModel({
    required this.id,
    required this.name,
    required this.type,
    required this.required,
    required this.unique,
    required this.indexed,
    required this.key,
    required this.avgSizeBytes,
    this.defaultValue,
    this.enumValues,
    this.vectorDimensions,
    this.description,
  });

  final String id;
  final String name;
  final String type;
  final bool required;
  final bool unique;
  final bool indexed;
  final FieldKeyConfig key;
  final int avgSizeBytes;
  final String? defaultValue;
  final List<String>? enumValues;
  final int? vectorDimensions;
  final String? description;

  factory EntityFieldModel.fromJson(Map<String, dynamic> json) {
    return EntityFieldModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      required: json['required'] as bool? ?? true,
      unique: json['unique'] as bool? ?? false,
      indexed: json['indexed'] as bool? ?? false,
      key: FieldKeyConfig.fromJson(
        json['key'] as Map<String, dynamic>? ?? const {},
      ),
      avgSizeBytes: json['avg_size_bytes'] as int? ?? 64,
      defaultValue: json['default_value'] as String?,
      enumValues: (json['enum_values'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
      vectorDimensions: json['vector_dimensions'] as int?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'required': required,
      'unique': unique,
      'indexed': indexed,
      'key': key.toJson(),
      'avg_size_bytes': avgSizeBytes,
      'default_value': defaultValue,
      'enum_values': enumValues,
      'vector_dimensions': vectorDimensions,
      'description': description,
    };
  }

  EntityFieldModel copyWith({
    String? name,
    String? type,
    bool? required,
    bool? unique,
    bool? indexed,
    FieldKeyConfig? key,
    int? avgSizeBytes,
    String? defaultValue,
    List<String>? enumValues,
    int? vectorDimensions,
    String? description,
  }) {
    return EntityFieldModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      required: required ?? this.required,
      unique: unique ?? this.unique,
      indexed: indexed ?? this.indexed,
      key: key ?? this.key,
      avgSizeBytes: avgSizeBytes ?? this.avgSizeBytes,
      defaultValue: defaultValue ?? this.defaultValue,
      enumValues: enumValues ?? this.enumValues,
      vectorDimensions: vectorDimensions ?? this.vectorDimensions,
      description: description ?? this.description,
    );
  }
}

class EntityIndexModel {
  const EntityIndexModel({
    required this.id,
    required this.name,
    required this.fieldIds,
    required this.type,
    required this.unique,
  });

  final String id;
  final String name;
  final List<String> fieldIds;
  final String type;
  final bool unique;

  factory EntityIndexModel.fromJson(Map<String, dynamic> json) {
    return EntityIndexModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fieldIds: (json['field_ids'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      type: json['type'] as String? ?? 'btree',
      unique: json['unique'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'field_ids': fieldIds,
      'type': type,
      'unique': unique,
    };
  }
}

class EntityModel {
  const EntityModel({
    required this.id,
    required this.name,
    required this.fields,
    required this.indexes,
    required this.isCentral,
    this.description,
  });

  final String id;
  final String name;
  final List<EntityFieldModel> fields;
  final List<EntityIndexModel> indexes;
  final bool isCentral;
  final String? description;

  int get avgRecordSizeBytes =>
      fields.fold<int>(0, (sum, field) => sum + field.avgSizeBytes);

  factory EntityModel.fromJson(Map<String, dynamic> json) {
    return EntityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fields: (json['fields'] as List<dynamic>? ?? [])
          .map(
            (item) => EntityFieldModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      indexes: (json['indexes'] as List<dynamic>? ?? [])
          .map(
            (item) => EntityIndexModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      isCentral: json['is_central'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fields': fields.map((field) => field.toJson()).toList(),
      'indexes': indexes.map((index) => index.toJson()).toList(),
      'is_central': isCentral,
      'description': description,
    };
  }

  EntityModel copyWith({
    String? name,
    List<EntityFieldModel>? fields,
    List<EntityIndexModel>? indexes,
    bool? isCentral,
    String? description,
  }) {
    return EntityModel(
      id: id,
      name: name ?? this.name,
      fields: fields ?? this.fields,
      indexes: indexes ?? this.indexes,
      isCentral: isCentral ?? this.isCentral,
      description: description ?? this.description,
    );
  }
}

class RelationshipModel {
  const RelationshipModel({
    required this.id,
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.type,
    required this.ratio,
    this.fkFieldId,
    this.description,
  });

  final String id;
  final String sourceEntityId;
  final String targetEntityId;
  final String type;
  final double ratio;
  final String? fkFieldId;
  final String? description;

  factory RelationshipModel.fromJson(Map<String, dynamic> json) {
    return RelationshipModel(
      id: json['id'] as String? ?? '',
      sourceEntityId: json['source_entity_id'] as String? ?? '',
      targetEntityId: json['target_entity_id'] as String? ?? '',
      type: json['type'] as String? ?? '1:N',
      ratio: (json['ratio'] as num?)?.toDouble() ?? 1,
      fkFieldId: json['fk_field_id'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_entity_id': sourceEntityId,
      'target_entity_id': targetEntityId,
      'type': type,
      'ratio': ratio,
      'fk_field_id': fkFieldId,
      'description': description,
    };
  }
}

class DbModelSpec {
  const DbModelSpec({
    required this.topologyComponentId,
    required this.databaseId,
    required this.entities,
    required this.relationships,
    required this.baseUserCount,
  });

  final String topologyComponentId;
  final String databaseId;
  final List<EntityModel> entities;
  final List<RelationshipModel> relationships;
  final int baseUserCount;

  factory DbModelSpec.fromJson(Map<String, dynamic> json) {
    return DbModelSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      databaseId: json['database_id'] as String? ?? 'postgresql',
      entities: (json['entities'] as List<dynamic>? ?? [])
          .map((item) => EntityModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      relationships: (json['relationships'] as List<dynamic>? ?? [])
          .map(
            (item) => RelationshipModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      baseUserCount: json['base_user_count'] as int? ?? 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'database_id': databaseId,
      'entities': entities.map((entity) => entity.toJson()).toList(),
      'relationships': relationships.map((item) => item.toJson()).toList(),
      'base_user_count': baseUserCount,
    };
  }

  DbModelSpec copyWith({
    String? databaseId,
    List<EntityModel>? entities,
    List<RelationshipModel>? relationships,
    int? baseUserCount,
  }) {
    return DbModelSpec(
      topologyComponentId: topologyComponentId,
      databaseId: databaseId ?? this.databaseId,
      entities: entities ?? this.entities,
      relationships: relationships ?? this.relationships,
      baseUserCount: baseUserCount ?? this.baseUserCount,
    );
  }
}

class EntityStorageProjection {
  const EntityStorageProjection({
    required this.entityId,
    required this.entityName,
    required this.recordCount,
    required this.avgRecordSizeBytes,
    required this.dataSizeBytes,
    required this.indexOverheadBytes,
    required this.totalSizeBytes,
  });

  final String entityId;
  final String entityName;
  final int recordCount;
  final int avgRecordSizeBytes;
  final int dataSizeBytes;
  final int indexOverheadBytes;
  final int totalSizeBytes;

  factory EntityStorageProjection.fromJson(Map<String, dynamic> json) {
    return EntityStorageProjection(
      entityId: json['entity_id'] as String? ?? '',
      entityName: json['entity_name'] as String? ?? '',
      recordCount: json['record_count'] as int? ?? 0,
      avgRecordSizeBytes: json['avg_record_size_bytes'] as int? ?? 0,
      dataSizeBytes: json['data_size_bytes'] as int? ?? 0,
      indexOverheadBytes: json['index_overhead_bytes'] as int? ?? 0,
      totalSizeBytes: json['total_size_bytes'] as int? ?? 0,
    );
  }
}

class DbStorageProjection {
  const DbStorageProjection({
    required this.topologyComponentId,
    required this.databaseId,
    required this.perEntity,
    required this.totalDataBytes,
    required this.totalIndexBytes,
    required this.walJournalBytes,
    required this.totalStorageBytes,
    required this.totalRecords,
  });

  final String topologyComponentId;
  final String databaseId;
  final List<EntityStorageProjection> perEntity;
  final int totalDataBytes;
  final int totalIndexBytes;
  final int walJournalBytes;
  final int totalStorageBytes;
  final int totalRecords;

  factory DbStorageProjection.fromJson(Map<String, dynamic> json) {
    return DbStorageProjection(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      databaseId: json['database_id'] as String? ?? 'postgresql',
      perEntity: (json['per_entity'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                EntityStorageProjection.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalDataBytes: json['total_data_bytes'] as int? ?? 0,
      totalIndexBytes: json['total_index_bytes'] as int? ?? 0,
      walJournalBytes: json['wal_journal_bytes'] as int? ?? 0,
      totalStorageBytes: json['total_storage_bytes'] as int? ?? 0,
      totalRecords: json['total_records'] as int? ?? 0,
    );
  }
}

class K8sContainerPort {
  const K8sContainerPort({
    required this.name,
    required this.containerPort,
    required this.protocol,
  });

  final String name;
  final int containerPort;
  final String protocol;

  factory K8sContainerPort.fromJson(Map<String, dynamic> json) {
    return K8sContainerPort(
      name: json['name'] as String? ?? '',
      containerPort: json['container_port'] as int? ?? 8080,
      protocol: json['protocol'] as String? ?? 'TCP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'container_port': containerPort,
      'protocol': protocol,
    };
  }
}

class K8sContainerModel {
  const K8sContainerModel({
    required this.name,
    required this.image,
    required this.tag,
    required this.ports,
  });

  final String name;
  final String image;
  final String tag;
  final List<K8sContainerPort> ports;

  factory K8sContainerModel.fromJson(Map<String, dynamic> json) {
    return K8sContainerModel(
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      tag: json['tag'] as String? ?? 'latest',
      ports: (json['ports'] as List<dynamic>? ?? [])
          .map(
            (item) => K8sContainerPort.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': image,
      'tag': tag,
      'ports': ports.map((item) => item.toJson()).toList(),
    };
  }
}

class K8sClusterSpec {
  const K8sClusterSpec({
    required this.topologyComponentId,
    required this.namespace,
    required this.replicas,
    required this.serviceType,
    required this.servicePort,
    required this.targetPort,
    required this.hpaEnabled,
    required this.minReplicas,
    required this.maxReplicas,
    required this.targetCpuUtilization,
    required this.containers,
  });

  final String topologyComponentId;
  final String namespace;
  final int replicas;
  final String serviceType;
  final int servicePort;
  final int targetPort;
  final bool hpaEnabled;
  final int minReplicas;
  final int maxReplicas;
  final int targetCpuUtilization;
  final List<K8sContainerModel> containers;

  factory K8sClusterSpec.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>? ?? const {};
    final hpa = json['hpa'] as Map<String, dynamic>? ?? const {};
    return K8sClusterSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      namespace: json['namespace'] as String? ?? 'default',
      replicas: json['replicas'] as int? ?? 1,
      serviceType: service['type'] as String? ?? 'ClusterIP',
      servicePort: service['port'] as int? ?? 80,
      targetPort: service['target_port'] as int? ?? 8080,
      hpaEnabled: hpa['enabled'] as bool? ?? false,
      minReplicas: hpa['min_replicas'] as int? ?? 1,
      maxReplicas: hpa['max_replicas'] as int? ?? 10,
      targetCpuUtilization: hpa['target_cpu_utilization'] as int? ?? 70,
      containers: (json['containers'] as List<dynamic>? ?? [])
          .map(
            (item) => K8sContainerModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'namespace': namespace,
      'replicas': replicas,
      'containers': containers.map((item) => item.toJson()).toList(),
      'service': {
        'type': serviceType,
        'port': servicePort,
        'target_port': targetPort,
      },
      'hpa': {
        'enabled': hpaEnabled,
        'min_replicas': minReplicas,
        'max_replicas': maxReplicas,
        'target_cpu_utilization': targetCpuUtilization,
      },
    };
  }

  K8sClusterSpec copyWith({
    String? namespace,
    int? replicas,
    String? serviceType,
    int? servicePort,
    int? targetPort,
    bool? hpaEnabled,
    int? minReplicas,
    int? maxReplicas,
    int? targetCpuUtilization,
    List<K8sContainerModel>? containers,
  }) {
    return K8sClusterSpec(
      topologyComponentId: topologyComponentId,
      namespace: namespace ?? this.namespace,
      replicas: replicas ?? this.replicas,
      serviceType: serviceType ?? this.serviceType,
      servicePort: servicePort ?? this.servicePort,
      targetPort: targetPort ?? this.targetPort,
      hpaEnabled: hpaEnabled ?? this.hpaEnabled,
      minReplicas: minReplicas ?? this.minReplicas,
      maxReplicas: maxReplicas ?? this.maxReplicas,
      targetCpuUtilization: targetCpuUtilization ?? this.targetCpuUtilization,
      containers: containers ?? this.containers,
    );
  }
}

class DockerPortMapping {
  const DockerPortMapping({
    required this.hostPort,
    required this.containerPort,
    required this.protocol,
  });

  final int hostPort;
  final int containerPort;
  final String protocol;

  factory DockerPortMapping.fromJson(Map<String, dynamic> json) {
    return DockerPortMapping(
      hostPort: json['host_port'] as int? ?? 8080,
      containerPort: json['container_port'] as int? ?? 8080,
      protocol: json['protocol'] as String? ?? 'TCP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host_port': hostPort,
      'container_port': containerPort,
      'protocol': protocol,
    };
  }
}

class DockerContainerSpec {
  const DockerContainerSpec({
    required this.topologyComponentId,
    required this.containerName,
    required this.image,
    required this.tag,
    required this.network,
    required this.restartPolicy,
    required this.ports,
  });

  final String topologyComponentId;
  final String containerName;
  final String image;
  final String tag;
  final String network;
  final String restartPolicy;
  final List<DockerPortMapping> ports;

  factory DockerContainerSpec.fromJson(Map<String, dynamic> json) {
    return DockerContainerSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      containerName: json['container_name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      tag: json['tag'] as String? ?? 'latest',
      network: json['network'] as String? ?? 'bridge',
      restartPolicy: json['restart_policy'] as String? ?? 'unless-stopped',
      ports: (json['ports'] as List<dynamic>? ?? [])
          .map(
            (item) => DockerPortMapping.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'container_name': containerName,
      'image': image,
      'tag': tag,
      'network': network,
      'restart_policy': restartPolicy,
      'ports': ports.map((item) => item.toJson()).toList(),
    };
  }

  DockerContainerSpec copyWith({
    String? containerName,
    String? image,
    String? tag,
    String? network,
    String? restartPolicy,
    List<DockerPortMapping>? ports,
  }) {
    return DockerContainerSpec(
      topologyComponentId: topologyComponentId,
      containerName: containerName ?? this.containerName,
      image: image ?? this.image,
      tag: tag ?? this.tag,
      network: network ?? this.network,
      restartPolicy: restartPolicy ?? this.restartPolicy,
      ports: ports ?? this.ports,
    );
  }
}

// --- New Spec Types ---

class GatewayRoute {
  const GatewayRoute({
    required this.pathPattern,
    required this.targetComponentId,
    required this.methods,
    this.rateLimit,
  });

  final String pathPattern;
  final String targetComponentId;
  final List<String> methods;
  final int? rateLimit;

  factory GatewayRoute.fromJson(Map<String, dynamic> json) {
    return GatewayRoute(
      pathPattern: json['path_pattern'] as String? ?? '',
      targetComponentId: json['target_component_id'] as String? ?? '',
      methods: (json['methods'] as List<dynamic>? ?? ['GET'])
          .map((item) => item.toString())
          .toList(),
      rateLimit: json['rate_limit'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path_pattern': pathPattern,
      'target_component_id': targetComponentId,
      'methods': methods,
      'rate_limit': rateLimit,
    };
  }
}

class APIGatewaySpec {
  const APIGatewaySpec({
    required this.topologyComponentId,
    required this.rateLimitEnabled,
    required this.rateLimitRps,
    required this.rateLimitBurst,
    required this.rateLimitWindowSeconds,
    required this.authType,
    required this.corsEnabled,
    required this.requestLogging,
    required this.routes,
    required this.estimatedRps,
  });

  final String topologyComponentId;
  final bool rateLimitEnabled;
  final int rateLimitRps;
  final int rateLimitBurst;
  final int rateLimitWindowSeconds;
  final String authType;
  final bool corsEnabled;
  final bool requestLogging;
  final List<GatewayRoute> routes;
  final double estimatedRps;

  factory APIGatewaySpec.fromJson(Map<String, dynamic> json) {
    final rateLimit = json['rate_limit'] as Map<String, dynamic>? ?? const {};
    return APIGatewaySpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      rateLimitEnabled: rateLimit['enabled'] as bool? ?? true,
      rateLimitRps: rateLimit['rps'] as int? ?? 1000,
      rateLimitBurst: rateLimit['burst'] as int? ?? 100,
      rateLimitWindowSeconds: rateLimit['window_seconds'] as int? ?? 60,
      authType: json['auth_type'] as String? ?? 'jwt',
      corsEnabled: json['cors_enabled'] as bool? ?? true,
      requestLogging: json['request_logging'] as bool? ?? true,
      routes: (json['routes'] as List<dynamic>? ?? [])
          .map((item) => GatewayRoute.fromJson(item as Map<String, dynamic>))
          .toList(),
      estimatedRps: (json['estimated_rps'] as num?)?.toDouble() ?? 500,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'rate_limit': {
        'enabled': rateLimitEnabled,
        'rps': rateLimitRps,
        'burst': rateLimitBurst,
        'window_seconds': rateLimitWindowSeconds,
      },
      'auth_type': authType,
      'cors_enabled': corsEnabled,
      'request_logging': requestLogging,
      'routes': routes.map((item) => item.toJson()).toList(),
      'estimated_rps': estimatedRps,
    };
  }

  APIGatewaySpec copyWith({
    bool? rateLimitEnabled,
    int? rateLimitRps,
    int? rateLimitBurst,
    int? rateLimitWindowSeconds,
    String? authType,
    bool? corsEnabled,
    bool? requestLogging,
    List<GatewayRoute>? routes,
    double? estimatedRps,
  }) {
    return APIGatewaySpec(
      topologyComponentId: topologyComponentId,
      rateLimitEnabled: rateLimitEnabled ?? this.rateLimitEnabled,
      rateLimitRps: rateLimitRps ?? this.rateLimitRps,
      rateLimitBurst: rateLimitBurst ?? this.rateLimitBurst,
      rateLimitWindowSeconds:
          rateLimitWindowSeconds ?? this.rateLimitWindowSeconds,
      authType: authType ?? this.authType,
      corsEnabled: corsEnabled ?? this.corsEnabled,
      requestLogging: requestLogging ?? this.requestLogging,
      routes: routes ?? this.routes,
      estimatedRps: estimatedRps ?? this.estimatedRps,
    );
  }
}

class CronJobSpec {
  const CronJobSpec({
    required this.topologyComponentId,
    required this.schedule,
    required this.command,
    required this.targetServiceId,
    required this.targetEndpoint,
    required this.timeoutSeconds,
    required this.maxRetries,
    required this.backoffMultiplier,
    required this.estimatedDurationSeconds,
  });

  final String topologyComponentId;
  final String schedule;
  final String command;
  final String targetServiceId;
  final String targetEndpoint;
  final int timeoutSeconds;
  final int maxRetries;
  final double backoffMultiplier;
  final int estimatedDurationSeconds;

  factory CronJobSpec.fromJson(Map<String, dynamic> json) {
    final retry = json['retry_policy'] as Map<String, dynamic>? ?? const {};
    return CronJobSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      schedule: json['schedule'] as String? ?? '0 */6 * * *',
      command: json['command'] as String? ?? '',
      targetServiceId: json['target_service_id'] as String? ?? '',
      targetEndpoint: json['target_endpoint'] as String? ?? '',
      timeoutSeconds: json['timeout_seconds'] as int? ?? 300,
      maxRetries: retry['max_retries'] as int? ?? 3,
      backoffMultiplier:
          (retry['backoff_multiplier'] as num?)?.toDouble() ?? 2.0,
      estimatedDurationSeconds:
          json['estimated_duration_seconds'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'schedule': schedule,
      'command': command,
      'target_service_id': targetServiceId,
      'target_endpoint': targetEndpoint,
      'timeout_seconds': timeoutSeconds,
      'retry_policy': {
        'max_retries': maxRetries,
        'backoff_multiplier': backoffMultiplier,
      },
      'estimated_duration_seconds': estimatedDurationSeconds,
    };
  }

  CronJobSpec copyWith({
    String? schedule,
    String? command,
    String? targetServiceId,
    String? targetEndpoint,
    int? timeoutSeconds,
    int? maxRetries,
    double? backoffMultiplier,
    int? estimatedDurationSeconds,
  }) {
    return CronJobSpec(
      topologyComponentId: topologyComponentId,
      schedule: schedule ?? this.schedule,
      command: command ?? this.command,
      targetServiceId: targetServiceId ?? this.targetServiceId,
      targetEndpoint: targetEndpoint ?? this.targetEndpoint,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxRetries: maxRetries ?? this.maxRetries,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      estimatedDurationSeconds:
          estimatedDurationSeconds ?? this.estimatedDurationSeconds,
    );
  }
}

class ObjectStorageSpec {
  const ObjectStorageSpec({
    required this.topologyComponentId,
    required this.provider,
    required this.estimatedStorageGb,
    required this.estimatedRequestsMonth,
    required this.estimatedEgressGbMonth,
    required this.accessPolicy,
    required this.versioningEnabled,
    required this.lifecycleRules,
  });

  final String topologyComponentId;
  final String provider;
  final double estimatedStorageGb;
  final double estimatedRequestsMonth;
  final double estimatedEgressGbMonth;
  final String accessPolicy;
  final bool versioningEnabled;
  final List<String> lifecycleRules;

  factory ObjectStorageSpec.fromJson(Map<String, dynamic> json) {
    return ObjectStorageSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      provider: json['provider'] as String? ?? 's3',
      estimatedStorageGb:
          (json['estimated_storage_gb'] as num?)?.toDouble() ?? 100,
      estimatedRequestsMonth:
          (json['estimated_requests_month'] as num?)?.toDouble() ?? 1000000,
      estimatedEgressGbMonth:
          (json['estimated_egress_gb_month'] as num?)?.toDouble() ?? 50,
      accessPolicy: json['access_policy'] as String? ?? 'private',
      versioningEnabled: json['versioning_enabled'] as bool? ?? false,
      lifecycleRules: (json['lifecycle_rules'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'provider': provider,
      'estimated_storage_gb': estimatedStorageGb,
      'estimated_requests_month': estimatedRequestsMonth,
      'estimated_egress_gb_month': estimatedEgressGbMonth,
      'access_policy': accessPolicy,
      'versioning_enabled': versioningEnabled,
      'lifecycle_rules': lifecycleRules,
    };
  }

  ObjectStorageSpec copyWith({
    String? provider,
    double? estimatedStorageGb,
    double? estimatedRequestsMonth,
    double? estimatedEgressGbMonth,
    String? accessPolicy,
    bool? versioningEnabled,
    List<String>? lifecycleRules,
  }) {
    return ObjectStorageSpec(
      topologyComponentId: topologyComponentId,
      provider: provider ?? this.provider,
      estimatedStorageGb: estimatedStorageGb ?? this.estimatedStorageGb,
      estimatedRequestsMonth:
          estimatedRequestsMonth ?? this.estimatedRequestsMonth,
      estimatedEgressGbMonth:
          estimatedEgressGbMonth ?? this.estimatedEgressGbMonth,
      accessPolicy: accessPolicy ?? this.accessPolicy,
      versioningEnabled: versioningEnabled ?? this.versioningEnabled,
      lifecycleRules: lifecycleRules ?? this.lifecycleRules,
    );
  }
}

class ServiceMeshSpec {
  const ServiceMeshSpec({
    required this.topologyComponentId,
    required this.meshType,
    required this.mtlsEnabled,
    required this.circuitBreakerEnabled,
    required this.circuitBreakerThreshold,
    required this.circuitBreakerRecoveryMs,
    required this.circuitBreakerHalfOpenRequests,
    required this.retryEnabled,
    required this.retryMaxAttempts,
    required this.loadBalancingAlgorithm,
    required this.observabilityEnabled,
  });

  final String topologyComponentId;
  final String meshType;
  final bool mtlsEnabled;
  final bool circuitBreakerEnabled;
  final int circuitBreakerThreshold;
  final int circuitBreakerRecoveryMs;
  final int circuitBreakerHalfOpenRequests;
  final bool retryEnabled;
  final int retryMaxAttempts;
  final String loadBalancingAlgorithm;
  final bool observabilityEnabled;

  factory ServiceMeshSpec.fromJson(Map<String, dynamic> json) {
    final cb =
        json['circuit_breaker'] as Map<String, dynamic>? ?? const {};
    final retry = json['retry_policy'] as Map<String, dynamic>? ?? const {};
    return ServiceMeshSpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      meshType: json['mesh_type'] as String? ?? 'istio',
      mtlsEnabled: json['mtls_enabled'] as bool? ?? true,
      circuitBreakerEnabled: cb['enabled'] as bool? ?? true,
      circuitBreakerThreshold: cb['threshold'] as int? ?? 5,
      circuitBreakerRecoveryMs: cb['recovery_ms'] as int? ?? 30000,
      circuitBreakerHalfOpenRequests: cb['half_open_requests'] as int? ?? 3,
      retryEnabled: retry['enabled'] as bool? ?? true,
      retryMaxAttempts: retry['max_attempts'] as int? ?? 3,
      loadBalancingAlgorithm:
          json['load_balancing_algorithm'] as String? ?? 'round_robin',
      observabilityEnabled: json['observability_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'mesh_type': meshType,
      'mtls_enabled': mtlsEnabled,
      'circuit_breaker': {
        'enabled': circuitBreakerEnabled,
        'threshold': circuitBreakerThreshold,
        'recovery_ms': circuitBreakerRecoveryMs,
        'half_open_requests': circuitBreakerHalfOpenRequests,
      },
      'retry_policy': {
        'enabled': retryEnabled,
        'max_attempts': retryMaxAttempts,
      },
      'load_balancing_algorithm': loadBalancingAlgorithm,
      'observability_enabled': observabilityEnabled,
    };
  }

  ServiceMeshSpec copyWith({
    String? meshType,
    bool? mtlsEnabled,
    bool? circuitBreakerEnabled,
    int? circuitBreakerThreshold,
    int? circuitBreakerRecoveryMs,
    int? circuitBreakerHalfOpenRequests,
    bool? retryEnabled,
    int? retryMaxAttempts,
    String? loadBalancingAlgorithm,
    bool? observabilityEnabled,
  }) {
    return ServiceMeshSpec(
      topologyComponentId: topologyComponentId,
      meshType: meshType ?? this.meshType,
      mtlsEnabled: mtlsEnabled ?? this.mtlsEnabled,
      circuitBreakerEnabled:
          circuitBreakerEnabled ?? this.circuitBreakerEnabled,
      circuitBreakerThreshold:
          circuitBreakerThreshold ?? this.circuitBreakerThreshold,
      circuitBreakerRecoveryMs:
          circuitBreakerRecoveryMs ?? this.circuitBreakerRecoveryMs,
      circuitBreakerHalfOpenRequests:
          circuitBreakerHalfOpenRequests ?? this.circuitBreakerHalfOpenRequests,
      retryEnabled: retryEnabled ?? this.retryEnabled,
      retryMaxAttempts: retryMaxAttempts ?? this.retryMaxAttempts,
      loadBalancingAlgorithm:
          loadBalancingAlgorithm ?? this.loadBalancingAlgorithm,
      observabilityEnabled: observabilityEnabled ?? this.observabilityEnabled,
    );
  }
}

class ThirdPartyAPISpec {
  const ThirdPartyAPISpec({
    required this.topologyComponentId,
    required this.serviceName,
    required this.baseUrl,
    required this.slaUptimePercent,
    required this.expectedLatencyMs,
    required this.fallbackBehavior,
    required this.estimatedCallsMonth,
    required this.costModel,
    required this.costPerCall,
    required this.subscriptionCostMonthly,
  });

  final String topologyComponentId;
  final String serviceName;
  final String baseUrl;
  final double slaUptimePercent;
  final double expectedLatencyMs;
  final String fallbackBehavior;
  final int estimatedCallsMonth;
  final String costModel;
  final double costPerCall;
  final double subscriptionCostMonthly;

  factory ThirdPartyAPISpec.fromJson(Map<String, dynamic> json) {
    return ThirdPartyAPISpec(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      baseUrl: json['base_url'] as String? ?? '',
      slaUptimePercent:
          (json['sla_uptime_percent'] as num?)?.toDouble() ?? 99.9,
      expectedLatencyMs:
          (json['expected_latency_ms'] as num?)?.toDouble() ?? 100,
      fallbackBehavior:
          json['fallback_behavior'] as String? ?? 'circuit_breaker',
      estimatedCallsMonth: json['estimated_calls_month'] as int? ?? 10000,
      costModel: json['cost_model'] as String? ?? 'per_call',
      costPerCall: (json['cost_per_call'] as num?)?.toDouble() ?? 0.001,
      subscriptionCostMonthly:
          (json['subscription_cost_monthly'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'service_name': serviceName,
      'base_url': baseUrl,
      'sla_uptime_percent': slaUptimePercent,
      'expected_latency_ms': expectedLatencyMs,
      'fallback_behavior': fallbackBehavior,
      'estimated_calls_month': estimatedCallsMonth,
      'cost_model': costModel,
      'cost_per_call': costPerCall,
      'subscription_cost_monthly': subscriptionCostMonthly,
    };
  }

  ThirdPartyAPISpec copyWith({
    String? serviceName,
    String? baseUrl,
    double? slaUptimePercent,
    double? expectedLatencyMs,
    String? fallbackBehavior,
    int? estimatedCallsMonth,
    String? costModel,
    double? costPerCall,
    double? subscriptionCostMonthly,
  }) {
    return ThirdPartyAPISpec(
      topologyComponentId: topologyComponentId,
      serviceName: serviceName ?? this.serviceName,
      baseUrl: baseUrl ?? this.baseUrl,
      slaUptimePercent: slaUptimePercent ?? this.slaUptimePercent,
      expectedLatencyMs: expectedLatencyMs ?? this.expectedLatencyMs,
      fallbackBehavior: fallbackBehavior ?? this.fallbackBehavior,
      estimatedCallsMonth: estimatedCallsMonth ?? this.estimatedCallsMonth,
      costModel: costModel ?? this.costModel,
      costPerCall: costPerCall ?? this.costPerCall,
      subscriptionCostMonthly:
          subscriptionCostMonthly ?? this.subscriptionCostMonthly,
    );
  }
}
