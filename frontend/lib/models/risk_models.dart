import '../core/utils/formatting.dart';

enum RiskSeverity { critical, high, medium, low, info }

extension RiskSeverityX on RiskSeverity {
  String get value => switch (this) {
    RiskSeverity.critical => 'critical',
    RiskSeverity.high => 'high',
    RiskSeverity.medium => 'medium',
    RiskSeverity.low => 'low',
    RiskSeverity.info => 'info',
  };

  String get label => titleCase(value);

  static RiskSeverity fromValue(String? value) {
    return RiskSeverity.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RiskSeverity.info,
    );
  }
}

enum RiskType {
  nPlusOne,
  missingPagination,
  unboundedFetch,
  fullTableScan,
  missingIndex,
  inefficientJoin,
  raceCondition,
}

extension RiskTypeX on RiskType {
  String get value => switch (this) {
    RiskType.nPlusOne => 'n_plus_one',
    RiskType.missingPagination => 'missing_pagination',
    RiskType.unboundedFetch => 'unbounded_fetch',
    RiskType.fullTableScan => 'full_table_scan',
    RiskType.missingIndex => 'missing_index',
    RiskType.inefficientJoin => 'inefficient_join',
    RiskType.raceCondition => 'race_condition',
  };

  String get label => switch (this) {
    RiskType.nPlusOne => 'N+1 Query',
    RiskType.missingPagination => 'Missing Pagination',
    RiskType.unboundedFetch => 'Unbounded Fetch',
    RiskType.fullTableScan => 'Full Table Scan',
    RiskType.missingIndex => 'Missing Index',
    RiskType.inefficientJoin => 'Inefficient Join',
    RiskType.raceCondition => 'Race Condition',
  };

  static RiskType fromValue(String? value) {
    return RiskType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => RiskType.unboundedFetch,
    );
  }
}

class RiskFinding {
  const RiskFinding({
    required this.id,
    required this.endpointId,
    required this.endpointPath,
    required this.riskType,
    required this.severity,
    required this.message,
    required this.sourceFile,
    this.codeSnippet,
    required this.recommendation,
    required this.detectedAt,
  });

  final String id;
  final String endpointId;
  final String endpointPath;
  final RiskType riskType;
  final RiskSeverity severity;
  final String message;
  final String sourceFile;
  final String? codeSnippet;
  final String recommendation;
  final String detectedAt;

  factory RiskFinding.fromJson(Map<String, dynamic> json) {
    return RiskFinding(
      id: json['id'] as String? ?? '',
      endpointId: json['endpoint_id'] as String? ?? '',
      endpointPath: json['endpoint_path'] as String? ?? '',
      riskType: RiskTypeX.fromValue(json['risk_type'] as String?),
      severity: RiskSeverityX.fromValue(json['severity'] as String?),
      message: json['message'] as String? ?? '',
      sourceFile: json['source_file'] as String? ?? '',
      codeSnippet: json['code_snippet'] as String?,
      recommendation: json['recommendation'] as String? ?? '',
      detectedAt: json['detected_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint_id': endpointId,
      'endpoint_path': endpointPath,
      'risk_type': riskType.value,
      'severity': severity.value,
      'message': message,
      'source_file': sourceFile,
      'code_snippet': codeSnippet,
      'recommendation': recommendation,
      'detected_at': detectedAt,
    };
  }
}

class EndpointRiskSummary {
  const EndpointRiskSummary({
    required this.endpointId,
    required this.endpointPath,
    required this.httpMethod,
    required this.overallRiskScore,
    required this.findingCount,
    required this.criticalCount,
    required this.highCount,
    required this.mediumCount,
    required this.findings,
  });

  final String endpointId;
  final String endpointPath;
  final String httpMethod;
  final double overallRiskScore;
  final int findingCount;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final List<RiskFinding> findings;

  factory EndpointRiskSummary.fromJson(Map<String, dynamic> json) {
    return EndpointRiskSummary(
      endpointId: json['endpoint_id'] as String? ?? '',
      endpointPath: json['endpoint_path'] as String? ?? '',
      httpMethod: json['http_method'] as String? ?? 'GET',
      overallRiskScore:
          (json['overall_risk_score'] as num?)?.toDouble() ?? 0,
      findingCount: json['finding_count'] as int? ?? 0,
      criticalCount: json['critical_count'] as int? ?? 0,
      highCount: json['high_count'] as int? ?? 0,
      mediumCount: json['medium_count'] as int? ?? 0,
      findings: (json['findings'] as List<dynamic>? ?? [])
          .map((item) => RiskFinding.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endpoint_id': endpointId,
      'endpoint_path': endpointPath,
      'http_method': httpMethod,
      'overall_risk_score': overallRiskScore,
      'finding_count': findingCount,
      'critical_count': criticalCount,
      'high_count': highCount,
      'medium_count': mediumCount,
      'findings': findings.map((item) => item.toJson()).toList(),
    };
  }
}

class RiskDashboard {
  const RiskDashboard({
    required this.projectId,
    required this.topologyId,
    required this.totalEndpoints,
    required this.analyzedEndpoints,
    required this.overallRiskScore,
    required this.riskDistribution,
    required this.topRisks,
    required this.riskByType,
    this.lastAnalyzedAt,
  });

  final String projectId;
  final String topologyId;
  final int totalEndpoints;
  final int analyzedEndpoints;
  final double overallRiskScore;
  final Map<String, int> riskDistribution;
  final List<EndpointRiskSummary> topRisks;
  final Map<String, int> riskByType;
  final String? lastAnalyzedAt;

  factory RiskDashboard.fromJson(Map<String, dynamic> json) {
    final rawDistribution =
        json['risk_distribution'] as Map<String, dynamic>? ?? {};
    final rawByType = json['risk_by_type'] as Map<String, dynamic>? ?? {};
    return RiskDashboard(
      projectId: json['project_id'] as String? ?? '',
      topologyId: json['topology_id'] as String? ?? '',
      totalEndpoints: json['total_endpoints'] as int? ?? 0,
      analyzedEndpoints: json['analyzed_endpoints'] as int? ?? 0,
      overallRiskScore:
          (json['overall_risk_score'] as num?)?.toDouble() ?? 0,
      riskDistribution: rawDistribution.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      topRisks: (json['top_risks'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                EndpointRiskSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      riskByType: rawByType.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      lastAnalyzedAt: json['last_analyzed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'topology_id': topologyId,
      'total_endpoints': totalEndpoints,
      'analyzed_endpoints': analyzedEndpoints,
      'overall_risk_score': overallRiskScore,
      'risk_distribution': riskDistribution,
      'top_risks': topRisks.map((item) => item.toJson()).toList(),
      'risk_by_type': riskByType,
      'last_analyzed_at': lastAnalyzedAt,
    };
  }
}
