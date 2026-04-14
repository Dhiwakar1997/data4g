import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  SessionStorage._();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _lastProjectKey = 'last_project_id';
  static const _teamIdKey = 'team_id';

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userIdKey, userId);
  }

  static Future<Map<String, String?>> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'accessToken': prefs.getString(_accessTokenKey),
      'refreshToken': prefs.getString(_refreshTokenKey),
      'userId': prefs.getString(_userIdKey),
      'lastProjectId': prefs.getString(_lastProjectKey),
    };
  }

  static Future<void> saveLastProjectId(String? projectId) async {
    final prefs = await SharedPreferences.getInstance();
    if (projectId == null || projectId.isEmpty) {
      await prefs.remove(_lastProjectKey);
      return;
    }
    await prefs.setString(_lastProjectKey, projectId);
  }

  static Future<void> saveTeamId(String? teamId) async {
    final prefs = await SharedPreferences.getInstance();
    if (teamId == null || teamId.isEmpty) {
      await prefs.remove(_teamIdKey);
      return;
    }
    await prefs.setString(_teamIdKey, teamId);
  }

  static Future<String?> loadTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_teamIdKey);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_lastProjectKey);
    await prefs.remove(_teamIdKey);
  }
}
