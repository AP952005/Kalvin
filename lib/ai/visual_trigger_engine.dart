/// Kalvin AI — Visual Trigger Engine
///
/// Bridges AI responses to Three.js visual engine.
/// Converts visual_scene strings into JavaScript commands.

class VisualTriggerEngine {
  static const Map<String, String> _sceneMap = {
    'volcano': 'volcano',
    'eruption': 'volcano',
    'lava': 'volcano',
    'solar_system': 'solar_system',
    'planets': 'solar_system',
    'sun': 'solar_system',
    'earth': 'solar_system',
    'space': 'solar_system',
    'water_cycle': 'water_cycle',
    'rain': 'water_cycle',
    'evaporation': 'water_cycle',
    'clouds': 'water_cycle',
  };

  static const Map<String, String> _focusMap = {
    'earth': 'focusEarth()',
    'sun': 'focusSun()',
    'mountain': 'focusMountain()',
    'ocean': 'focusOcean()',
  };

  String? resolveScene(String visualScene) {
    if (visualScene.isEmpty) return null;
    final lower = visualScene.toLowerCase().trim();
    if (_sceneMap.containsKey(lower)) return _sceneMap[lower];
    for (final e in _sceneMap.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return null;
  }

  String? getLoadSceneJS(String visualScene) {
    final scene = resolveScene(visualScene);
    if (scene == null) return null;
    return "loadScene('$scene')";
  }

  String? getFocusJS(String target) {
    final lower = target.toLowerCase().trim();
    return _focusMap[lower];
  }

  List<String> getCommandsForResponse({
    required bool visualRequired,
    required String visualScene,
  }) {
    final cmds = <String>[];
    if (!visualRequired || visualScene.isEmpty) return cmds;
    final loadCmd = getLoadSceneJS(visualScene);
    if (loadCmd != null) cmds.add(loadCmd);
    final focusCmd = getFocusJS(visualScene);
    if (focusCmd != null) cmds.add(focusCmd);
    if (resolveScene(visualScene) == 'volcano' &&
        visualScene.contains('erupt')) {
      cmds.add('triggerEruption()');
    }
    return cmds;
  }

  bool isSceneSupported(String name) => resolveScene(name) != null;

  List<String> get supportedScenes =>
      ['solar_system', 'volcano', 'water_cycle'];
}
