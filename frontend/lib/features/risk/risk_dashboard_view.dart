import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../models/risk_models.dart';
import '../workspace/workspace_controller.dart';

/// Risk analysis dashboard showing overall score, severity distribution,
/// type breakdown, and top-10 risky endpoints.
class RiskDashboardView extends ConsumerWidget {
  const RiskDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final controller = ref.read(workspaceControllerProvider.notifier);
    final dashboard = state.riskDashboard;
    final isLoading = state.isRiskLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.brandYellow, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Risk Analysis',
                  style: AppTheme.syne(fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isLoading ? null : () => controller.triggerRiskAnalysis(),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Scan Now'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (dashboard == null)
            _EmptyState(onScan: () => controller.triggerRiskAnalysis())
          else ...[
            // Score + stats row
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _ScoreGauge(score: dashboard.overallRiskScore),
                    _StatCard(
                      label: 'Endpoints',
                      value: '${dashboard.analyzedEndpoints}/${dashboard.totalEndpoints}',
                      subtitle: 'Analyzed',
                      color: AppColors.info,
                      width: compact ? null : 160,
                    ),
                    _StatCard(
                      label: 'Critical',
                      value: '${dashboard.riskDistribution['critical'] ?? 0}',
                      color: AppColors.riskCritical,
                      width: compact ? null : 120,
                    ),
                    _StatCard(
                      label: 'High',
                      value: '${dashboard.riskDistribution['high'] ?? 0}',
                      color: AppColors.riskHigh,
                      width: compact ? null : 120,
                    ),
                    _StatCard(
                      label: 'Medium',
                      value: '${dashboard.riskDistribution['medium'] ?? 0}',
                      color: AppColors.riskMedium,
                      width: compact ? null : 120,
                    ),
                    _StatCard(
                      label: 'Low',
                      value: '${dashboard.riskDistribution['low'] ?? 0}',
                      color: AppColors.riskLow,
                      width: compact ? null : 120,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Risk by type distribution
            _RiskByTypeSection(riskByType: dashboard.riskByType),
            const SizedBox(height: 24),

            // Top risky endpoints
            _TopRisksSection(topRisks: dashboard.topRisks),

            if (dashboard.lastAnalyzedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Last analyzed: ${dashboard.lastAnalyzedAt}',
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onScan});
  final VoidCallback onScan;

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
            const Icon(Icons.shield_outlined,
                size: 54, color: AppColors.brandYellow),
            const SizedBox(height: 18),
            Text(
              'No risk analysis yet',
              style: AppTheme.syne(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Run a risk scan to analyze endpoints for N+1 queries, missing pagination, unbounded fetches, and other performance risks.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.6),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Run First Scan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.score});
  final double score;

  Color _scoreColor() {
    if (score >= 80) return AppColors.riskCritical;
    if (score >= 60) return AppColors.riskHigh;
    if (score >= 40) return AppColors.riskMedium;
    if (score >= 20) return AppColors.riskLow;
    return AppColors.riskInfo;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            formatRiskScore(score),
            style: TextStyle(
              color: color,
              fontSize: 42,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            riskScoreLabel(score),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Risk Score',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.width,
  });

  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 10,
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

class _RiskByTypeSection extends StatelessWidget {
  const _RiskByTypeSection({required this.riskByType});
  final Map<String, int> riskByType;

  @override
  Widget build(BuildContext context) {
    if (riskByType.isEmpty) return const SizedBox.shrink();

    final sorted = riskByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount =
        sorted.isNotEmpty ? sorted.first.value.toDouble() : 1.0;

    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk by Type',
            style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...sorted.map((entry) {
            final riskType = RiskTypeX.fromValue(entry.key);
            final fraction = entry.value / maxCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      riskType.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.border.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction.clamp(0.02, 1.0),
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.riskHigh.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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

class _TopRisksSection extends StatelessWidget {
  const _TopRisksSection({required this.topRisks});
  final List<EndpointRiskSummary> topRisks;

  @override
  Widget build(BuildContext context) {
    if (topRisks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Risky Endpoints',
          style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...topRisks.take(10).map((summary) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EndpointRiskRow(summary: summary),
          );
        }),
      ],
    );
  }
}

class _EndpointRiskRow extends StatelessWidget {
  const _EndpointRiskRow({required this.summary});
  final EndpointRiskSummary summary;

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.riskCritical;
    if (score >= 60) return AppColors.riskHigh;
    if (score >= 40) return AppColors.riskMedium;
    if (score >= 20) return AppColors.riskLow;
    return AppColors.riskInfo;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(summary.overallRiskScore);

    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Score
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${summary.overallRiskScore.toInt()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Method badge
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              summary.httpMethod.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          // Path
          Expanded(
            child: Text(
              summary.endpointPath,
              style: GoogleFonts.spaceMono(fontSize: 13),
            ),
          ),
          // Severity counts
          if (summary.criticalCount > 0)
            _SeverityChip(
              count: summary.criticalCount,
              color: AppColors.riskCritical,
              label: 'C',
            ),
          if (summary.highCount > 0)
            _SeverityChip(
              count: summary.highCount,
              color: AppColors.riskHigh,
              label: 'H',
            ),
          if (summary.mediumCount > 0)
            _SeverityChip(
              count: summary.mediumCount,
              color: AppColors.riskMedium,
              label: 'M',
            ),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.count,
    required this.color,
    required this.label,
  });

  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label$count',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
