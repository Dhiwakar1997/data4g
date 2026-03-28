import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../models/topology_models.dart';
import '../workspace/workspace_controller.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.state});

  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.dashboard;
    if (dashboard == null) {
      return _DashboardPlaceholder(
        message: state.selectedProject == null
            ? 'Select a project to view dashboard results.'
            : 'Dashboard data will appear here once the active project has cost inputs.',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DashboardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total cost',
                        style: AppTheme.syne(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${money(dashboard.totalMonthlyCost)} / mo',
                        style: AppTheme.syne(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandYellow,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Base growth point: ${compactNumber(dashboard.baseUserCount)} users · ${dashboard.projectName}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _DashboardCard(
                  child: SizedBox(
                    height: 240,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 54,
                              sectionsSpace: 3,
                              sections: dashboard.perComponent
                                  .map(
                                    (item) => PieChartSectionData(
                                      value: item.totalMonthly,
                                      color: _componentColor(
                                        item.componentType,
                                      ),
                                      radius: 54,
                                      showTitle: false,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 180,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: dashboard.perComponent.take(6).map((
                              item,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _componentColor(
                                          item.componentType,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.componentName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Text(money(item.totalMonthly)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cost by category',
                  style: AppTheme.syne(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                ...dashboard.perCategory.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 130,
                              child: Text(
                                titleCase(item.category),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: item.percentage / 100,
                                minHeight: 12,
                                borderRadius: BorderRadius.circular(999),
                                backgroundColor: AppColors.panelSoft,
                                color: AppColors.brandYellow,
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 96,
                              child: Text(
                                money(item.totalMonthly),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _DashboardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growth projection',
                        style: AppTheme.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 280,
                        child: LineChart(
                          LineChartData(
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval:
                                  dashboard
                                      .growthProjections
                                      .last
                                      .totalMonthly /
                                  4,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.border,
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 52,
                                  getTitlesWidget: (value, meta) => Text(
                                    money(value),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 ||
                                        index >=
                                            dashboard
                                                .growthProjections
                                                .length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        compactNumber(
                                          dashboard
                                              .growthProjections[index]
                                              .userCount,
                                        ),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                color: AppColors.brandYellow,
                                dotData: const FlDotData(show: true),
                                barWidth: 3,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.brandYellow.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                                spots: dashboard.growthProjections
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => FlSpot(
                                        entry.key.toDouble(),
                                        entry.value.totalMonthly,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _DashboardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optimization hints',
                        style: AppTheme.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...dashboard.optimizationHints.map((hint) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandYellow.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      titleCase(hint.category),
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 11,
                                        color: AppColors.brandYellow,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(money(hint.estimatedSavingsMonthly)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                hint.message,
                                style: const TextStyle(height: 1.55),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Confidence ${(hint.confidence * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Per-entity storage cost',
                      style: AppTheme.syne(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (dashboard.comparisonDelta != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: dashboard.comparisonDelta!.isNegative
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${dashboard.comparisonDatabase} · ${dashboard.comparisonDelta!.isNegative ? '' : '+'}${money(dashboard.comparisonDelta!)}',
                          style: GoogleFonts.spaceMono(
                            color: dashboard.comparisonDelta!.isNegative
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.4),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      children: [
                        _TableHead('Entity'),
                        _TableHead('Records'),
                        _TableHead('Storage'),
                        _TableHead('Cost / mo'),
                        _TableHead('% of DB'),
                      ],
                    ),
                    ...dashboard.perEntityStorage.map(
                      (item) => TableRow(
                        children: [
                          _TableCell(item.entityName),
                          _TableCell(compactNumber(item.recordCount)),
                          _TableCell('${item.storageGb.toStringAsFixed(2)} GB'),
                          _TableCell(money(item.storageCostMonthly)),
                          _TableCell(
                            '${item.percentageOfDbCost.toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: child,
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label),
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.glassCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pie_chart_outline_rounded,
                size: 56,
                color: AppColors.brandYellow,
              ),
              const SizedBox(height: 16),
              Text(
                'Dashboard coming alive',
                style: AppTheme.syne(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _componentColor(ComponentType componentType) {
  return switch (componentType) {
    ComponentType.compute => AppColors.info,
    ComponentType.database => AppColors.success,
    ComponentType.cache => const Color(0xFFFAB1A0),
    ComponentType.loadBalancer => const Color(0xFFA29BFE),
    ComponentType.cdn => const Color(0xFF55EFC4),
    ComponentType.objectStore => AppColors.brandYellow,
    _ => AppColors.textMuted,
  };
}
