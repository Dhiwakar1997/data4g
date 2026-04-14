import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/cosmic_scaffold.dart';
import '../../data/team_repository.dart';
import '../../models/team_models.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _repo = TeamRepository();
  List<Team> _teams = [];
  List<TeamInvite> _invites = [];
  bool _loading = true;
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _loading = true);
    try {
      final teams = await _repo.listTeams();
      setState(() {
        _teams = teams;
        _loading = false;
        if (_selectedTeamId == null && teams.isNotEmpty) {
          _selectedTeamId = teams.first.teamId;
          _loadInvites(teams.first.teamId);
        }
      });
    } catch (_) {
      // Demo fallback
      setState(() {
        _teams = [
          Team(
            teamId: 'team-demo-1',
            name: 'Platform Engineering',
            ownerId: 'user-1',
            memberIds: const ['user-1', 'user-2', 'user-3'],
            createdAt: '2026-01-15',
          ),
          Team(
            teamId: 'team-demo-2',
            name: 'Backend Squad',
            ownerId: 'user-1',
            memberIds: const ['user-1', 'user-4'],
            createdAt: '2026-02-20',
          ),
        ];
        _loading = false;
        _selectedTeamId = _teams.first.teamId;
      });
    }
  }

  Future<void> _loadInvites(String teamId) async {
    try {
      final invites = await _repo.listInvites(teamId);
      setState(() => _invites = invites);
    } catch (_) {
      setState(() => _invites = []);
    }
  }

  Future<void> _createTeam() async {
    final name = await _showNameDialog('Create Team', '');
    if (name == null || name.isEmpty) return;
    try {
      await _repo.createTeam(name);
      await _loadTeams();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create team')),
        );
      }
    }
  }

  Future<void> _deleteTeam(String teamId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panelSoft,
        title: const Text('Delete Team'),
        content: const Text('This action cannot be undone. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.deleteTeam(teamId);
      setState(() {
        _selectedTeamId = null;
        _invites = [];
      });
      await _loadTeams();
    } catch (_) {}
  }

  Future<void> _generateInvite(String teamId) async {
    try {
      final invite = await _repo.generateInvite(teamId, expiresInDays: 7);
      setState(() => _invites = [..._invites, invite]);
      if (mounted) {
        _showInviteTokenDialog(invite.inviteToken);
      }
    } catch (_) {
      // Demo fallback
      if (mounted) {
        _showInviteTokenDialog('demo-invite-token-${DateTime.now().millisecondsSinceEpoch}');
      }
    }
  }

  void _showInviteTokenDialog(String token) {
    final url = '${Uri.base.origin}/teams/join/$token';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panelSoft,
        title: const Text('Invite Link Generated'),
        content: SelectableText(url, style: GoogleFonts.spaceMono(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy & Close'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNameDialog(String title, String initial) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panelSoft,
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Team name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeam = _selectedTeamId == null
        ? null
        : _teams.where((t) => t.teamId == _selectedTeamId).firstOrNull;

    return Scaffold(
      body: CosmicScaffold(
        padding: const EdgeInsets.all(28),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Team Management',
                        style: AppTheme.syne(fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _createTeam,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Team'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Team list sidebar
                        SizedBox(
                          width: 280,
                          child: Container(
                            decoration: AppTheme.glassCard(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _teams.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                              itemBuilder: (_, i) {
                                final team = _teams[i];
                                final selected = team.teamId == _selectedTeamId;
                                return ListTile(
                                  selected: selected,
                                  selectedTileColor: AppColors.brandYellow.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  leading: const Icon(Icons.group_rounded, color: AppColors.brandYellow),
                                  title: Text(team.name),
                                  subtitle: Text(
                                    '${team.memberCount} members',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                  onTap: () {
                                    setState(() => _selectedTeamId = team.teamId);
                                    _loadInvites(team.teamId);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Detail panel
                        Expanded(
                          child: selectedTeam == null
                              ? Center(
                                  child: Text(
                                    'Select a team to view details',
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                )
                              : _TeamDetailPanel(
                                  team: selectedTeam,
                                  invites: _invites,
                                  onGenerateInvite: () => _generateInvite(selectedTeam.teamId),
                                  onDelete: () => _deleteTeam(selectedTeam.teamId),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TeamDetailPanel extends StatelessWidget {
  const _TeamDetailPanel({
    required this.team,
    required this.invites,
    required this.onGenerateInvite,
    required this.onDelete,
  });

  final Team team;
  final List<TeamInvite> invites;
  final VoidCallback onGenerateInvite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      team.name,
                      style: AppTheme.syne(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Created ${team.createdAt}  ·  Owner: ${team.ownerId}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Members
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Members (${team.memberCount})',
                      style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: onGenerateInvite,
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('Invite'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...team.memberIds.map(
                  (memberId) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.brandYellow.withValues(alpha: 0.15),
                          child: Text(
                            memberId.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: AppColors.brandYellow, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(memberId),
                        if (memberId == team.ownerId) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.olive.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.olive),
                            ),
                            child: Text(
                              'Owner',
                              style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.brandYellow),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Invites
          if (invites.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Invites',
                    style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...invites.map(
                    (invite) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            invite.isActive ? Icons.link_rounded : Icons.link_off_rounded,
                            size: 18,
                            color: invite.isActive ? AppColors.brandYellow : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              invite.inviteToken,
                              style: GoogleFonts.spaceMono(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Used ${invite.useCount}${invite.maxUses != null ? '/${invite.maxUses}' : ''}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          if (invite.expiresAt != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              'Exp: ${invite.expiresAt}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
