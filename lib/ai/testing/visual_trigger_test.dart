/// Kalvin AI — Visual Trigger Test
///
/// Tests visual scene orchestration: JS command generation,
/// scene resolution, focus commands, and safety.

import '../visual_trigger_engine.dart';

class VisualTriggerTest {
  final VisualTriggerEngine _engine = VisualTriggerEngine();

  Future<VisualTriggerReport> runValidation() async {
    final results = <String, bool>{};

    // Test 1: Scene resolution
    results['volcano_resolve'] = _engine.resolveScene('volcano') == 'volcano';
    results['eruption_resolve'] = _engine.resolveScene('eruption') == 'volcano';
    results['solar_resolve'] = _engine.resolveScene('solar_system') == 'solar_system';
    results['planets_resolve'] = _engine.resolveScene('planets') == 'solar_system';
    results['rain_resolve'] = _engine.resolveScene('rain') == 'water_cycle';
    results['water_cycle_resolve'] = _engine.resolveScene('water_cycle') == 'water_cycle';
    results['unknown_resolve'] = _engine.resolveScene('quantum_physics') == null;
    results['empty_resolve'] = _engine.resolveScene('') == null;

    // Test 2: JS command generation
    results['volcano_js'] =
        _engine.getLoadSceneJS('volcano') == "loadScene('volcano')";
    results['solar_js'] =
        _engine.getLoadSceneJS('solar_system') == "loadScene('solar_system')";
    results['null_js'] = _engine.getLoadSceneJS('unknown') == null;

    // Test 3: Focus commands
    results['earth_focus'] = _engine.getFocusJS('earth') == 'focusEarth()';
    results['sun_focus'] = _engine.getFocusJS('sun') == 'focusSun()';
    results['unknown_focus'] = _engine.getFocusJS('mars') == null;

    // Test 4: Command generation for response
    final cmds = _engine.getCommandsForResponse(
        visualRequired: true, visualScene: 'volcano');
    results['command_generation'] = cmds.isNotEmpty &&
        cmds.contains("loadScene('volcano')");

    final noCmds = _engine.getCommandsForResponse(
        visualRequired: false, visualScene: 'volcano');
    results['no_visual_empty'] = noCmds.isEmpty;

    // Test 5: Supported scenes list
    results['supported_scenes'] =
        _engine.supportedScenes.length == 3 &&
        _engine.supportedScenes.contains('volcano');

    final passed = results.values.where((v) => v).length;

    return VisualTriggerReport(
      totalTests: results.length,
      passed: passed,
      results: results,
    );
  }
}

class VisualTriggerReport {
  final int totalTests;
  final int passed;
  final Map<String, bool> results;

  VisualTriggerReport({
    required this.totalTests,
    required this.passed,
    required this.results,
  });

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   VISUAL TRIGGER TEST REPORT         ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Tests: $totalTests | Passed: $passed');
    buf.writeln('Score: ${(passed / totalTests * 100).toStringAsFixed(1)}%');
    buf.writeln('\n--- Results ---');
    results.forEach((test, pass) {
      buf.writeln('${pass ? "✅" : "❌"} $test');
    });
    return buf.toString();
  }
}
