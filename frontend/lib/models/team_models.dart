class Team {
  const Team({
    required this.teamId,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  final String teamId;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final String createdAt;

  int get memberCount => memberIds.length;

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamId: json['team_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      memberIds: (json['member_ids'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'name': name,
      'owner_id': ownerId,
      'member_ids': memberIds,
      'created_at': createdAt,
    };
  }
}

class TeamInvite {
  const TeamInvite({
    required this.inviteId,
    required this.teamId,
    required this.inviteToken,
    this.maxUses,
    required this.useCount,
    this.expiresAt,
    required this.isActive,
  });

  final String inviteId;
  final String teamId;
  final String inviteToken;
  final int? maxUses;
  final int useCount;
  final String? expiresAt;
  final bool isActive;

  factory TeamInvite.fromJson(Map<String, dynamic> json) {
    return TeamInvite(
      inviteId: json['invite_id'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      inviteToken: json['invite_token'] as String? ?? '',
      maxUses: json['max_uses'] as int?,
      useCount: json['use_count'] as int? ?? 0,
      expiresAt: json['expires_at'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invite_id': inviteId,
      'team_id': teamId,
      'invite_token': inviteToken,
      'max_uses': maxUses,
      'use_count': useCount,
      'expires_at': expiresAt,
      'is_active': isActive,
    };
  }
}
