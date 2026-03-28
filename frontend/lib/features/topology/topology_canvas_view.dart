import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/topology_models.dart';
import '../workspace/workspace_controller.dart';

class TopologyCanvasView extends ConsumerStatefulWidget {
  const TopologyCanvasView({
    super.key,
    required this.state,
    this.isFullscreenMode = false,
  });

  final WorkspaceState state;
  final bool isFullscreenMode;

  @override
  ConsumerState<TopologyCanvasView> createState() => _TopologyCanvasViewState();
}

class _TopologyCanvasViewState extends ConsumerState<TopologyCanvasView> {
  final TransformationController _transformationController =
      TransformationController();
  final Map<String, Offset> _draftPositions = <String, Offset>{};
  bool _linkMode = false;

  @override
  void initState() {
    super.initState();
    _syncPositions();
  }

  @override
  void didUpdateWidget(covariant TopologyCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedTopologyId != widget.state.selectedTopologyId ||
        oldWidget.state.selectedTopology?.components.length !=
            widget.state.selectedTopology?.components.length) {
      _syncPositions();
    }
  }

  void _syncPositions() {
    _draftPositions
      ..clear()
      ..addEntries(
        (widget.state.selectedTopology?.components ??
                const <TopologyComponent>[])
            .map(
              (component) => MapEntry(
                component.id,
                Offset(component.canvasX, component.canvasY),
              ),
            ),
      );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topology = widget.state.selectedTopology;
    if (topology == null) {
      return _NoTopology(onCreateTopology: _showCreateTopologyDialog);
    }

    final controller = ref.read(workspaceControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1180;
        final children = [
          Expanded(
            child: Container(
              decoration: AppTheme.glassCard(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: topology.id,
                          decoration: const InputDecoration(
                            labelText: 'Topology',
                          ),
                          items: widget.state.topologies
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectTopology(value);
                            }
                          },
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showCreateTopologyDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New Topology'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => controller.collapseActiveTopology(),
                        icon: const Icon(Icons.compress_rounded),
                        label: const Text('Collapse'),
                      ),
                      if (!widget.isFullscreenMode)
                        OutlinedButton.icon(
                          onPressed: _openFullscreenEditor,
                          icon: const Icon(Icons.open_in_full_rounded),
                          label: const Text('Full Screen'),
                        ),
                      ...DeploymentMode.values.map(
                        (mode) => ChoiceChip(
                          selected: topology.deploymentMode == mode,
                          label: Text(mode.label),
                          onSelected: (_) => controller.setDeploymentMode(mode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ComponentType.values.map((type) {
                      return ActionChip(
                        avatar: Icon(_componentIcon(type), size: 18),
                        label: Text(type.label),
                        onPressed: () => controller.addComponent(type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.spaceBlack.withValues(alpha: 0.72),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: InteractiveViewer(
                                transformationController:
                                    _transformationController,
                                minScale: 0.35,
                                maxScale: 2.8,
                                constrained: false,
                                boundaryMargin: const EdgeInsets.all(600),
                                child: SizedBox(
                                  width: 2200,
                                  height: 1400,
                                  child: Stack(
                                    children: [
                                      CustomPaint(
                                        size: const Size(2200, 1400),
                                        painter: _TopologyBackdropPainter(),
                                      ),
                                      CustomPaint(
                                        size: const Size(2200, 1400),
                                        painter: _EdgePainter(
                                          topology: topology,
                                          positions: _draftPositions,
                                          selectedComponentId:
                                              widget.state.selectedComponentId,
                                        ),
                                      ),
                                      ...topology.components.map(
                                        (component) => _buildNode(component),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 18,
                              bottom: 18,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.panelSoft.withValues(
                                    alpha: 0.92,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _linkMode
                                          ? 'Click another node to connect'
                                          : 'Select a node to inspect or drag to reposition',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Scroll to zoom · drag background to pan',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: compact ? 0 : 20, height: compact ? 20 : 0),
          SizedBox(
            width: compact ? double.infinity : 340,
            child: _TopologyInspector(
              state: widget.state,
              linkMode: _linkMode,
              onToggleLinkMode: () {
                setState(() {
                  _linkMode = !_linkMode;
                });
              },
            ),
          ),
        ];

        return compact
            ? Column(children: children)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
      },
    );
  }

  Widget _buildNode(TopologyComponent component) {
    final controller = ref.read(workspaceControllerProvider.notifier);
    final position =
        _draftPositions[component.id] ??
        Offset(component.canvasX, component.canvasY);
    final isSelected = widget.state.selectedComponentId == component.id;
    final nodeColor = _componentColor(component.type);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () async {
          if (_linkMode && widget.state.selectedComponentId != null) {
            await controller.connectSelectedTo(component.id);
            if (mounted) {
              setState(() {
                _linkMode = false;
              });
            }
            return;
          }
          await controller.selectComponent(component.id);
        },
        onPanUpdate: (details) {
          setState(() {
            _draftPositions[component.id] = position + details.delta;
          });
        },
        onPanEnd: (_) async {
          final draft = _draftPositions[component.id] ?? position;
          await controller.updateComponentPosition(component.id, draft);
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: component.enabled ? 1 : 0.45,
          child: Container(
            width: 166,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.panelSoft.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? AppColors.brandYellow
                    : nodeColor.withValues(alpha: 0.6),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: nodeColor.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: nodeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _componentIcon(component.type),
                        color: nodeColor,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.radio_button_checked_rounded,
                        color: AppColors.brandYellow,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  component.name,
                  style: AppTheme.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  component.type.label,
                  style: GoogleFonts.spaceMono(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  component.location.region,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateTopologyDialog() async {
    final nameController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Topology'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Topology name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  return;
                }
                await ref
                    .read(workspaceControllerProvider.notifier)
                    .createTopology(nameController.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _openFullscreenEditor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _TopologyFullscreenPage(),
      ),
    );
  }
}

class _TopologyInspector extends ConsumerWidget {
  const _TopologyInspector({
    required this.state,
    required this.linkMode,
    required this.onToggleLinkMode,
  });

  final WorkspaceState state;
  final bool linkMode;
  final VoidCallback onToggleLinkMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final component = state.selectedComponent;
    final controller = ref.read(workspaceControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: component == null
                  ? const _InspectorPlaceholder()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _componentIcon(component.type),
                              color: _componentColor(component.type),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                component.name,
                                style: AppTheme.syne(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InspectorMeta(
                          label: 'Component',
                          value: component.type.label,
                        ),
                        _InspectorMeta(
                          label: 'Region',
                          value: component.location.region,
                        ),
                        _InspectorMeta(
                          label: 'Provider',
                          value: component.cloudProvider.label,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onToggleLinkMode,
                            icon: Icon(
                              linkMode
                                  ? Icons.link_off_rounded
                                  : Icons.link_rounded,
                            ),
                            label: Text(
                              linkMode
                                  ? 'Cancel Linking'
                                  : 'Connect From Selected',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                controller.removeSelectedComponent(),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Remove Component'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Quick edit',
                          style: AppTheme.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: component.name,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                          ),
                          onFieldSubmitted: (value) =>
                              controller.updateSelectedComponent(name: value),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: component.location.region,
                          decoration: const InputDecoration(
                            labelText: 'Region',
                          ),
                          items: state.regions
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.updateSelectedComponent(region: value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CloudProvider>(
                          isExpanded: true,
                          initialValue: component.cloudProvider,
                          decoration: const InputDecoration(
                            labelText: 'Cloud provider',
                          ),
                          items: CloudProvider.values
                              .map(
                                (provider) => DropdownMenuItem(
                                  value: provider,
                                  child: Text(
                                    provider.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.updateSelectedComponent(
                                cloudProvider: value,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 18),
                        Text(
                          'Topology access reminder',
                          style: AppTheme.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Owners can see every topology in the project. Members only see the topology IDs that are shared with them in settings.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _TopologyFullscreenPage extends ConsumerWidget {
  const _TopologyFullscreenPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final topologyName = state.selectedTopology?.name ?? 'Topology Editor';

    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        title: Text('$topologyName · Full Screen'),
        actions: [
          IconButton(
            tooltip: 'Exit full screen',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_fullscreen_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: TopologyCanvasView(state: state, isFullscreenMode: true),
        ),
      ),
    );
  }
}

class _InspectorMeta extends StatelessWidget {
  const _InspectorMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _InspectorPlaceholder extends StatelessWidget {
  const _InspectorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topology Inspector',
          style: AppTheme.syne(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select a component on the canvas to rename it, adjust region/provider, connect it to another node, or remove it from the active topology.',
          style: TextStyle(color: AppColors.textMuted, height: 1.6),
        ),
      ],
    );
  }
}

class _NoTopology extends StatelessWidget {
  const _NoTopology({required this.onCreateTopology});

  final VoidCallback onCreateTopology;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.glassCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hub_outlined,
                size: 54,
                color: AppColors.brandYellow,
              ),
              const SizedBox(height: 18),
              Text(
                'Create a topology to begin',
                style: AppTheme.syne(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Topologies are the editable high-level designs inside each project. Add one and start placing clients, servers, databases, queues, and storage nodes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onCreateTopology,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Topology'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopologyBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    const grid = 56.0;
    for (double x = 0; x <= size.width; x += grid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += grid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final random = math.Random(42);
    for (var i = 0; i < 220; i++) {
      final offset = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = 0.8 + random.nextDouble() * 1.8;
      canvas.drawCircle(
        offset,
        radius,
        Paint()..color = AppColors.brandYellow.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.topology,
    required this.positions,
    required this.selectedComponentId,
  });

  final TopologyModel topology;
  final Map<String, Offset> positions;
  final String? selectedComponentId;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in topology.edges) {
      final source = positions[edge.sourceComponentId];
      final target = positions[edge.targetComponentId];
      if (source == null || target == null) {
        continue;
      }

      final start = source + const Offset(83, 52);
      final end = target + const Offset(83, 52);
      final isSelected =
          edge.sourceComponentId == selectedComponentId ||
          edge.targetComponentId == selectedComponentId;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + 120,
          start.dy,
          end.dx - 120,
          end.dy,
          end.dx,
          end.dy,
        );

      final paint = Paint()
        ..color = (isSelected ? AppColors.brandYellow : AppColors.info)
            .withValues(alpha: isSelected ? 0.75 : 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) {
    return oldDelegate.topology != topology ||
        oldDelegate.positions != positions ||
        oldDelegate.selectedComponentId != selectedComponentId;
  }
}

IconData _componentIcon(ComponentType type) {
  return switch (type) {
    ComponentType.compute => Icons.memory_rounded,
    ComponentType.database => Icons.storage_rounded,
    ComponentType.cache => Icons.bolt_rounded,
    ComponentType.loadBalancer => Icons.balance_rounded,
    ComponentType.cdn => Icons.public_rounded,
    ComponentType.client => Icons.devices_rounded,
    ComponentType.objectStore => Icons.inventory_2_rounded,
    ComponentType.messageQueue => Icons.alt_route_rounded,
  };
}

Color _componentColor(ComponentType type) {
  return switch (type) {
    ComponentType.compute => AppColors.info,
    ComponentType.database => AppColors.success,
    ComponentType.cache => const Color(0xFFFAB1A0),
    ComponentType.loadBalancer => const Color(0xFFA29BFE),
    ComponentType.cdn => const Color(0xFF55EFC4),
    ComponentType.client => AppColors.textMuted,
    ComponentType.objectStore => AppColors.brandYellow,
    ComponentType.messageQueue => const Color(0xFFFF8AD8),
  };
}
