/// Kalvin AI — Offline Validation Test
///
/// Verifies all systems work without internet: llama.cpp local,
/// visuals, memory, narration, and orchestration.

import '../llama_service.dart';
import '../memory_engine.dart';
import '../narration_engine.dart';
import '../visual_trigger_engine.dart';
import '../response_parser.dart';

class OfflineValidationTest {
  Future<OfflineValidationReport> runValidation() async {
    final results = <String, bool>{};

    // Test 1: LLM server reachable on localhost
    try {
      final llama = LlamaService();
      final available = await llama.isAvailable();
      results['llm_localhost_available'] = available;
      llama.dispose();
    } catch (e) {
      results['llm_localhost_available'] = false;
    }

    // Test 2: LLM can generate response
    try {
      final llama = LlamaService();
      final response = await llama.generateResponse(
        'Say hello in one sentence. Respond with JSON: {"response":"hello"}',
      );
      results['llm_response_generation'] = response.isNotEmpty;
      llama.dispose();
    } catch (e) {
      results['llm_response_generation'] = false;
    }

    // Test 3: Memory engine (Hive — local filesystem)
    try {
      final memory = MemoryEngine();
      await memory.init();
      results['memory_hive_init'] = true;
    } catch (e) {
      results['memory_hive_init'] = false;
    }

    // Test 4: Narration engine (TTS — local system)
    try {
      final narration = NarrationEngine();
      await narration.init();
      results['narration_tts_init'] = true;
      narration.dispose();
    } catch (e) {
      results['narration_tts_init'] = false;
    }

    // Test 5: Visual trigger (pure Dart — no network)
    try {
      final visual = VisualTriggerEngine();
      final cmd = visual.getLoadSceneJS('volcano');
      results['visual_trigger_offline'] = cmd != null;
    } catch (e) {
      results['visual_trigger_offline'] = false;
    }

    // Test 6: Response parser (pure Dart — no network)
    try {
      final parser = ResponseParser();
      final result = parser.parse(
          '{"response":"test","narration":"test","emotion":"calm"}');
      results['response_parser_offline'] = result.response == 'test';
    } catch (e) {
      results['response_parser_offline'] = false;
    }

    // Test 7: Safety — empty input handling
    try {
      final parser = ResponseParser();
      final result = parser.parse('');
      results['empty_input_safety'] = result.response.isNotEmpty;
    } catch (e) {
      results['empty_input_safety'] = false;
    }

    // Test 8: Safety — malformed JSON handling
    try {
      final parser = ResponseParser();
      final result = parser.parse('{broken json here');
      results['malformed_json_safety'] = result.response.isNotEmpty;
    } catch (e) {
      results['malformed_json_safety'] = false;
    }

    // Test 9: Safety — nonsense input
    try {
      final parser = ResponseParser();
      final result = parser.parse('asdfghjkl random garbage 12345');
      results['nonsense_input_safety'] = result.response.isNotEmpty;
    } catch (e) {
      results['nonsense_input_safety'] = false;
    }

    final passed = results.values.where((v) => v).length;
    final offlineReady = results['llm_localhost_available'] == true &&
        results['memory_hive_init'] == true &&
        results['narration_tts_init'] == true;

    return OfflineValidationReport(
      totalTests: results.length,
      passed: passed,
      offlineReady: offlineReady,
      results: results,
    );
  }
}

class OfflineValidationReport {
  final int totalTests;
  final int passed;
  final bool offlineReady;
  final Map<String, bool> results;

  OfflineValidationReport({
    required this.totalTests,
    required this.passed,
    required this.offlineReady,
    required this.results,
  });

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   OFFLINE READINESS REPORT           ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Tests: $totalTests | Passed: $passed');
    buf.writeln('OFFLINE READY: ${offlineReady ? "✅ YES" : "❌ NO"}');
    buf.writeln('\n--- Results ---');
    results.forEach((test, pass) {
      buf.writeln('${pass ? "✅" : "❌"} $test');
    });
    return buf.toString();
  }
}
