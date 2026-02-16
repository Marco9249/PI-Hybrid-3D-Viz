import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/simulation_controller.dart' as sim;

/// Real-time irradiance chart showing Predicted (Cyan) vs Actual (Gold)
/// values during the simulation demo.
class IrradianceChart extends StatelessWidget {
  const IrradianceChart({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<sim.SimulationController>();

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
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'ANALYTICS DASHBOARD',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'REAL-TIME IRRADIANCE MONITORING',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: const Color(0xFF00F0FF).withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 24),

              // Main Chart
              _glassCard(
                title: 'GHI: PREDICTED vs ACTUAL',
                titleColor: const Color(0xFFFFD700),
                child: Column(
                  children: [
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendItem(
                            'PI-Hybrid Predicted', const Color(0xFF00F0FF)),
                        const SizedBox(width: 20),
                        _legendItem('Actual Measured', const Color(0xFFFFD700)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: _buildChart(controller),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Performance Metrics
              _glassCard(
                title: 'MODEL PERFORMANCE',
                titleColor: const Color(0xFFFF00E5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            'RMSE',
                            '19.53',
                            'W/m²',
                            const Color(0xFF00F0FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricCard(
                            'R²',
                            '0.997',
                            'Score',
                            const Color(0xFF00FF88),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricCard(
                            'MAE',
                            '14.21',
                            'W/m²',
                            const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Comparison bar
                    _comparisonBar('PI-Hybrid', 19.53, const Color(0xFF00F0FF)),
                    const SizedBox(height: 8),
                    _comparisonBar(
                        'Transformer', 30.64, const Color(0xFFFF5252)),
                    const SizedBox(height: 8),
                    _comparisonBar(
                        'LSTM Baseline', 55.32, const Color(0xFF8892B0)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live Stats
              _glassCard(
                title: 'LIVE SIMULATION',
                titleColor: const Color(0xFF00FF88),
                child: Column(
                  children: [
                    _liveRow(
                        'Current GHI',
                        '${controller.irradiance.toStringAsFixed(1)} W/m²',
                        const Color(0xFFFFD700)),
                    _liveRow(
                        'Predicted GHI',
                        '${controller.predictedIrradiance.toStringAsFixed(1)} W/m²',
                        const Color(0xFF00F0FF)),
                    _liveRow(
                        'Prediction Error',
                        '${(controller.irradiance - controller.predictedIrradiance).abs().toStringAsFixed(1)} W/m²',
                        const Color(0xFFFF00E5)),
                    _liveRow('Data Points', '${controller.actualData.length}',
                        const Color(0xFF00FF88)),
                    _liveRow(
                        'Simulation',
                        controller.isRunning ? 'RUNNING' : 'IDLE',
                        controller.isRunning
                            ? const Color(0xFF00FF88)
                            : const Color(0xFF8892B0)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(sim.SimulationController controller) {
    // Convert data
    List<FlSpot> actualSpots =
        controller.actualData.map((p) => FlSpot(p.x, p.y)).toList();
    List<FlSpot> predictedSpots =
        controller.predictedData.map((p) => FlSpot(p.x, p.y)).toList();

    if (actualSpots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded,
                size: 40, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 12),
            Text(
              'Press START DEMO to begin simulation',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    double maxY = 1100;
    double maxX = actualSpots.isNotEmpty ? max(actualSpots.last.x, 2.0) : 24;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 200,
          verticalInterval: 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.white.withOpacity(0.04),
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (v) => FlLine(
            color: Colors.white.withOpacity(0.04),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 200,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Text(
                '${v.toInt()}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              reservedSize: 24,
              getTitlesWidget: (v, meta) => Text(
                '${v.toInt()}h',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        lineBarsData: [
          // Actual
          LineChartBarData(
            spots: actualSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFFFFD700),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFFD700).withOpacity(0.06),
            ),
          ),
          // Predicted
          LineChartBarData(
            spots: predictedSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF00F0FF),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00F0FF).withOpacity(0.04),
            ),
            dashArray: [6, 3],
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF111827).withOpacity(0.9),
            getTooltipItems: (spots) {
              return spots.map((s) {
                bool isPredicted = s.barIndex == 1;
                return LineTooltipItem(
                  '${isPredicted ? "Pred" : "Actual"}: ${s.y.toStringAsFixed(1)} W/m²',
                  TextStyle(
                    fontSize: 10,
                    color: isPredicted
                        ? const Color(0xFF00F0FF)
                        : const Color(0xFFFFD700),
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 150),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonBar(String label, double rmse, Color color) {
    double pct = (rmse / 60).clamp(0, 1); // Max ~60

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.04),
              valueColor: AlwaysStoppedAnimation(color.withOpacity(0.7)),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${rmse.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }

  Widget _liveRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({
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
              letterSpacing: 2,
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
