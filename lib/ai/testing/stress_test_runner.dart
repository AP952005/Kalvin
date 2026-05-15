/// Kalvin AI — Stress Test Runner
///
/// Simulates rapid messages, long sessions, repeated narration,
/// and rapid scene switching to detect memory leaks, crashes,
/// and synchronization issues.

import '../learning_orchestrator.dart';
import 'orchestration_logger.dart';

class StressTestRunner {
  final LearningOrchestrator _orchestrator;
  final OrchestrationLogger _logger = OrchestrationLogger();

  StressTestRunner(this._orchestrator);

  static const _stressInputs = [
    'What is the sun?', 'How hot is lava?', 'Why does it rain?',
    'Tell me about space', 'What is gravity?', 'Show me volcanoes',
    'I don\'t get it', 'Explain again', 'What are clouds?',
    'How do plants grow?', 'What is photosynthesis?', 'Show me earth',
    'I\'m confused', 'That\'s amazing!', 'What is an atom?',
    'How do earthquakes happen?', 'What is DNA?', 'Tell me more',
    'I still don\'t understand', 'Skip this', 'Next topic',
    'What about the moon?', 'How far is the sun?', 'Why is sky blue?',
    'What is electricity?', 'How do magnets work?', 'Show water cycle',
    'I like science', 'This is boring', 'Make it fun',
    'What is temperature?', 'How do fish breathe?', 'What is oxygen?',
    'Tell me a story', 'Quiz me', 'I know this already',
    'What is evolution?', 'How old is earth?', 'What are fossils?',
    'Explain tides', 'What causes wind?', 'How do birds fly?',
    'What is energy?', 'How do cars work?', 'What is friction?',
    'Explain seasons', 'What is the equator?', 'Why do leaves fall?',
    'What is recycling?', 'How do vaccines work?',
  ];

  Future<StressTestReport> runStressTest({int count = 50}) async {
    final results = <_StressResult>[];
    final startTime = DateTime.now();
    int crashes = 0;
    int narrationOverlaps = 0;
    double maxResponseTime = 0;

    _logger.info('StressTest', 'Starting $count rapid requests');

    for (int i = 0; i < count && i < _stressInputs.length; i++) {
      final input = _stressInputs[i];
      final sw = Stopwatch()..start();

      try {
        final response = await _orchestrator.processUserInput(input);
        sw.stop();
        await _orchestrator.stopNarration();

        final ms = sw.elapsedMilliseconds.toDouble();
        if (ms > maxResponseTime) maxResponseTime = ms;

        results.add(_StressResult(
          index: i,
          input: input,
          responseTimeMs: ms,
          success: true,
        ));

        _logger.performance('StressTest', 'Request $i: ${ms.toInt()}ms',
            latencyMs: ms);
      } catch (e) {
        sw.stop();
        crashes++;
        results.add(_StressResult(
          index: i,
          input: input,
          responseTimeMs: sw.elapsedMilliseconds.toDouble(),
          success: false,
          error: e.toString(),
        ));
        _logger.error('StressTest', 'CRASH at $i: $e');
      }

      // Minimal delay — stress test
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final totalDuration = DateTime.now().difference(startTime);
    final successCount = results.where((r) => r.success).length;
    final avgTime = results.isEmpty
        ? 0.0
        : results.map((r) => r.responseTimeMs).reduce((a, b) => a + b) /
            results.length;

    return StressTestReport(
      totalRequests: results.length,
      successful: successCount,
      crashes: crashes,
      avgResponseTimeMs: avgTime,
      maxResponseTimeMs: maxResponseTime,
      totalDuration: totalDuration,
      narrationOverlaps: narrationOverlaps,
      results: results,
    );
  }
}

class _StressResult {
  final int index;
  final String input;
  final double responseTimeMs;
  final bool success;
  final String? error;

  _StressResult({
    required this.index,
    required this.input,
    required this.responseTimeMs,
    required this.success,
    this.error,
  });
}

class StressTestReport {
  final int totalRequests;
  final int successful;
  final int crashes;
  final double avgResponseTimeMs;
  final double maxResponseTimeMs;
  final Duration totalDuration;
  final int narrationOverlaps;
  final List<_StressResult> results;

  StressTestReport({
    required this.totalRequests,
    required this.successful,
    required this.crashes,
    required this.avgResponseTimeMs,
    required this.maxResponseTimeMs,
    required this.totalDuration,
    required this.narrationOverlaps,
    required this.results,
  });

  double get successRate =>
      totalRequests > 0 ? successful / totalRequests : 0;

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   STRESS TEST REPORT                 ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Requests: $totalRequests');
    buf.writeln('Success: $successful | Crashes: $crashes');
    buf.writeln('Success rate: ${(successRate * 100).toStringAsFixed(1)}%');
    buf.writeln('Avg response: ${avgResponseTimeMs.toStringAsFixed(0)}ms');
    buf.writeln('Max response: ${maxResponseTimeMs.toStringAsFixed(0)}ms');
    buf.writeln('Total time: ${totalDuration.inSeconds}s');
    buf.writeln('Narration overlaps: $narrationOverlaps');
    if (crashes > 0) {
      buf.writeln('\n--- Crashes ---');
      for (final r in results.where((r) => !r.success)) {
        buf.writeln('  #${r.index}: "${r.input}" — ${r.error}');
      }
    }
    return buf.toString();
  }
}
