import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/simulation_controller.dart';

/// SVG-style solar panels that glow brighter as irradiance increases.
class SolarArrayWidget extends StatefulWidget {
  const SolarArrayWidget({super.key});

  @override
  State<SolarArrayWidget> createState() => _SolarArrayWidgetState();
}

class _SolarArrayWidgetState extends State<SolarArrayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _trackCtrl;

  @override
  void initState() {
    super.initState();
    _trackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _trackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final irradiance = context.select<SimulationController, double>(
      (s) => s.irradiance,
    );

    return AnimatedBuilder2(
      animation: _trackCtrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _SolarPanelPainter(
            irradiance: irradiance,
            trackAngle: _trackCtrl.value,
          ),
          size: const Size(double.infinity, 160),
        );
      },
    );
  }
}

class _SolarPanelPainter extends CustomPainter {
  final double irradiance;
  final double trackAngle;

  _SolarPanelPainter({required this.irradiance, required this.trackAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Irradiance normalized: 0 to 1
    double glow = (irradiance / 1000).clamp(0, 1);

    // Draw 3x2 grid of panels
    double panelW = w * 0.22;
    double panelH = h * 0.35;
    double gapX = (w - panelW * 3) / 4;
    double gapY = h * 0.08;

    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        double x = gapX + col * (panelW + gapX);
        double y = gapY + row * (panelH + gapY * 2);

        // Slight sun-tracking rotation
        double angle = sin(trackAngle * 2 * pi) * 0.05;

        canvas.save();
        canvas.translate(x + panelW / 2, y + panelH / 2);
        canvas.rotate(angle);
        canvas.translate(-panelW / 2, -panelH / 2);

        // Panel glow shadow
        if (glow > 0.1) {
          final glowPaint = Paint()
            ..color = Color(0xFF00F0FF).withOpacity(glow * 0.3)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * glow);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(-4, -4, panelW + 8, panelH + 8),
              const Radius.circular(6),
            ),
            glowPaint,
          );
        }

        // Panel body
        final panelPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                const Color(0xFF1A1F36),
                const Color(0xFF0066CC),
                glow,
              )!,
              Color.lerp(
                const Color(0xFF151929),
                const Color(0xFF00A3FF),
                glow * 0.7,
              )!,
            ],
          ).createShader(Rect.fromLTWH(0, 0, panelW, panelH));

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, panelW, panelH),
            const Radius.circular(4),
          ),
          panelPaint,
        );

        // Panel border
        final borderPaint = Paint()
          ..color = Color.lerp(
            Colors.white.withOpacity(0.1),
            const Color(0xFF00F0FF).withOpacity(0.5),
            glow,
          )!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, panelW, panelH),
            const Radius.circular(4),
          ),
          borderPaint,
        );

        // Panel grid lines (solar cell pattern)
        final gridPaint = Paint()
          ..color = Colors.white.withOpacity(0.06 + glow * 0.08)
          ..strokeWidth = 0.5;

        // Horizontal
        for (int g = 1; g < 4; g++) {
          double gy = panelH * g / 4;
          canvas.drawLine(Offset(2, gy), Offset(panelW - 2, gy), gridPaint);
        }
        // Vertical
        for (int g = 1; g < 3; g++) {
          double gx = panelW * g / 3;
          canvas.drawLine(Offset(gx, 2), Offset(gx, panelH - 2), gridPaint);
        }

        // Stand/mount
        final standPaint = Paint()
          ..color = const Color(0xFF3A3A4A)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(panelW / 2, panelH),
          Offset(panelW / 2, panelH + gapY * 1.2),
          standPaint,
        );

        canvas.restore();
      }
    }

    // Irradiance label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '☀ ${irradiance.toStringAsFixed(0)} W/m²',
        style: TextStyle(
          color: Color.lerp(
            const Color(0xFF8892B0),
            const Color(0xFFFFD700),
            glow,
          ),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(w - textPainter.width - 8, h - 18));
  }

  @override
  bool shouldRepaint(covariant _SolarPanelPainter old) =>
      old.irradiance != irradiance || old.trackAngle != trackAngle;
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, null);
}
