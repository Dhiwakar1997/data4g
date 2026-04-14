import '../core/network/api_client.dart';
import '../models/team_models.dart';

class TeamRepository {
  TeamRepository() : _client = ApiClient.instance;

  final ApiClient _client;

  Future<List<Team>> listTeams() async {
    final response = await _client.dio.get<dynamic>('/teams');
    final data = response.data as Map<String, dynamic>;
    return (data['teams'] as List<dynamic>? ?? [])
        .map((item) => Team.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Team> createTeam(String name) async {
    final response = await _client.dio.post<dynamic>(
      '/teams',
      data: {'name': name},
    );
    return Team.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Team> getTeam(String teamId) async {
    final response = await _client.dio.get<dynamic>('/teams/$teamId');
    return Team.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Team> updateTeam(String teamId, String name) async {
    final response = await _client.dio.put<dynamic>(
      '/teams/$teamId',
      data: {'name': name},
    );
    return Team.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTeam(String teamId) async {
    await _client.dio.delete<dynamic>('/teams/$teamId');
  }

  Future<TeamInvite> generateInvite(
    String teamId, {
    int? maxUses,
    int? expiresInDays,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/teams/$teamId/invites',
      data: {
        if (maxUses != null) 'max_uses': maxUses,
        if (expiresInDays != null) 'expires_in_days': expiresInDays,
      },
    );
    return TeamInvite.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TeamInvite>> listInvites(String teamId) async {
    final response = await _client.dio.get<dynamic>(
      '/teams/$teamId/invites',
    );
    final data = response.data as Map<String, dynamic>;
    return (data['invites'] as List<dynamic>? ?? [])
        .map((item) => TeamInvite.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> joinTeam(String inviteToken) async {
    await _client.dio.post<dynamic>(
      '/teams/join',
      data: {'invite_token': inviteToken},
    );
  }

  Future<void> removeMember(String teamId, String userId) async {
    await _client.dio.delete<dynamic>('/teams/$teamId/members/$userId');
  }
}
