import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/router.dart';
import '../../core/config/app_environment.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/cosmic_scaffold.dart';
import '../../models/topology_models.dart';
import '../auth/auth_controller.dart';
import '../compare/compare_view.dart';
import '../dashboard/dashboard_view.dart';
import '../settings/settings_view.dart';
import '../specs/spec_editor_view.dart';
import '../topology/topology_canvas_view.dart';
import 'workspace_controller.dart';

enum WorkspaceSection { topology, specs, dashboard, compare, settings }

extension WorkspaceSectionX on WorkspaceSection {
  String get routeName => name;

  String get label => switch (this) {
    WorkspaceSection.topology => 'Topology',
    WorkspaceSection.specs => 'Specs',
    WorkspaceSection.dashboard => 'Dashboard',
    WorkspaceSection.compare => 'Compare',
    WorkspaceSection.settings => 'Settings',
  };

  IconData get icon => switch (this) {
    WorkspaceSection.topology => Icons.hub_outlined,
    WorkspaceSection.specs => Icons.tune_outlined,
    WorkspaceSection.dashboard => Icons.pie_chart_outline_rounded,
    WorkspaceSection.compare => Icons.compare_arrows_rounded,
    WorkspaceSection.settings => Icons.settings_outlined,
  };

  static WorkspaceSection fromRoute(String? value) {
    return WorkspaceSection.values.firstWhere(
      (section) => section.routeName == value,
      orElse: () => WorkspaceSection.topology,
    );
  }
}

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({
    super.key,
    required this.section,
    this.routeProjectId,
  });

  final WorkspaceSection section;
  final String? routeProjectId;

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRouteProject();
  }

  @override
  void didUpdateWidget(covariant WorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeProjectId != widget.routeProjectId) {
      _syncRouteProject();
    }
  }

  void _syncRouteProject() {
    final routeProjectId = widget.routeProjectId;
    if (routeProjectId == null) {
      return;
    }
    final state = ref.read(workspaceControllerProvider);
    if (routeProjectId == state.selectedProjectId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(workspaceControllerProvider.notifier)
          .selectProject(routeProjectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: CosmicScaffold(
        child: Column(
          children: [
            _WorkspaceHeader(section: widget.section, authState: authState),
            const SizedBox(height: 18),
            if (workspaceState.errorMessage != null)
              _Banner(
                color: AppColors.danger,
                icon: Icons.error_outline_rounded,
                message: workspaceState.errorMessage!,
              ),
            if (workspaceState.errorMessage != null) const SizedBox(height: 12),
            if (workspaceState.infoMessage != null)
              _Banner(
                color: AppColors.info,
                icon: Icons.info_outline_rounded,
                message: workspaceState.infoMessage!,
              ),
            if (workspaceState.infoMessage != null) const SizedBox(height: 12),
            Expanded(
              child: workspaceState.isLoading && workspaceState.projects.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : workspaceState.selectedProject == null
                  ? _EmptyWorkspace(
                      onCreateProject: () => _showCreateProjectDialog(context),
                    )
                  : _WorkspaceBody(section: widget.section),
            ),
            const SizedBox(height: 18),
            _WorkspaceFooter(state: workspaceState),
          ],
        ),
      ),
      floatingActionButton: workspaceState.selectedProject == null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateProjectDialog(context),
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.deepWine,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Project'),
            )
          : null,
    );
  }

  Future<void> _showCreateProjectDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Project'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Project name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  return;
                }
                await ref
                    .read(workspaceControllerProvider.notifier)
                    .createProject(
                      nameController.text.trim(),
                      description: descriptionController.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (!mounted || created != true) {
      return;
    }

    final projectId = ref.read(workspaceControllerProvider).selectedProjectId;
    goToWorkspace(context, widget.section, projectId: projectId);
  }
}

class _WorkspaceHeader extends ConsumerWidget {
  const _WorkspaceHeader({required this.section, required this.authState});

  final WorkspaceSection section;
  final AuthState authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final controller = ref.read(workspaceControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCard(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGlow(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.hub_rounded, color: AppColors.deepWine),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DataForge',
                      style: AppTheme.syne(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      state.selectedProject?.description ??
                          'Project-driven topology and cost planning workspace',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panelSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${AppEnvironment.environmentName.toUpperCase()} · ${AppEnvironment.apiBaseUrl}',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (authState.isAuthenticated)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => context.go('/auth'),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign In'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: WorkspaceSection.values.map((item) {
                    final selected = item == section;
                    return InkWell(
                      onTap: () => goToWorkspace(
                        context,
                        item,
                        projectId: state.selectedProjectId,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.brandYellow.withValues(alpha: 0.16)
                              : AppColors.panelSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.brandYellow
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 18,
                              color: selected
                                  ? AppColors.brandYellow
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(item.label),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: state.selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Current project',
                  ),
                  items: state.projects
                      .map(
                        (project) => DropdownMenuItem(
                          value: project.projectId,
                          child: Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }
                    await controller.selectProject(value);
                    if (context.mounted) {
                      goToWorkspace(context, section, projectId: value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceBody extends ConsumerWidget {
  const _WorkspaceBody({required this.section});

  final WorkspaceSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    return switch (section) {
      WorkspaceSection.topology => TopologyCanvasView(state: state),
      WorkspaceSection.specs => SpecEditorView(state: state),
      WorkspaceSection.dashboard => DashboardView(state: state),
      WorkspaceSection.compare => CompareView(state: state),
      WorkspaceSection.settings => SettingsView(state: state),
    };
  }
}

class _WorkspaceFooter extends StatelessWidget {
  const _WorkspaceFooter({required this.state});

  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final topology = state.selectedTopology;
    final dashboard = state.dashboard;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        children: [
          _FooterStat(
            label: 'Total monthly',
            value: dashboard == null ? '--' : money(dashboard.totalMonthlyCost),
          ),
          _FooterStat(
            label: 'Base users',
            value: topology == null
                ? '--'
                : compactNumber(topology.baseUserCount),
          ),
          _FooterStat(
            label: 'Mode',
            value: topology?.deploymentMode.label ?? '--',
          ),
          _FooterStat(label: 'Topologies', value: '${state.topologies.length}'),
          if (state.usingDemoData)
            const _FooterStat(label: 'Data source', value: 'Demo seed'),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  const _FooterStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace({required this.onCreateProject});

  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.glassCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_mosaic_rounded,
                size: 54,
                color: AppColors.brandYellow,
              ),
              const SizedBox(height: 18),
              Text(
                'Create your first project',
                style: AppTheme.syne(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Projects are the top-level containers in DataForge. Once created, you can add multiple topologies, compare them, and share access by role.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onCreateProject,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Create Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
