import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/spec_models.dart';
import '../workspace/workspace_controller.dart';

/// Drill-down view for a cache component.
///
/// Shows cache configuration, eviction policy, cluster nodes,
/// and hit ratio indicators.
class CacheDrilldownView extends ConsumerWidget {
  const CacheDrilldownView({super.key, required this.componentId});

  final String componentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final component = state.selectedTopology?.components.firstWhere(
      (c) => c.id == componentId,
      orElse: () => state.selectedTopology!.components.first,
    );
    final spec = state.cacheSpecs[componentId];

    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        title: Text(component?.name ?? 'Cache'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: spec == null
              ? _EmptyState(componentName: component?.name ?? 'Cache')
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1180;
                    return compact
                        ? SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Header(spec: spec),
                                const SizedBox(height: 20),
                                _StatsRow(spec: spec),
                                const SizedBox(height: 20),
                                _ConfigDetails(spec: spec),
                                const SizedBox(height: 20),
                                _ClusterInfo(spec: spec),
                              ],
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _Header(spec: spec),
                                      const SizedBox(height: 20),
                                      _StatsRow(spec: spec),
                                      const SizedBox(height: 20),
                                      _ConfigDetails(spec: spec),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 340,
                                child: _ClusterInfo(spec: spec),
                              ),
                            ],
                          );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.componentName});
  final String componentName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: AppTheme.glassCard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded,
                size: 48, color: Color(0xFFFAB1A0)),
            const SizedBox(height: 16),
            Text(
              'No spec configured for $componentName',
              style: AppTheme.syne(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open the Specs tab to configure this cache component.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.spec});
  final CacheSpec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.bolt_rounded, color: Color(0xFFFAB1A0), size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${spec.cacheDatabase} · Cache Drill-Down',
            style: AppTheme.syne(fontSize: 26, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.spec});
  final CacheSpec spec;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _StatCard(
          label: 'Memory',
          value: '${spec.memoryGb} GB',
          color: const Color(0xFFFAB1A0),
        ),
        _StatCard(
          label: 'Default TTL',
          value: '${spec.ttlSeconds}s',
          color: AppColors.brandYellow,
        ),
        _StatCard(
          label: 'Eviction',
          value: spec.evictionPolicy,
          color: AppColors.info,
        ),
        _StatCard(
          label: 'Cluster Nodes',
          value: '${spec.clusterNodes}',
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigDetails extends StatelessWidget {
  const _ConfigDetails({required this.spec});
  final CacheSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration',
            style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _ConfigRow(
            icon: Icons.dns_rounded,
            label: 'Cache Database',
            value: spec.cacheDatabase,
          ),
          _ConfigRow(
            icon: Icons.memory_rounded,
            label: 'Memory Allocation',
            value: '${spec.memoryGb} GB',
          ),
          _ConfigRow(
            icon: Icons.delete_sweep_rounded,
            label: 'Eviction Policy',
            value: spec.evictionPolicy,
          ),
          _ConfigRow(
            icon: Icons.timer_rounded,
            label: 'Default TTL',
            value: '${spec.ttlSeconds} seconds',
          ),
          _ConfigRow(
            icon: Icons.verified_rounded,
            label: 'High Availability',
            value: spec.highAvailability ? 'Enabled' : 'Disabled',
            valueColor:
                spec.highAvailability ? AppColors.success : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClusterInfo extends StatelessWidget {
  const _ClusterInfo({required this.spec});
  final CacheSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cluster Topology',
            style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...List.generate(spec.clusterNodes, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.spaceBlack.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == 0
                        ? AppColors.brandYellow.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Node ${i + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            i == 0 ? 'Primary' : 'Replica',
                            style: TextStyle(
                              color: i == 0
                                  ? AppColors.brandYellow
                                  : AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${spec.memoryGb} GB',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (spec.highAvailability) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded,
                      size: 16, color: AppColors.success),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'High availability enabled — automatic failover configured',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
