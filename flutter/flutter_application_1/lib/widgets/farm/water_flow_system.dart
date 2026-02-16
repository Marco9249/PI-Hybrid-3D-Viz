import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/simulation_controller.dart';

/// Animated bezier-curve pipe system with flowing particles when pump is active.
class WaterFlowSystem extends StatefulWidget {
  const WaterFlowSystem({super.key});

  @override
  State<WaterFlowSystem> createState() => _WaterFlowSystemState();
}

class _WaterFlowSystemState extends State<WaterFlowSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _flowCtrl;

  @override
  void initState() {
    super.initState();
    _flowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _flowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pumpOn = context.select<SimulationController, bool>(
      (s) => s.pumpActive,
    );

    return AnimatedBuilder3(
      animation: _flowCtrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _WaterFlowPainter(
            pumpOn: pumpOn,
            flowProgress: _flowCtrl.value,
          ),
          size: const Size(double.infinity, 120),
        );
      },
    );
  }
}

class _WaterFlowPainter extends CustomPainter {
  final bool pumpOn;
  final double flowProgress;

  _WaterFlowPainter({required this.pumpOn, required this.flowProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Define pipe path: Tank(left) → Pump(center) → Field(right)
    final tankCenter = Offset(w * 0.08, h * 0.3);
    final pumpCenter = Offset(w * 0.45, h * 0.5);
    final fieldCenter = Offset(w * 0.88, h * 0.7);

    // === Draw Tank ===
    _drawTank(canvas, tankCenter, w * 0.08, h * 0.4);

    // === Draw Pump ===
    _drawPump(canvas, pumpCenter, 18);

    // === Draw Crop/Field icon ===
    _drawField(canvas, fieldCenter, 22);

    // === Pipe path 1: Tank → Pump ===
    final pipePath1 = Path();
    final p1Start = Offset(tankCenter.dx + w * 0.06, tankCenter.dy + h * 0.12);
    final p1End = Offset(pumpCenter.dx - 16, pumpCenter.dy);
    final p1Ctrl1 =
        Offset(p1Start.dx + (p1End.dx - p1Start.dx) * 0.4, p1Start.dy);
    final p1Ctrl2 = Offset(p1End.dx - (p1End.dx - p1Start.dx) * 0.2, p1End.dy);

    pipePath1.moveTo(p1Start.dx, p1Start.dy);
    pipePath1.cubicTo(
        p1Ctrl1.dx, p1Ctrl1.dy, p1Ctrl2.dx, p1Ctrl2.dy, p1End.dx, p1End.dy);

    // === Pipe path 2: Pump → Field ===
    final pipePath2 = Path();
    final p2Start = Offset(pumpCenter.dx + 16, pumpCenter.dy);
    final p2End = Offset(fieldCenter.dx - 20, fieldCenter.dy);
    final p2Ctrl1 =
        Offset(p2Start.dx + (p2End.dx - p2Start.dx) * 0.3, p2Start.dy);
    final p2Ctrl2 = Offset(p2End.dx - (p2End.dx - p2Start.dx) * 0.2, p2End.dy);

    pipePath2.moveTo(p2Start.dx, p2Start.dy);
    pipePath2.cubicTo(
        p2Ctrl1.dx, p2Ctrl1.dy, p2Ctrl2.dx, p2Ctrl2.dy, p2End.dx, p2End.dy);

    // Draw pipes
    final pipeColor = pumpOn
        ? const Color(0xFF00B4D8).withOpacity(0.6)
        : const Color(0xFF3A3A4A).withOpacity(0.4);

    final pipePaint = Paint()
      ..color = pipeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(pipePath1, pipePaint);
    canvas.drawPath(pipePath2, pipePaint);

    // === Flowing particles when pump is ON ===
    if (pumpOn) {
      // Glow pipe
      final glowPipe = Paint()
        ..color = const Color(0xFF00B4D8).withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(pipePath1, glowPipe);
      canvas.drawPath(pipePath2, glowPipe);

      // Draw particles along path
      _drawFlowParticles(canvas, pipePath1, flowProgress, 8);
      _drawFlowParticles(canvas, pipePath2, flowProgress, 8);

      // Drip animation at field end
      _drawDrips(canvas, fieldCenter, flowProgress);
    }

    // Labels
    _drawLabel(
        canvas, 'TANK', Offset(tankCenter.dx - 14, tankCenter.dy + h * 0.22));
    _drawLabel(canvas, 'PUMP', Offset(pumpCenter.dx - 16, pumpCenter.dy + 28));
    _drawLabel(
        canvas, 'FIELD', Offset(fieldCenter.dx - 14, fieldCenter.dy + 28));
  }

  void _drawTank(Canvas canvas, Offset center, double w, double h) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w * 2, height: h),
      const Radius.circular(4),
    );
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A2744), Color(0xFF0D1B2A)],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, fill);

    // Water fill
    final waterRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left + 1.5,
        rect.top + h * 0.3,
        w * 2 - 3,
        h * 0.68,
      ),
      const Radius.circular(3),
    );
    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
      ).createShader(waterRect.outerRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 2);
    canvas.drawRRect(waterRect, waterPaint);

    // Border
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF00F0FF).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawPump(Canvas canvas, Offset center, double radius) {
    // Outer
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF1E293B),
    );
    // Inner highlight if active
    if (pumpOn) {
      canvas.drawCircle(
        center,
        radius - 3,
        Paint()
          ..color = const Color(0xFF00F0FF).withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = pumpOn
            ? const Color(0xFF00F0FF).withOpacity(0.5)
            : const Color(0xFF3A3A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Pump icon (small triangle)
    final iconPaint = Paint()
      ..color = pumpOn ? const Color(0xFF00F0FF) : const Color(0xFF8892B0);
    final path = Path()
      ..moveTo(center.dx - 6, center.dy - 6)
      ..lineTo(center.dx + 8, center.dy)
      ..lineTo(center.dx - 6, center.dy + 6)
      ..close();
    canvas.drawPath(path, iconPaint);
  }

  void _drawField(Canvas canvas, Offset center, double size) {
    // Simple plant icon
    final stemPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy + 10),
      Offset(center.dx, center.dy - 8),
      stemPaint,
    );

    // Leaves
    final leafPaint = Paint()..color = const Color(0xFF66BB6A);
    final leaf1 = Path()
      ..moveTo(center.dx, center.dy - 4)
      ..quadraticBezierTo(
          center.dx + 12, center.dy - 14, center.dx + 4, center.dy - 16);
    canvas.drawPath(leaf1, leafPaint);

    final leaf2 = Path()
      ..moveTo(center.dx, center.dy - 8)
      ..quadraticBezierTo(
          center.dx - 10, center.dy - 16, center.dx - 3, center.dy - 18);
    canvas.drawPath(leaf2, leafPaint);

    // Ground
    canvas.drawLine(
      Offset(center.dx - 14, center.dy + 10),
      Offset(center.dx + 14, center.dy + 10),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFlowParticles(
      Canvas canvas, Path path, double progress, int count) {
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;

    for (int i = 0; i < count; i++) {
      double t = (progress + i / count) % 1.0;
      double dist = t * totalLength;

      final pos = metrics.getTangentForOffset(dist)?.position;
      if (pos == null) continue;

      double particleSize = 2.5 + sin(t * pi) * 1.5;

      // Glow
      canvas.drawCircle(
        pos,
        particleSize + 3,
        Paint()
          ..color = const Color(0xFF00B4D8).withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Core
      canvas.drawCircle(
        pos,
        particleSize,
        Paint()..color = const Color(0xFF90E0EF),
      );
    }
  }

  void _drawDrips(Canvas canvas, Offset center, double progress) {
    final rng = Random(7);
    for (int i = 0; i < 3; i++) {
      double t = (progress * 2 + i * 0.33) % 1.0;
      double dx = center.dx - 8 + rng.nextDouble() * 16;
      double dy = center.dy + 12 + t * 20;
      double opacity = (1 - t).clamp(0, 1);

      canvas.drawCircle(
        Offset(dx, dy),
        1.5,
        Paint()..color = const Color(0xFF00B4D8).withOpacity(opacity * 0.6),
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF8892B0).withOpacity(0.7),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _WaterFlowPainter old) =>
      old.pumpOn != pumpOn || old.flowProgress != flowProgress;
}

class AnimatedBuilder3 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  const AnimatedBuilder3({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, null);
}
