/// Kalvin AI — Orchestrator Test Runner
///
/// Main validation suite for the full orchestration pipeline.
/// Runs real AI requests through all engines and reports results.

import '../learning_orchestrator.dart';
import 'orchestration_logger.dart';

class OrchestratorTestRunner {
  final LearningOrchestrator _orchestrator;
  final OrchestrationLogger _logger = OrchestrationLogger();
  final List<TestResult> _results = [];

  OrchestratorTestRunner(this._orchestrator);

  static const List<Map<String, dynamic>> _testCases = [
    {'input': 'Explain volcanoes', 'expectEmotion': 'curious', 'expectVisual': true},
    {'input': 'I don\'t understand gravity', 'expectEmotion': 'confused', 'expectVisual': false},
    {'input': 'Tell me about plants', 'expectEmotion': 'curious', 'expectVisual': false},
    {'input': 'How does rain happen?', 'expectEmotion': 'curious', 'expectVisual': true},
    {'input': 'This is confusing', 'expectEmotion': 'confused', 'expectVisual': false},
    {'input': 'Wow that\'s cool', 'expectEmotion': 'excited', 'expectVisual': false},
    {'input': 'I like cricket', 'expectEmotion': 'neutral', 'expectVisual': false},
    {'input': 'I help in farming', 'expectEmotion': 'neutral', 'expectVisual': false},
  ];

  Future<OrchestratorTestReport> runAllTests() async {
    _results.clear();
    _logger.info('OrchestratorTest', 'Starting ${_testCases.length} test cases');

    final overallStart = DateTime.now();

    for (int i = 0; i < _testCases.length; i++) {
      final tc = _testCases[i];
      final input = tc['input'] as String;
      _logger.info('OrchestratorTest', 'Test ${i + 1}: "$input"');

      final sw = Stopwatch()..start();
      try {
        final response = await _orchestrator.processUserInput(input);
        sw.stop();

        // Stop narration immediately (testing only)
        await _orchestrator.stopNarration();

        _results.add(TestResult(
          input: input,
          passed: true,
          responseTime: sw.elapsedMilliseconds,
          emotion: response.emotionState.name,
          modality: response.selectedModality.name,
          visualTriggered: response.learningResponse.visualRequired,
          visualScene: response.learningResponse.visualScene,
          comprehensionScore: response.comprehensionScore,
          responseLength: response.learningResponse.response.length,
          narrationLength: response.learningResponse.response.length,
          hasFollowUp: response.learningResponse.followUpQuestion.isNotEmpty,
          jsCommands: response.jsCommands,
        ));

        _logger.performance('OrchestratorTest', 'Test ${i + 1} completed',
            latencyMs: sw.elapsedMilliseconds.toDouble());
      } catch (e) {
        sw.stop();
        _results.add(TestResult(
          input: input,
          passed: false,
          responseTime: sw.elapsedMilliseconds,
          error: e.toString(),
        ));
        _logger.error('OrchestratorTest', 'Test ${i + 1} FAILED: $e');
      }

      // Small delay between tests
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final totalTime = DateTime.now().difference(overallStart);

    return OrchestratorTestReport(
      results: List.from(_results),
      totalTests: _testCases.length,
      passed: _results.where((r) => r.passed).length,
      failed: _results.where((r) => !r.passed).length,
      avgResponseTime: _results.isEmpty
          ? 0
          : _results.map((r) => r.responseTime).reduce((a, b) => a + b) /
              _results.length,
      totalDuration: totalTime,
    );
  }
}

class TestResult {
  final String input;
  final bool passed;
  final int responseTime;
  final String emotion;
  final String modality;
  final bool visualTriggered;
  final String visualScene;
  final double comprehensionScore;
  final int responseLength;
  final int narrationLength;
  final bool hasFollowUp;
  final List<String> jsCommands;
  final String? error;

  TestResult({
    required this.input,
    required this.passed,
    required this.responseTime,
    this.emotion = '',
    this.modality = '',
    this.visualTriggered = false,
    this.visualScene = '',
    this.comprehensionScore = 0,
    this.responseLength = 0,
    this.narrationLength = 0,
    this.hasFollowUp = false,
    this.jsCommands = const [],
    this.error,
  });

  @override
  String toString() {
    if (!passed) return '❌ "$input" — ERROR: $error (${responseTime}ms)';
    return '✅ "$input" — emotion:$emotion modality:$modality '
        'visual:$visualTriggered scene:$visualScene '
        'comp:${comprehensionScore.toStringAsFixed(2)} '
        '${responseTime}ms';
  }
}

class OrchestratorTestReport {
  final List<TestResult> results;
  final int totalTests;
  final int passed;
  final int failed;
  final double avgResponseTime;
  final Duration totalDuration;

  OrchestratorTestReport({
    required this.results,
    required this.totalTests,
    required this.passed,
    required this.failed,
    required this.avgResponseTime,
    required this.totalDuration,
  });

  double get passRate => totalTests > 0 ? passed / totalTests : 0;

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   ORCHESTRATOR TEST REPORT           ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Tests: $totalTests | Pass: $passed | Fail: $failed');
    buf.writeln('Pass rate: ${(passRate * 100).toStringAsFixed(1)}%');
    buf.writeln('Avg response: ${avgResponseTime.toStringAsFixed(0)}ms');
    buf.writeln('Total time: ${totalDuration.inSeconds}s');
    buf.writeln('\n--- Results ---');
    for (final r in results) {
      buf.writeln(r.toString());
    }
    return buf.toString();
  }
}
