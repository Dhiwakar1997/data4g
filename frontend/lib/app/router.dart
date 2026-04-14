import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/drilldown/server_drilldown_view.dart';
import '../features/drilldown/database_drilldown_view.dart';
import '../features/drilldown/cache_drilldown_view.dart';
import '../features/drilldown/queue_drilldown_view.dart';
import '../features/landing/landing_screen.dart';
import '../features/share/shared_view.dart';
import '../features/teams/team_screen.dart';
import '../features/teams/invite_screen.dart';
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
    // Drill-down routes
    GoRoute(
      path: '/workspace/topology/server/:componentId',
      builder: (context, state) => ServerDrilldownView(
        componentId: state.pathParameters['componentId']!,
      ),
    ),
    GoRoute(
      path: '/workspace/topology/database/:componentId',
      builder: (context, state) => DatabaseDrilldownView(
        componentId: state.pathParameters['componentId']!,
      ),
    ),
    GoRoute(
      path: '/workspace/topology/cache/:componentId',
      builder: (context, state) => CacheDrilldownView(
        componentId: state.pathParameters['componentId']!,
      ),
    ),
    GoRoute(
      path: '/workspace/topology/queue/:componentId',
      builder: (context, state) => QueueDrilldownView(
        componentId: state.pathParameters['componentId']!,
      ),
    ),
    // Team routes
    GoRoute(
      path: '/teams',
      builder: (context, state) => const TeamScreen(),
    ),
    GoRoute(
      path: '/teams/join/:inviteToken',
      builder: (context, state) => InviteScreen(
        inviteToken: state.pathParameters['inviteToken']!,
      ),
    ),
    // Shared read-only view
    GoRoute(
      path: '/shared/:shareToken',
      builder: (context, state) => SharedView(
        shareToken: state.pathParameters['shareToken']!,
      ),
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

void goToDrilldown(BuildContext context, String componentType, String componentId) {
  context.go('/workspace/topology/$componentType/$componentId');
}
