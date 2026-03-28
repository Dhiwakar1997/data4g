import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/session_storage.dart';
import '../../data/auth_repository.dart';
import '../../models/auth_models.dart';

class AuthState {
  const AuthState({
    required this.initialized,
    required this.isLoading,
    required this.isAuthenticated,
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.lastProjectId,
    this.errorMessage,
    this.infoMessage,
    this.showLoginAction = false,
    this.showResendVerification = false,
  });

  final bool initialized;
  final bool isLoading;
  final bool isAuthenticated;
  final String? userId;
  final String? accessToken;
  final String? refreshToken;
  final String? lastProjectId;
  final String? errorMessage;
  final String? infoMessage;
  final bool showLoginAction;
  final bool showResendVerification;

  factory AuthState.initial() {
    return const AuthState(
      initialized: false,
      isLoading: false,
      isAuthenticated: false,
    );
  }

  AuthState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isAuthenticated,
    String? userId,
    String? accessToken,
    String? refreshToken,
    String? lastProjectId,
    String? errorMessage,
    String? infoMessage,
    bool? showLoginAction,
    bool? showResendVerification,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      lastProjectId: lastProjectId ?? this.lastProjectId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
      showLoginAction: showLoginAction ?? this.showLoginAction,
      showResendVerification:
          showResendVerification ?? this.showResendVerification,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(AuthState.initial()) {
    initialize();
  }

  final AuthRepository _repository;

  Future<void> initialize() async {
    final session = await SessionStorage.loadSession();
    final accessToken = session['accessToken'];
    final refreshToken = session['refreshToken'];
    final userId = session['userId'];
    final lastProjectId = session['lastProjectId'];

    state = state.copyWith(
      initialized: true,
      isAuthenticated:
          accessToken != null && accessToken.isNotEmpty && userId != null,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      lastProjectId: lastProjectId,
      clearError: true,
      clearInfo: true,
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
      showLoginAction: false,
      showResendVerification: false,
    );
    try {
      final session = await _repository.login(
        LoginPayload(email: email, password: password),
      );
      await SessionStorage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        userId: session.userId,
      );
      final persisted = await SessionStorage.loadSession();
      state = state.copyWith(
        initialized: true,
        isLoading: false,
        isAuthenticated: true,
        userId: session.userId,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        lastProjectId: persisted['lastProjectId'],
        clearError: true,
        clearInfo: true,
        showLoginAction: false,
        showResendVerification: false,
      );
      return true;
    } on DioException catch (error) {
      final detail = error.response?.data is Map<String, dynamic>
          ? (error.response?.data as Map<String, dynamic>)['detail']
          : null;
      final detailMap = detail is Map<String, dynamic> ? detail : null;
      final isVerificationPending =
          error.response?.statusCode == 403 &&
          (detailMap?['code'] == 'email_not_verified' ||
              detail == 'Email not verified');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: isVerificationPending
            ? (detailMap?['message'] as String? ??
                  'Your account exists, but email verification is still pending.')
            : 'Unable to sign in. Please verify your credentials.',
        clearInfo: true,
        showLoginAction: false,
        showResendVerification:
            isVerificationPending &&
            (detailMap?['can_resend_verification'] as bool? ?? true),
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
      showLoginAction: false,
      showResendVerification: false,
    );
    try {
      final result = await _repository.signUp(
        SignupPayload(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
        ),
      );
      if (result.requiresVerification) {
        state = state.copyWith(
          isLoading: false,
          clearError: true,
          infoMessage: result.message,
          showLoginAction: true,
          showResendVerification: true,
        );
        return false;
      }
      return await signIn(email: email, password: password);
    } on DioException catch (error) {
      final detail = error.response?.data is Map<String, dynamic>
          ? (error.response?.data as Map<String, dynamic>)['detail']
          : null;
      final conflictDetail = detail is Map<String, dynamic> ? detail : null;
      final isConflict = error.response?.statusCode == 409;
      state = state.copyWith(
        isLoading: false,
        errorMessage: isConflict
            ? (conflictDetail?['message'] as String? ??
                  'Account already exists. Please log in or use another email.')
            : 'Unable to create your account right now.',
        clearInfo: true,
        showLoginAction: isConflict,
        showResendVerification:
            conflictDetail?['can_resend_verification'] == true,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to create your account right now.',
        clearInfo: true,
        showLoginAction: false,
        showResendVerification: false,
      );
      return false;
    }
  }

  Future<void> resendVerification(String email) async {
    state = state.copyWith(isLoading: true, clearInfo: true);
    try {
      final message = await _repository.resendVerification(email);
      state = state.copyWith(
        isLoading: false,
        clearError: true,
        infoMessage: message,
        showLoginAction: true,
        showResendVerification: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to resend verification right now.',
        clearInfo: true,
        showLoginAction: true,
        showResendVerification: true,
      );
    }
  }

  void clearFeedback() {
    state = state.copyWith(
      clearError: true,
      clearInfo: true,
      showLoginAction: false,
      showResendVerification: false,
    );
  }

  Future<void> rememberProject(String? projectId) async {
    await SessionStorage.saveLastProjectId(projectId);
    state = state.copyWith(lastProjectId: projectId);
  }

  Future<void> signOut() async {
    await SessionStorage.clearSession();
    state = const AuthState(
      initialized: true,
      isLoading: false,
      isAuthenticated: false,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);
