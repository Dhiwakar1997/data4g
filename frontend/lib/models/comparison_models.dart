class MetricComparison {
  const MetricComparison({
    required this.metricName,
    required this.sourceValue,
    required this.targetValue,
    required this.unit,
    this.deltaPercent,
  });

  final String metricName;
  final double sourceValue;
  final double targetValue;
  final String unit;
  final double? deltaPercent;

  double get delta => targetValue - sourceValue;
  bool get isImprovement => delta < 0;

  factory MetricComparison.fromJson(Map<String, dynamic> json) {
    return MetricComparison(
      metricName: json['metric_name'] as String? ?? '',
      sourceValue: (json['source_value'] as num?)?.toDouble() ?? 0,
      targetValue: (json['target_value'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? '',
      deltaPercent: (json['delta_percent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metric_name': metricName,
      'source_value': sourceValue,
      'target_value': targetValue,
      'unit': unit,
      'delta_percent': deltaPercent,
    };
  }
}

class ComponentDiff {
  const ComponentDiff({
    required this.componentName,
    required this.componentType,
    required this.status,
    required this.changes,
  });

  final String componentName;
  final String componentType;
  final String status;
  final List<String> changes;

  factory ComponentDiff.fromJson(Map<String, dynamic> json) {
    return ComponentDiff(
      componentName: json['component_name'] as String? ?? '',
      componentType: json['component_type'] as String? ?? '',
      status: json['status'] as String? ?? 'unchanged',
      changes: (json['changes'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class TopologyComparison {
  const TopologyComparison({
    required this.sourceProjectId,
    required this.sourceTopologyId,
    required this.sourceTopologyName,
    required this.targetProjectId,
    required this.targetTopologyId,
    required this.targetTopologyName,
    required this.componentDiffs,
    required this.addedComponents,
    required this.removedComponents,
    required this.modifiedComponents,
    required this.unchangedComponents,
    this.metricComparisons = const [],
  });

  final String sourceProjectId;
  final String sourceTopologyId;
  final String sourceTopologyName;
  final String targetProjectId;
  final String targetTopologyId;
  final String targetTopologyName;
  final List<ComponentDiff> componentDiffs;
  final int addedComponents;
  final int removedComponents;
  final int modifiedComponents;
  final int unchangedComponents;
  final List<MetricComparison> metricComparisons;

  factory TopologyComparison.fromJson(Map<String, dynamic> json) {
    return TopologyComparison(
      sourceProjectId: json['source_project_id'] as String? ?? '',
      sourceTopologyId: json['source_topology_id'] as String? ?? '',
      sourceTopologyName: json['source_topology_name'] as String? ?? '',
      targetProjectId: json['target_project_id'] as String? ?? '',
      targetTopologyId: json['target_topology_id'] as String? ?? '',
      targetTopologyName: json['target_topology_name'] as String? ?? '',
      componentDiffs: (json['component_diffs'] as List<dynamic>? ?? [])
          .map((item) => ComponentDiff.fromJson(item as Map<String, dynamic>))
          .toList(),
      addedComponents: json['added_components'] as int? ?? 0,
      removedComponents: json['removed_components'] as int? ?? 0,
      modifiedComponents: json['modified_components'] as int? ?? 0,
      unchangedComponents: json['unchanged_components'] as int? ?? 0,
      metricComparisons: (json['metric_comparisons'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                MetricComparison.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
