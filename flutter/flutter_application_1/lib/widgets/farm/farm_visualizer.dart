import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/simulation_controller.dart';
import 'dynamic_sky_box.dart';
import 'solar_array_widget.dart';
import 'water_flow_system.dart';
import 'soil_moisture_heatmap.dart';

/// Main Farm Digital Twin view compositing sky, solar panels, water,
/// and soil layers into a living visualization.
class FarmVisualizer extends StatelessWidget {
  const FarmVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    final sim = context.watch<SimulationController>();
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // === LAYER 0: Dynamic Sky ===
        const Positioned.fill(child: DynamicSkyBox()),

        // === LAYER 1: Content ===
        Positioned.fill(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Time & Status Banner
                  _buildStatusBanner(sim),
                  const SizedBox(height: 16),

                  // Solar Array
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('SOLAR ARRAY', Icons.solar_power_rounded,
                            const Color(0xFFFFD700)),
                        const SizedBox(height: 8),
                        const SolarArrayWidget(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Water Flow
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(
                          'IRRIGATION SYSTEM',
                          Icons.water_drop_rounded,
                          const Color(0xFF00B4D8),
                        ),
                        const SizedBox(height: 8),
                        const WaterFlowSystem(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Soil Heatmap
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(
                          'FIELD SENSOR GRID',
                          Icons.grid_on_rounded,
                          const Color(0xFF66BB6A),
                        ),
                        const SizedBox(height: 8),
                        const SoilMoistureHeatmap(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Stats Row
                  _buildQuickStats(sim),
                ],
              ),
            ),
          ),
        ),

        // === LAYER 2: Scanline overlay ===
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0A0E1A).withOpacity(0.3),
                    const Color(0xFF0A0E1A).withOpacity(0.7),
                  ],
                  stops: const [0, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(SimulationController sim) {
    String dayPhase = _getDayPhase(sim.simulationHour);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dayPhase,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00F0FF),
                letterSpacing: 1,
              ),
            ),
          ),
          const Spacer(),
          _miniStat('GHI', '${sim.irradiance.toStringAsFixed(0)} W/m²',
              const Color(0xFFFFD700)),
          const SizedBox(width: 16),
          _miniStat(
            'PUMP',
            sim.pumpActive ? 'ON' : 'OFF',
            sim.pumpActive ? const Color(0xFF00FF88) : const Color(0xFF8892B0),
          ),
          const SizedBox(width: 16),
          _miniStat(
            'AI',
            sim.aiAutoActive ? 'AUTO' : 'MANUAL',
            sim.aiAutoActive
                ? const Color(0xFF00F0FF)
                : const Color(0xFF8892B0),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(SimulationController sim) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Battery',
            '${(sim.batteryLevel * 100).round()}%',
            sim.batteryLevel,
            sim.batteryLevel > 0.5
                ? const Color(0xFF00FF88)
                : const Color(0xFFFFCA28),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Tank',
            '${(sim.tankLevel * 100).round()}%',
            sim.tankLevel,
            sim.tankLevel > 0.3
                ? const Color(0xFF00B4D8)
                : const Color(0xFFEF5350),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Avg Soil',
            '${(sim.soilMoisture.reduce((a, b) => a + b) / sim.soilMoisture.length * 100).round()}%',
            sim.soilMoisture.reduce((a, b) => a + b) / sim.soilMoisture.length,
            const Color(0xFF66BB6A),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, double pct, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct.clamp(0, 1),
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation(color.withOpacity(0.7)),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.45),
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
      child: child,
    );
  }

  Widget _sectionLabel(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _getDayPhase(double hour) {
    if (hour < 5) return '🌙 NIGHT';
    if (hour < 7) return '🌅 DAWN';
    if (hour < 10) return '☀️ MORNING';
    if (hour < 14) return '☀️ SOLAR PEAK';
    if (hour < 17) return '🌤 AFTERNOON';
    if (hour < 19) return '🌇 DUSK';
    return '🌙 NIGHT';
  }
}
