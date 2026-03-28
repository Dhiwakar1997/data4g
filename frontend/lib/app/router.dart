import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/landing/landing_screen.dart';
import '../features/workspace/workspace_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
    GoRoute(
      path: '/auth',
      builder: (context, state) => AuthScreen(
        initialMode: state.uri.queryParameters['mode'] == 'signup'
            ? AuthMode.signUp
            : AuthMode.signIn,
      ),
    ),
    GoRoute(path: '/workspace', redirect: (_, __) => '/workspace/topology'),
    GoRoute(
      path: '/workspace/:section',
      builder: (context, state) {
        final section = WorkspaceSectionX.fromRoute(
          state.pathParameters['section'],
        );
        final projectId = state.uri.queryParameters['projectId'];
        return WorkspaceScreen(section: section, routeProjectId: projectId);
      },
    ),
  ],
);

void goToWorkspace(
  BuildContext context,
  WorkspaceSection section, {
  String? projectId,
}) {
  final uri = Uri(
    path: '/workspace/${section.routeName}',
    queryParameters: projectId == null ? null : {'projectId': projectId},
  );
  context.go(uri.toString());
}
