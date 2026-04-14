import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/endpoint_models.dart';
import '../workspace/workspace_controller.dart';

/// Drill-down view for a compute/server component.
///
/// Shows the endpoint list with DB/cache/service calls, risk indicators,
/// expandable rows, and sort/filter controls.
class ServerDrilldownView extends ConsumerStatefulWidget {
  const ServerDrilldownView({super.key, required this.componentId});

  final String componentId;

  @override
  ConsumerState<ServerDrilldownView> createState() =>
      _ServerDrilldownViewState();
}

class _ServerDrilldownViewState extends ConsumerState<ServerDrilldownView> {
  String _sortBy = 'risk';
  String _filterMethod = 'all';
  String? _expandedEndpointId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceControllerProvider);
    final component = state.selectedTopology?.components.firstWhere(
      (c) => c.id == widget.componentId,
      orElse: () => state.selectedTopology!.components.first,
    );
    final registry = state.endpointRegistries[widget.componentId];
    final endpoints = _sortedAndFiltered(registry?.endpoints ?? []);

    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        title: Text(component?.name ?? 'Server'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.memory_rounded, color: AppColors.info, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${component?.name ?? 'Server'} · Endpoints',
                      style: AppTheme.syne(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatBadge(
                    label: 'Endpoints',
                    value: '${endpoints.length}',
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 12),
                  if (registry != null)
                    _StatBadge(
                      label: 'Synced',
                      value: registry.lastSyncedAt ?? '—',
                      color: AppColors.textMuted,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Sort & filter bar
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.panel,
                    items: const [
                      DropdownMenuItem(
                        value: 'risk',
                        child: Text('Sort by Risk'),
                      ),
                      DropdownMenuItem(
                        value: 'path',
                        child: Text('Sort by Path'),
                      ),
                      DropdownMenuItem(
                        value: 'method',
                        child: Text('Sort by Method'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _sortBy = v);
                    },
                  ),
                  ...['all', 'GET', 'POST', 'PUT', 'DELETE'].map(
                    (method) => ChoiceChip(
                      label: Text(method == 'all' ? 'All' : method),
                      selected: _filterMethod == method,
                      onSelected: (_) =>
                          setState(() => _filterMethod = method),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Endpoint list
              Expanded(
                child: endpoints.isEmpty
                    ? Center(
                        child: Text(
                          'No endpoints registered for this component.\nSync from MCP to populate.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            height: 1.6,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: endpoints.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final ep = endpoints[index];
                          final isExpanded =
                              _expandedEndpointId == ep.id;
                          return _EndpointRow(
                            endpoint: ep,
                            isExpanded: isExpanded,
                            onTap: () {
                              setState(() {
                                _expandedEndpointId =
                                    isExpanded ? null : ep.id;
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<EndpointMetadata> _sortedAndFiltered(List<EndpointMetadata> endpoints) {
    var filtered = endpoints.toList();
    if (_filterMethod != 'all') {
      filtered = filtered
          .where((e) => e.httpMethod.toUpperCase() == _filterMethod)
          .toList();
    }
    switch (_sortBy) {
      case 'risk':
        filtered.sort((a, b) => b.riskScore.compareTo(a.riskScore));
      case 'path':
        filtered.sort((a, b) => a.path.compareTo(b.path));
      case 'method':
        filtered.sort((a, b) => a.httpMethod.compareTo(b.httpMethod));
    }
    return filtered;
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({
    required this.endpoint,
    required this.isExpanded,
    required this.onTap,
  });

  final EndpointMetadata endpoint;
  final bool isExpanded;
  final VoidCallback onTap;

  Color _methodColor(String method) {
    return switch (method.toUpperCase()) {
      'GET' => AppColors.success,
      'POST' => AppColors.info,
      'PUT' => AppColors.brandYellow,
      'DELETE' => AppColors.danger,
      _ => AppColors.textMuted,
    };
  }

  Color _riskColor(double score) {
    if (score >= 80) return AppColors.riskCritical;
    if (score >= 60) return AppColors.riskHigh;
    if (score >= 40) return AppColors.riskMedium;
    if (score >= 20) return AppColors.riskLow;
    return AppColors.riskInfo;
  }

  @override
  Widget build(BuildContext context) {
    final mc = _methodColor(endpoint.httpMethod);
    final rc = _riskColor(endpoint.riskScore);

    return Container(
      decoration: AppTheme.glassCard(),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // HTTP Method badge
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: mc.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      endpoint.httpMethod.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        color: mc,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Path
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          endpoint.path,
                          style: GoogleFonts.spaceMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          endpoint.handlerFunction,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Call counts
                  _CallCountChip(
                    icon: Icons.storage_rounded,
                    count: endpoint.dbCalls.length,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _CallCountChip(
                    icon: Icons.bolt_rounded,
                    count: endpoint.cacheCalls.length,
                    color: const Color(0xFFFAB1A0),
                  ),
                  const SizedBox(width: 8),
                  _CallCountChip(
                    icon: Icons.alt_route_rounded,
                    count: endpoint.serviceCalls.length,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 14),
                  // Risk score
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: rc.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${endpoint.riskScore.toInt()}',
                      style: TextStyle(
                        color: rc,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          // Expanded details
          if (isExpanded) _ExpandedDetails(endpoint: endpoint),
        ],
      ),
    );
  }
}

class _CallCountChip extends StatelessWidget {
  const _CallCountChip({
    required this.icon,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({required this.endpoint});

  final EndpointMetadata endpoint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          // Source file
          Row(
            children: [
              const Icon(Icons.code_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  endpoint.sourceFile,
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // DB Calls
          if (endpoint.dbCalls.isNotEmpty) ...[
            _SectionLabel(icon: Icons.storage_rounded, label: 'Database Calls'),
            ...endpoint.dbCalls.map(
              (db) => _DetailRow(
                leading: db.queryType,
                trailing: db.targetEntity,
                subtitle: db.isPaginated ? 'paginated' : null,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Cache Calls
          if (endpoint.cacheCalls.isNotEmpty) ...[
            _SectionLabel(icon: Icons.bolt_rounded, label: 'Cache Calls'),
            ...endpoint.cacheCalls.map(
              (cache) => _DetailRow(
                leading: cache.operation,
                trailing: cache.keyPattern,
                subtitle:
                    cache.ttlSeconds != null ? 'TTL: ${cache.ttlSeconds}s' : null,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Service Calls
          if (endpoint.serviceCalls.isNotEmpty) ...[
            _SectionLabel(
              icon: Icons.alt_route_rounded,
              label: 'Service Calls',
            ),
            ...endpoint.serviceCalls.map(
              (svc) => _DetailRow(
                leading: '${svc.httpMethod} ${svc.targetEndpoint}',
                trailing: svc.targetService,
                subtitle: svc.isAsync ? 'async' : null,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Queue Interactions
          if (endpoint.queueInteractions.isNotEmpty) ...[
            _SectionLabel(
              icon: Icons.alt_route_rounded,
              label: 'Queue Interactions',
            ),
            ...endpoint.queueInteractions.map(
              (q) => _DetailRow(
                leading: q.role,
                trailing: q.queueName,
                subtitle: q.messageType,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Risk Findings
          if (endpoint.riskFindings.isNotEmpty) ...[
            _SectionLabel(
              icon: Icons.warning_amber_rounded,
              label: 'Risk Findings',
            ),
            ...endpoint.riskFindings.map(
              (finding) => Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.riskHigh,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        finding,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.syne(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.leading,
    required this.trailing,
    this.subtitle,
  });

  final String leading;
  final String trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              leading,
              style: GoogleFonts.spaceMono(fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              trailing,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                color: AppColors.textSoft,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
