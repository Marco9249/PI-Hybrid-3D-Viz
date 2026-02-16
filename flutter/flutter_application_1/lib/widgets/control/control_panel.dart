import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/simulation_controller.dart';

/// Industrial SCADA-style control center with neumorphic toggles,
/// circular gauges, and pulsing AI auto-pilot button.
class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final sim = context.watch<SimulationController>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E1A), Color(0xFF111827)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'COMMAND CENTER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'SCADA INTERFACE v2.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  color: const Color(0xFF00F0FF).withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 32),

              // === Circular Gauges Row ===
              Row(
                children: [
                  Expanded(
                    child: _CircularGauge(
                      label: 'BATTERY',
                      value: sim.batteryLevel,
                      color: sim.batteryLevel > 0.5
                          ? const Color(0xFF00FF88)
                          : const Color(0xFFFFCA28),
                      icon: Icons.battery_charging_full_rounded,
                      unit: '%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CircularGauge(
                      label: 'TANK LEVEL',
                      value: sim.tankLevel,
                      color: sim.tankLevel > 0.3
                          ? const Color(0xFF00B4D8)
                          : const Color(0xFFEF5350),
                      icon: Icons.water_rounded,
                      unit: '%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Irradiance Gauge
              _CircularGauge(
                label: 'SOLAR IRRADIANCE',
                value: (sim.irradiance / 1000).clamp(0, 1),
                color: const Color(0xFFFFD700),
                icon: Icons.wb_sunny_rounded,
                unit: 'W/m²',
                displayValue: sim.irradiance.toStringAsFixed(0),
                large: true,
              ),
              const SizedBox(height: 28),

              // === Pump Control ===
              _glassSection(
                title: 'PUMP CONTROL',
                titleColor: const Color(0xFF00B4D8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manual Pump Override',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sim.manualOverride
                                  ? 'Override Active — Pump Forced ON'
                                  : 'AI-Controlled — Autonomous Mode',
                              style: TextStyle(
                                fontSize: 11,
                                color: sim.manualOverride
                                    ? const Color(0xFFFFCA28)
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                        _NeumorphicToggle(
                          value: sim.manualOverride,
                          onChanged: (_) => sim.toggleManualPump(),
                          activeColor: const Color(0xFFFFCA28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Pump status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: sim.pumpActive
                            ? const Color(0xFF00FF88).withOpacity(0.08)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sim.pumpActive
                              ? const Color(0xFF00FF88).withOpacity(0.3)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sim.pumpActive
                                  ? const Color(0xFF00FF88)
                                  : const Color(0xFF4A4A4A),
                              boxShadow: sim.pumpActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00FF88)
                                            .withOpacity(0.6),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            sim.pumpActive ? 'PUMP RUNNING' : 'PUMP STANDBY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: sim.pumpActive
                                  ? const Color(0xFF00FF88)
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // === AI Auto-Pilot ===
              _glassSection(
                title: 'AI ENGINE',
                titleColor: const Color(0xFFFF00E5),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Auto-Pilot',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sim.aiAutoActive
                                  ? 'PI-Hybrid CNN-BiLSTM ACTIVE'
                                  : 'Neural Engine Standby',
                              style: TextStyle(
                                fontSize: 11,
                                color: sim.aiAutoActive
                                    ? const Color(0xFF00F0FF)
                                    : Colors.white.withOpacity(0.4),
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                        _NeumorphicToggle(
                          value: sim.aiAutoActive,
                          onChanged: (_) => sim.toggleAiAutoPilot(),
                          activeColor: const Color(0xFF00F0FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Model info card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF00E5).withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _infoRow('Model', 'PI-Hybrid CNN-BiLSTM'),
                          _infoRow('Parameters', '492,200'),
                          _infoRow('RMSE', '19.53 W/m²'),
                          _infoRow('R²', '0.997'),
                          _infoRow('Inference', '~2ms'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF00E5),
              fontFamily: 'Courier',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassSection({
    required String title,
    required Color titleColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: titleColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Neumorphic-style toggle switch with glow effect
class _NeumorphicToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _NeumorphicToggle({
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 56,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              value ? activeColor.withOpacity(0.15) : const Color(0xFF1A1F36),
          border: Border.all(
            color: value
                ? activeColor.withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? activeColor : const Color(0xFF3A3A4A),
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular progress gauge with glow and label
class _CircularGauge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String unit;
  final String? displayValue;
  final bool large;

  const _CircularGauge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.unit,
    this.displayValue,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    double size = large ? 160 : 120;
    double strokeW = large ? 10 : 7;
    String val = displayValue ?? '${(value * 100).round()}';

    return Container(
      padding: EdgeInsets.all(large ? 20 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _GaugePainter(
                value: value.clamp(0, 1),
                color: color,
                strokeWidth: strokeW,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: large ? 24 : 18, color: color),
                    const SizedBox(height: 4),
                    Text(
                      val,
                      style: TextStyle(
                        fontSize: large ? 28 : 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(0.5),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final double strokeWidth;

  _GaugePainter({
    required this.value,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Value arc with glow
    final sweepAngle = pi * 1.5 * value;

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      sweepAngle,
      false,
      Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}
