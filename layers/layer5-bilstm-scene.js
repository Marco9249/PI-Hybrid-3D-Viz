// ═══════════════════════════════════════════════════════
//  Layer 5: BiLSTM — Interactive 3D Visualization Engine
//  Dual-stream temporal memory with gate mechanics
//  + Data flow particles + Sigmoid surface + Merge zone
// ═══════════════════════════════════════════════════════

let scene, camera, renderer, controls;
let forwardChain = [], backwardChain = [];
let gateParticles = [];
let dataFlowParticles = [];
let cellStateRing, cellCore;
let mergeZone;
let currentGate = 'forget';
let currentDirection = 'forward';
let timeStep = 12;
let gateBias = 0;
const SEQ_LEN = 24;

const gateColors = {
    forget: new THREE.Color(0xEF4444),
    input:  new THREE.Color(0x10B981),
    cell:   new THREE.Color(0x3B82F6),
    output: new THREE.Color(0xF59E0B)
};

const gateInfo = {
    forget: {
        title: 'Forget Gate (f_t)',
        text: 'Decides what information to discard from the cell state. A sigmoid layer outputs values between 0 (forget entirely) and 1 (keep entirely). In solar forecasting, this allows the network to forget stale weather patterns that no longer apply.',
        math: 'f_t = σ(W_f · [h_t-1, x_t] + b_f)'
    },
    input: {
        title: 'Input Gate (i_t)',
        text: 'Controls what new information gets stored in the cell state. First, a sigmoid decides which values to update. Then, a tanh creates a candidate vector of new values. Together they filter only the most relevant new solar irradiance patterns into memory.',
        math: 'i_t = σ(W_i · [h_t-1, x_t] + b_i)\nC̃_t = tanh(W_C · [h_t-1, x_t] + b_C)'
    },
    cell: {
        title: 'Cell State Update (C_t)',
        text: 'The cell state is the highway of information flow through time. Old state is multiplied by the forget gate (erasing irrelevant data), then new candidate values scaled by the input gate are added. This is the core mechanism that prevents vanishing gradients.',
        math: 'C_t = f_t ⊙ C_t-1 + i_t ⊙ C̃_t'
    },
    output: {
        title: 'Output Gate (o_t)',
        text: 'Determines what parts of the cell state to expose as the hidden state output. The cell state passes through tanh (squashing to [-1,1]) and is filtered by the sigmoid output gate. This hidden state feeds into the next Dense layer for GHI prediction.',
        math: 'o_t = σ(W_o · [h_t-1, x_t] + b_o)\nh_t = o_t ⊙ tanh(C_t)'
    }
};

function sigmoid(x) { return 1 / (1 + Math.exp(-x)); }

function init() {
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x030712);
    scene.fog = new THREE.FogExp2(0x030712, 0.012);

    camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 500);
    camera.position.set(0, 25, 55);

    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    document.getElementById('canvas-container').appendChild(renderer.domElement);

    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.autoRotate = true;
    controls.autoRotateSpeed = 0.3;
    controls.maxPolarAngle = Math.PI * 0.85;

    // Lights
    scene.add(new THREE.AmbientLight(0x4466aa, 0.4));
    const pLight = new THREE.PointLight(0x3B82F6, 1.5, 120);
    pLight.position.set(0, 30, 0);
    scene.add(pLight);
    const pLight2 = new THREE.PointLight(0x06B6D4, 0.8, 80);
    pLight2.position.set(-20, 10, 20);
    scene.add(pLight2);

    // Grid
    const grid = new THREE.GridHelper(80, 40, 0x1e3a5f, 0x0f1a2e);
    grid.position.y = -12;
    scene.add(grid);
    scene.add(new THREE.AxesHelper(10));

    buildSequenceChains();
    buildCellStateRing();
    buildGateParticles();
    buildDataFlowParticles();
    buildMergeZone();

    setupEvents();
    animate();
}

// ── Sequence Chains ──────────────────────────────────
function buildSequenceChains() {
    const nodeGeo = new THREE.SphereGeometry(0.5, 12, 12);
    const spacing = 2.5;
    const startX = -(SEQ_LEN * spacing) / 2;

    // Forward chain (top, cyan)
    for (let i = 0; i < SEQ_LEN; i++) {
        const mat = new THREE.MeshPhongMaterial({ color: 0x06B6D4, emissive: 0x023040, transparent: true, opacity: 0.8 });
        const mesh = new THREE.Mesh(nodeGeo, mat);
        mesh.position.set(startX + i * spacing, 5, 0);
        scene.add(mesh);
        forwardChain.push(mesh);
        if (i < SEQ_LEN - 1) {
            const pts = [new THREE.Vector3(startX + i * spacing + 0.6, 5, 0), new THREE.Vector3(startX + (i+1) * spacing - 0.6, 5, 0)];
            scene.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), new THREE.LineBasicMaterial({ color: 0x06B6D4, transparent: true, opacity: 0.3 })));
        }
    }

    // Backward chain (bottom, blue)
    for (let i = 0; i < SEQ_LEN; i++) {
        const mat = new THREE.MeshPhongMaterial({ color: 0x3B82F6, emissive: 0x0a1a40, transparent: true, opacity: 0.8 });
        const mesh = new THREE.Mesh(nodeGeo, mat);
        mesh.position.set(startX + i * spacing, -5, 0);
        scene.add(mesh);
        backwardChain.push(mesh);
        if (i < SEQ_LEN - 1) {
            const pts = [new THREE.Vector3(startX + i * spacing + 0.6, -5, 0), new THREE.Vector3(startX + (i+1) * spacing - 0.6, -5, 0)];
            scene.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), new THREE.LineBasicMaterial({ color: 0x3B82F6, transparent: true, opacity: 0.3 })));
        }
    }

    // Vertical merge lines
    for (let i = 0; i < SEQ_LEN; i++) {
        const pts = [new THREE.Vector3(startX + i * spacing, 4.4, 0), new THREE.Vector3(startX + i * spacing, -4.4, 0)];
        scene.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.06 })));
    }

    addTextSprite('FORWARD →', -25, 8, 0, 0x06B6D4);
    addTextSprite('← BACKWARD', -25, -8, 0, 0x3B82F6);
    addTextSprite('t=1', -(SEQ_LEN * spacing) / 2, 10, 0, 0xffffff, 0.6);
    addTextSprite('t=24', (SEQ_LEN * spacing) / 2 - spacing, 10, 0, 0xffffff, 0.6);
}

function addTextSprite(text, x, y, z, color, scale) {
    const canvas = document.createElement('canvas');
    canvas.width = 256; canvas.height = 64;
    const ctx = canvas.getContext('2d');
    ctx.font = 'bold 28px Space Mono, monospace';
    ctx.fillStyle = '#' + new THREE.Color(color).getHexString();
    ctx.textAlign = 'center';
    ctx.fillText(text, 128, 40);
    const tex = new THREE.CanvasTexture(canvas);
    const mat = new THREE.SpriteMaterial({ map: tex, transparent: true, opacity: 0.7 });
    const sprite = new THREE.Sprite(mat);
    sprite.position.set(x, y, z);
    sprite.scale.set((scale || 1) * 8, (scale || 1) * 2, 1);
    scene.add(sprite);
}

// ── Cell State Ring ──────────────────────────────────
function buildCellStateRing() {
    const torusGeo = new THREE.TorusGeometry(3, 0.15, 8, 40);
    const torusMat = new THREE.MeshPhongMaterial({ color: 0x3B82F6, emissive: 0x1a3a6a, transparent: true, opacity: 0.6 });
    cellStateRing = new THREE.Mesh(torusGeo, torusMat);
    cellStateRing.position.set(0, 0, 8);
    cellStateRing.rotation.x = Math.PI / 2;
    scene.add(cellStateRing);

    const coreGeo = new THREE.SphereGeometry(1.5, 16, 16);
    const coreMat = new THREE.MeshPhongMaterial({ color: 0x06B6D4, emissive: 0x023040, transparent: true, opacity: 0.4 });
    cellCore = new THREE.Mesh(coreGeo, coreMat);
    cellCore.position.copy(cellStateRing.position);
    scene.add(cellCore);

    addTextSprite('CELL STATE', 0, 5, 8, 0x3B82F6, 0.8);
}

// ── Gate Particles ──────────────────────────────────
function buildGateParticles() {
    const geo = new THREE.SphereGeometry(0.2, 6, 6);
    for (let i = 0; i < 60; i++) {
        const mat = new THREE.MeshBasicMaterial({ color: gateColors[currentGate], transparent: true, opacity: 0.7 });
        const mesh = new THREE.Mesh(geo, mat);
        const angle = (i / 60) * Math.PI * 2;
        const radius = 3 + (Math.random() - 0.5) * 2;
        mesh.position.set(Math.cos(angle) * radius, (Math.random() - 0.5) * 4, 8 + Math.sin(angle) * radius);
        mesh.userData = { angle, radius, speed: 0.3 + Math.random() * 0.5, yOff: mesh.position.y };
        scene.add(mesh);
        gateParticles.push(mesh);
    }
}

// ── NEW: Data Flow Particles ─────────────────────────
function buildDataFlowParticles() {
    const geo = new THREE.SphereGeometry(0.18, 6, 6);
    const spacing = 2.5;
    const startX = -(SEQ_LEN * spacing) / 2;
    const totalLen = SEQ_LEN * spacing;

    // 40 forward particles (cyan, travel left→right along top chain)
    for (let i = 0; i < 40; i++) {
        const mat = new THREE.MeshBasicMaterial({ color: 0x06B6D4, transparent: true, opacity: 0 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.userData = {
            dir: 'forward',
            progress: Math.random(), // 0..1
            speed: 0.15 + Math.random() * 0.15,
            startX, totalLen,
            yBase: 5,
            trail: Math.random() * 0.5
        };
        mesh.position.set(startX, 5, 0);
        scene.add(mesh);
        dataFlowParticles.push(mesh);
    }

    // 40 backward particles (blue, travel right→left along bottom chain)
    for (let i = 0; i < 40; i++) {
        const mat = new THREE.MeshBasicMaterial({ color: 0x3B82F6, transparent: true, opacity: 0 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.userData = {
            dir: 'backward',
            progress: Math.random(),
            speed: 0.15 + Math.random() * 0.15,
            startX, totalLen,
            yBase: -5,
            trail: Math.random() * 0.5
        };
        mesh.position.set(startX + SEQ_LEN * spacing, -5, 0);
        scene.add(mesh);
        dataFlowParticles.push(mesh);
    }

    // 20 merge particles (white, fall from forward to backward at timeStep)
    for (let i = 0; i < 20; i++) {
        const mat = new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.userData = {
            dir: 'merge',
            progress: Math.random(),
            speed: 0.4 + Math.random() * 0.3,
            startX, totalLen
        };
        scene.add(mesh);
        dataFlowParticles.push(mesh);
    }
}

// ── NEW: Merge Zone (where forward+backward concatenate) ──
function buildMergeZone() {
    const geo = new THREE.CylinderGeometry(1.2, 1.2, 10, 16, 1, true);
    const mat = new THREE.MeshBasicMaterial({
        color: 0x8B5CF6,
        transparent: true,
        opacity: 0.08,
        side: THREE.DoubleSide,
        wireframe: true
    });
    mergeZone = new THREE.Mesh(geo, mat);
    mergeZone.position.set(0, 0, 0);
    scene.add(mergeZone);
    addTextSprite('CONCAT [210+210=420]', 0, -10, 0, 0x8B5CF6, 0.7);
}

// ── Gate switching ──────────────────────────────────
function setGate(gate) {
    currentGate = gate;
    const info = gateInfo[gate];
    document.getElementById('desc-title').innerText = info.title;
    document.getElementById('desc-text').innerText = info.text;
    document.getElementById('desc-math').innerText = info.math;
    document.querySelectorAll('.gate-btn').forEach(btn => btn.classList.remove('active'));
    if (event && event.currentTarget) event.currentTarget.classList.add('active');
    const col = gateColors[gate];
    gateParticles.forEach(p => p.material.color.copy(col));
    cellStateRing.material.color.copy(col);
    cellStateRing.material.emissive.copy(col).multiplyScalar(0.3);
}

function setDirection(dir) {
    currentDirection = dir;
    document.querySelectorAll('.dir-btn').forEach(btn => btn.classList.remove('active'));
    if (event && event.currentTarget) event.currentTarget.classList.add('active');
}

function setupEvents() {
    window.addEventListener('resize', () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });
    document.getElementById('slider-timestep').addEventListener('input', (e) => {
        timeStep = parseInt(e.target.value);
        document.getElementById('val-timestep').innerText = timeStep;
    });
    document.getElementById('slider-bias').addEventListener('input', (e) => {
        gateBias = parseFloat(e.target.value);
        document.getElementById('val-bias').innerText = gateBias.toFixed(1);
    });
}

// ── Animation Loop ──────────────────────────────────
let clock = 0;

function animate() {
    requestAnimationFrame(animate);
    controls.update();
    clock += 0.016;

    const spacing = 2.5;
    const startX = -(SEQ_LEN * spacing) / 2;

    // ─── Animate sequence chain nodes ───
    for (let i = 0; i < SEQ_LEN; i++) {
        const isActive = (i === timeStep - 1);
        const isPast = (i < timeStep - 1);
        const fNode = forwardChain[i];
        const fS = isActive ? 1.8 + Math.sin(clock * 4) * 0.3 : (isPast ? 1.0 : 0.5);
        fNode.scale.lerp(new THREE.Vector3(fS, fS, fS), 0.1);
        fNode.material.emissive.lerp(new THREE.Color(0x06B6D4).multiplyScalar(isActive ? 0.5 : (isPast ? 0.15 : 0.02)), 0.08);
        fNode.material.opacity = isActive ? 1.0 : (isPast ? 0.7 : 0.3);
        if (currentDirection === 'forward' && isPast) {
            fNode.position.y = 5 + Math.sin(clock * 3 + i * 0.4) * 0.3;
        } else { fNode.position.y += (5 - fNode.position.y) * 0.05; }

        const bNode = backwardChain[i];
        const bIsFuture = (i > timeStep - 1);
        const bS = isActive ? 1.8 + Math.sin(clock * 4) * 0.3 : (bIsFuture ? 1.0 : 0.5);
        bNode.scale.lerp(new THREE.Vector3(bS, bS, bS), 0.1);
        bNode.material.emissive.lerp(new THREE.Color(0x3B82F6).multiplyScalar(isActive ? 0.5 : (bIsFuture ? 0.15 : 0.02)), 0.08);
        bNode.material.opacity = isActive ? 1.0 : (bIsFuture ? 0.7 : 0.3);
        if (currentDirection === 'backward' && bIsFuture) {
            bNode.position.y = -5 + Math.sin(clock * 3 + i * 0.4) * 0.3;
        } else { bNode.position.y += (-5 - bNode.position.y) * 0.05; }
    }

    // ─── Gate particles orbit ───
    gateParticles.forEach((p, i) => {
        p.userData.angle += p.userData.speed * 0.016;
        const a = p.userData.angle;
        const r = p.userData.radius;
        p.position.x = Math.cos(a) * r;
        p.position.z = 8 + Math.sin(a) * r;
        p.position.y = p.userData.yOff + Math.sin(clock * 2 + i) * 0.5;
        p.material.opacity = 0.4 + Math.sin(clock * 3 + i * 0.5) * 0.3;
    });

    // ─── Cell state ring ───
    cellStateRing.rotation.z = clock * 0.3;
    const coreScale = 1.5 + Math.sin(clock * 2) * 0.2;
    cellCore.scale.set(coreScale, coreScale, coreScale);

    // ─── NEW: Data flow particles ───
    const dt = 0.016;
    const activeX = startX + (timeStep - 1) * spacing;

    dataFlowParticles.forEach(p => {
        const d = p.userData;
        if (d.dir === 'forward') {
            const isActive = currentDirection === 'forward' || currentDirection === 'both';
            if (isActive) {
                d.progress += d.speed * dt;
                if (d.progress > 1) d.progress = 0;
                p.position.x = d.startX + d.progress * d.totalLen;
                p.position.y = d.yBase + Math.sin(clock * 5 + d.trail * 10) * 0.4;
                p.position.z = Math.sin(clock * 3 + d.trail * 20) * 0.3;
                // Brighten near active timestep
                const dist = Math.abs(p.position.x - activeX);
                p.material.opacity = dist < 3 ? 0.9 : 0.3;
                p.scale.setScalar(dist < 3 ? 1.5 : 0.8);
            } else {
                p.material.opacity *= 0.95;
            }
        } else if (d.dir === 'backward') {
            const isActive = currentDirection === 'backward' || currentDirection === 'both';
            if (isActive) {
                d.progress += d.speed * dt;
                if (d.progress > 1) d.progress = 0;
                p.position.x = d.startX + d.totalLen - d.progress * d.totalLen;
                p.position.y = d.yBase + Math.sin(clock * 5 + d.trail * 10) * 0.4;
                p.position.z = Math.sin(clock * 3 + d.trail * 20) * 0.3;
                const dist = Math.abs(p.position.x - activeX);
                p.material.opacity = dist < 3 ? 0.9 : 0.3;
                p.scale.setScalar(dist < 3 ? 1.5 : 0.8);
            } else {
                p.material.opacity *= 0.95;
            }
        } else if (d.dir === 'merge') {
            // Merge particles: vertical flow at active timestep position
            d.progress += d.speed * dt;
            if (d.progress > 1) d.progress = 0;
            p.position.x = activeX + (Math.random() - 0.5) * 0.3;
            p.position.y = 5 - d.progress * 10; // from +5 to -5
            p.position.z = Math.sin(d.progress * Math.PI) * 2;
            p.material.opacity = Math.sin(d.progress * Math.PI) * 0.6;
            p.scale.setScalar(0.5 + Math.sin(d.progress * Math.PI) * 0.5);
        }
    });

    // ─── Merge zone follows timestep ───
    mergeZone.position.x += (activeX - mergeZone.position.x) * 0.08;
    mergeZone.rotation.y = clock * 0.5;
    mergeZone.material.opacity = 0.05 + Math.sin(clock * 2) * 0.03;

    // ─── Stats display ───
    const inputVal = Math.sin(clock + timeStep * 0.5) * 2;
    const gateVal = sigmoid(inputVal + gateBias);
    const cellVal = Math.tanh(inputVal * gateVal);
    document.getElementById('stat-gate').innerText = gateVal.toFixed(3);
    document.getElementById('stat-cell').innerText = cellVal.toFixed(3);
    const gCard = document.getElementById('card-gate-val');
    gCard.style.borderLeftColor = gateVal > 0.5 ? '#10B981' : '#EF4444';

    renderer.render(scene, camera);
}

window.setGate = setGate;
window.setDirection = setDirection;
init();
