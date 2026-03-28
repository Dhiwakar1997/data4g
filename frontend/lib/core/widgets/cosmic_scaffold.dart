import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CosmicScaffold extends StatelessWidget {
  const CosmicScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.25,
          colors: [Color(0xFF15151F), AppColors.deepWine, AppColors.spaceBlack],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _GridPainter()),
          const _ParticlesLayer(),
          SafeArea(
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 48.0;
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.26)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final radialPaint = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x22FFDE42), Color(0x124C5C2D), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.6, 0),
              radius: size.shortestSide * 0.7,
            ),
          );

    canvas.drawRect(Offset.zero & size, radialPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParticlesLayer extends StatelessWidget {
  const _ParticlesLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: List.generate(32, (index) {
              final random = math.Random(index * 91);
              final left = random.nextDouble() * constraints.maxWidth;
              final top = random.nextDouble() * constraints.maxHeight;
              final size = 2.0 + random.nextDouble() * 4;
              final opacity = 0.15 + random.nextDouble() * 0.5;
              final color = index.isEven
                  ? AppColors.brandYellow
                  : AppColors.success;
              return Positioned(
                left: left,
                top: top,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: opacity),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: opacity),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
