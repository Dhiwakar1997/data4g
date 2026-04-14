import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/dataforge_repository.dart';
import '../../models/share_models.dart';
import '../workspace/workspace_controller.dart';

class ShareDialog extends ConsumerStatefulWidget {
  const ShareDialog({super.key});

  @override
  ConsumerState<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends ConsumerState<ShareDialog> {
  bool _loading = false;
  List<ShareLink> _links = [];
  bool _shareTopologyOnly = false;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final state = ref.read(workspaceControllerProvider);
    final projectId = state.selectedProjectId;
    if (projectId == null) return;

    setState(() => _loading = true);
    try {
      final repo = DataForgeRepository();
      final links = await repo.listShareLinks(projectId);
      setState(() {
        _links = links;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _createLink() async {
    final state = ref.read(workspaceControllerProvider);
    final projectId = state.selectedProjectId;
    if (projectId == null) return;

    setState(() => _loading = true);
    try {
      final repo = DataForgeRepository();
      final link = await repo.createShareLink(
        projectId: projectId,
        topologyId: _shareTopologyOnly ? state.selectedTopologyId : null,
      );
      setState(() {
        _links = [..._links, link];
        _loading = false;
      });
    } catch (_) {
      // Demo fallback
      final demoLink = ShareLink(
        id: 'share-${DateTime.now().millisecondsSinceEpoch}',
        projectId: projectId,
        topologyId: _shareTopologyOnly ? state.selectedTopologyId : null,
        token: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        readOnly: true,
        createdBy: 'current-user',
        createdAt: DateTime.now().toIso8601String(),
      );
      setState(() {
        _links = [..._links, demoLink];
        _loading = false;
      });
    }
  }

  String _shareUrl(ShareLink link) {
    return '${Uri.base.origin}/shared/${link.token}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panelSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.share_rounded, color: AppColors.brandYellow),
                  const SizedBox(width: 10),
                  Text(
                    'Share Project',
                    style: AppTheme.syne(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Options
              CheckboxListTile(
                title: const Text('Share current topology only'),
                subtitle: const Text(
                  'Otherwise shares the entire project',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                value: _shareTopologyOnly,
                onChanged: (v) => setState(() => _shareTopologyOnly = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.brandYellow,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loading ? null : _createLink,
                icon: const Icon(Icons.add_link, size: 18),
                label: const Text('Generate Share Link'),
              ),
              const SizedBox(height: 20),
              if (_links.isNotEmpty) ...[
                Text(
                  'Active Links',
                  style: AppTheme.syne(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _links.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final link = _links[i];
                      final url = _shareUrl(link);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.panelSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    url,
                                    style: GoogleFonts.spaceMono(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    link.topologyId != null
                                        ? 'Topology only · Read-only'
                                        : 'Full project · Read-only',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              tooltip: 'Copy link',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: url));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Link copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (_loading && _links.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
