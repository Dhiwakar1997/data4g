import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/cosmic_scaffold.dart';
import '../../data/team_repository.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key, required this.inviteToken});

  final String inviteToken;

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _repo = TeamRepository();
  bool _joining = false;
  String? _error;
  bool _success = false;

  Future<void> _joinTeam() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await _repo.joinTeam(widget.inviteToken);
      setState(() {
        _joining = false;
        _success = true;
      });
    } catch (e) {
      setState(() {
        _joining = false;
        _error = 'Failed to join team. The invite may have expired or reached its usage limit.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicScaffold(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: AppTheme.glassCard(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _success ? Icons.check_circle_outline_rounded : Icons.group_add_rounded,
                    size: 56,
                    color: _success ? Colors.greenAccent : AppColors.brandYellow,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _success ? 'You\'re In!' : 'Team Invitation',
                    style: AppTheme.syne(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _success
                        ? 'You have successfully joined the team. Head to the workspace to start collaborating.'
                        : 'You\'ve been invited to join a team on DataForge. Click below to accept the invitation.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, height: 1.6),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (_success)
                    ElevatedButton.icon(
                      onPressed: () => context.go('/workspace/topology'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Go to Workspace'),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton(
                          onPressed: _joining ? null : _joinTeam,
                          child: _joining
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Accept Invitation'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
