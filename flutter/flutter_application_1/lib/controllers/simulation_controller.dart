import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Core simulation state manager for the PI-Hybrid Digital Twin.
/// Compresses 24 hours of solar irrigation data into 60 seconds.
class SimulationController extends ChangeNotifier {
  // === SIMULATION STATE ===
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  double _simulationHour = 6.0; // Start at 6 AM
  double get simulationHour => _simulationHour;

  double _irradiance = 0.0; // W/m² (0-1000)
  double get irradiance => _irradiance;

  double _predictedIrradiance = 0.0;
  double get predictedIrradiance => _predictedIrradiance;

  double _batteryLevel = 0.65;
  double get batteryLevel => _batteryLevel;

  double _tankLevel = 0.80;
  double get tankLevel => _tankLevel;

  bool _pumpActive = false;
  bool get pumpActive => _pumpActive;

  bool _aiAutoActive = false;
  bool get aiAutoActive => _aiAutoActive;

  bool _manualOverride = false;
  bool get manualOverride => _manualOverride;

  // Soil moisture grid (6x8 = 48 cells)
  late List<double> _soilMoisture;
  List<double> get soilMoisture => _soilMoisture;

  // Chart data points
  final List<FlSpot> _actualData = [];
  List<FlSpot> get actualData => List.unmodifiable(_actualData);

  final List<FlSpot> _predictedData = [];
  List<FlSpot> get predictedData => List.unmodifiable(_predictedData);

  // Event notifications
  String? _currentNotification;
  String? get currentNotification => _currentNotification;

  Timer? _timer;
  final Random _rng = Random(42);

  // Cloud event state
  bool _cloudEventActive = false;
  double _cloudStartHour = 0;
  double _cloudDuration = 0;

  SimulationController() {
    _soilMoisture = List.generate(48, (i) => 0.3 + _rng.nextDouble() * 0.2);
  }

  // === CONTROLS ===
  void startDemo() {
    _isRunning = true;
    _simulationHour = 0.0;
    _actualData.clear();
    _predictedData.clear();
    _batteryLevel = 0.20;
    _tankLevel = 0.85;
    _pumpActive = false;
    _aiAutoActive = true;
    _cloudEventActive = false;
    _soilMoisture = List.generate(48, (i) => 0.3 + _rng.nextDouble() * 0.15);
    _currentNotification = '🚀 Demo Mode Activated — AI Auto-Pilot ON';
    notifyListeners();

    // Schedule cloud event between hour 10-14
    _cloudStartHour = 10.0 + _rng.nextDouble() * 2;
    _cloudDuration = 1.5 + _rng.nextDouble() * 1.5;

    // 60 seconds = 24 hours → tick every ~42ms for smooth animation
    const tickInterval = Duration(milliseconds: 42);
    const hoursPerTick = 24.0 / (60000 / 42); // ~0.0168 hours per tick

    _timer?.cancel();
    _timer = Timer.periodic(tickInterval, (timer) {
      _simulationHour += hoursPerTick;

      if (_simulationHour >= 24.0) {
        stopDemo();
        return;
      }

      _updatePhysics();
      notifyListeners();
    });
  }

  void stopDemo() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _currentNotification = '✅ Demo Complete — 24h Cycle Finished';
    notifyListeners();
  }

  void toggleManualPump() {
    _manualOverride = !_manualOverride;
    if (_manualOverride) {
      _pumpActive = true;
      _currentNotification = '⚙️ Manual Pump Override: ON';
    } else {
      _currentNotification = '⚙️ Manual Override Released → AI Control';
    }
    notifyListeners();
  }

  void toggleAiAutoPilot() {
    _aiAutoActive = !_aiAutoActive;
    _currentNotification = _aiAutoActive
        ? '🤖 AI Auto-Pilot: ENGAGED'
        : '🤖 AI Auto-Pilot: DISENGAGED';
    notifyListeners();
  }

  void clearNotification() {
    _currentNotification = null;
    notifyListeners();
  }

  // === PHYSICS ENGINE ===
  void _updatePhysics() {
    final h = _simulationHour;

    // 1. Solar Irradiance — sinusoidal curve with cloud events
    double clearSkyGHI = _calcClearSkyGHI(h);

    // Check for cloud event
    bool inCloud =
        h >= _cloudStartHour && h <= _cloudStartHour + _cloudDuration;
    double cloudFactor = 1.0;

    if (inCloud && !_cloudEventActive) {
      _cloudEventActive = true;
      _currentNotification =
          '⚠️ Physics Constraint Active: Cloud cover predicted by PI-Hybrid';
    } else if (!inCloud &&
        _cloudEventActive &&
        h > _cloudStartHour + _cloudDuration) {
      _cloudEventActive = false;
      _currentNotification = '☀️ Clear sky restored — Irradiance recovering';
    }

    if (inCloud) {
      double progress = (h - _cloudStartHour) / _cloudDuration;
      cloudFactor = 0.3 + 0.2 * sin(progress * pi); // Dip to ~30-50%
    }

    // Add sensor noise
    double noise = (_rng.nextDouble() - 0.5) * 20;
    _irradiance = (clearSkyGHI * cloudFactor + noise).clamp(0, 1100).toDouble();

    // Predicted: PI-Hybrid model tracks with slight lead (no phase lag)
    double predNoise = (_rng.nextDouble() - 0.5) * 12;
    double predCloudFactor = inCloud
        ? 0.3 + 0.15 * sin(((h - _cloudStartHour) / _cloudDuration) * pi)
        : 1.0;
    _predictedIrradiance =
        (clearSkyGHI * predCloudFactor + predNoise).clamp(0, 1100).toDouble();

    // 2. Battery: charges during daylight
    if (_irradiance > 50) {
      _batteryLevel = (_batteryLevel + 0.0008).clamp(0.0, 1.0);
    } else {
      _batteryLevel = (_batteryLevel - 0.0003).clamp(0.0, 1.0);
    }

    // 3. AI Pump logic
    if (_aiAutoActive && !_manualOverride) {
      bool shouldPump = _irradiance > 200 &&
          _batteryLevel > 0.3 &&
          _tankLevel > 0.15 &&
          _soilMoisture.any((m) => m < 0.55);

      if (shouldPump && !_pumpActive) {
        _pumpActive = true;
        _currentNotification =
            '💧 AI Decision: Pump ACTIVATED — Optimal solar window';
      } else if (!shouldPump && _pumpActive && !_manualOverride) {
        _pumpActive = false;
      }
    }

    // 4. Tank & soil updates
    if (_pumpActive) {
      _tankLevel = (_tankLevel - 0.001).clamp(0.0, 1.0);
      for (int i = 0; i < _soilMoisture.length; i++) {
        _soilMoisture[i] =
            (_soilMoisture[i] + 0.002 + _rng.nextDouble() * 0.001)
                .clamp(0.0, 1.0);
      }
    } else {
      // Evaporation
      for (int i = 0; i < _soilMoisture.length; i++) {
        double evapRate = 0.0005 * (_irradiance / 1000);
        _soilMoisture[i] = (_soilMoisture[i] - evapRate).clamp(0.0, 1.0);
      }
    }

    // 5. Record chart data (every ~15 simulated minutes)
    if (_actualData.isEmpty || (h - (_actualData.last.x)) >= 0.25) {
      _actualData.add(FlSpot(h, _irradiance));
      _predictedData.add(FlSpot(h, _predictedIrradiance));
    }
  }

  double _calcClearSkyGHI(double hour) {
    if (hour < 5.5 || hour > 18.5) return 0;
    // Bell curve peaking at solar noon (~12.5 for Omdurman)
    double solarNoon = 12.5;
    double spread = 3.5;
    double peak = 980; // W/m² peak GHI for Omdurman
    return peak * exp(-pow(hour - solarNoon, 2) / (2 * spread * spread));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Simple chart data point (replicating fl_chart FlSpot for the controller)
class FlSpot {
  final double x;
  final double y;
  const FlSpot(this.x, this.y);
}
