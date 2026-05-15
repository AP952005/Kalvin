/*
  scenes/volcano.js
  Volcano scene for the Kalvin Visual Engine.
  Creates mountain, terrain, lava glow, eruption particles, smoke.
  Stylized-realistic educational visualization.
*/

function createVolcanoScene(scene, textureLoader, textureBasePath) {

  // ===== Lighting =====
  var ambientLight = new THREE.AmbientLight(0x332211, 0.4);
  scene.add(ambientLight);

  // Warm directional light (sunset feel)
  var dirLight = new THREE.DirectionalLight(0xffaa55, 0.8);
  dirLight.position.set(5, 8, 3);
  scene.add(dirLight);

  // Lava glow from crater
  var lavaLight = new THREE.PointLight(0xff4400, 3, 15);
  lavaLight.position.set(0, 3.5, 0);
  scene.add(lavaLight);

  var lavaLight2 = new THREE.PointLight(0xff6600, 1.5, 8);
  lavaLight2.position.set(0, 4, 0);
  scene.add(lavaLight2);

  // ===== Terrain (flat ground) =====
  var terrainGeo = new THREE.PlaneGeometry(40, 40, 32, 32);
  var rockTex = textureLoader.load(textureBasePath + '/rock.jpg', function () {}, undefined, function () {});
  if (rockTex) {
    rockTex.wrapS = THREE.RepeatWrapping;
    rockTex.wrapT = THREE.RepeatWrapping;
    rockTex.repeat.set(6, 6);
  }
  var terrainMat = new THREE.MeshStandardMaterial({
    map: rockTex,
    color: 0x554433,
    roughness: 0.9
  });
  var terrain = new THREE.Mesh(terrainGeo, terrainMat);
  terrain.rotation.x = -Math.PI / 2;
  terrain.position.y = -0.5;
  terrain.name = 'terrain';
  scene.add(terrain);

  // ===== Mountain (cone) =====
  var mountainGeo = new THREE.ConeGeometry(4, 6, 32, 8);
  var mountainTex = textureLoader.load(textureBasePath + '/mountain.jpg', function () {}, undefined, function () {});
  var mountainMat = new THREE.MeshStandardMaterial({
    map: mountainTex,
    color: 0x665544,
    roughness: 0.85
  });
  var mountain = new THREE.Mesh(mountainGeo, mountainMat);
  mountain.position.y = 2.5;
  mountain.name = 'mountain';
  scene.add(mountain);

  // ===== Crater (top of mountain) =====
  var craterGeo = new THREE.CylinderGeometry(0.8, 1.2, 0.6, 32);
  var craterMat = new THREE.MeshStandardMaterial({
    color: 0x221100,
    roughness: 1.0,
    emissive: 0x331100,
    emissiveIntensity: 0.3
  });
  var crater = new THREE.Mesh(craterGeo, craterMat);
  crater.position.y = 5.2;
  crater.name = 'crater';
  scene.add(crater);

  // ===== Lava Pool (inside crater) =====
  var lavaGeo = new THREE.CircleGeometry(0.7, 32);
  var lavaTex = textureLoader.load(textureBasePath + '/lava.jpg', function () {}, undefined, function () {});
  var lavaMat = new THREE.MeshBasicMaterial({
    map: lavaTex,
    color: 0xff6600
  });
  var lavaPool = new THREE.Mesh(lavaGeo, lavaMat);
  lavaPool.rotation.x = -Math.PI / 2;
  lavaPool.position.y = 5.25;
  lavaPool.name = 'lavaPool';
  scene.add(lavaPool);

  // ===== Eruption Particles =====
  var particleCount = 200;
  var particleGeo = new THREE.BufferGeometry();
  var particlePositions = new Float32Array(particleCount * 3);
  var particleVelocities = [];
  var particleColors = new Float32Array(particleCount * 3);

  for (var i = 0; i < particleCount; i++) {
    resetParticle(i);
    // Orange-red colors
    particleColors[i * 3] = 0.9 + Math.random() * 0.1;
    particleColors[i * 3 + 1] = 0.3 + Math.random() * 0.4;
    particleColors[i * 3 + 2] = 0.0 + Math.random() * 0.1;
  }

  particleGeo.setAttribute('position', new THREE.BufferAttribute(particlePositions, 3));
  particleGeo.setAttribute('color', new THREE.BufferAttribute(particleColors, 3));
  var particleMat = new THREE.PointsMaterial({
    size: 0.12,
    vertexColors: true,
    transparent: true,
    opacity: 0.8
  });
  var particles = new THREE.Points(particleGeo, particleMat);
  particles.name = 'eruptionParticles';
  scene.add(particles);

  function resetParticle(idx) {
    // Start from crater top
    particlePositions[idx * 3] = (Math.random() - 0.5) * 0.8;
    particlePositions[idx * 3 + 1] = 5.3 + Math.random() * 0.5;
    particlePositions[idx * 3 + 2] = (Math.random() - 0.5) * 0.8;

    particleVelocities[idx] = {
      x: (Math.random() - 0.5) * 0.03,
      y: 0.02 + Math.random() * 0.06,
      z: (Math.random() - 0.5) * 0.03,
      life: 0,
      maxLife: 60 + Math.random() * 120
    };
  }

  // ===== Smoke Particles =====
  var smokeCount = 80;
  var smokeGeo = new THREE.BufferGeometry();
  var smokePositions = new Float32Array(smokeCount * 3);
  var smokeVelocities = [];

  for (var s = 0; s < smokeCount; s++) {
    resetSmoke(s);
  }

  smokeGeo.setAttribute('position', new THREE.BufferAttribute(smokePositions, 3));
  var smokeMat = new THREE.PointsMaterial({
    size: 0.3,
    color: 0x888888,
    transparent: true,
    opacity: 0.25
  });
  var smoke = new THREE.Points(smokeGeo, smokeMat);
  smoke.name = 'smoke';
  scene.add(smoke);

  function resetSmoke(idx) {
    smokePositions[idx * 3] = (Math.random() - 0.5) * 0.6;
    smokePositions[idx * 3 + 1] = 5.5 + Math.random() * 2;
    smokePositions[idx * 3 + 2] = (Math.random() - 0.5) * 0.6;
    smokeVelocities[idx] = {
      x: (Math.random() - 0.5) * 0.01,
      y: 0.01 + Math.random() * 0.02,
      z: (Math.random() - 0.5) * 0.01,
      life: 0,
      maxLife: 100 + Math.random() * 150
    };
  }

  // ===== Stars (dim, night sky) =====
  var starsGeo = new THREE.BufferGeometry();
  var starPos = [];
  for (var st = 0; st < 1500; st++) {
    starPos.push(
      (Math.random() - 0.5) * 200,
      20 + Math.random() * 80,
      (Math.random() - 0.5) * 200
    );
  }
  starsGeo.setAttribute('position', new THREE.Float32BufferAttribute(starPos, 3));
  var starsMat = new THREE.PointsMaterial({ color: 0xffffff, size: 0.1, transparent: true, opacity: 0.5 });
  var stars = new THREE.Points(starsGeo, starsMat);
  scene.add(stars);

  // ===== Camera shake state =====
  var shakeIntensity = 0;
  var shakeDecay = 0.98;

  // Return scene handle
  return {
    mountain: mountain,
    crater: crater,
    lavaPool: lavaPool,

    triggerEruption: function () {
      shakeIntensity = 0.15;
      for (var e = 0; e < particleCount; e++) {
        resetParticle(e);
        particleVelocities[e].y = 0.04 + Math.random() * 0.08;
      }
    },

    update: function (time) {
      // Lava glow pulse
      var pulse = Math.sin(time * 3) * 0.3 + 0.7;
      lavaLight.intensity = 2 + pulse * 2;
      lavaLight2.intensity = 1 + pulse;
      lavaMat.color.setHex(pulse > 0.5 ? 0xff6600 : 0xff4400);

      // Eruption particles
      var pPos = particles.geometry.attributes.position.array;
      for (var p = 0; p < particleCount; p++) {
        var v = particleVelocities[p];
        v.life++;
        if (v.life > v.maxLife) {
          resetParticle(p);
        } else {
          pPos[p * 3] += v.x;
          pPos[p * 3 + 1] += v.y;
          pPos[p * 3 + 2] += v.z;
          v.y -= 0.0005; // gravity
        }
      }
      particles.geometry.attributes.position.needsUpdate = true;

      // Smoke
      var sPos = smoke.geometry.attributes.position.array;
      for (var sm = 0; sm < smokeCount; sm++) {
        var sv = smokeVelocities[sm];
        sv.life++;
        if (sv.life > sv.maxLife) {
          resetSmoke(sm);
        } else {
          sPos[sm * 3] += sv.x;
          sPos[sm * 3 + 1] += sv.y;
          sPos[sm * 3 + 2] += sv.z;
        }
      }
      smoke.geometry.attributes.position.needsUpdate = true;

      // Camera shake
      if (shakeIntensity > 0.001) {
        shakeIntensity *= shakeDecay;
      } else {
        shakeIntensity = 0;
      }

      return { shakeIntensity: shakeIntensity };
    },

    getLabelPositions: function (camera, w, h) {
      return {
        mountain: toScreenPosition(mountain, camera, w, h),
        crater: toScreenPosition(crater, camera, w, h)
      };
    }
  };
}
