import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/cosmic_scaffold.dart';
import '../../models/topology_models.dart';
import '../auth/auth_controller.dart';
import '../compare/compare_view.dart';
import '../dashboard/dashboard_view.dart';
import '../risk/risk_dashboard_view.dart';
import '../settings/settings_view.dart';
import '../specs/spec_editor_view.dart';
import '../topology/topology_canvas_view.dart';
import '../traffic/traffic_simulation_view.dart';
import 'workspace_controller.dart';

enum WorkspaceSection { topology, specs, risk, traffic, dashboard, compare, settings }

extension WorkspaceSectionX on WorkspaceSection {
  String get routeName => name;

  String get label => switch (this) {
    WorkspaceSection.topology => 'Topology',
    WorkspaceSection.specs => 'Specs',
    WorkspaceSection.risk => 'Risk',
    WorkspaceSection.traffic => 'Traffic',
    WorkspaceSection.dashboard => 'Dashboard',
    WorkspaceSection.compare => 'Compare',
    WorkspaceSection.settings => 'Settings',
  };

  IconData get icon => switch (this) {
    WorkspaceSection.topology => Icons.hub_outlined,
    WorkspaceSection.specs => Icons.tune_outlined,
    WorkspaceSection.risk => Icons.shield_outlined,
    WorkspaceSection.traffic => Icons.speed_outlined,
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
  String? _lastShownInfo;
  String? _lastShownError;
  bool _statsExpanded = true;

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

  void _showToastIfNeeded(WorkspaceState workspaceState) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (workspaceState.errorMessage != null &&
          workspaceState.errorMessage != _lastShownError) {
        _lastShownError = workspaceState.errorMessage;
        _showToast(workspaceState.errorMessage!, AppColors.danger, Icons.error_outline_rounded);
      }
      if (workspaceState.infoMessage != null &&
          workspaceState.infoMessage != _lastShownInfo) {
        _lastShownInfo = workspaceState.infoMessage;
        _showToast(workspaceState.infoMessage!, AppColors.info, Icons.info_outline_rounded);
      }
      if (workspaceState.errorMessage == null) _lastShownError = null;
      if (workspaceState.infoMessage == null) _lastShownInfo = null;
    });
  }

  void _showToast(String message, Color color, IconData icon) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FloatingToast(
        message: message,
        color: color,
        icon: icon,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final authState = ref.watch(authControllerProvider);
    _showToastIfNeeded(workspaceState);

    return Scaffold(
      body: CosmicScaffold(
        child: Column(
          children: [
            _WorkspaceHeader(section: widget.section, authState: authState),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: workspaceState.isLoading && workspaceState.projects.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : workspaceState.selectedProject == null
                        ? _EmptyWorkspace(
                            onCreateProject: () => _showCreateProjectDialog(context),
                          )
                        : _WorkspaceBody(section: widget.section),
                  ),
                  // Floating stats toggle
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: _StatsToggleButton(
                      expanded: _statsExpanded,
                      onPressed: () => setState(() => _statsExpanded = !_statsExpanded),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _statsExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _WorkspaceFooter(state: workspaceState),
                    )
                  : const SizedBox.shrink(),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppTheme.glassCard(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGlow(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hub_rounded, color: AppColors.deepWine, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'DataForge',
            style: AppTheme.syne(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: WorkspaceSection.values.map((item) {
                  final selected = item == section;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => goToWorkspace(
                        context,
                        item,
                        projectId: state.selectedProjectId,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.brandYellow.withValues(alpha: 0.16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.brandYellow
                                : AppColors.border.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 16,
                              color: selected
                                  ? AppColors.brandYellow
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected ? AppColors.brandYellow : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            child: Builder(
              builder: (context) {
                final projectIds = state.projects.map((p) => p.projectId).toSet();
                final selected = state.selectedProjectId != null &&
                        projectIds.contains(state.selectedProjectId)
                    ? state.selectedProjectId
                    : null;
                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: state.projects
                      .map(
                        (project) => DropdownMenuItem(
                          value: project.projectId,
                          child: Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    await controller.selectProject(value);
                    if (context.mounted) {
                      goToWorkspace(context, section, projectId: value);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          if (authState.isAuthenticated)
            IconButton(
              tooltip: 'Sign Out',
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
            )
          else
            TextButton.icon(
              onPressed: () => context.go('/auth'),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Sign In'),
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
      WorkspaceSection.risk => const RiskDashboardView(),
      WorkspaceSection.traffic => const TrafficSimulationView(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FooterStat(
              label: 'Total monthly',
              value: dashboard == null ? '--' : money(dashboard.totalMonthlyCost),
            ),
            const SizedBox(width: 18),
            if (state.riskDashboard != null) ...[
              _FooterStat(
                label: 'Risk',
                value: formatRiskScore(state.riskDashboard!.overallRiskScore),
              ),
              const SizedBox(width: 18),
            ],
            _FooterStat(
              label: 'Base users',
              value: topology == null ? '--' : compactNumber(topology.baseUserCount),
            ),
            const SizedBox(width: 18),
            _FooterStat(
              label: 'Mode',
              value: topology?.deploymentMode.label ?? '--',
            ),
            const SizedBox(width: 18),
            _FooterStat(label: 'Topologies', value: '${state.topologies.length}'),
            if (state.lastMcpSyncAt != null) ...[
              const SizedBox(width: 18),
              _FooterStat(label: 'Last MCP sync', value: state.lastMcpSyncAt!),
            ],
            if (state.usingDemoData) ...[
              const SizedBox(width: 18),
              const _FooterStat(label: 'Data source', value: 'Demo seed'),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsToggleButton extends StatelessWidget {
  const _StatsToggleButton({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: expanded ? 'Hide stats' : 'Show stats',
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.panelSoft.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  expanded ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  expanded ? 'Hide stats' : 'Stats',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
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
        Text('$label: ', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}

class _FloatingToast extends StatefulWidget {
  const _FloatingToast({
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  @override
  State<_FloatingToast> createState() => _FloatingToastState();
}

class _FloatingToastState extends State<_FloatingToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.panelSoft.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.color.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: widget.color, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: TextStyle(fontSize: 13, color: widget.color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
