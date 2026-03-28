import '../core/network/api_client.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository() : _client = ApiClient.instance;

  final ApiClient _client;

  Future<SignupResult> signUp(SignupPayload payload) async {
    final response = await _client.dio.post<dynamic>(
      '/auth/signup',
      data: payload.toJson(),
    );
    return SignupResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthSession> login(LoginPayload payload) async {
    final response = await _client.dio.post<dynamic>(
      '/auth/login',
      data: payload.toJson(),
    );
    return AuthSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> resendVerification(String email) async {
    final response = await _client.dio.post<dynamic>(
      '/auth/resend-verification',
      data: ResendVerificationPayload(email: email).toJson(),
    );
    return ApiMessage.fromJson(response.data as Map<String, dynamic>).message;
  }
}
