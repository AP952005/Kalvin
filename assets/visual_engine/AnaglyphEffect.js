/**
 * AnaglyphEffect.js — Stereoscopic red/cyan anaglyph renderer
 * Compatible with THREE.js non-module builds (THREE global namespace)
 * Adapted from Three.js examples for offline educational use
 */

THREE.AnaglyphEffect = function (renderer, width, height) {
  var _camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  var _scene = new THREE.Scene();
  var _stereo = new THREE.StereoCamera();
  _stereo.eyeSep = 0.064;

  var _params = {
    minFilter: THREE.LinearFilter,
    magFilter: THREE.NearestFilter,
    format: THREE.RGBAFormat
  };

  if (width === undefined) width = 512;
  if (height === undefined) height = 512;

  var _renderTargetL = new THREE.WebGLRenderTarget(width, height, _params);
  var _renderTargetR = new THREE.WebGLRenderTarget(width, height, _params);

  var _material = new THREE.ShaderMaterial({
    uniforms: {
      mapLeft: { value: _renderTargetL.texture },
      mapRight: { value: _renderTargetR.texture }
    },
    vertexShader: [
      'varying vec2 vUv;',
      'void main() {',
      '  vUv = vec2(uv.x, uv.y);',
      '  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);',
      '}'
    ].join('\n'),
    fragmentShader: [
      'uniform sampler2D mapLeft;',
      'uniform sampler2D mapRight;',
      'varying vec2 vUv;',
      'void main() {',
      '  vec4 colorL = texture2D(mapLeft, vUv);',
      '  vec4 colorR = texture2D(mapRight, vUv);',
      // Anaglyph color matrix (red-cyan)
      '  gl_FragColor = vec4(',
      '    colorL.r * 0.456100 + colorL.g * 0.500484 + colorL.b * 0.176381,',
      '    colorR.r * -0.0434706 + colorR.g * 0.378476 + colorR.b * -0.0721527,',
      '    colorR.r * -0.0152183 + colorR.g * -0.0205971 + colorR.b * 0.911874,',
      '    1.0);',
      '}'
    ].join('\n')
  });

  var _mesh = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), _material);
  _scene.add(_mesh);

  this.setSize = function (width, height) {
    renderer.setSize(width, height);
    var pixelRatio = renderer.getPixelRatio();
    _renderTargetL.setSize(width * pixelRatio, height * pixelRatio);
    _renderTargetR.setSize(width * pixelRatio, height * pixelRatio);
  };

  this.render = function (scene, camera) {
    scene.updateMatrixWorld();
    if (camera.parent === null) camera.updateMatrixWorld();

    _stereo.update(camera);

    renderer.setRenderTarget(_renderTargetL);
    renderer.clear();
    renderer.render(scene, _stereo.cameraL);

    renderer.setRenderTarget(_renderTargetR);
    renderer.clear();
    renderer.render(scene, _stereo.cameraR);

    renderer.setRenderTarget(null);
    renderer.render(_scene, _camera);
  };

  this.dispose = function () {
    _renderTargetL.dispose();
    _renderTargetR.dispose();
    _material.dispose();
    _mesh.geometry.dispose();
  };
};
