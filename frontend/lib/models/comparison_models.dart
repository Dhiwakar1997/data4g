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
    );
  }
}
