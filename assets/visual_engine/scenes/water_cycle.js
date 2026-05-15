/*
  scenes/water_cycle.js
  Water Cycle — Educational Visualization
  Clear directional flow: Sun heats → Evaporation ↑ → Clouds → Condensation → Rain ↓ → Ocean
  Procedural + textured, fully offline.
*/

function createWaterCycleScene(scene, textureLoader, textureBasePath) {

  // ===== Sky gradient (light blue) =====
  scene.background = new THREE.Color(0x87CEEB);

  // ===== Lighting =====
  var ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
  scene.add(ambientLight);

  var sunLight = new THREE.DirectionalLight(0xffffcc, 1.2);
  sunLight.position.set(8, 10, 5);
  scene.add(sunLight);

  // ===== Sun (top-right, heating source) =====
  var sunGeo = new THREE.SphereGeometry(1.2, 32, 32);
  var sunTex = textureLoader.load(textureBasePath + '/sun.jpg', function () {}, undefined, function () {});
  var sunMat = new THREE.MeshBasicMaterial({
    map: sunTex,
    color: 0xffdd44
  });
  var sun = new THREE.Mesh(sunGeo, sunMat);
  sun.position.set(8, 7, -5);
  sun.name = 'sun';
  scene.add(sun);

  // Sun glow
  var sunGlow = new THREE.PointLight(0xffdd44, 2, 30);
  sunGlow.position.copy(sun.position);
  scene.add(sunGlow);

  // Sun heat rays (visual beam toward ocean)
  var rayCount = 8;
  var rays = [];
  for (var ri = 0; ri < rayCount; ri++) {
    var rayGeo = new THREE.CylinderGeometry(0.015, 0.015, 6, 4);
    var rayMat = new THREE.MeshBasicMaterial({
      color: 0xffee66,
      transparent: true,
      opacity: 0.15 + Math.random() * 0.1
    });
    var ray = new THREE.Mesh(rayGeo, rayMat);
    var angle = -0.6 - (ri * 0.08);
    ray.rotation.z = angle;
    ray.position.set(
      sun.position.x - 2.5 - ri * 0.4,
      sun.position.y - 3.5,
      sun.position.z + 1 + Math.random()
    );
    scene.add(ray);
    rays.push({ mesh: ray, baseOpacity: 0.15 + Math.random() * 0.1 });
  }

  // ===== Ocean (bottom, full width) =====
  var oceanGeo = new THREE.PlaneGeometry(30, 15, 64, 32);
  var waterTex = textureLoader.load(textureBasePath + '/water.jpg', function () {}, undefined, function () {});
  if (waterTex) {
    waterTex.wrapS = THREE.RepeatWrapping;
    waterTex.wrapT = THREE.RepeatWrapping;
    waterTex.repeat.set(4, 2);
  }
  var oceanMat = new THREE.MeshStandardMaterial({
    map: waterTex,
    color: 0x2288cc,
    roughness: 0.3,
    metalness: 0.1,
    transparent: true,
    opacity: 0.85
  });
  var ocean = new THREE.Mesh(oceanGeo, oceanMat);
  ocean.rotation.x = -Math.PI / 2;
  ocean.position.set(0, -1, 3);
  ocean.name = 'ocean';
  scene.add(ocean);

  // ===== Mountains (background) =====
  var mtMat = new THREE.MeshStandardMaterial({ color: 0x556644, roughness: 0.9 });
  var mt1 = new THREE.Mesh(new THREE.ConeGeometry(3, 5, 6), mtMat);
  mt1.position.set(-6, 1.5, -5);
  scene.add(mt1);

  var mt2 = new THREE.Mesh(new THREE.ConeGeometry(2.5, 4, 6), mtMat);
  mt2.position.set(-3, 1, -4);
  scene.add(mt2);

  // ===== Ground strip (shoreline) =====
  var groundGeo = new THREE.PlaneGeometry(30, 6);
  var groundMat = new THREE.MeshStandardMaterial({ color: 0x88aa66, roughness: 0.95 });
  var ground = new THREE.Mesh(groundGeo, groundMat);
  ground.rotation.x = -Math.PI / 2;
  ground.position.set(0, -0.98, -4);
  scene.add(ground);

  // ===== EVAPORATION PARTICLES (rise UPWARD only — from ocean surface) =====
  var evapCount = 80;
  var evapGeo = new THREE.BufferGeometry();
  var evapPositions = new Float32Array(evapCount * 3);
  var evapAlphas = new Float32Array(evapCount);
  var evapVelocities = [];

  for (var e = 0; e < evapCount; e++) {
    resetEvapParticle(e);
  }

  evapGeo.setAttribute('position', new THREE.BufferAttribute(evapPositions, 3));
  var evapMat = new THREE.PointsMaterial({
    size: 0.1,
    color: 0xaaddff,
    transparent: true,
    opacity: 0.4
  });
  var evapParticles = new THREE.Points(evapGeo, evapMat);
  evapParticles.name = 'evaporation';
  scene.add(evapParticles);

  function resetEvapParticle(idx) {
    // Spawn near ocean surface (right side, where sun heats)
    evapPositions[idx * 3] = 1 + Math.random() * 8;          // right half (heated area)
    evapPositions[idx * 3 + 1] = -0.8 + Math.random() * 0.3; // just above ocean
    evapPositions[idx * 3 + 2] = (Math.random() - 0.5) * 6;
    evapVelocities[idx] = {
      y: 0.015 + Math.random() * 0.02,  // upward ONLY
      x: -0.002 + Math.random() * 0.001, // slight drift left toward clouds
      life: 0,
      maxLife: 150 + Math.random() * 200
    };
  }

  // ===== CLOUDS (top area — store condensed water) =====
  var clouds = [];
  var cloudPositions = [
    { x: -5, y: 5.5 },
    { x: -2, y: 6.0 },
    { x: 1, y: 5.3 },
    { x: 4, y: 5.8 },
    { x: -7, y: 5.0 },
  ];
  for (var c = 0; c < cloudPositions.length; c++) {
    var cloudGroup = new THREE.Group();
    var cloudMat = new THREE.MeshBasicMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.7
    });

    for (var s = 0; s < 5; s++) {
      var r = 0.4 + Math.random() * 0.5;
      var sphere = new THREE.Mesh(new THREE.SphereGeometry(r, 16, 16), cloudMat);
      sphere.position.set(
        (Math.random() - 0.5) * 1.8,
        (Math.random() - 0.5) * 0.3,
        (Math.random() - 0.5) * 0.8
      );
      cloudGroup.add(sphere);
    }

    cloudGroup.position.set(
      cloudPositions[c].x,
      cloudPositions[c].y,
      -1 + Math.random() * 2
    );
    cloudGroup.name = 'cloud_' + c;
    scene.add(cloudGroup);
    clouds.push({
      mesh: cloudGroup,
      speed: 0.002 + Math.random() * 0.003,
      baseY: cloudPositions[c].y
    });
  }

  // ===== RAIN PARTICLES (fall DOWNWARD only — from cloud level) =====
  var rainCount = 200;
  var rainGeo = new THREE.BufferGeometry();
  var rainPositions = new Float32Array(rainCount * 3);
  var rainVelocities = [];

  for (var r = 0; r < rainCount; r++) {
    resetRainParticle(r);
  }

  rainGeo.setAttribute('position', new THREE.BufferAttribute(rainPositions, 3));
  var rainMat = new THREE.PointsMaterial({
    size: 0.04,
    color: 0x4488cc,
    transparent: true,
    opacity: 0.6
  });
  var rain = new THREE.Points(rainGeo, rainMat);
  rain.name = 'rain';
  scene.add(rain);

  function resetRainParticle(idx) {
    // Spawn from cloud area (LEFT side — rain falls on left)
    rainPositions[idx * 3] = -8 + Math.random() * 8;           // left half
    rainPositions[idx * 3 + 1] = 4 + Math.random() * 2;        // cloud height
    rainPositions[idx * 3 + 2] = (Math.random() - 0.5) * 8;
    rainVelocities[idx] = {
      y: -0.05 - Math.random() * 0.05,  // downward ONLY
      life: 0,
      maxLife: 60 + Math.random() * 60
    };
  }

  // ===== Educational labels (HTML overlay positions) =====
  // Create 3D position markers for labels
  var labelEvap = new THREE.Object3D();
  labelEvap.position.set(5, 2, 0);
  labelEvap.name = 'label_evaporation';
  scene.add(labelEvap);

  var labelCloud = new THREE.Object3D();
  labelCloud.position.set(-1, 6.5, 0);
  labelCloud.name = 'label_clouds';
  scene.add(labelCloud);

  var labelRain = new THREE.Object3D();
  labelRain.position.set(-5, 2, 0);
  labelRain.name = 'label_rain';
  scene.add(labelRain);

  var labelOcean = new THREE.Object3D();
  labelOcean.position.set(0, -0.5, 5);
  labelOcean.name = 'label_ocean';
  scene.add(labelOcean);

  // Return scene handle
  return {
    sun: sun,
    ocean: ocean,
    clouds: clouds,

    update: function (time) {
      // Sun gentle rotation
      sun.rotation.y += 0.002;

      // Sun ray pulse
      for (var rr = 0; rr < rays.length; rr++) {
        rays[rr].mesh.material.opacity = rays[rr].baseOpacity + Math.sin(time * 3 + rr) * 0.05;
      }

      // Ocean wave animation
      var oceanVerts = ocean.geometry.attributes.position;
      for (var ov = 0; ov < oceanVerts.count; ov++) {
        var x = oceanVerts.getX(ov);
        var z = oceanVerts.getZ(ov);
        oceanVerts.setY(ov, Math.sin(x * 0.5 + time * 2) * 0.06 + Math.cos(z * 0.5 + time * 1.5) * 0.04);
      }
      oceanVerts.needsUpdate = true;
      ocean.geometry.computeVertexNormals();

      // Evaporation: particles rise UPWARD only from heated ocean
      var ep = evapParticles.geometry.attributes.position.array;
      for (var ei = 0; ei < evapCount; ei++) {
        var ev = evapVelocities[ei];
        ev.life++;
        if (ev.life > ev.maxLife || ep[ei * 3 + 1] > 5) {
          // Reset when reaching cloud height or expired
          resetEvapParticle(ei);
        } else {
          ep[ei * 3 + 1] += ev.y;  // rise
          ep[ei * 3] += ev.x;      // slight horizontal drift
        }
      }
      evapParticles.geometry.attributes.position.needsUpdate = true;

      // Clouds: gentle drift + breathing
      for (var ci = 0; ci < clouds.length; ci++) {
        clouds[ci].mesh.position.x += clouds[ci].speed;
        // Gentle vertical breathing
        clouds[ci].mesh.position.y = clouds[ci].baseY + Math.sin(time * 0.5 + ci) * 0.1;
        if (clouds[ci].mesh.position.x > 12) {
          clouds[ci].mesh.position.x = -12;
        }
      }

      // Rain: particles fall DOWNWARD only from clouds
      var rp = rain.geometry.attributes.position.array;
      for (var rii = 0; rii < rainCount; rii++) {
        var rv = rainVelocities[rii];
        rv.life++;
        if (rv.life > rv.maxLife || rp[rii * 3 + 1] < -0.8) {
          // Reset when hitting ocean or expired
          resetRainParticle(rii);
        } else {
          rp[rii * 3 + 1] += rv.y; // fall
        }
      }
      rain.geometry.attributes.position.needsUpdate = true;
    },

    getLabelPositions: function (camera, w, h) {
      return {
        sun: toScreenPosition(sun, camera, w, h),
        ocean: toScreenPosition(ocean, camera, w, h),
        evaporation: toScreenPosition(labelEvap, camera, w, h),
        clouds: toScreenPosition(labelCloud, camera, w, h),
        rain: toScreenPosition(labelRain, camera, w, h)
      };
    }
  };
}
