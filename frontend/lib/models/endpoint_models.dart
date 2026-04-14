class DBCallMetadata {
  const DBCallMetadata({
    required this.queryType,
    required this.targetEntity,
    required this.isPaginated,
    this.estimatedRowsAffected,
  });

  final String queryType;
  final String targetEntity;
  final bool isPaginated;
  final String? estimatedRowsAffected;

  factory DBCallMetadata.fromJson(Map<String, dynamic> json) {
    return DBCallMetadata(
      queryType: json['query_type'] as String? ?? 'SELECT',
      targetEntity: json['target_entity'] as String? ?? '',
      isPaginated: json['is_paginated'] as bool? ?? false,
      estimatedRowsAffected: json['estimated_rows_affected'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query_type': queryType,
      'target_entity': targetEntity,
      'is_paginated': isPaginated,
      'estimated_rows_affected': estimatedRowsAffected,
    };
  }
}

class CacheCallMetadata {
  const CacheCallMetadata({
    required this.operation,
    required this.keyPattern,
    this.ttlSeconds,
  });

  final String operation;
  final String keyPattern;
  final int? ttlSeconds;

  factory CacheCallMetadata.fromJson(Map<String, dynamic> json) {
    return CacheCallMetadata(
      operation: json['operation'] as String? ?? 'GET',
      keyPattern: json['key_pattern'] as String? ?? '',
      ttlSeconds: json['ttl_seconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'key_pattern': keyPattern,
      'ttl_seconds': ttlSeconds,
    };
  }
}

class ServiceCallMetadata {
  const ServiceCallMetadata({
    required this.targetService,
    required this.targetEndpoint,
    required this.httpMethod,
    required this.isAsync,
  });

  final String targetService;
  final String targetEndpoint;
  final String httpMethod;
  final bool isAsync;

  factory ServiceCallMetadata.fromJson(Map<String, dynamic> json) {
    return ServiceCallMetadata(
      targetService: json['target_service'] as String? ?? '',
      targetEndpoint: json['target_endpoint'] as String? ?? '',
      httpMethod: json['http_method'] as String? ?? 'GET',
      isAsync: json['is_async'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target_service': targetService,
      'target_endpoint': targetEndpoint,
      'http_method': httpMethod,
      'is_async': isAsync,
    };
  }
}

class QueueInteraction {
  const QueueInteraction({
    required this.role,
    required this.queueName,
    this.messageType,
  });

  final String role;
  final String queueName;
  final String? messageType;

  factory QueueInteraction.fromJson(Map<String, dynamic> json) {
    return QueueInteraction(
      role: json['role'] as String? ?? 'producer',
      queueName: json['queue_name'] as String? ?? '',
      messageType: json['message_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'queue_name': queueName,
      'message_type': messageType,
    };
  }
}

class EndpointMetadata {
  const EndpointMetadata({
    required this.id,
    required this.path,
    required this.httpMethod,
    required this.handlerFunction,
    required this.sourceFile,
    required this.dbCalls,
    required this.cacheCalls,
    required this.serviceCalls,
    required this.queueInteractions,
    required this.riskScore,
    required this.riskFindings,
  });

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

  factory EndpointMetadata.fromJson(Map<String, dynamic> json) {
    return EndpointMetadata(
      id: json['id'] as String? ?? '',
      path: json['path'] as String? ?? '',
      httpMethod: json['http_method'] as String? ?? 'GET',
      handlerFunction: json['handler_function'] as String? ?? '',
      sourceFile: json['source_file'] as String? ?? '',
      dbCalls: (json['db_calls'] as List<dynamic>? ?? [])
          .map((item) => DBCallMetadata.fromJson(item as Map<String, dynamic>))
          .toList(),
      cacheCalls: (json['cache_calls'] as List<dynamic>? ?? [])
          .map(
            (item) => CacheCallMetadata.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      serviceCalls: (json['service_calls'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ServiceCallMetadata.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      queueInteractions: (json['queue_interactions'] as List<dynamic>? ?? [])
          .map(
            (item) => QueueInteraction.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0,
      riskFindings: (json['risk_findings'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'http_method': httpMethod,
      'handler_function': handlerFunction,
      'source_file': sourceFile,
      'db_calls': dbCalls.map((item) => item.toJson()).toList(),
      'cache_calls': cacheCalls.map((item) => item.toJson()).toList(),
      'service_calls': serviceCalls.map((item) => item.toJson()).toList(),
      'queue_interactions':
          queueInteractions.map((item) => item.toJson()).toList(),
      'risk_score': riskScore,
      'risk_findings': riskFindings,
    };
  }
}

class ServerEndpointRegistry {
  const ServerEndpointRegistry({
    required this.topologyComponentId,
    required this.endpoints,
    this.lastSyncedAt,
    this.syncVersion,
  });

  final String topologyComponentId;
  final List<EndpointMetadata> endpoints;
  final String? lastSyncedAt;
  final int? syncVersion;

  factory ServerEndpointRegistry.fromJson(Map<String, dynamic> json) {
    return ServerEndpointRegistry(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      endpoints: (json['endpoints'] as List<dynamic>? ?? [])
          .map(
            (item) => EndpointMetadata.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      lastSyncedAt: json['last_synced_at'] as String?,
      syncVersion: json['sync_version'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_component_id': topologyComponentId,
      'endpoints': endpoints.map((item) => item.toJson()).toList(),
      'last_synced_at': lastSyncedAt,
      'sync_version': syncVersion,
    };
  }
}
