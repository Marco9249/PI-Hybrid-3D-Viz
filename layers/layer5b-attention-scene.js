// ═══════════════════════════════════════════════════════
//  Layer 5b: Self-Attention — 3D Visualization Engine
//  Q/K/V tensor blocks, attention heatmap, data flow
// ═══════════════════════════════════════════════════════

let scene, camera, renderer, controls;
let inputBlock, queryBlock, keyBlock, valueBlock, scoreGrid, outputBlock;
let flowParticles = [];
let attentionLines = [];
let connectors = [];
let currentStep = 0;
let animSpeed = 1.0;
let temperature = 1.0;
let cameraTargetPos = new THREE.Vector3(0, 35, 80);
let orbitTargetPos = new THREE.Vector3(0, 0, 0);

const SEQ = 24;
const stepColors = [
    new THREE.Color(0x0ea5e9), // Input - sky blue
    new THREE.Color(0xec4899), // Q - pink
    new THREE.Color(0x8b5cf6), // K - purple
    new THREE.Color(0x22c55e), // V - green
    new THREE.Color(0xf59e0b), // Score - amber
    new THREE.Color(0xf472b6), // Softmax - light pink
    new THREE.Color(0x06b6d4)  // Output - cyan
];

const stepInfo = [
    { title:'01 — Input Sequence (X)', text:'BiLSTM output arrives as a matrix of 24 timesteps × 420 features (210 forward + 210 backward concatenated). This is the raw material for attention computation.', math:'X ∈ ℝ^(24 × 420)' },
    { title:'02 — Query Projection (Q)', text:'Each timestep is linearly transformed by W_q to produce a Query vector. This represents "what am I looking for?" at each point in the weather sequence.', math:'Q = X · W_q   |   W_q ∈ ℝ^(420 × 420)' },
    { title:'03 — Key Projection (K)', text:'Same input, different projection W_k. Keys represent "what do I contain?" — the label describing the information at each timestep.', math:'K = X · W_k   |   W_k ∈ ℝ^(420 × 420)' },
    { title:'04 — Value Projection (V)', text:'The third projection W_v extracts the actual payload. If Query matches Key, this Value vector is what gets extracted and aggregated.', math:'V = X · W_v   |   W_v ∈ ℝ^(420 × 420)' },
    { title:'05 — Score Computation (S)', text:'Dot-product of Q and transposed K, divided by √420 for numerical stability. Creates a 24×24 compatibility matrix: how much should timestep i attend to timestep j?', math:'S = Q · Kᵀ / √420   |   S ∈ ℝ^(24 × 24)' },
    { title:'06 — Softmax Normalization (A)', text:'Raw scores are converted to a probability distribution via softmax. Each row sums to 1.0, representing the attention weight distribution for that timestep.', math:'A_ij = exp(S_ij) / Σ_k exp(S_ik)' },
    { title:'07 — Context Output (Y)', text:'The final weighted sum: attention weights (A) multiplied by Values (V). Each output timestep is now a weighted blend of ALL input timesteps, enriched with global context.', math:'Y = A · V   |   Y ∈ ℝ^(24 × 420)' }
];

function init() {
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x030712);
    scene.fog = new THREE.FogExp2(0x030712, 0.008);

    camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 500);
    camera.position.set(0, 35, 80);

    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    document.getElementById('canvas-container').appendChild(renderer.domElement);

    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.autoRotate = true;
    controls.autoRotateSpeed = 0.3;

    // Lights
    scene.add(new THREE.AmbientLight(0x334466, 0.5));
    const pl1 = new THREE.PointLight(0xf59e0b, 1.2, 150);
    pl1.position.set(0, 40, 0);
    scene.add(pl1);
    const pl2 = new THREE.PointLight(0xec4899, 0.6, 100);
    pl2.position.set(-30, 10, 30);
    scene.add(pl2);

    // Grid
    const grid = new THREE.GridHelper(120, 60, 0x1e3a5f, 0x0f1a2e);
    grid.position.y = -20;
    scene.add(grid);
    scene.add(new THREE.AxesHelper(8));

    buildTensorBlocks();
    buildAttentionGrid();
    buildFlowParticles();
    buildConnectors();

    setupEvents();
    animate();

    // Hide loader after init
    setTimeout(() => setStep(0), 200);
}

// ── Tensor Blocks ─────────────────────────────────
function makeTensorBlock(w, h, d, color, label, pos, segW=12, segH=4) {
    // Segmented geometry to look like a matrix/grid of data
    const geo = new THREE.BoxGeometry(w, h, d, segW, segH, 1);
    const mat = new THREE.MeshPhongMaterial({
        color: color,
        emissive: new THREE.Color(color).multiplyScalar(0.4),
        transparent: true,
        opacity: 0.6,
        wireframe: false,
        blending: THREE.AdditiveBlending
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.copy(pos);
    scene.add(mesh);

    // Glowing wireframe grid (shows the data cells)
    const wireMat = new THREE.MeshBasicMaterial({ 
        color, 
        wireframe: true, 
        transparent: true, 
        opacity: 0.5,
        blending: THREE.AdditiveBlending 
    });
    const wire = new THREE.Mesh(geo, wireMat);
    wire.position.copy(pos);
    scene.add(wire);

    // Subtle inner glow plane
    const glowGeo = new THREE.PlaneGeometry(w * 1.5, d * 1.5);
    const glowMat = new THREE.MeshBasicMaterial({
        color: color,
        transparent: true,
        opacity: 0.15,
        blending: THREE.AdditiveBlending,
        depthWrite: false
    });
    const glow = new THREE.Mesh(glowGeo, glowMat);
    glow.rotation.x = -Math.PI / 2;
    glow.position.copy(pos);
    glow.position.y -= h/2;
    scene.add(glow);

    // Label
    addLabel(label, pos.x, pos.y + h/2 + 3, pos.z, color);

    return { mesh, wire, glow, basePos: pos.clone() };
}

function buildTensorBlocks() {
    inputBlock  = makeTensorBlock(12, 4, 6, 0x0ea5e9, 'INPUT X [24×420]', new THREE.Vector3(-45, 0, 0), 12, 4);
    queryBlock  = makeTensorBlock(8, 4, 6, 0xec4899, 'QUERY Q [24×d_k]',  new THREE.Vector3(-15, 12, 0), 8, 4);
    keyBlock    = makeTensorBlock(8, 4, 6, 0x8b5cf6, 'KEY K [24×d_k]',    new THREE.Vector3(-15, 0, 0), 8, 4);
    valueBlock  = makeTensorBlock(8, 4, 6, 0x22c55e, 'VALUE V [24×d_v]',  new THREE.Vector3(-15, -12, 0), 8, 4);
    outputBlock = makeTensorBlock(12, 4, 6, 0x06b6d4, 'OUTPUT Y [24×420]', new THREE.Vector3(45, 0, 0), 12, 4);
}

function addLabel(text, x, y, z, color) {
    const canvas = document.createElement('canvas');
    canvas.width = 512; canvas.height = 64;
    const ctx = canvas.getContext('2d');
    ctx.font = 'bold 24px Space Mono, monospace';
    ctx.fillStyle = '#' + new THREE.Color(color).getHexString();
    ctx.textAlign = 'center';
    ctx.fillText(text, 256, 40);
    const tex = new THREE.CanvasTexture(canvas);
    const mat = new THREE.SpriteMaterial({ map: tex, transparent: true, opacity: 0.8 });
    const sprite = new THREE.Sprite(mat);
    sprite.position.set(x, y, z);
    sprite.scale.set(12, 1.5, 1);
    scene.add(sprite);
}

// ── Attention Score Grid (24×24 heatmap) ──────────
function buildAttentionGrid() {
    const cellSize = 1.0;
    const gridSize = 12; // visual representation
    const startX = 15;
    const startZ = -gridSize * cellSize / 2;
    const startY = -gridSize * cellSize / 2;

    for (let i = 0; i < gridSize; i++) {
        for (let j = 0; j < gridSize; j++) {
            const geo = new THREE.BoxGeometry(cellSize * 0.85, cellSize * 0.85, 0.3);
            const val = Math.random();
            const color = new THREE.Color().lerpColors(new THREE.Color(0x0f0f2a), new THREE.Color(0xf59e0b), val);
            const mat = new THREE.MeshPhongMaterial({ 
                color, 
                emissive: color.clone().multiplyScalar(0.5),
                transparent: true, 
                opacity: 0.8,
                blending: THREE.AdditiveBlending
            });
            const mesh = new THREE.Mesh(geo, mat);
            mesh.position.set(startX + i * cellSize, startY + j * cellSize, 0);
            mesh.userData = { row: i, col: j, baseVal: val };
            scene.add(mesh);
            attentionLines.push(mesh);
        }
    }
    
    // Background glow for the grid
    const bgGeo = new THREE.PlaneGeometry(gridSize * cellSize + 2, gridSize * cellSize + 2);
    const bgMat = new THREE.MeshBasicMaterial({ color: 0xf59e0b, transparent: true, opacity: 0.05, blending: THREE.AdditiveBlending, depthWrite: false });
    const bgMesh = new THREE.Mesh(bgGeo, bgMat);
    bgMesh.position.set(startX + (gridSize * cellSize)/2 - cellSize/2, 0, -0.5);
    scene.add(bgMesh);

    addLabel('SCORE MATRIX [24×24]', startX + gridSize * cellSize / 2 - cellSize/2, gridSize * cellSize / 2 + 3, 0, 0xf59e0b);
}

// ── Flow Particles ───────────────────────────────
function buildFlowParticles() {
    // Represent data packets as small cubes instead of spheres
    const geo = new THREE.BoxGeometry(0.5, 0.5, 0.5);

    // Input → Q/K/V flow
    for (let i = 0; i < 45; i++) {
        const color = [0xec4899, 0x8b5cf6, 0x22c55e][i % 3];
        const mat = new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.8, blending: THREE.AdditiveBlending });
        const mesh = new THREE.Mesh(geo, mat);
        const targetY = [12, 0, -12][i % 3];
        mesh.userData = {
            type: 'split',
            progress: Math.random(),
            speed: 0.15 + Math.random() * 0.15,
            startX: -45, endX: -15,
            startY: 0, endY: targetY,
            wave: Math.random() * Math.PI * 2
        };
        scene.add(mesh);
        flowParticles.push(mesh);
    }

    // Q/K → Score flow
    for (let i = 0; i < 30; i++) {
        const isQ = i % 2 === 0;
        const mat = new THREE.MeshBasicMaterial({ color: isQ ? 0xec4899 : 0x8b5cf6, transparent: true, opacity: 0.6, blending: THREE.AdditiveBlending });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.userData = {
            type: 'score',
            progress: Math.random(),
            speed: 0.2 + Math.random() * 0.15,
            startX: -15, endX: 15,
            startY: isQ ? 12 : 0, endY: (Math.random() - 0.5) * 10,
            wave: Math.random() * Math.PI * 2
        };
        scene.add(mesh);
        flowParticles.push(mesh);
    }

    // Score+V → Output flow
    for (let i = 0; i < 30; i++) {
        const mat = new THREE.MeshBasicMaterial({ color: 0x06b6d4, transparent: true, opacity: 0.7, blending: THREE.AdditiveBlending });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.userData = {
            type: 'output',
            progress: Math.random(),
            speed: 0.2 + Math.random() * 0.15,
            startX: 15, endX: 45,
            startY: (Math.random() - 0.5) * 10, endY: 0,
            wave: Math.random() * Math.PI * 2
        };
        scene.add(mesh);
        flowParticles.push(mesh);
    }
}

function buildConnectors() {
    const mat = new THREE.LineDashedMaterial({ color: 0xffffff, transparent: true, opacity: 0.1, dashSize: 0.5, gapSize: 0.5 });
    
    const lines = [
        [[-45,0,0], [-15,12,0]], // Input to Q
        [[-45,0,0], [-15,0,0]],  // Input to K
        [[-45,0,0], [-15,-12,0]],// Input to V
        [[-15,12,0], [15,6,0]],  // Q to Score
        [[-15,0,0], [15,0,0]],   // K to Score
        [[15,0,0], [45,0,0]],    // Score to Output
        [[-15,-12,0], [45,0,0]]  // V to Output
    ];

    lines.forEach(pts => {
        const geo = new THREE.BufferGeometry().setFromPoints(pts.map(p => new THREE.Vector3(...p)));
        const line = new THREE.Line(geo, mat);
        line.computeLineDistances();
        scene.add(line);
        connectors.push(line);
    });
}

// ── Step Control ─────────────────────────────────
function setStep(s) {
    currentStep = s;
    const info = stepInfo[s];
    document.getElementById('desc-title').innerText = info.title;
    document.getElementById('desc-text').innerText = info.text;
    document.getElementById('desc-math').innerText = info.math;

    document.querySelectorAll('.step-btn').forEach((btn, idx) => {
        btn.classList.toggle('active', idx === s);
    });

    // Update block opacities based on step
    const blocks = [inputBlock, queryBlock, keyBlock, valueBlock];
    blocks.forEach((b, i) => {
        const shouldHighlight = (s === 0 && i === 0) || (s === 1 && i === 1) || (s === 2 && i === 2) || (s === 3 && i === 3) || (s >= 1 && i === 0) || s >= 4;
        b.mesh.material.opacity = shouldHighlight ? 0.9 : 0.1;
        b.wire.material.opacity = shouldHighlight ? 0.8 : 0.05;
        b.glow.material.opacity = shouldHighlight ? 0.25 : 0.02;
    });

    // Score grid highlight
    attentionLines.forEach(cell => {
        cell.material.opacity = (s >= 4) ? 0.9 : 0.05;
        if (s === 5) {
            // Softmax highlight
            cell.material.color.lerpColors(new THREE.Color(0xf59e0b), new THREE.Color(0xf472b6), 0.5);
        } else {
            // Revert color based on temperature
            const rawScore = cell.userData.baseVal * 3 - 1.5;
            const scaled = rawScore / temperature;
            const expVal = Math.exp(scaled);
            const brightness = Math.min(expVal / (expVal + 1), 1);
            cell.material.color.lerpColors(new THREE.Color(0x0f0f2a), new THREE.Color(0xf59e0b), brightness);
        }
    });

    // Output block
    outputBlock.mesh.material.opacity = (s === 6) ? 0.9 : 0.1;
    outputBlock.wire.material.opacity = (s === 6) ? 0.8 : 0.05;
    outputBlock.glow.material.opacity = (s === 6) ? 0.25 : 0.02;

    // Camera targets for cinematic view
    if (s === 0) {
        cameraTargetPos.set(-45, 10, 50);
        orbitTargetPos.set(-45, 0, 0);
    } else if (s === 1) {
        cameraTargetPos.set(-15, 25, 40);
        orbitTargetPos.set(-15, 12, 0);
    } else if (s === 2) {
        cameraTargetPos.set(-15, 10, 40);
        orbitTargetPos.set(-15, 0, 0);
    } else if (s === 3) {
        cameraTargetPos.set(-15, -10, 40);
        orbitTargetPos.set(-15, -12, 0);
    } else if (s === 4 || s === 5) {
        cameraTargetPos.set(15, 20, 60);
        orbitTargetPos.set(15, 0, 0);
    } else if (s === 6) {
        cameraTargetPos.set(45, 10, 50);
        orbitTargetPos.set(45, 0, 0);
    }
}

function setupEvents() {
    window.addEventListener('resize', () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });

    document.getElementById('slider-speed').addEventListener('input', (e) => {
        animSpeed = parseFloat(e.target.value);
        document.getElementById('val-speed').innerText = animSpeed.toFixed(1) + '×';
    });

    document.getElementById('slider-temp').addEventListener('input', (e) => {
        temperature = parseFloat(e.target.value);
        document.getElementById('val-temp').innerText = temperature.toFixed(1);
        // Update heatmap with new temperature
        attentionLines.forEach(cell => {
            const rawScore = cell.userData.baseVal * 3 - 1.5;
            const scaled = rawScore / temperature;
            const expVal = Math.exp(scaled);
            const brightness = Math.min(expVal / (expVal + 1), 1);
            cell.material.color.lerpColors(new THREE.Color(0x0f0f2a), new THREE.Color(0xf59e0b), brightness);
        });
    });

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
        if (e.key >= '1' && e.key <= '7') setStep(parseInt(e.key) - 1);
        if (e.key === 'ArrowRight' && currentStep < 6) setStep(currentStep + 1);
        if (e.key === 'ArrowLeft' && currentStep > 0) setStep(currentStep - 1);
    });
}

// ── Animation Loop ──────────────────────────────
let clock = 0;

function animate() {
    requestAnimationFrame(animate);
    
    // Smooth camera and target interpolation
    camera.position.lerp(cameraTargetPos, 0.03);
    controls.target.lerp(orbitTargetPos, 0.05);
    controls.update();
    
    clock += 0.016 * animSpeed;

    // Tensor block subtle breathing
    [inputBlock, queryBlock, keyBlock, valueBlock, outputBlock].forEach((block, i) => {
        const s = 1 + Math.sin(clock * 1.5 + i) * 0.03;
        block.mesh.scale.set(s, s, s);
        block.wire.scale.set(s, s, s);
        block.glow.scale.set(s, s, 1);
    });

    // Flow particles
    flowParticles.forEach(p => {
        const d = p.userData;
        let shouldAnimate = false;

        if (d.type === 'split') shouldAnimate = currentStep >= 0 && currentStep <= 3;
        if (d.type === 'score') shouldAnimate = currentStep >= 4 && currentStep <= 5;
        if (d.type === 'output') shouldAnimate = currentStep >= 6;

        if (shouldAnimate) {
            d.progress += d.speed * 0.016 * animSpeed;
            if (d.progress > 1) d.progress = 0;

            const t = d.progress;
            p.position.x = d.startX + (d.endX - d.startX) * t;
            p.position.y = d.startY + (d.endY - d.startY) * t + Math.sin(t * Math.PI * 2 + d.wave) * 2;
            p.position.z = Math.sin(t * Math.PI + d.wave) * 3;
            
            // Cubes rotate as they flow
            p.rotation.x += 0.05;
            p.rotation.y += 0.05;

            p.material.opacity = Math.sin(t * Math.PI) * 1.0;
            p.scale.setScalar(0.5 + Math.sin(t * Math.PI) * 1.0);
        } else {
            p.material.opacity *= 0.85;
            if (p.material.opacity < 0.01) p.material.opacity = 0;
        }
    });

    // Connectors animation (marching ants effect)
    connectors.forEach(line => {
        line.material.dashOffset -= 0.05 * animSpeed;
        line.material.opacity = (currentStep > 0 && currentStep < 7) ? 0.3 : 0.05;
    });

    // Attention grid animation (wave effect)
    if (currentStep >= 4) {
        attentionLines.forEach((cell, idx) => {
            const row = cell.userData.row;
            const col = cell.userData.col;
            const wave = Math.sin(clock * 2 + row * 0.2 + col * 0.2) * 0.5;
            cell.position.z = wave;
        });
    }

    // Score scale display
    document.getElementById('stat-scale').innerText = (1 / Math.sqrt(420)).toFixed(3);

    renderer.render(scene, camera);
}

window.setStep = setStep;
init();
