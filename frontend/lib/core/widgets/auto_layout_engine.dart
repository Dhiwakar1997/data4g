import 'dart:math' as math;
import 'dart:ui';

import '../../models/topology_models.dart';

/// Result of running the auto-layout algorithm.
class LayoutResult {
  const LayoutResult({required this.positions, required this.edges});

  /// Map of componentId → top-left position on canvas.
  final Map<String, Offset> positions;

  /// Routed edges with optional waypoints for orthogonal/curved routing.
  final List<LayoutEdge> edges;
}

/// A routed edge between two components with waypoints.
class LayoutEdge {
  const LayoutEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.waypoints,
  });

  final String id;
  final String sourceId;
  final String targetId;

  /// Ordered points from source center to target center.
  final List<Offset> waypoints;
}

/// Sugiyama-style layered graph layout engine.
///
/// Steps:
/// 1. Assign layers based on component type (client/CDN first, DB/cache/queue last).
/// 2. Order nodes within layers using barycenter heuristic to minimize crossings.
/// 3. Assign x/y coordinates with configurable spacing.
/// 4. Route edges through waypoints.
class AutoLayoutEngine {
  AutoLayoutEngine({
    this.nodeWidth = 136,
    this.nodeHeight = 110,
    this.horizontalSpacing = 70,
    this.verticalSpacing = 80,
    this.canvasPadding = 60,
  });

  final double nodeWidth;
  final double nodeHeight;
  final double horizontalSpacing;
  final double verticalSpacing;
  final double canvasPadding;

  /// Run the full layout algorithm.
  LayoutResult layout(
    List<TopologyComponent> components,
    List<TopologyEdge> edges,
  ) {
    if (components.isEmpty) {
      return const LayoutResult(positions: {}, edges: []);
    }

    // Build adjacency
    final adjacency = <String, Set<String>>{};
    final reverseAdj = <String, Set<String>>{};
    for (final c in components) {
      adjacency[c.id] = {};
      reverseAdj[c.id] = {};
    }
    for (final e in edges) {
      adjacency[e.sourceComponentId]?.add(e.targetComponentId);
      reverseAdj[e.targetComponentId]?.add(e.sourceComponentId);
    }

    // Step 1: Layer assignment by component type
    final layers = _assignLayers(components);

    // Step 2: Order nodes within layers to minimize crossings
    _orderWithinLayers(layers, adjacency, reverseAdj);

    // Step 3: Assign coordinates
    final positions = _assignCoordinates(layers);

    // Step 4: Route edges
    final layoutEdges = _routeEdges(edges, positions);

    return LayoutResult(positions: positions, edges: layoutEdges);
  }

  /// Assigns components to layers based on their type.
  /// Layer 0 = clients/CDN (entry points)
  /// Layer 1 = load balancers / API gateways
  /// Layer 2 = compute / service mesh / cron jobs
  /// Layer 3 = databases / cache / queues / object store / third-party APIs
  List<List<TopologyComponent>> _assignLayers(
    List<TopologyComponent> components,
  ) {
    final buckets = <int, List<TopologyComponent>>{};
    for (final c in components) {
      final layer = _layerForType(c.type);
      (buckets[layer] ??= []).add(c);
    }

    if (buckets.isEmpty) return [];

    final maxLayer = buckets.keys.reduce(math.max);
    final layers = <List<TopologyComponent>>[];
    for (var i = 0; i <= maxLayer; i++) {
      layers.add(buckets[i] ?? []);
    }

    // Remove empty leading/trailing layers
    while (layers.isNotEmpty && layers.first.isEmpty) {
      layers.removeAt(0);
    }
    while (layers.isNotEmpty && layers.last.isEmpty) {
      layers.removeLast();
    }

    return layers;
  }

  int _layerForType(ComponentType type) {
    return switch (type) {
      ComponentType.client || ComponentType.cdn => 0,
      ComponentType.loadBalancer || ComponentType.apiGateway => 1,
      ComponentType.compute ||
      ComponentType.serviceMesh ||
      ComponentType.cronJob =>
        2,
      ComponentType.database ||
      ComponentType.cache ||
      ComponentType.messageQueue ||
      ComponentType.objectStore ||
      ComponentType.thirdPartyApi =>
        3,
    };
  }

  /// Barycenter heuristic: order each layer by the average position of
  /// connected nodes in the previous layer.
  void _orderWithinLayers(
    List<List<TopologyComponent>> layers,
    Map<String, Set<String>> adjacency,
    Map<String, Set<String>> reverseAdj,
  ) {
    // Forward pass
    for (var i = 1; i < layers.length; i++) {
      _orderLayer(layers[i], layers[i - 1], reverseAdj);
    }
    // Backward pass
    for (var i = layers.length - 2; i >= 0; i--) {
      _orderLayer(layers[i], layers[i + 1], adjacency);
    }
  }

  void _orderLayer(
    List<TopologyComponent> layer,
    List<TopologyComponent> referenceLayer,
    Map<String, Set<String>> connections,
  ) {
    final refIndex = <String, int>{};
    for (var i = 0; i < referenceLayer.length; i++) {
      refIndex[referenceLayer[i].id] = i;
    }

    final barycenters = <String, double>{};
    for (final node in layer) {
      final connected = connections[node.id] ?? {};
      final positions = <int>[];
      for (final neighborId in connected) {
        if (refIndex.containsKey(neighborId)) {
          positions.add(refIndex[neighborId]!);
        }
      }
      if (positions.isEmpty) {
        barycenters[node.id] = double.infinity;
      } else {
        barycenters[node.id] =
            positions.reduce((a, b) => a + b) / positions.length;
      }
    }

    layer.sort((a, b) {
      final ba = barycenters[a.id] ?? double.infinity;
      final bb = barycenters[b.id] ?? double.infinity;
      return ba.compareTo(bb);
    });
  }

  /// Assign x/y positions. Layers flow top-to-bottom (y axis).
  /// Nodes within a layer are centered horizontally.
  Map<String, Offset> _assignCoordinates(
    List<List<TopologyComponent>> layers,
  ) {
    final positions = <String, Offset>{};

    // Find the widest layer to determine centering
    double maxLayerWidth = 0;
    for (final layer in layers) {
      final w = layer.length * nodeWidth +
          (layer.length - 1).clamp(0, double.infinity) * horizontalSpacing;
      if (w > maxLayerWidth) maxLayerWidth = w;
    }

    for (var layerIdx = 0; layerIdx < layers.length; layerIdx++) {
      final layer = layers[layerIdx];
      final layerWidth = layer.length * nodeWidth +
          (layer.length - 1).clamp(0, double.infinity) * horizontalSpacing;
      final startX = canvasPadding + (maxLayerWidth - layerWidth) / 2;
      final y = canvasPadding + layerIdx * (nodeHeight + verticalSpacing);

      for (var nodeIdx = 0; nodeIdx < layer.length; nodeIdx++) {
        final x = startX + nodeIdx * (nodeWidth + horizontalSpacing);
        positions[layer[nodeIdx].id] = Offset(x, y);
      }
    }

    return positions;
  }

  /// Route edges as straight lines with source bottom-center to target top-center.
  List<LayoutEdge> _routeEdges(
    List<TopologyEdge> edges,
    Map<String, Offset> positions,
  ) {
    final layoutEdges = <LayoutEdge>[];

    for (final edge in edges) {
      final sourcePos = positions[edge.sourceComponentId];
      final targetPos = positions[edge.targetComponentId];
      if (sourcePos == null || targetPos == null) continue;

      // Source bottom-center
      final start = Offset(
        sourcePos.dx + nodeWidth / 2,
        sourcePos.dy + nodeHeight,
      );
      // Target top-center
      final end = Offset(
        targetPos.dx + nodeWidth / 2,
        targetPos.dy,
      );

      // Mid-point for smooth routing
      final midY = (start.dy + end.dy) / 2;

      layoutEdges.add(LayoutEdge(
        id: edge.id,
        sourceId: edge.sourceComponentId,
        targetId: edge.targetComponentId,
        waypoints: [
          start,
          Offset(start.dx, midY),
          Offset(end.dx, midY),
          end,
        ],
      ));
    }

    return layoutEdges;
  }
}
