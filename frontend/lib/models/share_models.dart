class ShareLink {
  const ShareLink({
    required this.id,
    required this.projectId,
    this.topologyId,
    required this.token,
    this.expiresAt,
    required this.readOnly,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String? topologyId;
  final String token;
  final String? expiresAt;
  final bool readOnly;
  final String createdBy;
  final String createdAt;

  factory ShareLink.fromJson(Map<String, dynamic> json) {
    return ShareLink(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      topologyId: json['topology_id'] as String?,
      token: json['token'] as String? ?? '',
      expiresAt: json['expires_at'] as String?,
      readOnly: json['read_only'] as bool? ?? true,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'topology_id': topologyId,
      'token': token,
      'expires_at': expiresAt,
      'read_only': readOnly,
      'created_by': createdBy,
      'created_at': createdAt,
    };
  }
}
