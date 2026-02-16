import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/simulation_controller.dart';
import '../widgets/farm/farm_visualizer.dart';
import '../widgets/control/control_panel.dart';
import '../widgets/neural/model_web_viewer.dart';
import '../widgets/charts/irradiance_chart.dart';

class DigitalTwinScreen extends StatefulWidget {
  const DigitalTwinScreen({super.key});

  @override
  State<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends State<DigitalTwinScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _fabPulse;

  final List<_TabItem> _tabs = const [
    _TabItem(Icons.landscape_rounded, 'Digital Twin'),
    _TabItem(Icons.dashboard_customize_rounded, 'Control'),
    _TabItem(Icons.hub_rounded, 'Neural'),
    _TabItem(Icons.show_chart_rounded, 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    _fabPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fabPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sim = context.watch<SimulationController>();

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(sim),
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentTab,
            children: const [
              FarmVisualizer(),
              ControlPanel(),
              ModelWebViewer(),
              IrradianceChart(),
            ],
          ),

          // Toast notification
          if (sim.currentNotification != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: _NotificationToast(
                message: sim.currentNotification!,
                onDismiss: () => sim.clearNotification(),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildFab(sim),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(SimulationController sim) {
    String timeStr = _formatTime(sim.simulationHour);
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sim.isRunning
                  ? const Color(0xFF00FF88)
                  : const Color(0xFF8892B0),
              boxShadow: sim.isRunning
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00FF88).withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'NEUROTWIN',
            style: TextStyle(
              letterSpacing: 4,
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (sim.isRunning) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withOpacity(0.3),
                ),
              ),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: Color(0xFF00F0FF),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFab(SimulationController sim) {
    return AnimatedBuilder(
      animation: _fabPulse,
      builder: (context, child) {
        double scale = sim.aiAutoActive ? 1.0 + _fabPulse.value * 0.08 : 1.0;
        double glow = sim.aiAutoActive ? _fabPulse.value * 0.5 : 0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (sim.aiAutoActive)
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withOpacity(glow),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                if (sim.isRunning) {
                  sim.stopDemo();
                } else {
                  sim.startDemo();
                }
              },
              icon: Icon(
                sim.isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 22,
              ),
              label: Text(
                sim.isRunning ? 'STOP' : 'START DEMO',
                style: const TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A).withOpacity(0.85),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (i) {
                  bool active = i == _currentTab;
                  return GestureDetector(
                    onTap: () => setState(() => _currentTab = i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF00F0FF).withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: active
                            ? Border.all(
                                color:
                                    const Color(0xFF00F0FF).withOpacity(0.25),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tabs[i].icon,
                            size: 22,
                            color: active
                                ? const Color(0xFF00F0FF)
                                : const Color(0xFF8892B0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tabs[i].label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              color: active
                                  ? const Color(0xFF00F0FF)
                                  : const Color(0xFF8892B0),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(double hour) {
    int h = hour.floor() % 24;
    int m = ((hour - hour.floor()) * 60).floor();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}

class _NotificationToast extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const _NotificationToast({required this.message, required this.onDismiss});

  @override
  State<_NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<_NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _ctrl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withOpacity(0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00F0FF).withOpacity(0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFF0F4FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper: AnimatedBuilder is just an alias for AnimatedWidget pattern
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
