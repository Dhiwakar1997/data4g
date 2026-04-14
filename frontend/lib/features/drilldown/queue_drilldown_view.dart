import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../workspace/workspace_controller.dart';

/// Drill-down view for a message queue component.
///
/// Shows producer/consumer topology derived from endpoint registries,
/// message types, and queue interactions across all server components.
class QueueDrilldownView extends ConsumerWidget {
  const QueueDrilldownView({super.key, required this.componentId});

  final String componentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final component = state.selectedTopology?.components.firstWhere(
      (c) => c.id == componentId,
      orElse: () => state.selectedTopology!.components.first,
    );

    // Gather queue interactions from all endpoint registries
    final producers = <_QueueUsage>[];
    final consumers = <_QueueUsage>[];

    for (final entry in state.endpointRegistries.entries) {
      for (final endpoint in entry.value.endpoints) {
        for (final qi in endpoint.queueInteractions) {
          final usage = _QueueUsage(
            serverId: entry.key,
            endpointPath: endpoint.path,
            httpMethod: endpoint.httpMethod,
            queueName: qi.queueName,
            messageType: qi.messageType,
          );
          if (qi.role == 'producer') {
            producers.add(usage);
          } else {
            consumers.add(usage);
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        title: Text(component?.name ?? 'Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1180;
              return compact
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                            componentName: component?.name ?? 'Queue',
                            producerCount: producers.length,
                            consumerCount: consumers.length,
                          ),
                          const SizedBox(height: 20),
                          _StatsRow(
                            producerCount: producers.length,
                            consumerCount: consumers.length,
                          ),
                          const SizedBox(height: 20),
                          _UsageSection(
                            title: 'Producers',
                            icon: Icons.upload_rounded,
                            color: AppColors.success,
                            usages: producers,
                          ),
                          const SizedBox(height: 20),
                          _UsageSection(
                            title: 'Consumers',
                            icon: Icons.download_rounded,
                            color: AppColors.info,
                            usages: consumers,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Header(
                                  componentName: component?.name ?? 'Queue',
                                  producerCount: producers.length,
                                  consumerCount: consumers.length,
                                ),
                                const SizedBox(height: 20),
                                _StatsRow(
                                  producerCount: producers.length,
                                  consumerCount: consumers.length,
                                ),
                                const SizedBox(height: 20),
                                _UsageSection(
                                  title: 'Producers',
                                  icon: Icons.upload_rounded,
                                  color: AppColors.success,
                                  usages: producers,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _UsageSection(
                              title: 'Consumers',
                              icon: Icons.download_rounded,
                              color: AppColors.info,
                              usages: consumers,
                            ),
                          ),
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

class _QueueUsage {
  const _QueueUsage({
    required this.serverId,
    required this.endpointPath,
    required this.httpMethod,
    required this.queueName,
    this.messageType,
  });

  final String serverId;
  final String endpointPath;
  final String httpMethod;
  final String queueName;
  final String? messageType;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.componentName,
    required this.producerCount,
    required this.consumerCount,
  });

  final String componentName;
  final int producerCount;
  final int consumerCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.alt_route_rounded,
            color: Color(0xFFFF8AD8), size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$componentName · Queue Drill-Down',
                style: AppTheme.syne(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '$producerCount producers · $consumerCount consumers',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.producerCount,
    required this.consumerCount,
  });

  final int producerCount;
  final int consumerCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _StatCard(
          label: 'Producers',
          value: '$producerCount',
          color: AppColors.success,
        ),
        _StatCard(
          label: 'Consumers',
          value: '$consumerCount',
          color: AppColors.info,
        ),
        _StatCard(
          label: 'Total Interactions',
          value: '${producerCount + consumerCount}',
          color: const Color(0xFFFF8AD8),
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

class _UsageSection extends StatelessWidget {
  const _UsageSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.usages,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_QueueUsage> usages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${usages.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (usages.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassCard(),
            child: Text(
              'No ${title.toLowerCase()} found in endpoint registries.\nSync from MCP to populate.',
              style: const TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          )
        else
          ...usages.map((usage) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // HTTP method badge
                    Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        usage.httpMethod.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceMono(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usage.endpointPath,
                            style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Queue: ${usage.queueName}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (usage.messageType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          usage.messageType!,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
