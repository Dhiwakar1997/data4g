// Models mirroring the backend `/scan` + `/keys` endpoints.

class ProjectApiKeySummary {
  const ProjectApiKeySummary({
    required this.keyId,
    required this.lastFour,
    required this.label,
    required this.createdBy,
    required this.createdAt,
    this.lastUsedAt,
    this.revokedAt,
  });

  final String keyId;
  final String lastFour;
  final String label;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final DateTime? revokedAt;

  bool get isRevoked => revokedAt != null;

  factory ProjectApiKeySummary.fromJson(Map<String, dynamic> json) {
    return ProjectApiKeySummary(
      keyId: json['key_id'] as String,
      lastFour: json['last_four'] as String,
      label: json['label'] as String,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: json['last_used_at'] == null
          ? null
          : DateTime.parse(json['last_used_at'] as String),
      revokedAt: json['revoked_at'] == null
          ? null
          : DateTime.parse(json['revoked_at'] as String),
    );
  }
}

class ProjectApiKeyCreated {
  const ProjectApiKeyCreated({
    required this.keyId,
    required this.plaintextKey,
    required this.lastFour,
    required this.label,
    required this.createdAt,
  });

  final String keyId;
  final String plaintextKey;
  final String lastFour;
  final String label;
  final DateTime createdAt;

  factory ProjectApiKeyCreated.fromJson(Map<String, dynamic> json) {
    return ProjectApiKeyCreated(
      keyId: json['key_id'] as String,
      plaintextKey: json['plaintext_key'] as String,
      lastFour: json['last_four'] as String,
      label: json['label'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ScanSessionSnapshot {
  const ScanSessionSnapshot({
    required this.syncId,
    required this.state,
    required this.startedAt,
    required this.expiresAt,
    required this.endpointCount,
    required this.entityCount,
    required this.serviceCount,
    required this.riskCount,
    required this.noteCount,
    this.note,
  });

  final String syncId;
  final String state;
  final DateTime startedAt;
  final DateTime expiresAt;
  final int endpointCount;
  final int entityCount;
  final int serviceCount;
  final int riskCount;
  final int noteCount;
  final String? note;

  factory ScanSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return ScanSessionSnapshot(
      syncId: json['sync_id'] as String,
      state: json['state'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      note: json['note'] as String?,
      endpointCount: (json['endpoint_count'] as num?)?.toInt() ?? 0,
      entityCount: (json['entity_count'] as num?)?.toInt() ?? 0,
      serviceCount: (json['service_count'] as num?)?.toInt() ?? 0,
      riskCount: (json['risk_count'] as num?)?.toInt() ?? 0,
      noteCount: (json['note_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScanSyncLastSummary {
  const ScanSyncLastSummary({
    required this.syncId,
    required this.status,
    required this.endpointsSynced,
    required this.entitiesSynced,
    required this.riskFindingsCount,
    required this.syncedAt,
    this.apiKeyId,
  });

  final String syncId;
  final String status;
  final int endpointsSynced;
  final int entitiesSynced;
  final int riskFindingsCount;
  final DateTime syncedAt;
  final String? apiKeyId;

  factory ScanSyncLastSummary.fromJson(Map<String, dynamic> json) {
    return ScanSyncLastSummary(
      syncId: json['sync_id'] as String,
      status: json['status'] as String,
      endpointsSynced: (json['endpoints_synced'] as num?)?.toInt() ?? 0,
      entitiesSynced: (json['entities_synced'] as num?)?.toInt() ?? 0,
      riskFindingsCount: (json['risk_findings_count'] as num?)?.toInt() ?? 0,
      syncedAt: DateTime.parse(json['synced_at'] as String),
      apiKeyId: json['api_key_id'] as String?,
    );
  }
}

class ScanStatus {
  const ScanStatus({
    required this.projectId,
    required this.activeSessions,
    this.lastSync,
  });

  final String projectId;
  final ScanSyncLastSummary? lastSync;
  final List<ScanSessionSnapshot> activeSessions;

  factory ScanStatus.fromJson(Map<String, dynamic> json) {
    return ScanStatus(
      projectId: json['project_id'] as String,
      lastSync: json['last_sync'] == null
          ? null
          : ScanSyncLastSummary.fromJson(
              json['last_sync'] as Map<String, dynamic>,
            ),
      activeSessions: ((json['active_sessions'] as List<dynamic>?) ?? const [])
          .map((item) =>
              ScanSessionSnapshot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static const ScanStatus empty = ScanStatus(
    projectId: '',
    activeSessions: [],
  );
}
