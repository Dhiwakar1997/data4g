enum ExportFormat { png, svg, pdf }

extension ExportFormatX on ExportFormat {
  String get value => switch (this) {
    ExportFormat.png => 'png',
    ExportFormat.svg => 'svg',
    ExportFormat.pdf => 'pdf',
  };

  String get label => value.toUpperCase();

  static ExportFormat fromValue(String? value) {
    return ExportFormat.values.firstWhere(
      (f) => f.value == value,
      orElse: () => ExportFormat.png,
    );
  }
}

class ExportRequest {
  const ExportRequest({
    required this.projectId,
    required this.topologyId,
    required this.format,
    required this.includeSpecs,
    required this.includeCostSummary,
    required this.includeRiskAnalysis,
  });

  final String projectId;
  final String topologyId;
  final ExportFormat format;
  final bool includeSpecs;
  final bool includeCostSummary;
  final bool includeRiskAnalysis;

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'topology_id': topologyId,
      'format': format.value,
      'include_specs': includeSpecs,
      'include_cost_summary': includeCostSummary,
      'include_risk_analysis': includeRiskAnalysis,
    };
  }
}

class ExportResponse {
  const ExportResponse({
    required this.downloadUrl,
    required this.format,
    required this.generatedAt,
    required this.sizeBytes,
  });

  final String downloadUrl;
  final String format;
  final String generatedAt;
  final int sizeBytes;

  factory ExportResponse.fromJson(Map<String, dynamic> json) {
    return ExportResponse(
      downloadUrl: json['download_url'] as String? ?? '',
      format: json['format'] as String? ?? 'png',
      generatedAt: json['generated_at'] as String? ?? '',
      sizeBytes: json['size_bytes'] as int? ?? 0,
    );
  }
}
