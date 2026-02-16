import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/simulation_controller.dart';

/// Background gradient that shifts from Dawn → Noon → Dusk → Night
/// based on the simulation hour.
class DynamicSkyBox extends StatelessWidget {
  const DynamicSkyBox({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = context.select<SimulationController, double>(
      (s) => s.simulationHour,
    );

    final colors = _getSkyColors(hour);
    final size = MediaQuery.of(context).size;

    return SizedBox.expand(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: CustomPaint(
          painter: _SkyElementsPainter(hour: hour, size: size),
        ),
      ),
    );
  }

  List<Color> _getSkyColors(double hour) {
    if (hour < 5) {
      // Night
      return [const Color(0xFF050A18), const Color(0xFF0A1128)];
    } else if (hour < 7) {
      // Dawn
      double t = (hour - 5) / 2;
      return [
        Color.lerp(const Color(0xFF050A18), const Color(0xFF1A0A2E), t)!,
        Color.lerp(const Color(0xFF0A1128), const Color(0xFFFF6B35), t)!,
      ];
    } else if (hour < 9) {
      // Early morning
      double t = (hour - 7) / 2;
      return [
        Color.lerp(const Color(0xFF1A0A2E), const Color(0xFF1565C0), t)!,
        Color.lerp(const Color(0xFFFF6B35), const Color(0xFF42A5F5), t)!,
      ];
    } else if (hour < 15) {
      // Day
      return [const Color(0xFF0D47A1), const Color(0xFF42A5F5)];
    } else if (hour < 17) {
      // Afternoon
      double t = (hour - 15) / 2;
      return [
        Color.lerp(const Color(0xFF0D47A1), const Color(0xFF4A148C), t)!,
        Color.lerp(const Color(0xFF42A5F5), const Color(0xFFFF8A65), t)!,
      ];
    } else if (hour < 19) {
      // Dusk
      double t = (hour - 17) / 2;
      return [
        Color.lerp(const Color(0xFF4A148C), const Color(0xFF1A0533), t)!,
        Color.lerp(const Color(0xFFFF8A65), const Color(0xFF6A1B9A), t)!,
      ];
    } else {
      // Night
      double t = min(1, (hour - 19) / 2);
      return [
        Color.lerp(const Color(0xFF1A0533), const Color(0xFF050A18), t)!,
        Color.lerp(const Color(0xFF6A1B9A), const Color(0xFF0A1128), t)!,
      ];
    }
  }
}

class _SkyElementsPainter extends CustomPainter {
  final double hour;
  final Size size;

  _SkyElementsPainter({required this.hour, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;

    // Draw stars at night
    if (hour < 6 || hour > 19) {
      final rng = Random(42);
      final starPaint = Paint()..color = Colors.white;

      double starOpacity = (hour > 19)
          ? min(1, (hour - 19) / 2)
          : (hour < 6 ? min(1, (6 - hour) / 2) : 0);

      for (int i = 0; i < 60; i++) {
        double sx = rng.nextDouble() * w;
        double sy = rng.nextDouble() * h * 0.6;
        double size = 0.5 + rng.nextDouble() * 1.5;
        double flicker = 0.5 + 0.5 * sin(hour * 10 + i);
        starPaint.color = Colors.white.withOpacity(starOpacity * flicker * 0.8);
        canvas.drawCircle(Offset(sx, sy), size, starPaint);
      }
    }

    // Draw sun
    if (hour >= 5.5 && hour <= 18.5) {
      // Sun arc: rises from left, peaks at top, sets to right
      double progress = (hour - 5.5) / 13.0; // 0 to 1
      double sunX = w * 0.1 + w * 0.8 * progress;
      double sunArc = sin(progress * pi);
      double sunY = h * 0.7 - sunArc * h * 0.55;

      // Sun glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.6),
            const Color(0xFFFF8C00).withOpacity(0.15),
            Colors.transparent,
          ],
          stops: const [0, 0.4, 1],
        ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: 60));

      canvas.drawCircle(Offset(sunX, sunY), 60, glowPaint);

      // Sun core
      final sunPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(sunX, sunY), 14, sunPaint);

      sunPaint.maskFilter = null;
      sunPaint.color = const Color(0xFFFFF8E1);
      canvas.drawCircle(Offset(sunX, sunY), 10, sunPaint);
    }

    // Moon at night
    if (hour < 5 || hour > 20) {
      double moonX = w * 0.75;
      double moonY = h * 0.15;
      final moonPaint = Paint()
        ..color = const Color(0xFFE0E0E0).withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(moonX, moonY), 16, moonPaint);

      // Crescent shadow
      final shadowPaint = Paint()
        ..color = const Color(0xFF050A18).withOpacity(0.9);
      canvas.drawCircle(Offset(moonX + 6, moonY - 3), 13, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SkyElementsPainter old) => old.hour != hour;
}
