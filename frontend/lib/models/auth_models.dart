class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
    );
  }
}

class ApiMessage {
  const ApiMessage({required this.message});

  final String message;

  factory ApiMessage.fromJson(Map<String, dynamic> json) {
    return ApiMessage(message: json['message'] as String? ?? '');
  }
}

class SignupResult {
  const SignupResult({
    required this.userId,
    required this.message,
    required this.requiresVerification,
  });

  final String userId;
  final String message;
  final bool requiresVerification;

  factory SignupResult.fromJson(Map<String, dynamic> json) {
    return SignupResult(
      userId: json['user_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      requiresVerification: json['requires_verification'] as bool? ?? false,
    );
  }
}

class SignupPayload {
  const SignupPayload({
    required this.email,
    required this.password,
    required this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
  });

  final String email;
  final String password;
  final String firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;

  Map<String, dynamic> toJson() {
    return {
      'email_id': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
    };
  }
}

class ResendVerificationPayload {
  const ResendVerificationPayload({required this.email});

  final String email;

  Map<String, dynamic> toJson() {
    return {'email_id': email};
  }
}

class LoginPayload {
  const LoginPayload({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return {'email_id': email, 'password': password};
  }
}
