import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/dataforge_repository.dart';
import '../../models/scan_models.dart';

/// Owner-only card for managing project-scoped API keys that the local
/// `data4g-mcp` server uses to ingest scans. Plaintext is shown exactly
/// once at creation — after that we only surface `last_four` + label.
class ScanIntegrationCard extends StatefulWidget {
  const ScanIntegrationCard({
    super.key,
    required this.projectId,
    required this.isOwner,
    this.usingDemoData = false,
  });

  final String projectId;
  final bool isOwner;
  final bool usingDemoData;

  @override
  State<ScanIntegrationCard> createState() => _ScanIntegrationCardState();
}

class _ScanIntegrationCardState extends State<ScanIntegrationCard> {
  final DataForgeRepository _repo = DataForgeRepository();
  final TextEditingController _labelCtrl = TextEditingController();

  List<ProjectApiKeySummary> _keys = const [];
  ScanStatus _status = ScanStatus.empty;
  bool _loading = true;
  String? _error;
  ProjectApiKeyCreated? _justCreated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ScanIntegrationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _load();
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.usingDemoData) {
      setState(() {
        _loading = false;
        _error = null;
        _keys = const [];
        _status = ScanStatus.empty;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        if (widget.isOwner) _repo.listApiKeys(widget.projectId),
        _repo.fetchScanStatus(widget.projectId),
      ]);
      if (!mounted) return;
      setState(() {
        _keys = widget.isOwner
            ? results[0] as List<ProjectApiKeySummary>
            : const [];
        _status = (widget.isOwner ? results[1] : results[0]) as ScanStatus;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load: $err';
      });
    }
  }

  Future<void> _createKey() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;
    setState(() => _loading = true);
    try {
      final created = await _repo.createApiKey(widget.projectId, label: label);
      _labelCtrl.clear();
      if (!mounted) return;
      setState(() => _justCreated = created);
      await _load();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Create failed: $err';
      });
    }
  }

  Future<void> _revoke(ProjectApiKeySummary key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Revoke API key?'),
        content: Text(
          'Revoking "${key.label}" will immediately stop any agent sessions '
          'that use this key. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.revokeApiKey(widget.projectId, key.keyId);
      await _load();
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = 'Revoke failed: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Integration',
            style: AppTheme.syne(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Install `data4g-mcp` locally, point your AI agent at it, then '
            'ask the agent to sync this repo. Ingestion is authenticated '
            'with the project-scoped API keys below — humans never upload.',
            style: TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 16),
          _buildStatusStrip(),
          const SizedBox(height: 18),
          if (widget.usingDemoData)
            const _NoteBanner(
              color: AppColors.info,
              text:
                  'Demo mode: scan status and API keys are stubbed. Switch to a live backend to manage real keys.',
            )
          else if (!widget.isOwner)
            const _NoteBanner(
              color: AppColors.info,
              text:
                  'Only project owners can mint or revoke API keys. Ask an owner if you need a new key for your agent.',
            )
          else ...[
            _buildKeyList(),
            const SizedBox(height: 14),
            _buildCreateForm(),
          ],
          if (_justCreated != null) ...[
            const SizedBox(height: 14),
            _PlaintextKeyCallout(
              created: _justCreated!,
              onDismiss: () => setState(() => _justCreated = null),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _NoteBanner(color: AppColors.danger, text: _error!),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusStrip() {
    if (_loading && !widget.usingDemoData) {
      return const SizedBox(
        height: 32,
        child: Center(child: LinearProgressIndicator(minHeight: 2)),
      );
    }
    final last = _status.lastSync;
    final active = _status.activeSessions;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatusPill(
          label: 'Last sync',
          value: last == null ? 'Never' : _formatTime(last.syncedAt),
          tone: last == null ? AppColors.textMuted : AppColors.success,
        ),
        if (last != null) ...[
          _StatusPill(
            label: 'Endpoints',
            value: '${last.endpointsSynced}',
          ),
          _StatusPill(
            label: 'Risks',
            value: '${last.riskFindingsCount}',
            tone: last.riskFindingsCount > 0 ? AppColors.brandYellow : null,
          ),
        ],
        _StatusPill(
          label: 'Active sessions',
          value: '${active.length}',
          tone: active.isEmpty ? null : AppColors.info,
        ),
      ],
    );
  }

  Widget _buildKeyList() {
    if (_keys.isEmpty) {
      return const _NoteBanner(
        color: AppColors.brandYellow,
        text:
            'No API keys yet. Create one below and set it as DATA4G_API_KEY '
            'in the shell that launches your AI agent.',
      );
    }
    return Column(
      children: _keys.map((k) => _ApiKeyTile(
            summary: k,
            onRevoke: () => _revoke(k),
          )).toList(),
    );
  }

  Widget _buildCreateForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Label for new key',
              hintText: 'e.g. "Claude Code - Dhiwakar\'s Mac"',
            ),
            enabled: _keys.length < 2,
            onSubmitted: (_) => _createKey(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _keys.length < 2 ? _createKey : null,
          icon: const Icon(Icons.key_rounded),
          label: Text(
            _keys.length < 2 ? 'Create key' : 'Max 2 keys',
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

class _ApiKeyTile extends StatelessWidget {
  const _ApiKeyTile({required this.summary, required this.onRevoke});

  final ProjectApiKeySummary summary;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.label,
                  style: AppTheme.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'd4g_…${summary.lastFour}  •  '
                  'last used ${summary.lastUsedAt == null ? 'never' : _ago(summary.lastUsedAt!)}',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRevoke,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Revoke'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PlaintextKeyCallout extends StatelessWidget {
  const _PlaintextKeyCallout({required this.created, required this.onDismiss});

  final ProjectApiKeyCreated created;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.brandYellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Copy this key now — it won\'t be shown again',
                  style: AppTheme.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Hide',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    created.plaintextKey,
                    style: GoogleFonts.spaceMono(fontSize: 13),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: created.plaintextKey),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API key copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Export it in the shell that launches your agent:',
            style: TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              'export DATA4G_API_KEY=${created.plaintextKey}',
              style: GoogleFonts.spaceMono(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: AppTheme.syne(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NoteBanner extends StatelessWidget {
  const _NoteBanner({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: const TextStyle(height: 1.6)),
    );
  }
}
