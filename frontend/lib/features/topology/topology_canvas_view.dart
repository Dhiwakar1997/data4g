import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auto_layout_engine.dart';
import '../../models/topology_models.dart';
import '../workspace/workspace_controller.dart';
import 'topology_edge_painter.dart';
import 'topology_node_widget.dart';

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
  final AutoLayoutEngine _layoutEngine = AutoLayoutEngine();
  LayoutResult? _layoutResult;
  bool _linkMode = false;
  bool _inspectorOpen = true;

  @override
  void initState() {
    super.initState();
    _runLayout();
  }

  @override
  void didUpdateWidget(covariant TopologyCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedTopologyId != widget.state.selectedTopologyId ||
        oldWidget.state.selectedTopology?.components.length !=
            widget.state.selectedTopology?.components.length ||
        oldWidget.state.selectedTopology?.edges.length !=
            widget.state.selectedTopology?.edges.length) {
      _runLayout();
    }
  }

  void _runLayout() {
    final topology = widget.state.selectedTopology;
    if (topology == null) {
      _layoutResult = null;
      return;
    }
    _layoutResult = _layoutEngine.layout(topology.components, topology.edges);
  }

  Size _computeCanvasSize() {
    const minWidth = 2200.0;
    const minHeight = 1400.0;
    const padding = 400.0;
    final nodeW = _layoutEngine.nodeWidth;
    final nodeH = _layoutEngine.nodeHeight;

    if (_layoutResult == null || _layoutResult!.positions.isEmpty) {
      return const Size(minWidth, minHeight);
    }

    double maxX = 0;
    double maxY = 0;
    for (final pos in _layoutResult!.positions.values) {
      if (pos.dx + nodeW > maxX) maxX = pos.dx + nodeW;
      if (pos.dy + nodeH > maxY) maxY = pos.dy + nodeH;
    }

    return Size(
      math.max(minWidth, maxX + padding),
      math.max(minHeight, maxY + padding),
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
      return _NoTopology(
        onCreateTopology: _showCreateTopologyDialog,
        onSyncTopology: () => ref.read(workspaceControllerProvider.notifier).syncFromMcp(),
      );
    }

    final controller = ref.read(workspaceControllerProvider.notifier);
    final isLive = topology.isLive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.spaceBlack.withValues(alpha: 0.72),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  children: [
                    // Infinite backdrop
                    Positioned.fill(
                      child: ListenableBuilder(
                        listenable: _transformationController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _TopologyBackdropPainter(
                              transform: _transformationController.value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Interactive canvas
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.1,
                        maxScale: 3.0,
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        child: Builder(
                          builder: (context) {
                            final canvasSize = _computeCanvasSize();
                            return SizedBox(
                              width: canvasSize.width,
                              height: canvasSize.height,
                              child: Stack(
                                children: [
                                  if (_layoutResult != null)
                                    CustomPaint(
                                      size: canvasSize,
                                      painter: TopologyEdgePainter(
                                        edges: _layoutResult!.edges,
                                        selectedComponentId:
                                            widget.state.selectedComponentId,
                                      ),
                                    ),
                                  ...topology.components.map(
                                    (component) =>
                                        _buildNode(component, isLive),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Floating toolbar — top-left
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _CanvasToolbar(
                        topology: topology,
                        topologies: widget.state.topologies,
                        isLive: isLive,
                        isFullscreenMode: widget.isFullscreenMode,
                        onSelectTopology: (id) => controller.selectTopology(id),
                        onNewTopology: _showCreateTopologyDialog,
                        onRelayout: () => setState(_runLayout),
                        onCloneToExperiment: () => controller.cloneToExperimental(topology.id),
                        onFullScreen: _openFullscreenEditor,
                        onSetDeploymentMode: (mode) => controller.setDeploymentMode(mode),
                      ),
                    ),
                    // Floating collapsible component palette — top-left below toolbar
                    Positioned(
                      left: 14,
                      top: 60,
                      child: _CollapsibleComponentPalette(
                        disabled: isLive,
                        onAdd: (type) => controller.addComponent(type),
                      ),
                    ),
                    // Help tooltip — bottom-right
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.panelSoft.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          isLive
                              ? 'Read-only · Clone to experiment'
                              : _linkMode
                                  ? 'Click another node to connect'
                                  : 'Click select · Double-click drill down · Scroll zoom · Drag pan',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    // Floating inspector — right side
                    _CollapsibleInspector(
                      state: widget.state,
                      linkMode: _linkMode,
                      isReadOnly: isLive,
                      inspectorOpen: _inspectorOpen,
                      onToggleInspector: () => setState(() => _inspectorOpen = !_inspectorOpen),
                      onToggleLinkMode: () => setState(() => _linkMode = !_linkMode),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];

        return Column(children: children);
      },
    );
  }

  Widget _buildNode(TopologyComponent component, bool isReadOnly) {
    final controller = ref.read(workspaceControllerProvider.notifier);
    final position = _layoutResult?.positions[component.id] ??
        Offset(component.canvasX, component.canvasY);
    final isSelected = widget.state.selectedComponentId == component.id;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: TopologyNodeWidget(
        component: component,
        isSelected: isSelected,
        onTap: () async {
          if (_linkMode &&
              widget.state.selectedComponentId != null &&
              !isReadOnly) {
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
        onDoubleTap: () {
          _navigateToDrilldown(component);
        },
      ),
    );
  }

  void _navigateToDrilldown(TopologyComponent component) {
    final typeRoute = switch (component.type) {
      ComponentType.compute => 'server',
      ComponentType.database => 'database',
      ComponentType.cache => 'cache',
      ComponentType.messageQueue => 'queue',
      _ => null,
    };
    if (typeRoute != null) {
      goToDrilldown(context, typeRoute, component.id);
    }
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

class _CollapsibleInspector extends ConsumerWidget {
  const _CollapsibleInspector({
    required this.state,
    required this.linkMode,
    required this.isReadOnly,
    required this.inspectorOpen,
    required this.onToggleInspector,
    required this.onToggleLinkMode,
  });

  final WorkspaceState state;
  final bool linkMode;
  final bool isReadOnly;
  final bool inspectorOpen;
  final VoidCallback onToggleInspector;
  final VoidCallback onToggleLinkMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final component = state.selectedComponent;
    final controller = ref.read(workspaceControllerProvider.notifier);

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle tab on the edge — centered vertically
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: onToggleInspector,
              child: Container(
                width: 24,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.panelSoft.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  inspectorOpen ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          // Panel — stretches to full height via Row's stretch alignment
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: inspectorOpen ? 300 : 0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.panelSoft.withValues(alpha: 0.95),
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 300,
              maxWidth: 300,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: component == null
                    ? const _InspectorPlaceholder()
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  componentIcon(component.type),
                                  color: componentColor(component.type),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    component.name,
                                    style: AppTheme.syne(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _InspectorMeta(label: 'Type', value: component.type.label),
                            _InspectorMeta(label: 'Region', value: component.location.region),
                            _InspectorMeta(label: 'Provider', value: component.cloudProvider.label),
                            const SizedBox(height: 12),
                            if (_hasDrilldown(component.type))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final typeRoute = _drilldownRoute(component.type);
                                      if (typeRoute != null) {
                                        goToDrilldown(context, typeRoute, component.id);
                                      }
                                    },
                                    icon: const Icon(Icons.zoom_in_rounded, size: 18),
                                    label: const Text('Drill Down'),
                                  ),
                                ),
                              ),
                            if (!isReadOnly) ...[
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: onToggleLinkMode,
                                  icon: Icon(
                                    linkMode ? Icons.link_off_rounded : Icons.link_rounded,
                                    size: 18,
                                  ),
                                  label: Text(linkMode ? 'Cancel Linking' : 'Connect'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => controller.removeSelectedComponent(),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  label: const Text('Remove'),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Quick edit',
                                style: AppTheme.syne(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: component.name,
                                decoration: const InputDecoration(
                                  labelText: 'Display name',
                                  isDense: true,
                                ),
                                onFieldSubmitted: (value) =>
                                    controller.updateSelectedComponent(name: value),
                              ),
                              const SizedBox(height: 10),
                              Builder(
                                builder: (context) {
                                  final regionIds = state.regions.map((r) => r.id).toSet();
                                  final selectedRegion =
                                      regionIds.contains(component.location.region)
                                          ? component.location.region
                                          : null;
                                  return DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: selectedRegion,
                                    decoration: const InputDecoration(
                                      labelText: 'Region',
                                      isDense: true,
                                    ),
                                    items: state.regions
                                        .map(
                                          (item) => DropdownMenuItem(
                                            value: item.id,
                                            child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        controller.updateSelectedComponent(region: value);
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<CloudProvider>(
                                isExpanded: true,
                                initialValue: component.cloudProvider,
                                decoration: const InputDecoration(
                                  labelText: 'Cloud provider',
                                  isDense: true,
                                ),
                                items: CloudProvider.values
                                    .map(
                                      (provider) => DropdownMenuItem(
                                        value: provider,
                                        child: Text(provider.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.updateSelectedComponent(cloudProvider: value);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasDrilldown(ComponentType type) {
    return type == ComponentType.compute ||
        type == ComponentType.database ||
        type == ComponentType.cache ||
        type == ComponentType.messageQueue;
  }

  String? _drilldownRoute(ComponentType type) {
    return switch (type) {
      ComponentType.compute => 'server',
      ComponentType.database => 'database',
      ComponentType.cache => 'cache',
      ComponentType.messageQueue => 'queue',
      _ => null,
    };
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

class _CanvasToolbar extends StatelessWidget {
  const _CanvasToolbar({
    required this.topology,
    required this.topologies,
    required this.isLive,
    required this.isFullscreenMode,
    required this.onSelectTopology,
    required this.onNewTopology,
    required this.onRelayout,
    required this.onCloneToExperiment,
    required this.onFullScreen,
    required this.onSetDeploymentMode,
  });

  final TopologyModel topology;
  final List<TopologyModel> topologies;
  final bool isLive;
  final bool isFullscreenMode;
  final ValueChanged<String> onSelectTopology;
  final VoidCallback onNewTopology;
  final VoidCallback onRelayout;
  final VoidCallback onCloneToExperiment;
  final VoidCallback onFullScreen;
  final ValueChanged<DeploymentMode> onSetDeploymentMode;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isLive
        ? AppColors.liveBadgeColor
        : AppColors.experimentalBadgeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panelSoft.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Topology dropdown
          SizedBox(
            width: 160,
            child: Builder(
              builder: (context) {
                final topologyIds = topologies.map((t) => t.id).toSet();
                final selected = topologyIds.contains(topology.id) ? topology.id : null;
                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selected,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: InputBorder.none,
                  ),
                  items: topologies
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onSelectTopology(value);
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          // Live/Experimental badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLive ? Icons.circle : Icons.science_outlined,
                  size: 8,
                  color: badgeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  topology.topologyType.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _ToolbarIconButton(
            tooltip: 'Re-layout',
            icon: Icons.auto_fix_high_rounded,
            onPressed: onRelayout,
          ),
          _ToolbarIconButton(
            tooltip: isLive ? 'New Topology (disabled in Live)' : 'New Topology',
            icon: Icons.add_rounded,
            onPressed: isLive ? null : onNewTopology,
          ),
          _ToolbarIconButton(
            tooltip: 'Clone to Experiment',
            icon: Icons.science_outlined,
            onPressed: onCloneToExperiment,
          ),
          _ToolbarIconButton(
            tooltip: isFullscreenMode ? 'Already in Full Screen' : 'Full Screen',
            icon: Icons.open_in_full_rounded,
            onPressed: isFullscreenMode ? null : onFullScreen,
          ),
          const SizedBox(width: 4),
          // Deployment mode chips
          ...DeploymentMode.values.map(
            (mode) => Padding(
              padding: const EdgeInsets.only(left: 2),
              child: ChoiceChip(
                selected: topology.deploymentMode == mode,
                label: Text(mode.label, style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: isLive
                    ? null
                    : (_) => onSetDeploymentMode(mode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.border.withValues(alpha: disabled ? 0.25 : 0.5),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.textMuted.withValues(alpha: disabled ? 0.4 : 1.0),
          ),
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
          'Select a component on the canvas to inspect it, or double-click to drill down into its details.',
          style: TextStyle(color: AppColors.textMuted, height: 1.6),
        ),
      ],
    );
  }
}

class _NoTopology extends StatelessWidget {
  const _NoTopology({
    required this.onCreateTopology,
    required this.onSyncTopology,
  });

  final VoidCallback onCreateTopology;
  final VoidCallback onSyncTopology;

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
                'No topology yet',
                style: AppTheme.syne(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Create a new topology from scratch or sync your live infrastructure to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onSyncTopology,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync Live Topology'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onCreateTopology,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Topology'),
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

class _CollapsibleComponentPalette extends StatefulWidget {
  const _CollapsibleComponentPalette({
    required this.disabled,
    required this.onAdd,
  });

  final bool disabled;
  final ValueChanged<ComponentType> onAdd;

  @override
  State<_CollapsibleComponentPalette> createState() =>
      _CollapsibleComponentPaletteState();
}

class _CollapsibleComponentPaletteState
    extends State<_CollapsibleComponentPalette> {
  bool _open = true;

  static const double _cardSize = 34;
  static const double _spacing = 6;
  static const double _stackedOffset = 4; // peek when collapsed
  static const double _toggleSize = 24;
  static const double _hPad = 8;
  static const double _vPad = 6;

  @override
  Widget build(BuildContext context) {
    final types = ComponentType.values;
    final count = types.length;

    final openWidth = count * _cardSize + (count - 1) * _spacing;
    final closedWidth = _cardSize + (count - 1) * _stackedOffset;
    final innerWidth = _open ? openWidth : closedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
      decoration: BoxDecoration(
        color: AppColors.panelSoft.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle chevron — opens/closes left-to-right
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Container(
              width: _toggleSize,
              height: _cardSize,
              alignment: Alignment.center,
              child: Icon(
                _open ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Animated stack of cards
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            width: innerWidth,
            height: _cardSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(count, (i) {
                final type = types[i];
                final openLeft = i * (_cardSize + _spacing);
                final closedLeft = i * _stackedOffset;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  left: _open ? openLeft : closedLeft,
                  top: 0,
                  width: _cardSize,
                  height: _cardSize,
                  child: Tooltip(
                    message: widget.disabled
                        ? '${type.label} (disabled in Live)'
                        : type.label,
                    child: InkWell(
                      onTap: widget.disabled ? null : () => widget.onAdd(type),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          // Solid fill when collapsed so stacked cards are
                          // visibly layered; translucent when fanned open.
                          color: _open
                              ? componentColor(type).withValues(
                                  alpha: widget.disabled ? 0.06 : 0.12,
                                )
                              : Color.alphaBlend(
                                  componentColor(type).withValues(
                                    alpha: widget.disabled ? 0.55 : 0.9,
                                  ),
                                  AppColors.panelSoft,
                                ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _open
                                ? componentColor(type).withValues(
                                    alpha: widget.disabled ? 0.18 : 0.3,
                                  )
                                : componentColor(type).withValues(
                                    alpha: widget.disabled ? 0.5 : 1.0,
                                  ),
                            width: _open ? 1 : 1.2,
                          ),
                          boxShadow: _open
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 5,
                                    offset: const Offset(1.5, 1.5),
                                  ),
                                ],
                        ),
                        child: Icon(
                          componentIcon(type),
                          size: 16,
                          color: _open
                              ? componentColor(type).withValues(
                                  alpha: widget.disabled ? 0.5 : 1.0,
                                )
                              : (componentColor(type).computeLuminance() > 0.5
                                  ? AppColors.spaceBlack
                                  : Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopologyBackdropPainter extends CustomPainter {
  _TopologyBackdropPainter({required this.transform});

  final Matrix4 transform;

  @override
  void paint(Canvas canvas, Size size) {
    // Extract scale and translation from the InteractiveViewer transform
    final scale = transform.getMaxScaleOnAxis();
    final tx = transform.entry(0, 3);
    final ty = transform.entry(1, 3);

    // Compute the visible region in canvas-space coordinates
    final left = -tx / scale;
    final top = -ty / scale;
    final visibleWidth = size.width / scale;
    final visibleHeight = size.height / scale;

    // Fill background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.spaceBlack.withValues(alpha: 0.72),
    );

    const grid = 56.0;
    final gridLeft = (left / grid).floor() * grid;
    final gridTop = (top / grid).floor() * grid;
    final gridRight = left + visibleWidth + grid;
    final gridBottom = top + visibleHeight + grid;

    canvas.save();
    canvas.transform(transform.storage);

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.35)
      ..strokeWidth = 1 / scale;

    for (double x = gridLeft; x <= gridRight; x += grid) {
      canvas.drawLine(
        Offset(x, gridTop),
        Offset(x, gridBottom),
        gridPaint,
      );
    }
    for (double y = gridTop; y <= gridBottom; y += grid) {
      canvas.drawLine(
        Offset(gridLeft, y),
        Offset(gridRight, y),
        gridPaint,
      );
    }

    // Draw deterministic stars across visible region
    // Use tile-based approach: divide world into tiles, each tile has fixed stars
    const tileSize = 400.0;
    final starPaint = Paint()
      ..color = AppColors.brandYellow.withValues(alpha: 0.35);

    final tileLeft = (left / tileSize).floor();
    final tileTop = (top / tileSize).floor();
    final tileRight = ((left + visibleWidth) / tileSize).ceil();
    final tileBottom = ((top + visibleHeight) / tileSize).ceil();

    for (var tx = tileLeft; tx <= tileRight; tx++) {
      for (var ty = tileTop; ty <= tileBottom; ty++) {
        // Deterministic seed per tile so stars stay fixed when panning
        final seed = tx * 7919 + ty * 104729 + 42;
        final random = math.Random(seed);
        const starsPerTile = 8;
        for (var i = 0; i < starsPerTile; i++) {
          final offset = Offset(
            tx * tileSize + random.nextDouble() * tileSize,
            ty * tileSize + random.nextDouble() * tileSize,
          );
          final radius = (0.8 + random.nextDouble() * 1.8) / scale;
          canvas.drawCircle(offset, radius, starPaint);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TopologyBackdropPainter oldDelegate) =>
      oldDelegate.transform != transform;
}
