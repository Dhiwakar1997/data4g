import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/cosmic_scaffold.dart';
import '../../data/dataforge_repository.dart';
import '../../models/share_models.dart';

class SharedView extends StatefulWidget {
  const SharedView({super.key, required this.shareToken});

  final String shareToken;

  @override
  State<SharedView> createState() => _SharedViewState();
}

class _SharedViewState extends State<SharedView> {
  bool _loading = true;
  ShareLink? _link;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSharedData();
  }

  Future<void> _loadSharedData() async {
    try {
      final repo = DataForgeRepository();
      final link = await repo.getShareLink(widget.shareToken);
      setState(() {
        _link = link;
        _loading = false;
      });
    } catch (_) {
      // Demo fallback
      setState(() {
        _link = ShareLink(
          id: 'shared-demo',
          projectId: 'demo-project',
          token: widget.shareToken,
          readOnly: true,
          createdBy: 'demo-user',
          createdAt: '2026-04-01',
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicScaffold(
        padding: const EdgeInsets.all(28),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildSharedContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(36),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: AppTheme.glassCard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Link Expired or Invalid',
              style: AppTheme.syne(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'This shared link is no longer available. It may have expired or been revoked by the owner.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedContent() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassCard(),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGlow(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hub_rounded, color: AppColors.deepWine, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DataForge — Shared View',
                        style: AppTheme.syne(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Read-only · Project ${_link?.projectId ?? ''}',
                        style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandYellow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded, size: 14, color: AppColors.brandYellow),
                        const SizedBox(width: 6),
                        Text(
                          'Read-only',
                          style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.brandYellow),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Topology placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.glassCard(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_tree_rounded,
                        size: 64,
                        color: AppColors.brandYellow.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Shared Topology View',
                        style: AppTheme.syne(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The topology canvas and dashboard for this shared project\nwill render here with read-only access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, height: 1.6),
                      ),
                      if (_link?.topologyId != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Topology: ${_link!.topologyId}',
                          style: GoogleFonts.spaceMono(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Shared by: ${_link?.createdBy ?? 'unknown'}  ·  Created: ${_link?.createdAt ?? ''}',
                        style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
