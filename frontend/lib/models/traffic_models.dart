class EntryPointTraffic {
  const EntryPointTraffic({
    required this.endpointId,
    required this.requestsPerSecond,
  });

  final String endpointId;
  final double requestsPerSecond;

  factory EntryPointTraffic.fromJson(Map<String, dynamic> json) {
    return EntryPointTraffic(
      endpointId: json['endpoint_id'] as String? ?? '',
      requestsPerSecond:
          (json['requests_per_second'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endpoint_id': endpointId,
      'requests_per_second': requestsPerSecond,
    };
  }

  EntryPointTraffic copyWith({double? requestsPerSecond}) {
    return EntryPointTraffic(
      endpointId: endpointId,
      requestsPerSecond: requestsPerSecond ?? this.requestsPerSecond,
    );
  }
}

class TrafficInput {
  const TrafficInput({required this.entryPoints});

  final List<EntryPointTraffic> entryPoints;

  factory TrafficInput.fromJson(Map<String, dynamic> json) {
    return TrafficInput(
      entryPoints: (json['entry_points'] as List<dynamic>? ?? [])
          .map(
            (item) => EntryPointTraffic.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entry_points': entryPoints.map((item) => item.toJson()).toList(),
    };
  }
}

class TrafficSource {
  const TrafficSource({
    required this.sourceEndpointId,
    required this.sourceEndpointPath,
    required this.requestsPerSecond,
    required this.multiplier,
  });

  final String sourceEndpointId;
  final String sourceEndpointPath;
  final double requestsPerSecond;
  final double multiplier;

  factory TrafficSource.fromJson(Map<String, dynamic> json) {
    return TrafficSource(
      sourceEndpointId: json['source_endpoint_id'] as String? ?? '',
      sourceEndpointPath: json['source_endpoint_path'] as String? ?? '',
      requestsPerSecond:
          (json['requests_per_second'] as num?)?.toDouble() ?? 0,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_endpoint_id': sourceEndpointId,
      'source_endpoint_path': sourceEndpointPath,
      'requests_per_second': requestsPerSecond,
      'multiplier': multiplier,
    };
  }
}

class ComponentTrafficLoad {
  const ComponentTrafficLoad({
    required this.componentId,
    required this.componentName,
    required this.componentType,
    required this.totalRequestsPerSecond,
    required this.breakdown,
    required this.capacityStatus,
    this.capacityReason,
  });

  final String componentId;
  final String componentName;
  final String componentType;
  final double totalRequestsPerSecond;
  final List<TrafficSource> breakdown;
  final String capacityStatus;
  final String? capacityReason;

  bool get isBottleneck => capacityStatus != 'OK';

  factory ComponentTrafficLoad.fromJson(Map<String, dynamic> json) {
    return ComponentTrafficLoad(
      componentId: json['component_id'] as String? ?? '',
      componentName: json['component_name'] as String? ?? '',
      componentType: json['component_type'] as String? ?? '',
      totalRequestsPerSecond:
          (json['total_requests_per_second'] as num?)?.toDouble() ?? 0,
      breakdown: (json['breakdown'] as List<dynamic>? ?? [])
          .map(
            (item) => TrafficSource.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      capacityStatus: json['capacity_status'] as String? ?? 'OK',
      capacityReason: json['capacity_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'component_id': componentId,
      'component_name': componentName,
      'component_type': componentType,
      'total_requests_per_second': totalRequestsPerSecond,
      'breakdown': breakdown.map((item) => item.toJson()).toList(),
      'capacity_status': capacityStatus,
      'capacity_reason': capacityReason,
    };
  }
}

class TrafficSimulationResult {
  const TrafficSimulationResult({
    required this.topologyId,
    required this.entryPointTotalQps,
    required this.perComponentLoad,
    required this.bottleneckComponents,
    required this.estimatedMonthlyCostAtTraffic,
    this.estimatedTotalLatencyMs,
  });

  final String topologyId;
  final double entryPointTotalQps;
  final List<ComponentTrafficLoad> perComponentLoad;
  final List<String> bottleneckComponents;
  final double estimatedMonthlyCostAtTraffic;
  final double? estimatedTotalLatencyMs;

  factory TrafficSimulationResult.fromJson(Map<String, dynamic> json) {
    return TrafficSimulationResult(
      topologyId: json['topology_id'] as String? ?? '',
      entryPointTotalQps:
          (json['entry_point_total_qps'] as num?)?.toDouble() ?? 0,
      perComponentLoad: (json['per_component_load'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ComponentTrafficLoad.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      bottleneckComponents:
          (json['bottleneck_components'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .toList(),
      estimatedMonthlyCostAtTraffic:
          (json['estimated_monthly_cost_at_traffic'] as num?)?.toDouble() ?? 0,
      estimatedTotalLatencyMs:
          (json['estimated_total_latency_ms'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topology_id': topologyId,
      'entry_point_total_qps': entryPointTotalQps,
      'per_component_load':
          perComponentLoad.map((item) => item.toJson()).toList(),
      'bottleneck_components': bottleneckComponents,
      'estimated_monthly_cost_at_traffic': estimatedMonthlyCostAtTraffic,
      'estimated_total_latency_ms': estimatedTotalLatencyMs,
    };
  }
}
