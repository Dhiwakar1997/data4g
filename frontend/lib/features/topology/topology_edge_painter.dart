import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/auto_layout_engine.dart';

/// CustomPainter that renders waypoint-based edges with directional arrows.
///
/// Highlights edges connected to the selected component.
class TopologyEdgePainter extends CustomPainter {
  TopologyEdgePainter({
    required this.edges,
    this.selectedComponentId,
  });

  final List<LayoutEdge> edges;
  final String? selectedComponentId;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final isSelected = edge.sourceId == selectedComponentId ||
          edge.targetId == selectedComponentId;

      _drawEdge(canvas, edge, isSelected);
    }
  }

  void _drawEdge(Canvas canvas, LayoutEdge edge, bool isSelected) {
    if (edge.waypoints.length < 2) return;

    final paint = Paint()
      ..color = (isSelected ? AppColors.brandYellow : AppColors.info)
          .withValues(alpha: isSelected ? 0.8 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = edge.waypoints;

    // Draw smooth curve through waypoints
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
    } else if (points.length == 4) {
      // 4-point waypoints: source, control1, control2, target
      // Draw as cubic bezier for smooth routing
      path.cubicTo(
        points[1].dx,
        points[1].dy,
        points[2].dx,
        points[2].dy,
        points[3].dx,
        points[3].dy,
      );
    } else {
      // Generic: connect with lines through waypoints
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, paint);

    // Draw arrowhead at target
    _drawArrowhead(
      canvas,
      points[points.length - 2],
      points.last,
      isSelected,
    );
  }

  void _drawArrowhead(
    Canvas canvas,
    Offset from,
    Offset to,
    bool isSelected,
  ) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 10.0;
    const arrowAngle = 0.5; // radians (~28 degrees)

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * math.cos(angle - arrowAngle),
        to.dy - arrowSize * math.sin(angle - arrowAngle),
      )
      ..lineTo(
        to.dx - arrowSize * math.cos(angle + arrowAngle),
        to.dy - arrowSize * math.sin(angle + arrowAngle),
      )
      ..close();

    final paint = Paint()
      ..color = (isSelected ? AppColors.brandYellow : AppColors.info)
          .withValues(alpha: isSelected ? 0.8 : 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TopologyEdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.selectedComponentId != selectedComponentId;
  }
}
