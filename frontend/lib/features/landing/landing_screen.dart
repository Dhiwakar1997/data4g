import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cosmic_scaffold.dart';
import '../workspace/workspace_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicScaffold(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 36),
                  _buildHero(context),
                  const SizedBox(height: 48),
                  _buildSection(
                    kicker: 'Two-stage architecture',
                    title:
                        'Start with topology, then drill into component specs',
                    description:
                        'DataForge mirrors the base plan: first shape the high-level deployment graph, then configure the low-level compute, database, cache, orchestration, and networking details that drive cost.',
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: const [
                        _StageCard(
                          index: '01',
                          title: 'Project + topology',
                          points: [
                            'Pick a project from the menu bar and move between topologies.',
                            'Use the infinite browser canvas to place clients, servers, storage, gateways, and queues.',
                            'Connect nodes with edges to describe the real traffic path.',
                          ],
                        ),
                        _StageCard(
                          index: '02',
                          title: 'Specs + modeling',
                          points: [
                            'Size compute with CPU, RAM, GPU, autoscaling, Kubernetes, and Docker.',
                            'Design database entities, fields, PK/FK links, ratios, and storage growth.',
                            'Tune cache, load balancer, and CDN behavior from context-aware panels.',
                          ],
                        ),
                        _StageCard(
                          index: '03',
                          title: 'Compare + collaborate',
                          points: [
                            'Compare topologies across projects you can access.',
                            'Surface cost deltas, growth curves, and optimization hints.',
                            'Share full owner access or topology-specific member access.',
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildSection(
                    kicker: 'What the UI covers',
                    title:
                        'A browser-first workspace that can grow into tablets later',
                    description:
                        'The current build is optimized for desktop web while keeping patterns that translate cleanly to Android tablets and iPad layouts in future phases.',
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: const [
                        _FeatureCard(
                          icon: Icons.grid_view_rounded,
                          title: 'Infinite cosmic canvas',
                          description:
                              'Star-grid topology editing inspired by the existing DataForge HTML visual language.',
                        ),
                        _FeatureCard(
                          icon: Icons.storage_rounded,
                          title: 'Database design panel',
                          description:
                              'Entity cards, relationship ratios, and projected storage alongside cost signals.',
                        ),
                        _FeatureCard(
                          icon: Icons.memory_rounded,
                          title: 'Compute + orchestration',
                          description:
                              'CPU, RAM, GPU, autoscaling, Kubernetes clusters, Docker ports, and deployment structure.',
                        ),
                        _FeatureCard(
                          icon: Icons.auto_graph_rounded,
                          title: 'Consolidated dashboard',
                          description:
                              'Component costs, category mix, growth curves, and optimization hints for each project.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildSection(
                    kicker: 'Access model',
                    title:
                        'Owners and members work from the same project safely',
                    description:
                        'Project owners have access to every topology. Members can be invited into the project and then granted only the specific topology IDs that should be visible to them.',
                    child: Row(
                      children: const [
                        Expanded(
                          child: _AccessCard(
                            role: 'Owner',
                            description:
                                'Manage every topology, compare environments, invite members, and control access.',
                            badge: 'Full control',
                          ),
                        ),
                        SizedBox(width: 18),
                        Expanded(
                          child: _AccessCard(
                            role: 'Member',
                            description:
                                'Work only on the topologies explicitly shared inside the project.',
                            badge: 'Scoped access',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 42),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: AppTheme.glassCard(),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 16,
                      spacing: 16,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready to shape the current project?',
                              style: AppTheme.syne(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Open the browser workspace, connect to local or cloud endpoints through env config, and start iterating.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => context.go('/auth?mode=signup'),
                              icon: const Icon(Icons.rocket_launch_outlined),
                              label: const Text('Create Account'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => goToWorkspace(
                                context,
                                WorkspaceSection.topology,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Open Demo Workspace'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGlow(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.hub_rounded, color: AppColors.deepWine),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DataForge',
                    style: AppTheme.syne(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Topology and cost planning control room',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          children: [
            TextButton(
              onPressed: () => context.go('/auth'),
              child: const Text('Sign In'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/auth?mode=signup'),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandYellow.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.brandYellow.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Open source vision · browser-first · future tablet-ready',
              style: GoogleFonts.spaceMono(
                color: AppColors.brandYellow,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text.rich(
            TextSpan(
              text: 'Design ',
              children: [
                TextSpan(
                  text: 'data and infrastructure',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = AppTheme.accentGlow().createShader(
                        const Rect.fromLTWH(0, 0, 360, 70),
                      ),
                  ),
                ),
                const TextSpan(text: ' before you deploy.'),
              ],
            ),
            style: AppTheme.syne(
              fontSize: 58,
              fontWeight: FontWeight.w800,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 18),
          const SizedBox(
            width: 760,
            child: Text(
              'DataForge helps teams move from a high-level project topology to deep component configuration and cost estimation. Clients, servers, storages, queues, gateways, schemas, Kubernetes clusters, and Docker containers all live inside the same collaborative project workspace.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 17,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _HeroTag(label: 'Projects + topologies'),
              _HeroTag(label: 'Compute + GPU sizing'),
              _HeroTag(label: 'DB models + ratios'),
              _HeroTag(label: 'Kubernetes + Docker'),
              _HeroTag(label: 'Dashboard + comparisons'),
              _HeroTag(label: 'Owner/member access'),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go('/auth?mode=signup'),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Start in the Workspace'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    goToWorkspace(context, WorkspaceSection.topology),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Preview the Demo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String kicker,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker.toUpperCase(),
          style: GoogleFonts.spaceMono(
            color: AppColors.brandYellow,
            letterSpacing: 1.4,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppTheme.syne(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 820,
          child: Text(
            description,
            style: const TextStyle(color: AppColors.textMuted, height: 1.65),
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.index,
    required this.title,
    required this.points,
  });

  final String index;
  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassCard(color: AppColors.panelSoft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              index,
              style: AppTheme.syne(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.brandYellow.withValues(alpha: 0.5),
              ),
            ),
            Text(
              title,
              style: AppTheme.syne(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ...points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.arrow_right_rounded,
                        color: AppColors.brandYellow,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: AppTheme.glassCard(color: AppColors.panelSoft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brandYellow, size: 28),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTheme.syne(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: AppColors.textMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.role,
    required this.description,
    required this.badge,
  });

  final String role;
  final String description;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.olive),
            ),
            child: Text(
              badge,
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: AppColors.brandYellow,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            role,
            style: AppTheme.syne(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
        ],
      ),
    );
  }
}
