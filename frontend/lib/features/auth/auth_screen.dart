import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cosmic_scaffold.dart';
import '../workspace/workspace_screen.dart';
import 'auth_controller.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.initialMode});

  final AuthMode initialMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late AuthMode _mode;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: CosmicScaffold(
        padding: const EdgeInsets.all(28),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 960;
                if (compact) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoPanel(context),
                        const SizedBox(height: 24),
                        _buildAuthCard(context, authState),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildInfoPanel(context)),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 420,
                      child: _buildAuthCard(context, authState),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.olive),
            ),
            child: Text(
              'Secure project planning for infrastructure teams',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: AppColors.brandYellow,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Step into the DataForge workspace',
            style: AppTheme.syne(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Design topologies, shape compute and data specs, compare environments, and share access with owners and members from one browser-first control room.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _AuthFeatureCard(
                title: 'Topology Builder',
                description:
                    'Infinite canvas with draggable nodes, edges, and project-level topology selection.',
                icon: Icons.hub_outlined,
              ),
              _AuthFeatureCard(
                title: 'Spec Editors',
                description:
                    'Database models, compute sizing, Kubernetes, Docker, CDN, cache, and gateway settings.',
                icon: Icons.tune_outlined,
              ),
              _AuthFeatureCard(
                title: 'Project Access',
                description:
                    'Owners see everything; members get explicit topology access for shared collaboration.',
                icon: Icons.manage_accounts_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to landing page'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context, AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _mode == AuthMode.signIn ? 'Welcome back' : 'Create your account',
              style: AppTheme.syne(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _mode == AuthMode.signIn
                  ? 'Sign in to connect your real API workspace and persist changes.'
                  : 'Start with browser-based planning and keep the same app ready for future tablet expansion.',
              style: const TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (_mode == AuthMode.signUp) ...[
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (value) {
                  if (_mode == AuthMode.signUp &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Use at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            if (authState.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.32),
                  ),
                ),
                child: Text(authState.errorMessage!),
              ),
            if (authState.errorMessage != null) const SizedBox(height: 18),
            if (authState.infoMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.olive.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.olive.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(authState.infoMessage!),
              ),
            if (authState.infoMessage != null) const SizedBox(height: 18),
            if (authState.showLoginAction || authState.showResendVerification)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (authState.showLoginAction)
                    OutlinedButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .clearFeedback();
                              setState(() {
                                _mode = AuthMode.signIn;
                              });
                            },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Go to Login'),
                    ),
                  if (authState.showResendVerification)
                    OutlinedButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .resendVerification(
                                    _emailController.text.trim(),
                                  );
                            },
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: Text(
                        authState.isLoading
                            ? 'Sending...'
                            : 'Resend Verification',
                      ),
                    ),
                ],
              ),
            if (authState.showLoginAction || authState.showResendVerification)
              const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _submit,
                child: Text(
                  authState.isLoading
                      ? 'Please wait...'
                      : _mode == AuthMode.signIn
                      ? 'Sign In'
                      : 'Create Account',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => goToWorkspace(
                  context,
                  WorkspaceSection.topology,
                  projectId: authState.lastProjectId,
                ),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Continue with demo workspace'),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _mode == AuthMode.signIn
                        ? 'New here?'
                        : 'Already have an account?',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                ref.read(authControllerProvider.notifier).clearFeedback();
                setState(() {
                  _mode = _mode == AuthMode.signIn
                      ? AuthMode.signUp
                      : AuthMode.signIn;
                });
              },
              child: Text(
                _mode == AuthMode.signIn
                    ? 'Create an account'
                    : 'Switch to sign in',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(authControllerProvider.notifier);
    final success = _mode == AuthMode.signIn
        ? await controller.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await controller.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim().isEmpty
                ? null
                : _lastNameController.text.trim(),
          );

    if (!mounted || !success) {
      return;
    }

    final state = ref.read(authControllerProvider);
    goToWorkspace(
      context,
      WorkspaceSection.topology,
      projectId: state.lastProjectId,
    );
  }
}

class _AuthFeatureCard extends StatelessWidget {
  const _AuthFeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.panelSoft.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brandYellow),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTheme.syne(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: AppColors.textMuted, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
