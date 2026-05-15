/*
  Kalvin Visual Engine — main.js
  Core engine: renderer, camera, controls, anaglyph 3D, scene manager.
  Lightweight, offline, mobile-first.
*/

// ===== Renderer =====
var renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
document.body.appendChild(renderer.domElement);

// ===== Scene =====
var scene = new THREE.Scene();
scene.background = new THREE.Color(0x000000);

// ===== Camera =====
var camera = new THREE.PerspectiveCamera(
  60,
  window.innerWidth / window.innerHeight,
  0.1,
  1000
);
camera.position.set(0, 3, 10);

// ===== OrbitControls =====
var controls = new THREE.OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.enableZoom = true;
controls.zoomSpeed = 0.8;
controls.enableRotate = true;
controls.rotateSpeed = 0.6;
controls.enablePan = false;
controls.minDistance = 3;
controls.maxDistance = 50;
controls.target.set(0, 0, 0);
controls.update();

// ===== Anaglyph 3D =====
var anaglyphEffect = null;
var is3DEnabled = false;

if (typeof THREE.AnaglyphEffect !== 'undefined') {
  anaglyphEffect = new THREE.AnaglyphEffect(renderer, window.innerWidth, window.innerHeight);
}

// ===== Texture Loader =====
var textureLoader = new THREE.TextureLoader();

// ===== Scene Manager =====
var currentScene = null;
var currentSceneName = '';

var sceneConfigs = {
  solar_system: {
    create: typeof createSolarSystem !== 'undefined' ? createSolarSystem : null,
    textureSet: 'planets',
    cameraPos: { x: 0, y: 3, z: 10 },
    bgColor: 0x000000
  },
  volcano: {
    create: typeof createVolcanoScene !== 'undefined' ? createVolcanoScene : null,
    textureSet: 'volcano',
    cameraPos: { x: 6, y: 5, z: 10 },
    bgColor: 0x0a0505
  },
  water_cycle: {
    create: typeof createWaterCycleScene !== 'undefined' ? createWaterCycleScene : null,
    textureSet: 'water',
    cameraPos: { x: 0, y: 4, z: 12 },
    bgColor: 0x87CEEB
  }
};

function clearScene() {
  // Remove all objects except camera/controls
  while (scene.children.length > 0) {
    var child = scene.children[0];
    scene.remove(child);
    if (child.geometry) child.geometry.dispose();
    if (child.material) {
      if (child.material.map) child.material.map.dispose();
      child.material.dispose();
    }
  }
  // Hide all labels
  var labels = document.querySelectorAll('.scene-label');
  for (var l = 0; l < labels.length; l++) {
    labels[l].style.display = 'none';
  }
}

function _loadScene(sceneName) {
  var config = sceneConfigs[sceneName];
  if (!config || !config.create) {
    console.warn('Scene not found: ' + sceneName);
    return;
  }

  clearScene();

  var basePath = 'textures/' + config.textureSet;
  scene.background = new THREE.Color(config.bgColor);

  currentScene = config.create(scene, textureLoader, basePath);
  currentSceneName = sceneName;

  // Reset camera
  camera.position.set(config.cameraPos.x, config.cameraPos.y, config.cameraPos.z);
  controls.target.set(0, 0, 0);
  controls.update();

  // Load scene audio
  if (typeof loadSceneAudio === 'function') {
    loadSceneAudio(sceneName);
  }
}

// Load default scene
_loadScene('solar_system');

// ===== Camera Lerp System =====
var cameraLerp = {
  active: false,
  startPos: new THREE.Vector3(),
  endPos: new THREE.Vector3(),
  startTarget: new THREE.Vector3(),
  endTarget: new THREE.Vector3(),
  progress: 0,
  speed: 0.02
};

function lerpCamera(targetPos, targetLookAt, speed) {
  cameraLerp.startPos.copy(camera.position);
  cameraLerp.endPos.copy(targetPos);
  cameraLerp.startTarget.copy(controls.target);
  cameraLerp.endTarget.copy(targetLookAt);
  cameraLerp.progress = 0;
  cameraLerp.speed = speed || 0.02;
  cameraLerp.active = true;
}

function updateCameraLerp() {
  if (!cameraLerp.active) return;
  cameraLerp.progress += cameraLerp.speed;
  if (cameraLerp.progress >= 1) {
    cameraLerp.progress = 1;
    cameraLerp.active = false;
  }
  var t = cameraLerp.progress;
  var ease = t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
  camera.position.lerpVectors(cameraLerp.startPos, cameraLerp.endPos, ease);
  controls.target.lerpVectors(cameraLerp.startTarget, cameraLerp.endTarget, ease);
}

// ===== Global API (callable from Flutter) =====

window.loadScene = function (sceneName) {
  _loadScene(sceneName);
};

window.toggle3DMode = function (enabled) {
  is3DEnabled = !!enabled;
  if (is3DEnabled && anaglyphEffect) {
    anaglyphEffect.setSize(window.innerWidth, window.innerHeight);
  }
};

window.focusEarth = function () {
  if (!currentScene || !currentScene.earth) return;
  var pos = currentScene.earth.position.clone();
  lerpCamera(pos.clone().add(new THREE.Vector3(2, 1, 3)), pos, 0.025);
};

window.focusSun = function () {
  if (!currentScene || !currentScene.sun) return;
  var pos = currentScene.sun.position.clone();
  lerpCamera(pos.clone().add(new THREE.Vector3(4, 2, 5)), pos, 0.025);
};

window.focusMountain = function () {
  if (!currentScene || !currentScene.mountain) return;
  var pos = currentScene.mountain.position.clone();
  lerpCamera(pos.clone().add(new THREE.Vector3(5, 3, 8)), pos, 0.02);
};

window.focusOcean = function () {
  if (!currentScene || !currentScene.ocean) return;
  var pos = currentScene.ocean.position.clone();
  lerpCamera(pos.clone().add(new THREE.Vector3(3, 3, 8)), pos, 0.02);
};

window.triggerEruption = function () {
  if (currentScene && currentScene.triggerEruption) {
    currentScene.triggerEruption();
  }
};

window.resetCamera = function () {
  var config = sceneConfigs[currentSceneName];
  if (!config) return;
  var defaultPos = new THREE.Vector3(config.cameraPos.x, config.cameraPos.y, config.cameraPos.z);
  var defaultTarget = new THREE.Vector3(0, 0, 0);
  lerpCamera(defaultPos, defaultTarget, 0.02);
};

// ===== Label System =====
var labelEarth = document.getElementById('label-earth');
var labelSun = document.getElementById('label-sun');

function updateLabels() {
  if (!currentScene || !currentScene.getLabelPositions) return;
  var w = renderer.domElement.width / (window.devicePixelRatio || 1);
  var h = renderer.domElement.height / (window.devicePixelRatio || 1);
  var positions = currentScene.getLabelPositions(camera, w, h);

  // Solar system labels
  if (labelEarth && positions.earth) {
    if (positions.earth.z < 1) {
      labelEarth.style.display = 'block';
      labelEarth.style.left = positions.earth.x + 'px';
      labelEarth.style.top = (positions.earth.y - 40) + 'px';
    } else {
      labelEarth.style.display = 'none';
    }
  }
  if (labelSun && positions.sun) {
    if (positions.sun.z < 1) {
      labelSun.style.display = 'block';
      labelSun.style.left = positions.sun.x + 'px';
      labelSun.style.top = (positions.sun.y - 55) + 'px';
    } else {
      labelSun.style.display = 'none';
    }
  }
}

// ===== Camera shake offset =====
var cameraBasePos = new THREE.Vector3();

// ===== Persistent Ambient Audio Engine (Web Audio API) =====
var audioCtx = null;
var audioEnabled = true;
var audioGainNode = null;
var audioSourceNode = null;
var audioFilterNode = null;
var currentAudioScene = '';
var audioGenId = 0; // prevent race conditions

function getAudioContext() {
  if (!audioCtx) {
    try {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    } catch (e) { return null; }
  }
  if (audioCtx.state === 'suspended') {
    audioCtx.resume().catch(function(){});
  }
  return audioCtx;
}

function stopSceneAudio() {
  audioGenId++; // invalidate any pending operations
  currentAudioScene = '';

  // Immediate cleanup — no delayed disconnect
  if (audioGainNode) {
    try { audioGainNode.gain.cancelScheduledValues(0); } catch(e) {}
    try { audioGainNode.gain.value = 0; } catch(e) {}
  }
  if (audioSourceNode) {
    try { audioSourceNode.stop(); } catch(e) {}
    try { audioSourceNode.disconnect(); } catch(e) {}
    audioSourceNode = null;
  }
  if (audioFilterNode) {
    try { audioFilterNode.disconnect(); } catch(e) {}
    audioFilterNode = null;
  }
  if (audioGainNode) {
    try { audioGainNode.disconnect(); } catch(e) {}
    audioGainNode = null;
  }
}

function createNoiseBuffer(ctx, type) {
  var bufferSize = 2 * ctx.sampleRate;
  var noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
  var output = noiseBuffer.getChannelData(0);

  if (type === 'brown') {
    // Brown noise — low frequency rumble for volcano
    var lastOut = 0;
    for (var i = 0; i < bufferSize; i++) {
      var white = Math.random() * 2 - 1;
      output[i] = (lastOut + (0.02 * white)) / 1.02;
      lastOut = output[i];
      output[i] *= 3.5;
    }
  } else {
    // White noise — base for rain
    for (var i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }
  }
  return noiseBuffer;
}

function loadSceneAudio(sceneName) {
  // Don't reload same scene audio
  if (currentAudioScene === sceneName && audioSourceNode) return;

  // Stop any existing audio first
  stopSceneAudio();

  if (!audioEnabled) return;
  if (sceneName !== 'volcano' && sceneName !== 'water_cycle') return;

  var ctx = getAudioContext();
  if (!ctx) return;

  var myGenId = ++audioGenId;
  currentAudioScene = sceneName;

  // Create gain node
  audioGainNode = ctx.createGain();
  audioGainNode.gain.value = 0;
  audioGainNode.connect(ctx.destination);

  // Create audio based on scene
  var source = ctx.createBufferSource();
  source.loop = true; // INFINITE LOOP — never stops

  if (sceneName === 'water_cycle') {
    source.buffer = createNoiseBuffer(ctx, 'white');

    // Bandpass for rain character
    var bandpass = ctx.createBiquadFilter();
    bandpass.type = 'bandpass';
    bandpass.frequency.value = 3000;
    bandpass.Q.value = 0.5;

    // Soften highs
    var shelf = ctx.createBiquadFilter();
    shelf.type = 'highshelf';
    shelf.frequency.value = 8000;
    shelf.gain.value = -6;

    source.connect(bandpass);
    bandpass.connect(shelf);
    shelf.connect(audioGainNode);
    audioFilterNode = bandpass; // store for cleanup

  } else if (sceneName === 'volcano') {
    source.buffer = createNoiseBuffer(ctx, 'brown');

    // Deep lowpass for rumble
    var lowpass = ctx.createBiquadFilter();
    lowpass.type = 'lowpass';
    lowpass.frequency.value = 180;
    lowpass.Q.value = 1.2;

    source.connect(lowpass);
    lowpass.connect(audioGainNode);
    audioFilterNode = lowpass;
  }

  // Check generation is still valid (race guard)
  if (myGenId !== audioGenId) {
    try { source.disconnect(); } catch(e) {}
    return;
  }

  audioSourceNode = source;
  source.start(0);

  // Smooth fade in over 2 seconds
  audioGainNode.gain.setTargetAtTime(0.1, ctx.currentTime, 0.8);
}

// Watchdog: keep audio alive — called every frame
var audioWatchdogCounter = 0;
function updateAudioFade() {
  audioWatchdogCounter++;
  // Check every ~300 frames (~5 seconds at 60fps)
  if (audioWatchdogCounter % 300 === 0) {
    // If audio should be playing but isn't, restart it
    if (audioEnabled && currentAudioScene && !audioSourceNode) {
      loadSceneAudio(currentAudioScene);
    }
    // Resume suspended context
    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume().catch(function(){});
    }
  }
}

// ===== Cinematic Orbit =====
var cinematicOrbit = {
  active: false,
  speed: 0.002,
  radius: 10,
  angle: 0,
  height: 3,
  target: new THREE.Vector3(0, 0, 0)
};

// ===== Animate Loop =====
function animate(time) {
  requestAnimationFrame(animate);

  time *= 0.001; // seconds

  var sceneResult = null;
  if (currentScene && currentScene.update) {
    sceneResult = currentScene.update(time);
  }

  // Camera lerp
  updateCameraLerp();

  // Camera shake (from volcano eruption)
  if (sceneResult && sceneResult.shakeIntensity > 0) {
    camera.position.x += (Math.random() - 0.5) * sceneResult.shakeIntensity;
    camera.position.y += (Math.random() - 0.5) * sceneResult.shakeIntensity;
  }

  // Cinematic orbit
  if (cinematicOrbit.active && !cameraLerp.active) {
    cinematicOrbit.angle += cinematicOrbit.speed;
    camera.position.x = cinematicOrbit.target.x + Math.cos(cinematicOrbit.angle) * cinematicOrbit.radius;
    camera.position.z = cinematicOrbit.target.z + Math.sin(cinematicOrbit.angle) * cinematicOrbit.radius;
    camera.position.y = cinematicOrbit.height;
    controls.target.copy(cinematicOrbit.target);
  }

  // Audio watchdog
  updateAudioFade();

  // Update controls
  controls.update();

  // Update labels
  updateLabels();

  // Render
  if (is3DEnabled && anaglyphEffect) {
    anaglyphEffect.render(scene, camera);
  } else {
    renderer.render(scene, camera);
  }
}

animate(0);

// ===== Window Resize =====
function onResize() {
  var w = window.innerWidth;
  var h = window.innerHeight;
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  renderer.setSize(w, h);
  if (anaglyphEffect) {
    anaglyphEffect.setSize(w, h);
  }
}

window.addEventListener('resize', onResize);
window.addEventListener('orientationchange', function () {
  setTimeout(onResize, 100);
});
onResize();

// Resume AudioContext on user interaction (mobile requirement)
var audioResumeHandler = function() {
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume().catch(function(){});
  }
  // Retry audio if scene loaded but source died
  if (audioEnabled && currentAudioScene && !audioSourceNode) {
    loadSceneAudio(currentAudioScene);
  }
};
document.addEventListener('touchstart', audioResumeHandler, { passive: true });
document.addEventListener('click', audioResumeHandler, { passive: true });

// ===== Window API — Audio =====
window.setAudioEnabled = function (enabled) {
  audioEnabled = !!enabled;
  if (!audioEnabled) {
    stopSceneAudio();
  } else if (currentAudioScene) {
    loadSceneAudio(currentAudioScene);
  }
};

window.toggleAudio = function () {
  audioEnabled = !audioEnabled;
  if (!audioEnabled) {
    stopSceneAudio();
  } else if (currentAudioScene) {
    loadSceneAudio(currentAudioScene);
  }
  return audioEnabled;
};

window.getAudioState = function () {
  return audioEnabled;
};

// ===== Window API — Cinematic Orbit =====
window.startCinematicOrbit = function (speed, radius, height) {
  cinematicOrbit.active = true;
  cinematicOrbit.speed = speed || 0.002;
  cinematicOrbit.radius = radius || 10;
  cinematicOrbit.height = height || 3;
  cinematicOrbit.angle = Math.atan2(camera.position.z, camera.position.x);
  cinematicOrbit.target.copy(controls.target);
};

window.stopCinematicOrbit = function () {
  cinematicOrbit.active = false;
};