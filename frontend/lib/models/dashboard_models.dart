import 'topology_models.dart';

class ComponentCostSummary {
  const ComponentCostSummary({
    required this.topologyComponentId,
    required this.componentName,
    required this.componentType,
    required this.totalMonthly,
    required this.details,
  });

  final String topologyComponentId;
  final String componentName;
  final ComponentType componentType;
  final double totalMonthly;
  final Map<String, double> details;

  factory ComponentCostSummary.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'] as Map<String, dynamic>? ?? {};
    return ComponentCostSummary(
      topologyComponentId: json['topology_component_id'] as String? ?? '',
      componentName: json['component_name'] as String? ?? '',
      componentType: ComponentTypeX.fromValue(
        json['component_type'] as String?,
      ),
      totalMonthly: (json['total_monthly'] as num?)?.toDouble() ?? 0,
      details: rawDetails.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }
}

class CategoryCostSummary {
  const CategoryCostSummary({
    required this.category,
    required this.totalMonthly,
    required this.percentage,
  });

  final String category;
  final double totalMonthly;
  final double percentage;

  factory CategoryCostSummary.fromJson(Map<String, dynamic> json) {
    return CategoryCostSummary(
      category: json['category'] as String? ?? '',
      totalMonthly: (json['total_monthly'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GrowthProjection {
  const GrowthProjection({
    required this.userCount,
    required this.totalMonthly,
    required this.perComponent,
  });

  final int userCount;
  final double totalMonthly;
  final List<ComponentCostSummary> perComponent;

  factory GrowthProjection.fromJson(Map<String, dynamic> json) {
    return GrowthProjection(
      userCount: json['user_count'] as int? ?? 0,
      totalMonthly: (json['total_monthly'] as num?)?.toDouble() ?? 0,
      perComponent: (json['per_component'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ComponentCostSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class EntityCostDetail {
  const EntityCostDetail({
    required this.entityId,
    required this.entityName,
    required this.recordCount,
    required this.storageGb,
    required this.storageCostMonthly,
    required this.percentageOfDbCost,
  });

  final String entityId;
  final String entityName;
  final int recordCount;
  final double storageGb;
  final double storageCostMonthly;
  final double percentageOfDbCost;

  factory EntityCostDetail.fromJson(Map<String, dynamic> json) {
    return EntityCostDetail(
      entityId: json['entity_id'] as String? ?? '',
      entityName: json['entity_name'] as String? ?? '',
      recordCount: json['record_count'] as int? ?? 0,
      storageGb: (json['storage_gb'] as num?)?.toDouble() ?? 0,
      storageCostMonthly:
          (json['storage_cost_monthly'] as num?)?.toDouble() ?? 0,
      percentageOfDbCost:
          (json['percentage_of_db_cost'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OptimizationHint {
  const OptimizationHint({
    required this.category,
    required this.message,
    required this.estimatedSavingsMonthly,
    required this.confidence,
  });

  final String category;
  final String message;
  final double estimatedSavingsMonthly;
  final double confidence;

  factory OptimizationHint.fromJson(Map<String, dynamic> json) {
    return OptimizationHint(
      category: json['category'] as String? ?? '',
      message: json['message'] as String? ?? '',
      estimatedSavingsMonthly:
          (json['estimated_savings_monthly'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ConsolidatedDashboard {
  const ConsolidatedDashboard({
    required this.projectId,
    required this.projectName,
    required this.deploymentMode,
    required this.baseUserCount,
    required this.totalMonthlyCost,
    required this.perComponent,
    required this.perCategory,
    required this.perEntityStorage,
    required this.growthProjections,
    required this.optimizationHints,
    this.comparisonDatabase,
    this.comparisonTotalMonthly,
    this.comparisonDelta,
  });

  final String projectId;
  final String projectName;
  final String deploymentMode;
  final int baseUserCount;
  final double totalMonthlyCost;
  final List<ComponentCostSummary> perComponent;
  final List<CategoryCostSummary> perCategory;
  final List<EntityCostDetail> perEntityStorage;
  final List<GrowthProjection> growthProjections;
  final List<OptimizationHint> optimizationHints;
  final String? comparisonDatabase;
  final double? comparisonTotalMonthly;
  final double? comparisonDelta;

  factory ConsolidatedDashboard.fromJson(Map<String, dynamic> json) {
    return ConsolidatedDashboard(
      projectId: json['project_id'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      deploymentMode: json['deployment_mode'] as String? ?? 'multi_tier',
      baseUserCount: json['base_user_count'] as int? ?? 1000,
      totalMonthlyCost: (json['total_monthly_cost'] as num?)?.toDouble() ?? 0,
      perComponent: (json['per_component'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ComponentCostSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      perCategory: (json['per_category'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                CategoryCostSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      perEntityStorage: (json['per_entity_storage'] as List<dynamic>? ?? [])
          .map(
            (item) => EntityCostDetail.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      growthProjections: (json['growth_projections'] as List<dynamic>? ?? [])
          .map(
            (item) => GrowthProjection.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      optimizationHints: (json['optimization_hints'] as List<dynamic>? ?? [])
          .map(
            (item) => OptimizationHint.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      comparisonDatabase: json['comparison_database'] as String?,
      comparisonTotalMonthly: (json['comparison_total_monthly'] as num?)
          ?.toDouble(),
      comparisonDelta: (json['comparison_delta'] as num?)?.toDouble(),
    );
  }

  ConsolidatedDashboard copyWith({
    String? comparisonDatabase,
    double? comparisonTotalMonthly,
    double? comparisonDelta,
  }) {
    return ConsolidatedDashboard(
      projectId: projectId,
      projectName: projectName,
      deploymentMode: deploymentMode,
      baseUserCount: baseUserCount,
      totalMonthlyCost: totalMonthlyCost,
      perComponent: perComponent,
      perCategory: perCategory,
      perEntityStorage: perEntityStorage,
      growthProjections: growthProjections,
      optimizationHints: optimizationHints,
      comparisonDatabase: comparisonDatabase ?? this.comparisonDatabase,
      comparisonTotalMonthly:
          comparisonTotalMonthly ?? this.comparisonTotalMonthly,
      comparisonDelta: comparisonDelta ?? this.comparisonDelta,
    );
  }
}
