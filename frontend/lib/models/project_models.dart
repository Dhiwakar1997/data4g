import 'topology_models.dart';

class ProjectSummary {
  const ProjectSummary({
    required this.projectId,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.topologyCount,
    required this.createdAt,
    required this.updatedAt,
    this.gitRepoUrl,
    this.teamId,
    this.cloudProvider,
    this.lastMcpSyncAt,
  });

  final String projectId;
  final String ownerId;
  final String name;
  final String description;
  final int topologyCount;
  final String createdAt;
  final String updatedAt;
  final String? gitRepoUrl;
  final String? teamId;
  final String? cloudProvider;
  final String? lastMcpSyncAt;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      projectId: json['project_id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      topologyCount: json['topology_count'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      gitRepoUrl: json['git_repo_url'] as String?,
      teamId: json['team_id'] as String?,
      cloudProvider: json['cloud_provider'] as String?,
      lastMcpSyncAt: json['last_mcp_sync_at'] as String?,
    );
  }
}

enum ProjectRole { owner, member }

extension ProjectRoleX on ProjectRole {
  String get value => name;

  String get label => switch (this) {
    ProjectRole.owner => 'Owner',
    ProjectRole.member => 'Member',
  };

  static ProjectRole fromValue(String? value) {
    return ProjectRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => ProjectRole.member,
    );
  }
}

class MemberRecord {
  const MemberRecord({
    required this.projectId,
    required this.userId,
    required this.role,
    required this.topologyAccess,
    required this.addedBy,
    required this.createdAt,
  });

  final String projectId;
  final String userId;
  final ProjectRole role;
  final List<String> topologyAccess;
  final String addedBy;
  final String createdAt;

  factory MemberRecord.fromJson(Map<String, dynamic> json) {
    return MemberRecord(
      projectId: json['project_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      role: ProjectRoleX.fromValue(json['role'] as String?),
      topologyAccess: (json['topology_access'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      addedBy: json['added_by'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  MemberRecord copyWith({ProjectRole? role, List<String>? topologyAccess}) {
    return MemberRecord(
      projectId: projectId,
      userId: userId,
      role: role ?? this.role,
      topologyAccess: topologyAccess ?? this.topologyAccess,
      addedBy: addedBy,
      createdAt: createdAt,
    );
  }
}

class TopologyOption {
  const TopologyOption({required this.id, required this.name});

  final String id;
  final String name;

  factory TopologyOption.fromTopology(TopologyModel topology) {
    return TopologyOption(id: topology.id, name: topology.name);
  }
}
