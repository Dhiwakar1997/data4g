import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../models/traffic_models.dart';
import '../workspace/workspace_controller.dart';

/// Traffic simulation view with QPS sliders per entry endpoint,
/// run button, per-component load cards, and bottleneck indicators.
class TrafficSimulationView extends ConsumerStatefulWidget {
  const TrafficSimulationView({super.key});

  @override
  ConsumerState<TrafficSimulationView> createState() =>
      _TrafficSimulationViewState();
}

class _TrafficSimulationViewState
    extends ConsumerState<TrafficSimulationView> {
  final List<EntryPointTraffic> _entryPoints = [];
  bool _initialized = false;

  void _initializeEntryPoints(WorkspaceState state) {
    if (_initialized) return;
    _initialized = true;

    // Build entry points from endpoint registries
    for (final entry in state.endpointRegistries.entries) {
      for (final endpoint in entry.value.endpoints) {
        _entryPoints.add(EntryPointTraffic(
          endpointId: endpoint.id,
          requestsPerSecond: 100,
        ));
      }
    }

    // If no registries, add a default entry
    if (_entryPoints.isEmpty) {
      _entryPoints.add(const EntryPointTraffic(
        endpointId: 'default',
        requestsPerSecond: 100,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceControllerProvider);
    final controller = ref.read(workspaceControllerProvider.notifier);
    final result = state.trafficResult;
    final isLoading = state.isTrafficLoading;

    _initializeEntryPoints(state);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.speed_rounded,
                  color: AppColors.brandYellow, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Traffic Simulation',
                  style:
                      AppTheme.syne(fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        controller.runTrafficSimulation(
                          TrafficInput(entryPoints: _entryPoints),
                        );
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run Simulation'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // QPS Sliders
          _SliderSection(
            entryPoints: _entryPoints,
            onChanged: (index, value) {
              setState(() {
                _entryPoints[index] =
                    _entryPoints[index].copyWith(requestsPerSecond: value);
              });
            },
          ),
          const SizedBox(height: 24),

          // Results
          if (result != null) ...[
            // Summary stats
            _ResultSummary(result: result),
            const SizedBox(height: 24),

            // Bottlenecks
            if (result.bottleneckComponents.isNotEmpty) ...[
              _BottleneckSection(result: result),
              const SizedBox(height: 24),
            ],

            // Per-component load
            _ComponentLoadSection(result: result),
          ] else if (!isLoading)
            _EmptyState(),
        ],
      ),
    );
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({
    required this.entryPoints,
    required this.onChanged,
  });

  final List<EntryPointTraffic> entryPoints;
  final void Function(int index, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entry Point QPS',
            style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adjust requests per second for each entry point',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...List.generate(entryPoints.length, (i) {
            final ep = entryPoints[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      ep.endpointId,
                      style: GoogleFonts.spaceMono(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: ep.requestsPerSecond,
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      activeColor: AppColors.brandYellow,
                      inactiveColor: AppColors.border,
                      onChanged: (v) => onChanged(i, v),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      rpsLabel(ep.requestsPerSecond),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.spaceMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandYellow,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result});
  final TrafficSimulationResult result;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _SummaryCard(
          label: 'Total QPS',
          value: rpsLabel(result.entryPointTotalQps),
          color: AppColors.brandYellow,
        ),
        _SummaryCard(
          label: 'Est. Monthly Cost',
          value: '\$${result.estimatedMonthlyCostAtTraffic.toStringAsFixed(0)}',
          color: AppColors.info,
        ),
        if (result.estimatedTotalLatencyMs != null)
          _SummaryCard(
            label: 'Est. Latency',
            value: latencyLabel(result.estimatedTotalLatencyMs!),
            color: AppColors.success,
          ),
        _SummaryCard(
          label: 'Bottlenecks',
          value: '${result.bottleneckComponents.length}',
          color: result.bottleneckComponents.isEmpty
              ? AppColors.success
              : AppColors.riskCritical,
        ),
        _SummaryCard(
          label: 'Components',
          value: '${result.perComponentLoad.length}',
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
              fontSize: 20,
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

class _BottleneckSection extends StatelessWidget {
  const _BottleneckSection({required this.result});
  final TrafficSimulationResult result;

  @override
  Widget build(BuildContext context) {
    final bottlenecks = result.perComponentLoad
        .where((c) => c.isBottleneck)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.riskCritical.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.riskCritical.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.riskCritical, size: 22),
              const SizedBox(width: 8),
              Text(
                'Bottlenecks Detected',
                style: AppTheme.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.riskCritical,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...bottlenecks.map((comp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: AppColors.riskCritical),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${comp.componentName} (${comp.componentType})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (comp.capacityReason != null)
                          Text(
                            comp.capacityReason!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    rpsLabel(comp.totalRequestsPerSecond),
                    style: GoogleFonts.spaceMono(
                      color: AppColors.riskCritical,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ComponentLoadSection extends StatelessWidget {
  const _ComponentLoadSection({required this.result});
  final TrafficSimulationResult result;

  @override
  Widget build(BuildContext context) {
    final loads = result.perComponentLoad.toList()
      ..sort(
          (a, b) => b.totalRequestsPerSecond.compareTo(a.totalRequestsPerSecond));
    final maxRps = loads.isNotEmpty ? loads.first.totalRequestsPerSecond : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per-Component Load',
          style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...loads.map((comp) {
          final fraction =
              (comp.totalRequestsPerSecond / maxRps).clamp(0.02, 1.0);
          final isBottleneck = comp.isBottleneck;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: AppTheme.glassCard(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isBottleneck)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.warning_amber_rounded,
                              size: 16, color: AppColors.riskCritical),
                        ),
                      Expanded(
                        child: Text(
                          comp.componentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          comp.componentType,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        rpsLabel(comp.totalRequestsPerSecond),
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isBottleneck
                              ? AppColors.riskCritical
                              : AppColors.brandYellow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Utilization bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.border.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: isBottleneck
                                  ? AppColors.riskCritical
                                  : AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (comp.capacityReason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${comp.capacityStatus}: ${comp.capacityReason}',
                      style: TextStyle(
                        color: isBottleneck
                            ? AppColors.riskCritical
                            : AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: AppTheme.glassCard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed_rounded,
                size: 54, color: AppColors.brandYellow),
            const SizedBox(height: 18),
            Text(
              'Run a simulation',
              style: AppTheme.syne(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Adjust the QPS sliders above and click "Run Simulation" to see how traffic flows through your topology and identify bottlenecks.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
