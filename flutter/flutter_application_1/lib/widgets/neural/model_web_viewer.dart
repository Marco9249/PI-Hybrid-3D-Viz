import 'package:flutter/material.dart';

/// Neural Architecture Inspector — Shows the PI-Hybrid CNN-BiLSTM
/// model layers as an interactive visual with layer selector.
/// Uses a built-in visualization since WebView requires platform setup.
class ModelWebViewer extends StatefulWidget {
  const ModelWebViewer({super.key});

  @override
  State<ModelWebViewer> createState() => _ModelWebViewerState();
}

class _ModelWebViewerState extends State<ModelWebViewer>
    with SingleTickerProviderStateMixin {
  int _selectedLayer = -1; // -1 means overview
  late AnimationController _pulseCtrl;

  // Layer definitions matching the PI-Hybrid CNN-BiLSTM architecture (Table III)
  static const List<_LayerInfo> _layers = [
    _LayerInfo(
      index: 0,
      name: 'Input',
      type: 'InputLayer',
      shape: '(24, 15)',
      params: 0,
      color: Color(0xFF00F0FF),
      description: '24-hour look-back window × 15 physics features\n'
          'Features: GHI, Clear-Sky, KTcalc, Log-KTsat,\n'
          'Volatility, DNI, DHI, RH, Tdew, Tamb, Twet,\n'
          'Sin/Cos Hour, Sin/Cos Day',
      icon: Icons.input_rounded,
    ),
    _LayerInfo(
      index: 1,
      name: 'Conv1D',
      type: '1D-CNN',
      shape: '(22, 64)',
      params: 2944,
      color: Color(0xFF7C4DFF),
      description: '64 filters, Kernel Size 3\n'
          'Local temporal gradient extraction\n'
          'Captures short-term weather patterns',
      icon: Icons.filter_list_rounded,
    ),
    _LayerInfo(
      index: 2,
      name: 'BatchNorm',
      type: 'Batch Normalization',
      shape: '(22, 64)',
      params: 256,
      color: Color(0xFF448AFF),
      description: 'Normalizes activations for training stability\n'
          'Reduces internal covariate shift\n'
          'Enables higher learning rates',
      icon: Icons.tune_rounded,
    ),
    _LayerInfo(
      index: 3,
      name: 'ReLU',
      type: 'Activation',
      shape: '(22, 64)',
      params: 0,
      color: Color(0xFF00E676),
      description: 'Rectified Linear Unit activation\n'
          'f(x) = max(0, x)\n'
          'Introduces non-linearity',
      icon: Icons.trending_up_rounded,
    ),
    _LayerInfo(
      index: 4,
      name: 'Dropout₁',
      type: 'Dropout',
      shape: '(22, 64)',
      params: 0,
      color: Color(0xFFFF5252),
      description: 'Regularization layer (Bayesian-tuned rate)\n'
          'Prevents co-adaptation of neurons\n'
          'Critical for arid-climate noise handling',
      icon: Icons.blur_on_rounded,
    ),
    _LayerInfo(
      index: 5,
      name: 'BiLSTM',
      type: 'Bidirectional LSTM',
      shape: '(210)',
      params: 485040,
      color: Color(0xFFFFD700),
      description: '210 bidirectional units (105 forward + 105 backward)\n'
          'Captures temporal causality in both directions\n'
          'Core sequence modeling engine — 98.5% of total params',
      icon: Icons.swap_horiz_rounded,
    ),
    _LayerInfo(
      index: 6,
      name: 'Dropout₂',
      type: 'Dropout',
      shape: '(210)',
      params: 0,
      color: Color(0xFFFF5252),
      description: 'Post-BiLSTM regularization\n'
          'Prevents overfitting on dust-storm noise\n'
          'Bayesian-optimized dropout rate',
      icon: Icons.blur_on_rounded,
    ),
    _LayerInfo(
      index: 7,
      name: 'Dense',
      type: 'Fully Connected',
      shape: '(32)',
      params: 6752,
      color: Color(0xFFFF6E40),
      description: '32-unit dense layer\n'
          'Feature compression before regression\n'
          'Learns high-level irradiance patterns',
      icon: Icons.layers_rounded,
    ),
    _LayerInfo(
      index: 8,
      name: 'ReLU₂',
      type: 'Activation',
      shape: '(32)',
      params: 0,
      color: Color(0xFF00E676),
      description: 'Second ReLU activation\n'
          'Non-linear transformation on compressed features',
      icon: Icons.trending_up_rounded,
    ),
    _LayerInfo(
      index: 9,
      name: 'Output Dense',
      type: 'Dense',
      shape: '(1)',
      params: 33,
      color: Color(0xFFFF00E5),
      description: 'Single neuron — GHI prediction output\n'
          'Linear activation (regression)\n'
          'Predicts next-hour solar irradiance in W/m²',
      icon: Icons.output_rounded,
    ),
    _LayerInfo(
      index: 10,
      name: 'Regression',
      type: 'Loss: MSE',
      shape: '(1)',
      params: 0,
      color: Color(0xFF00FF88),
      description: 'Mean Squared Error optimization\n'
          'RMSE: 19.53 W/m² | R²: 0.997\n'
          'Outperforms Transformers (30.64 W/m²)',
      icon: Icons.assessment_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E1A), Color(0xFF0D1220)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 56),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'NEURAL ANATOMY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF00E5).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFF00E5).withOpacity(0.2),
                      ),
                    ),
                    child: const Text(
                      '492,200 PARAMS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF00E5),
                        letterSpacing: 1,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main content
            Expanded(
              child: _selectedLayer == -1
                  ? _buildOverview()
                  : _buildLayerDetail(_layers[_selectedLayer]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        children: [
          // Architecture flow
          for (int i = 0; i < _layers.length; i++) ...[
            _buildLayerCard(_layers[i]),
            if (i < _layers.length - 1) _buildConnector(_layers[i].color),
          ],
        ],
      ),
    );
  }

  Widget _buildLayerCard(_LayerInfo layer) {
    bool isBiLSTM = layer.index == 5;

    return GestureDetector(
      onTap: () => setState(() => _selectedLayer = layer.index),
      child: AnimatedBuilder4(
        animation: _pulseCtrl,
        builder: (context, _) {
          double glow = isBiLSTM ? _pulseCtrl.value * 0.15 : 0;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: layer.color.withOpacity(0.2 + glow),
                width: isBiLSTM ? 1.5 : 1,
              ),
              boxShadow: [
                if (isBiLSTM)
                  BoxShadow(
                    color: layer.color.withOpacity(glow),
                    blurRadius: 12,
                  ),
              ],
            ),
            child: Row(
              children: [
                // Layer index badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: layer.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: layer.color.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${layer.index}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: layer.color,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layer.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: layer.color,
                        ),
                      ),
                      Text(
                        '${layer.type}  •  ${layer.shape}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.4),
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
                // Params
                if (layer.params > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatParams(layer.params),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.4),
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white.withOpacity(0.2),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnector(Color color) {
    return SizedBox(
      height: 20,
      child: Center(
        child: Container(
          width: 2,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.4),
                color.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerDetail(_LayerInfo layer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          GestureDetector(
            onTap: () => setState(() => _selectedLayer = -1),
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios_rounded,
                    size: 14, color: Colors.white.withOpacity(0.4)),
                Text(
                  'Back to Overview',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Layer hero card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: layer.color.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: layer.color.withOpacity(0.08),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              children: [
                // Icon + Name
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: layer.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: layer.color.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: layer.color.withOpacity(0.15),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(layer.icon, size: 28, color: layer.color),
                ),
                const SizedBox(height: 16),
                Text(
                  'LAYER ${layer.index}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  layer.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: layer.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  layer.type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 20),

                // Specs
                _specRow('Output Shape', layer.shape),
                _specRow('Parameters', _formatParams(layer.params)),
                _specRow('Layer Index', '${layer.index}/10'),
                const SizedBox(height: 16),

                // Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: layer.color.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    layer.description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Colors.white.withOpacity(0.6),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Navigation
          Row(
            children: [
              if (layer.index > 0)
                Expanded(
                  child: _navButton(
                    'Layer ${layer.index - 1} — ${_layers[layer.index - 1].name}',
                    Icons.arrow_back_rounded,
                    () => setState(() => _selectedLayer = layer.index - 1),
                  ),
                ),
              if (layer.index > 0 && layer.index < _layers.length - 1)
                const SizedBox(width: 10),
              if (layer.index < _layers.length - 1)
                Expanded(
                  child: _navButton(
                    'Layer ${layer.index + 1} — ${_layers[layer.index + 1].name}',
                    Icons.arrow_forward_rounded,
                    () => setState(() => _selectedLayer = layer.index + 1),
                    trailing: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00F0FF),
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String text, IconData icon, VoidCallback onTap,
      {bool trailing = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!trailing) ...[
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.4)),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.4)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatParams(int params) {
    if (params == 0) return '0';
    if (params >= 1000) return '${(params / 1000).toStringAsFixed(1)}K';
    return '$params';
  }
}

class _LayerInfo {
  final int index;
  final String name;
  final String type;
  final String shape;
  final int params;
  final Color color;
  final String description;
  final IconData icon;

  const _LayerInfo({
    required this.index,
    required this.name,
    required this.type,
    required this.shape,
    required this.params,
    required this.color,
    required this.description,
    required this.icon,
  });
}

class AnimatedBuilder4 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  const AnimatedBuilder4({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, null);
}
