/*
  scenes/solar_system.js
  Solar System scene for the Astralearn Visual Engine.
  Creates Sun, Earth (with atmosphere), Stars, and Lighting.
  Returns scene objects for the engine to animate.
*/

function createSolarSystem(scene, textureLoader, textureBasePath) {

  // ===== Lighting =====
  var ambientLight = new THREE.AmbientLight(0xffffff, 0.15);
  scene.add(ambientLight);

  var pointLight = new THREE.PointLight(0xffcc88, 3, 200);
  pointLight.position.set(0, 0, 0);
  scene.add(pointLight);

  // Subtle sun glow light
  var sunGlow = new THREE.PointLight(0xffaa44, 1.5, 50);
  sunGlow.position.set(0, 0, 0);
  scene.add(sunGlow);

  // ===== Sun =====
  var sunGeometry = new THREE.SphereGeometry(1.5, 64, 64);
  var sunTexture = textureLoader.load(
    textureBasePath + '/sun.jpg',
    function () {},
    undefined,
    function () {
      sun.material = new THREE.MeshBasicMaterial({ color: 0xffcc33 });
    }
  );
  var sunMaterial = new THREE.MeshBasicMaterial({ map: sunTexture });
  var sun = new THREE.Mesh(sunGeometry, sunMaterial);
  sun.name = 'sun';
  scene.add(sun);

  // ===== Earth =====
  var earthGeometry = new THREE.SphereGeometry(0.6, 64, 64);
  var earthTexture = textureLoader.load(
    textureBasePath + '/earth.jpg',
    function () {},
    undefined,
    function () {
      earth.material = new THREE.MeshStandardMaterial({ color: 0x2244cc });
    }
  );
  var earthMaterial = new THREE.MeshStandardMaterial({ map: earthTexture });
  var earth = new THREE.Mesh(earthGeometry, earthMaterial);
  earth.name = 'earth';
  earth.userData = { rotateSpeed: 0.01 };
  scene.add(earth);

  // ===== Earth Atmosphere Glow =====
  var atmosGeometry = new THREE.SphereGeometry(0.68, 64, 64);
  var atmosMaterial = new THREE.MeshBasicMaterial({
    color: 0x4488ff,
    transparent: true,
    opacity: 0.15,
    side: THREE.FrontSide
  });
  var atmosphere = new THREE.Mesh(atmosGeometry, atmosMaterial);
  atmosphere.name = 'atmosphere';
  // Atmosphere follows Earth - we parent it to the scene and update its position in the animation loop
  scene.add(atmosphere);

  // ===== Stars (procedural) =====
  var starsGeometry = new THREE.BufferGeometry();
  var positions = [];
  var colors = [];
  for (var i = 0; i < 4000; i++) {
    positions.push(
      (Math.random() - 0.5) * 300,
      (Math.random() - 0.5) * 300,
      (Math.random() - 0.5) * 300
    );
    // Slight colour variation for stars
    var brightness = 0.7 + Math.random() * 0.3;
    colors.push(brightness, brightness, brightness + Math.random() * 0.1);
  }
  starsGeometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  starsGeometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
  var starsMaterial = new THREE.PointsMaterial({
    size: 0.15,
    vertexColors: true,
    transparent: true,
    opacity: 0.9
  });
  var stars = new THREE.Points(starsGeometry, starsMaterial);
  stars.name = 'stars';
  scene.add(stars);

  // ===== Return scene objects for engine to animate =====
  return {
    sun: sun,
    earth: earth,
    atmosphere: atmosphere,
    stars: stars,
    pointLight: pointLight,
    sunGlow: sunGlow,

    // Animation update called each frame
    update: function (angle) {
      // Earth orbit
      earth.position.x = Math.cos(angle) * 4;
      earth.position.z = Math.sin(angle) * 4;
      earth.rotation.y += earth.userData.rotateSpeed;

      // Atmosphere follows Earth
      atmosphere.position.copy(earth.position);
      atmosphere.rotation.y += 0.003;

      // Sun rotation
      sun.rotation.y += 0.002;
    },

    // Get label screen positions
    getLabelPositions: function (camera, rendererWidth, rendererHeight) {
      var earthScreenPos = toScreenPosition(earth, camera, rendererWidth, rendererHeight);
      var sunScreenPos = toScreenPosition(sun, camera, rendererWidth, rendererHeight);
      return {
        earth: earthScreenPos,
        sun: sunScreenPos
      };
    }
  };
}

// ===== Utility: project 3D position to 2D screen coordinates =====
function toScreenPosition(obj, camera, width, height) {
  var vector = new THREE.Vector3();
  obj.updateMatrixWorld();
  vector.setFromMatrixPosition(obj.matrixWorld);
  vector.project(camera);

  var x = (vector.x * 0.5 + 0.5) * width;
  var y = (-(vector.y * 0.5) + 0.5) * height;

  return { x: x, y: y, z: vector.z };
}
