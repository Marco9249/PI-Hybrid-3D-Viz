<div align="center">

# 🌌 PI-Hybrid 3D Viz

### Physics-Informed Solar Forecasting Intelligence

---

## 🚀 **SYSTEM CONTROL CENTER** 🚀

<a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/">
  <img src="https://img.shields.io/badge/LAUNCH_SYSTEM-LOGIN_NOW-00f2ff?style=for-the-badge&logo=google-chrome&logoColor=black&labelColor=101010" height="60">
</a>

<br>

<a href="https://www.techrxiv.org//1376729">
  <img src="https://img.shields.io/badge/SCIENTIFIC_PAPER-READ_ON_TECHRXIV-0056D2?style=for-the-badge&logo=googlescholar&logoColor=white" height="40">
</a>
&nbsp; &nbsp;
<a href="https://www.linkedin.com/in/mohammed924">
  <img src="https://img.shields.io/badge/LINKEDIN-CONNECT_WITH_ME-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" height="40">
</a>

</div>

---

## 📖 **Overview**

This project is a high-fidelity **interactive 3D visualization** of the **Physics-Informed Hybrid CNN-BiLSTM** model proposed in our research paper: *"Physics Is All You Need: Outperforming Self-Attention Mechanisms in Solar Irradiance Forecasting"*.

It allows users to dissect the internal mechanisms of solar irradiance forecasting, bridging the gap between "Black Box" Deep Learning and atmospheric physics through **scrollytelling**.

---

## 🔬 **New Research Highlights**

* **Peak Accuracy:** RMSE **19.53 W/m²** (R² = 0.9969) on Sudanese climate data.
* **The Complexity Paradox:** Explicit Physics is a superior "Attention Mechanism." Adding Self-Attention actually *degraded* performance (19.53 → 30.64 RMSE).
* **Ablation Control Panel:** Chapter 08 now includes a live dashboard where you can toggle model layers (Physics, CNN, Memory) to see failure modes in real-time.
* **Weather Time Machine:** Chapter 09 allows replaying extreme weather events (Dust Storms, Cloudy Days) with live GHI stats for all models.

---

## 🧠 **Model Architecture (Sequential Hybrid)**

The system visualizes a sequential deep learning pipeline designed to capture both local cloud dynamics and long-term solar trends:

### 1. **Physics-Informed Input Layer (Tensor Shape: 24×15)**

Unlike standard data-driven models, our input tensor incorporates **15 distinct features** grounded in atmospheric physics (Clear Sky GHI, Clearness Index, Volatility, etc.).

### 2. **Spatial Feature Extraction (1D-CNN)**

Extracts local gradients and rapid fluctuations from the temporal sequence.

### 3. **Temporal Memory Core (BiLSTM)**

210 Units processing features in both directions for full causal understanding.

---

<div align="center">

### 🔬 **NEURAL LAYER DIRECT ACCESS**

| | | |
|:---:|:---:|:---:|
| <a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer0-input.html"><img src="https://img.shields.io/badge/LAYER_0-INPUT_PHYSICS-blue?style=for-the-badge"></a> | <a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer1-conv1d.html"><img src="https://img.shields.io/badge/LAYER_1-SPATIAL_CNN-blueviolet?style=for-the-badge"></a> | <a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer2-batchnorm.html"><img src="https://img.shields.io/badge/LAYER_2-BATCHNORM-success?style=for-the-badge"></a> |
| <a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer3-relu.html"><img src="https://img.shields.io/badge/LAYER_3-RELU_ACT-orange?style=for-the-badge"></a> | <a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer4-dropout1.html"><img src="https://img.shields.io/badge/LAYER_4-DROPOUT-red?style=for-the-badge"></a> | **<a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer5-bilstm.html"><img src="https://img.shields.io/badge/LAYER_5-TEMPORAL_BILSTM-FFD700?style=for-the-badge&logo=bitcoin&logoColor=black"></a>** |
| <a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer6-dropout2.html"><img src="https://img.shields.io/badge/LAYER_6-DROPOUT-red?style=for-the-badge"></a> | <a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer7-dense.html"><img src="https://img.shields.io/badge/LAYER_7-DENSE_FC-success?style=for-the-badge"></a> | <a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer8-relu2.html"><img src="https://img.shields.io/badge/LAYER_8-RELU-orange?style=for-the-badge"></a> |
| <a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer9-output.html"><img src="https://img.shields.io/badge/LAYER_9-OUTPUT_GHI-00f2ff?style=for-the-badge"></a> | **<a href="https://Marco9249.github.io/PI-Hybrid-3D-Viz/layers/layer10-regression.html"><img src="https://img.shields.io/badge/LAYER_10-LOSS_LANDSCAPE-ff0000?style=for-the-badge"></a>** | |

<br>

![Status](https://img.shields.io/badge/Status-Research_Active-success?style=flat-square&logo=github) ![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

</div>
