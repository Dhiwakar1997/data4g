import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/spec_models.dart';
import '../workspace/workspace_controller.dart';

/// Drill-down view for a database component.
///
/// Shows entity-relationship diagram, field types, PK/FK indicators,
/// and storage projection sidebar.
class DatabaseDrilldownView extends ConsumerWidget {
  const DatabaseDrilldownView({super.key, required this.componentId});

  final String componentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final component = state.selectedTopology?.components.firstWhere(
      (c) => c.id == componentId,
      orElse: () => state.selectedTopology!.components.first,
    );
    final spec = state.dbSpecs[componentId];
    final projection = state.storageProjections[componentId];

    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        title: Text(component?.name ?? 'Database'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: spec == null
              ? _EmptyState(componentName: component?.name ?? 'Database')
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
                                _EntityList(spec: spec),
                                const SizedBox(height: 20),
                                _StorageSidebar(
                                    spec: spec, projection: projection),
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
                                      _EntityList(spec: spec),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 340,
                                child: _StorageSidebar(
                                    spec: spec, projection: projection),
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
            const Icon(Icons.storage_rounded,
                size: 48, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'No spec configured for $componentName',
              style: AppTheme.syne(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open the Specs tab to configure this database component.',
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
  final DbModelSpec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.storage_rounded, color: AppColors.success, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${spec.databaseId} · Entity Diagram',
                style: AppTheme.syne(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${spec.entities.length} entities · ${spec.relationships.length} relationships',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntityList extends StatelessWidget {
  const _EntityList({required this.spec});
  final DbModelSpec spec;

  @override
  Widget build(BuildContext context) {
    if (spec.entities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassCard(),
        child: const Text(
          'No entities defined yet.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      children: spec.entities.map((entity) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _EntityCard(entity: entity),
        );
      }).toList(),
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({required this.entity});
  final EntityModel entity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart_rounded,
                  size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                entity.name,
                style: AppTheme.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (entity.isCentral) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CENTRAL',
                    style: TextStyle(
                      color: AppColors.brandYellow,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${entity.fields.length} fields',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (entity.description != null) ...[
            const SizedBox(height: 6),
            Text(
              entity.description!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          // Fields table
          ...entity.fields.map((field) {
            final isPk = field.key.keyType == 'primary';
            final isFk = field.key.keyType == 'foreign';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (isPk)
                    const _FieldBadge(
                        label: 'PK', color: AppColors.brandYellow)
                  else if (isFk)
                    const _FieldBadge(label: 'FK', color: AppColors.info)
                  else
                    const SizedBox(width: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      field.name,
                      style: GoogleFonts.spaceMono(fontSize: 13),
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
                      field.type,
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (field.indexed) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: AppColors.brandYellow,
                    ),
                  ],
                  if (field.required) ...[
                    const SizedBox(width: 6),
                    const Text(
                      '*',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          // Indexes
          if (entity.indexes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Indexes',
              style: AppTheme.syne(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...entity.indexes.map(
              (idx) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 14, color: AppColors.brandYellow),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${idx.name} (${idx.fieldIds.join(', ')})',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Text(
                      idx.unique ? 'unique' : 'non-unique',
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 11,
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

class _FieldBadge extends StatelessWidget {
  const _FieldBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StorageSidebar extends StatelessWidget {
  const _StorageSidebar({required this.spec, this.projection});
  final DbModelSpec spec;
  final DbStorageProjection? projection;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

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
            'Storage Projection',
            style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _SidebarRow(label: 'Database', value: spec.databaseId),
          _SidebarRow(
              label: 'Entities', value: '${spec.entities.length}'),
          _SidebarRow(
              label: 'Base Users', value: '${spec.baseUserCount}'),
          _SidebarRow(
              label: 'Relationships',
              value: '${spec.relationships.length}'),
          if (projection != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Projected Storage',
              style: AppTheme.syne(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _SidebarRow(
              label: 'Total Data',
              value: _formatBytes(projection!.totalDataBytes),
            ),
            _SidebarRow(
              label: 'Index Overhead',
              value: _formatBytes(projection!.totalIndexBytes),
            ),
            _SidebarRow(
              label: 'WAL/Journal',
              value: _formatBytes(projection!.walJournalBytes),
            ),
            _SidebarRow(
              label: 'Total',
              value: _formatBytes(projection!.totalStorageBytes),
            ),
            _SidebarRow(
              label: 'Total Records',
              value: '${projection!.totalRecords}',
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Per Entity',
              style: AppTheme.syne(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...projection!.perEntity.map(
              (ep) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ep.entityName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      _formatBytes(ep.totalSizeBytes),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (projection == null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Storage projection not yet computed.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
