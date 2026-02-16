import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/simulation_controller.dart';

/// Grid representing the farm field. Cells change color
/// from Red (Dry: <0.3) to Yellow (0.5) to Green (Optimal: >0.7)
/// based on soil moisture sensor data.
class SoilMoistureHeatmap extends StatelessWidget {
  const SoilMoistureHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final soilData = context.select<SimulationController, List<double>>(
      (s) => s.soilMoisture,
    );

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SOIL MOISTURE MAP',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                _buildLegend(),
              ],
            ),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1,
            ),
            itemCount: soilData.length,
            itemBuilder: (context, i) {
              final moisture = soilData[i];
              return _SoilCell(moisture: moisture);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(const Color(0xFFEF5350), 'Dry'),
        const SizedBox(width: 6),
        _legendDot(const Color(0xFFFFCA28), 'Mid'),
        const SizedBox(width: 6),
        _legendDot(const Color(0xFF66BB6A), 'Opt'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 7,
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SoilCell extends StatelessWidget {
  final double moisture;
  const _SoilCell({required this.moisture});

  @override
  Widget build(BuildContext context) {
    final color = _moistureColor(moisture);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${(moisture * 100).round()}',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Color _moistureColor(double m) {
    if (m < 0.3) {
      return Color.lerp(
        const Color(0xFFD32F2F), // Deep red
        const Color(0xFFEF5350), // Light red
        (m / 0.3).clamp(0, 1),
      )!;
    } else if (m < 0.55) {
      return Color.lerp(
        const Color(0xFFEF5350),
        const Color(0xFFFFCA28), // Yellow
        ((m - 0.3) / 0.25).clamp(0, 1),
      )!;
    } else if (m < 0.75) {
      return Color.lerp(
        const Color(0xFFFFCA28),
        const Color(0xFF66BB6A), // Green
        ((m - 0.55) / 0.2).clamp(0, 1),
      )!;
    } else {
      return Color.lerp(
        const Color(0xFF66BB6A),
        const Color(0xFF2E7D32), // Deep green
        ((m - 0.75) / 0.25).clamp(0, 1),
      )!;
    }
  }
}
