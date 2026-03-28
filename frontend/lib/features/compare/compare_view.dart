import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../models/project_models.dart';
import '../../models/topology_models.dart';
import '../workspace/workspace_controller.dart';

class CompareView extends ConsumerStatefulWidget {
  const CompareView({super.key, required this.state});

  final WorkspaceState state;

  @override
  ConsumerState<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends ConsumerState<CompareView> {
  String? _selectedDatabaseId;
  String? _sourceProjectId;
  String? _sourceTopologyId;
  String? _targetProjectId;
  String? _targetTopologyId;
  final Map<String, List<TopologyModel>> _projectTopologies =
      <String, List<TopologyModel>>{};
  final Set<String> _loadingProjects = <String>{};

  @override
  void initState() {
    super.initState();
    _cacheCurrentProjectTopologies();
    _primeSelections();
  }

  @override
  void didUpdateWidget(covariant CompareView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedProjectId != widget.state.selectedProjectId ||
        oldWidget.state.topologies != widget.state.topologies ||
        oldWidget.state.projects != widget.state.projects ||
        oldWidget.state.databases != widget.state.databases) {
      _cacheCurrentProjectTopologies();
      _primeSelections();
    }
  }

  void _cacheCurrentProjectTopologies() {
    final currentProjectId = widget.state.selectedProjectId;
    if (currentProjectId == null) {
      return;
    }
    _projectTopologies[currentProjectId] = widget.state.topologies;
  }

  void _primeSelections() {
    final currentProjectId = widget.state.selectedProjectId;
    final currentTopologyId = widget.state.selectedTopologyId;

    if (widget.state.databases.isNotEmpty) {
      final valid = widget.state.databases.any(
        (item) => item.id == _selectedDatabaseId,
      );
      _selectedDatabaseId = valid
          ? _selectedDatabaseId
          : widget.state.databases.first.id;
    } else {
      _selectedDatabaseId = null;
    }

    _sourceProjectId = _ensureProjectSelection(
      _sourceProjectId,
      currentProjectId,
    );
    _targetProjectId = _ensureProjectSelection(
      _targetProjectId,
      currentProjectId,
    );

    _sourceTopologyId = _ensureTopologySelection(
      projectId: _sourceProjectId,
      preferredTopologyId: _sourceTopologyId ?? currentTopologyId,
      fallbackTopologyId: currentTopologyId,
    );

    final targetFallback = _pickAlternativeTopology(
      _targetProjectId,
      excludedId: _sourceTopologyId,
    );
    _targetTopologyId = _ensureTopologySelection(
      projectId: _targetProjectId,
      preferredTopologyId: _targetTopologyId,
      fallbackTopologyId: targetFallback ?? currentTopologyId,
    );
  }

  String? _ensureProjectSelection(String? projectId, String? currentProjectId) {
    final availableProjectIds = widget.state.projects
        .map((item) => item.projectId)
        .toSet();
    if (projectId != null && availableProjectIds.contains(projectId)) {
      return projectId;
    }
    return currentProjectId;
  }

  String? _ensureTopologySelection({
    required String? projectId,
    required String? preferredTopologyId,
    required String? fallbackTopologyId,
  }) {
    final topologies = _topologiesFor(projectId);
    if (topologies.isEmpty) {
      return null;
    }
    if (preferredTopologyId != null &&
        topologies.any((item) => item.id == preferredTopologyId)) {
      return preferredTopologyId;
    }
    if (fallbackTopologyId != null &&
        topologies.any((item) => item.id == fallbackTopologyId)) {
      return fallbackTopologyId;
    }
    return topologies.first.id;
  }

  String? _pickAlternativeTopology(String? projectId, {String? excludedId}) {
    final topologies = _topologiesFor(projectId);
    for (final topology in topologies) {
      if (topology.id != excludedId) {
        return topology.id;
      }
    }
    return topologies.isNotEmpty ? topologies.first.id : null;
  }

  List<TopologyModel> _topologiesFor(String? projectId) {
    if (projectId == null) {
      return const <TopologyModel>[];
    }
    if (projectId == widget.state.selectedProjectId) {
      return widget.state.topologies;
    }
    return _projectTopologies[projectId] ?? const <TopologyModel>[];
  }

  Future<void> _ensureProjectTopologies(String? projectId) async {
    if (projectId == null ||
        widget.state.usingDemoData ||
        _projectTopologies.containsKey(projectId) ||
        _loadingProjects.contains(projectId)) {
      return;
    }

    setState(() {
      _loadingProjects.add(projectId);
    });

    try {
      final topologies = await ref
          .read(dataForgeRepositoryProvider)
          .listTopologies(projectId);
      if (!mounted) {
        return;
      }
      setState(() {
        _projectTopologies[projectId] = topologies;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _projectTopologies[projectId] = const <TopologyModel>[];
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingProjects.remove(projectId);
        _primeSelections();
      });
    }
  }

  Future<void> _handleProjectChange({
    required bool isSource,
    required String? projectId,
  }) async {
    if (projectId == null) {
      return;
    }
    await _ensureProjectTopologies(projectId);
    final topologies = _topologiesFor(projectId);
    final nextTopologyId = isSource
        ? _ensureTopologySelection(
            projectId: projectId,
            preferredTopologyId: null,
            fallbackTopologyId: widget.state.selectedTopologyId,
          )
        : _pickAlternativeTopology(projectId, excludedId: _sourceTopologyId);

    if (!mounted) {
      return;
    }

    setState(() {
      if (isSource) {
        _sourceProjectId = projectId;
        _sourceTopologyId =
            nextTopologyId ??
            (topologies.isNotEmpty ? topologies.first.id : null);
        if (_targetProjectId == projectId &&
            _targetTopologyId == _sourceTopologyId) {
          _targetTopologyId = _pickAlternativeTopology(
            projectId,
            excludedId: _sourceTopologyId,
          );
        }
      } else {
        _targetProjectId = projectId;
        _targetTopologyId =
            nextTopologyId ??
            (topologies.isNotEmpty ? topologies.first.id : null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(workspaceControllerProvider.notifier);
    final dashboard = widget.state.dashboard;
    final comparison = widget.state.comparison;
    final sourceTopologies = _topologiesFor(_sourceProjectId);
    final targetTopologies = _topologiesFor(_targetProjectId);
    final compact = MediaQuery.sizeOf(context).width < 1180;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          compact
              ? Column(
                  children: [
                    _DatabaseComparisonCard(
                      state: widget.state,
                      selectedDatabaseId: _selectedDatabaseId,
                      dashboard: dashboard,
                      onChanged: (value) => setState(() {
                        _selectedDatabaseId = value;
                      }),
                      onCompare: _selectedDatabaseId == null
                          ? null
                          : () => controller.compareDatabase(
                              _selectedDatabaseId!,
                            ),
                    ),
                    const SizedBox(height: 18),
                    _TopologyComparisonCard(
                      state: widget.state,
                      sourceProjectId: _sourceProjectId,
                      sourceTopologyId: _sourceTopologyId,
                      sourceTopologies: sourceTopologies,
                      targetProjectId: _targetProjectId,
                      targetTopologyId: _targetTopologyId,
                      targetTopologies: targetTopologies,
                      loadingSource: _loadingProjects.contains(
                        _sourceProjectId,
                      ),
                      loadingTarget: _loadingProjects.contains(
                        _targetProjectId,
                      ),
                      onSourceProjectChanged: (value) => _handleProjectChange(
                        isSource: true,
                        projectId: value,
                      ),
                      onSourceTopologyChanged: (value) => setState(() {
                        _sourceTopologyId = value;
                        if (_sourceProjectId == _targetProjectId &&
                            _sourceTopologyId == _targetTopologyId) {
                          _targetTopologyId = _pickAlternativeTopology(
                            _targetProjectId,
                            excludedId: _sourceTopologyId,
                          );
                        }
                      }),
                      onTargetProjectChanged: (value) => _handleProjectChange(
                        isSource: false,
                        projectId: value,
                      ),
                      onTargetTopologyChanged: (value) => setState(() {
                        _targetTopologyId = value;
                      }),
                      onCompare:
                          (_sourceProjectId == null ||
                              _sourceTopologyId == null ||
                              _targetProjectId == null ||
                              _targetTopologyId == null)
                          ? null
                          : () => controller.compareTopologies(
                              sourceProjectId: _sourceProjectId!,
                              sourceTopologyId: _sourceTopologyId!,
                              targetProjectId: _targetProjectId!,
                              targetTopologyId: _targetTopologyId!,
                            ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DatabaseComparisonCard(
                        state: widget.state,
                        selectedDatabaseId: _selectedDatabaseId,
                        dashboard: dashboard,
                        onChanged: (value) => setState(() {
                          _selectedDatabaseId = value;
                        }),
                        onCompare: _selectedDatabaseId == null
                            ? null
                            : () => controller.compareDatabase(
                                _selectedDatabaseId!,
                              ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _TopologyComparisonCard(
                        state: widget.state,
                        sourceProjectId: _sourceProjectId,
                        sourceTopologyId: _sourceTopologyId,
                        sourceTopologies: sourceTopologies,
                        targetProjectId: _targetProjectId,
                        targetTopologyId: _targetTopologyId,
                        targetTopologies: targetTopologies,
                        loadingSource: _loadingProjects.contains(
                          _sourceProjectId,
                        ),
                        loadingTarget: _loadingProjects.contains(
                          _targetProjectId,
                        ),
                        onSourceProjectChanged: (value) => _handleProjectChange(
                          isSource: true,
                          projectId: value,
                        ),
                        onSourceTopologyChanged: (value) => setState(() {
                          _sourceTopologyId = value;
                          if (_sourceProjectId == _targetProjectId &&
                              _sourceTopologyId == _targetTopologyId) {
                            _targetTopologyId = _pickAlternativeTopology(
                              _targetProjectId,
                              excludedId: _sourceTopologyId,
                            );
                          }
                        }),
                        onTargetProjectChanged: (value) => _handleProjectChange(
                          isSource: false,
                          projectId: value,
                        ),
                        onTargetTopologyChanged: (value) => setState(() {
                          _targetTopologyId = value;
                        }),
                        onCompare:
                            (_sourceProjectId == null ||
                                _sourceTopologyId == null ||
                                _targetProjectId == null ||
                                _targetTopologyId == null)
                            ? null
                            : () => controller.compareTopologies(
                                sourceProjectId: _sourceProjectId!,
                                sourceTopologyId: _sourceTopologyId!,
                                targetProjectId: _targetProjectId!,
                                targetTopologyId: _targetTopologyId!,
                              ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 18),
          _CompareCard(
            title: 'Diff Summary',
            child: comparison == null
                ? const Text(
                    'Run a topology comparison to inspect added, removed, modified, and unchanged components across project boundaries.',
                    style: TextStyle(color: AppColors.textMuted),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _DiffStat(
                            label: 'Added',
                            value: comparison.addedComponents,
                          ),
                          _DiffStat(
                            label: 'Removed',
                            value: comparison.removedComponents,
                          ),
                          _DiffStat(
                            label: 'Modified',
                            value: comparison.modifiedComponents,
                          ),
                          _DiffStat(
                            label: 'Unchanged',
                            value: comparison.unchangedComponents,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${comparison.sourceTopologyName}  ->  ${comparison.targetTopologyName}',
                        style: AppTheme.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Project ${comparison.sourceProjectId} compared with ${comparison.targetProjectId}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ...comparison.componentDiffs.map((diff) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.panelSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      diff.componentName,
                                      style: AppTheme.syne(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _CompareStatusChip(status: diff.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                titleCase(diff.componentType),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...diff.changes.map(
                                (change) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.arrow_right_rounded,
                                        color: AppColors.brandYellow,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(change)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DatabaseComparisonCard extends StatelessWidget {
  const _DatabaseComparisonCard({
    required this.state,
    required this.selectedDatabaseId,
    required this.dashboard,
    required this.onChanged,
    required this.onCompare,
  });

  final WorkspaceState state;
  final String? selectedDatabaseId;
  final dynamic dashboard;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    return _CompareCard(
      title: 'Database Cost Comparison',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Swap the current database choice against the same topology to inspect the estimated delta before you rebuild infrastructure.',
            style: TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: selectedDatabaseId,
            decoration: const InputDecoration(labelText: 'Alternate database'),
            items: state.databases
                .map(
                  (db) => DropdownMenuItem(
                    value: db.id,
                    child: Text(
                      '${db.name} · ${titleCase(db.category)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCompare,
            icon: const Icon(Icons.compare_arrows_rounded),
            label: const Text('Run comparison'),
          ),
          const SizedBox(height: 20),
          if (dashboard?.comparisonDelta != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dashboard.comparisonDelta!.isNegative
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dashboard.comparisonDelta!.isNegative
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current total ${money(dashboard.totalMonthlyCost)}',
                    style: AppTheme.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'With ${dashboard.comparisonDatabase}: ${money(dashboard.comparisonTotalMonthly ?? 0)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Delta ${dashboard.comparisonDelta!.isNegative ? '' : '+'}${money(dashboard.comparisonDelta!)}',
                    style: TextStyle(
                      color: dashboard.comparisonDelta!.isNegative
                          ? AppColors.success
                          : AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'Choose an alternate database and run the comparison to populate the delta card.',
              style: TextStyle(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _TopologyComparisonCard extends StatelessWidget {
  const _TopologyComparisonCard({
    required this.state,
    required this.sourceProjectId,
    required this.sourceTopologyId,
    required this.sourceTopologies,
    required this.targetProjectId,
    required this.targetTopologyId,
    required this.targetTopologies,
    required this.loadingSource,
    required this.loadingTarget,
    required this.onSourceProjectChanged,
    required this.onSourceTopologyChanged,
    required this.onTargetProjectChanged,
    required this.onTargetTopologyChanged,
    required this.onCompare,
  });

  final WorkspaceState state;
  final String? sourceProjectId;
  final String? sourceTopologyId;
  final List<TopologyModel> sourceTopologies;
  final String? targetProjectId;
  final String? targetTopologyId;
  final List<TopologyModel> targetTopologies;
  final bool loadingSource;
  final bool loadingTarget;
  final ValueChanged<String?> onSourceProjectChanged;
  final ValueChanged<String?> onSourceTopologyChanged;
  final ValueChanged<String?> onTargetProjectChanged;
  final ValueChanged<String?> onTargetTopologyChanged;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    return _CompareCard(
      title: 'Topology Diff',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compare two topologies from the same project or another project the signed-in user can access.',
            style: TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 16),
          _ProjectTopologySelector(
            label: 'Source',
            projects: state.projects,
            projectId: sourceProjectId,
            topologyId: sourceTopologyId,
            topologies: sourceTopologies,
            loading: loadingSource,
            onProjectChanged: onSourceProjectChanged,
            onTopologyChanged: onSourceTopologyChanged,
          ),
          const SizedBox(height: 16),
          _ProjectTopologySelector(
            label: 'Target',
            projects: state.projects,
            projectId: targetProjectId,
            topologyId: targetTopologyId,
            topologies: targetTopologies,
            loading: loadingTarget,
            onProjectChanged: onTargetProjectChanged,
            onTopologyChanged: onTargetTopologyChanged,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCompare,
            icon: const Icon(Icons.sync_alt_rounded),
            label: const Text('Compare topologies'),
          ),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.title, required this.child});

  final String title;
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
            style: AppTheme.syne(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ProjectTopologySelector extends StatelessWidget {
  const _ProjectTopologySelector({
    required this.label,
    required this.projects,
    required this.projectId,
    required this.topologyId,
    required this.topologies,
    required this.loading,
    required this.onProjectChanged,
    required this.onTopologyChanged,
  });

  final String label;
  final List<ProjectSummary> projects;
  final String? projectId;
  final String? topologyId;
  final List<TopologyModel> topologies;
  final bool loading;
  final ValueChanged<String?> onProjectChanged;
  final ValueChanged<String?> onTopologyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: projectId,
          decoration: InputDecoration(labelText: '$label project'),
          items: projects
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
          onChanged: onProjectChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: topologyId,
          decoration: InputDecoration(
            labelText: loading
                ? '$label topology (loading...)'
                : '$label topology',
          ),
          items: topologies
              .map(
                (topology) => DropdownMenuItem(
                  value: topology.id,
                  child: Text(
                    topology.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: loading || topologies.isEmpty ? null : onTopologyChanged,
        ),
        if (!loading && topologies.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No accessible topologies found for the selected project yet.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}

class _DiffStat extends StatelessWidget {
  const _DiffStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: AppTheme.syne(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _CompareStatusChip extends StatelessWidget {
  const _CompareStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'added' => AppColors.success,
      'removed' => AppColors.danger,
      'modified' => AppColors.brandYellow,
      _ => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        titleCase(status),
        style: GoogleFonts.spaceMono(fontSize: 11, color: color),
      ),
    );
  }
}
