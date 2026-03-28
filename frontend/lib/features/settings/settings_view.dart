import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_environment.dart';
import '../../core/theme/app_theme.dart';
import '../../models/project_models.dart';
import '../../models/topology_models.dart';
import '../workspace/workspace_controller.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key, required this.state});

  final WorkspaceState state;

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  late final TextEditingController _userIdController;
  ProjectRole _newMemberRole = ProjectRole.member;
  Set<String> _newMemberTopologyAccess = <String>{};
  final Map<String, Set<String>> _sharingDrafts = <String, Set<String>>{};

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController();
    _syncMemberDrafts();
  }

  @override
  void didUpdateWidget(covariant SettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedProjectId != widget.state.selectedProjectId ||
        oldWidget.state.members != widget.state.members ||
        oldWidget.state.topologies != widget.state.topologies) {
      _syncMemberDrafts();
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  void _syncMemberDrafts() {
    _sharingDrafts
      ..clear()
      ..addEntries(
        widget.state.members.map(
          (member) => MapEntry(member.userId, member.topologyAccess.toSet()),
        ),
      );

    final topologyIds = widget.state.topologies.map((item) => item.id).toSet();
    _newMemberTopologyAccess = _newMemberTopologyAccess.intersection(
      topologyIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.state.selectedProject;
    if (project == null) {
      return const _SettingsPlaceholder(
        title: 'Settings unlock per project',
        message:
            'Create or select a project first. Then you can manage owners, member topology access, and environment routing for the browser workspace.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1180;
        final left = Column(
          children: [
            _ProjectOverviewCard(state: widget.state),
            const SizedBox(height: 18),
            const _AccessModelCard(),
            const SizedBox(height: 18),
            const _EnvironmentCard(),
          ],
        );
        final right = Column(
          children: [
            _AddMemberCard(
              userIdController: _userIdController,
              newMemberRole: _newMemberRole,
              selectedTopologyIds: _newMemberTopologyAccess,
              topologies: widget.state.topologies,
              onRoleChanged: (value) => setState(() {
                _newMemberRole = value;
                if (value == ProjectRole.owner) {
                  _newMemberTopologyAccess = widget.state.topologies
                      .map((item) => item.id)
                      .toSet();
                }
              }),
              onToggleTopology: (topologyId) => setState(() {
                if (_newMemberTopologyAccess.contains(topologyId)) {
                  _newMemberTopologyAccess.remove(topologyId);
                } else {
                  _newMemberTopologyAccess.add(topologyId);
                }
              }),
              onSubmit: _addMember,
            ),
            const SizedBox(height: 18),
            _MembersCard(
              state: widget.state,
              sharingDrafts: _sharingDrafts,
              onToggleTopology: (userId, topologyId) => setState(() {
                final draft = _sharingDrafts[userId] ?? <String>{};
                if (draft.contains(topologyId)) {
                  draft.remove(topologyId);
                } else {
                  draft.add(topologyId);
                }
                _sharingDrafts[userId] = draft;
              }),
              onSave: _saveMemberAccess,
            ),
          ],
        );

        if (compact) {
          return SingleChildScrollView(
            child: Column(children: [left, const SizedBox(height: 18), right]),
          );
        }

        return SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 18),
              Expanded(child: right),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addMember() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      return;
    }

    final controller = ref.read(workspaceControllerProvider.notifier);
    final topologyAccess = _newMemberRole == ProjectRole.owner
        ? widget.state.topologies.map((item) => item.id).toList()
        : _newMemberTopologyAccess.toList();

    await controller.addMember(
      userId: userId,
      role: _newMemberRole,
      topologyAccess: topologyAccess,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _userIdController.clear();
      _newMemberRole = ProjectRole.member;
      _newMemberTopologyAccess = <String>{};
    });
  }

  Future<void> _saveMemberAccess(String userId) async {
    final topologyIds = _sharingDrafts[userId]?.toList() ?? const <String>[];
    await ref
        .read(workspaceControllerProvider.notifier)
        .shareTopologyAccess(userId: userId, topologyIds: topologyIds);
  }
}

class _ProjectOverviewCard extends StatelessWidget {
  const _ProjectOverviewCard({required this.state});

  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final project = state.selectedProject!;
    final topology = state.selectedTopology;
    return _SettingsCard(
      title: 'Project Overview',
      subtitle:
          'Projects are the high-level container in DataForge. The selected project controls which topologies, members, and comparisons you are working with.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: AppTheme.syne(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            project.description.isEmpty
                ? 'No description yet. This project is ready for multi-topology planning and cost modelling.'
                : project.description,
            style: const TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _OverviewStat(
                label: 'Topologies',
                value: '${state.topologies.length}',
              ),
              _OverviewStat(label: 'Members', value: '${state.members.length}'),
              _OverviewStat(
                label: 'Current topology',
                value: topology?.name ?? '--',
              ),
              _OverviewStat(
                label: 'Mode',
                value: topology?.deploymentMode.label ?? '--',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _InlineNote(
            icon: Icons.route_rounded,
            text:
                'Project selection stays in the workspace header so users can jump between high-level initiatives without leaving the browser shell.',
          ),
        ],
      ),
    );
  }
}

class _AccessModelCard extends StatelessWidget {
  const _AccessModelCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Access Model',
      subtitle:
          'The UI mirrors the backend membership rules so sharing decisions stay consistent when this expands to Android tablets and iPad later.',
      child: Column(
        children: [
          _RoleTile(
            color: AppColors.brandYellow,
            title: 'Owner',
            description:
                'Owners can access every topology in the project, manage membership, and compare any project topology they can see.',
          ),
          const SizedBox(height: 12),
          _RoleTile(
            color: AppColors.success,
            title: 'Member',
            description:
                'Members can only access the topologies explicitly shared with them. This keeps collaboration granular inside a shared project.',
          ),
        ],
      ),
    );
  }
}

class _EnvironmentCard extends StatelessWidget {
  const _EnvironmentCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Environment Routing',
      subtitle:
          'Local and cloud endpoints live in environment files so we can switch API targets without changing app code.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommandTile(
            label: 'Current env',
            value:
                '${AppEnvironment.environmentName.toUpperCase()} -> ${AppEnvironment.apiBaseUrl}',
          ),
          const SizedBox(height: 10),
          const _CommandTile(
            label: 'Local file',
            value: 'assets/env/local.env',
          ),
          const SizedBox(height: 10),
          const _CommandTile(
            label: 'Cloud file',
            value: 'assets/env/cloud.env',
          ),
          const SizedBox(height: 16),
          const _CommandTile(
            label: 'Run local',
            value: 'flutter run -d chrome --dart-define=APP_ENV=local',
          ),
          const SizedBox(height: 10),
          const _CommandTile(
            label: 'Run cloud',
            value: 'flutter run -d chrome --dart-define=APP_ENV=cloud',
          ),
        ],
      ),
    );
  }
}

class _AddMemberCard extends StatelessWidget {
  const _AddMemberCard({
    required this.userIdController,
    required this.newMemberRole,
    required this.selectedTopologyIds,
    required this.topologies,
    required this.onRoleChanged,
    required this.onToggleTopology,
    required this.onSubmit,
  });

  final TextEditingController userIdController;
  final ProjectRole newMemberRole;
  final Set<String> selectedTopologyIds;
  final List<TopologyModel> topologies;
  final ValueChanged<ProjectRole> onRoleChanged;
  final ValueChanged<String> onToggleTopology;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Add Member',
      subtitle:
          'The current backend expects a `user_id`, role, and topology access list. This form maps directly to those endpoints.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: userIdController,
            decoration: const InputDecoration(
              labelText: 'User ID',
              hintText: 'user_123 or an existing backend user id',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ProjectRole>(
            isExpanded: true,
            initialValue: newMemberRole,
            decoration: const InputDecoration(labelText: 'Role'),
            items: ProjectRole.values
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(
                      role.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onRoleChanged(value);
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Topology access',
            style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            newMemberRole == ProjectRole.owner
                ? 'Owners automatically receive access to every topology in the project.'
                : 'Members only receive access to the topologies you select here.',
            style: const TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: topologies.map((topology) {
              final selected =
                  newMemberRole == ProjectRole.owner ||
                  selectedTopologyIds.contains(topology.id);
              return FilterChip(
                selected: selected,
                label: Text(topology.name),
                onSelected: newMemberRole == ProjectRole.owner
                    ? null
                    : (_) => onToggleTopology(topology.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add member'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({
    required this.state,
    required this.sharingDrafts,
    required this.onToggleTopology,
    required this.onSave,
  });

  final WorkspaceState state;
  final Map<String, Set<String>> sharingDrafts;
  final void Function(String userId, String topologyId) onToggleTopology;
  final ValueChanged<String> onSave;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Members & Sharing',
      subtitle:
          'Adjust topology access per member without changing the underlying project itself.',
      child: state.members.isEmpty
          ? const Text(
              'No members yet. Add owners or members to start project collaboration.',
              style: TextStyle(color: AppColors.textMuted),
            )
          : Column(
              children: state.members.map((member) {
                final accessible =
                    sharingDrafts[member.userId] ??
                    member.topologyAccess.toSet();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.userId,
                                  style: AppTheme.syne(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _MemberChip(
                                      label: member.role.label,
                                      color: member.role == ProjectRole.owner
                                          ? AppColors.brandYellow
                                          : AppColors.success,
                                    ),
                                    _MemberChip(
                                      label: 'Added by ${member.addedBy}',
                                      color: AppColors.info,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (member.role == ProjectRole.member)
                            ElevatedButton.icon(
                              onPressed: () => onSave(member.userId),
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Save access'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (member.role == ProjectRole.owner)
                        const Text(
                          'Owner access covers every topology in the project.',
                          style: TextStyle(color: AppColors.textMuted),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: state.topologies.map((topology) {
                            final selected = accessible.contains(topology.id);
                            return FilterChip(
                              selected: selected,
                              label: Text(topology.name),
                              onSelected: (_) =>
                                  onToggleTopology(member.userId, topology.id),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.syne(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.color,
    required this.title,
    required this.description,
  });

  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.verified_user_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandYellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.brandYellow,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.6))),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.spaceMono(fontSize: 12)),
        ],
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.glassCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.settings_suggest_outlined,
                size: 54,
                color: AppColors.brandYellow,
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: AppTheme.syne(fontSize: 30, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
