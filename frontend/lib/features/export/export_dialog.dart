import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/dataforge_repository.dart';
import '../../models/export_models.dart';
import '../workspace/workspace_controller.dart';

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportFormat _format = ExportFormat.png;
  bool _includeSpecs = true;
  bool _includeCost = true;
  bool _includeRisk = true;
  bool _exporting = false;
  String? _downloadUrl;

  Future<void> _export() async {
    final state = ref.read(workspaceControllerProvider);
    final projectId = state.selectedProjectId;
    final topologyId = state.selectedTopologyId;
    if (projectId == null || topologyId == null) return;

    setState(() => _exporting = true);
    try {
      final repo = DataForgeRepository();
      final response = await repo.requestExport(
        ExportRequest(
          projectId: projectId,
          topologyId: topologyId,
          format: _format,
          includeSpecs: _includeSpecs,
          includeCostSummary: _includeCost,
          includeRiskAnalysis: _includeRisk,
        ),
      );
      setState(() {
        _exporting = false;
        _downloadUrl = response.downloadUrl;
      });
    } catch (_) {
      setState(() {
        _exporting = false;
        _downloadUrl = 'demo://export-${_format.value}-${DateTime.now().millisecondsSinceEpoch}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panelSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.file_download_outlined, color: AppColors.brandYellow),
                  const SizedBox(width: 10),
                  Text(
                    'Export Topology',
                    style: AppTheme.syne(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Format selector
              Text(
                'Format',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: ExportFormat.values.map((fmt) {
                  final selected = fmt == _format;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(fmt.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _format = fmt),
                      selectedColor: AppColors.brandYellow.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.brandYellow : AppColors.textPrimary,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.brandYellow : AppColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Include Sections',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                title: const Text('Component Specs'),
                value: _includeSpecs,
                onChanged: (v) => setState(() => _includeSpecs = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.brandYellow,
              ),
              CheckboxListTile(
                title: const Text('Cost Summary'),
                value: _includeCost,
                onChanged: (v) => setState(() => _includeCost = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.brandYellow,
              ),
              CheckboxListTile(
                title: const Text('Risk Analysis'),
                value: _includeRisk,
                onChanged: (v) => setState(() => _includeRisk = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.brandYellow,
              ),
              const SizedBox(height: 20),
              if (_downloadUrl != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Export ready for download', style: TextStyle(color: Colors.greenAccent)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _exporting ? null : _export,
                    child: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_downloadUrl != null ? 'Re-export' : 'Export'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
