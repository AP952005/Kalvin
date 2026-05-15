/// Kalvin AI — Comprehension Test Runner
///
/// Simulates a learner progressively getting confused to verify
/// adaptive teaching: vocabulary simplification, analogy changes,
/// visual escalation, and emotional support increases.

import '../learning_orchestrator.dart';
import 'orchestration_logger.dart';

class ComprehensionTestRunner {
  final LearningOrchestrator _orchestrator;
  final OrchestrationLogger _logger = OrchestrationLogger();

  ComprehensionTestRunner(this._orchestrator);

  /// Simulate progressive confusion about gravity.
  Future<ComprehensionTestReport> runAdaptiveTest() async {
    final sequence = [
      'Explain gravity',
      'I don\'t understand',
      'Still confusing',
      'Can you explain more simply?',
      'Still hard to understand',
      'What does gravity actually do?',
      'Oh I think I get it now',
      'Yes that makes sense!',
    ];

    final results = <_ComprehensionStep>[];
    double prevComprehension = 0.5;

    for (int i = 0; i < sequence.length; i++) {
      final input = sequence[i];
      _logger.info('ComprehensionTest', 'Step ${i + 1}: "$input"');

      try {
        final response = await _orchestrator.processUserInput(input);
        await _orchestrator.stopNarration();

        final comp = response.comprehensionScore;
        final isSimplifying = comp < prevComprehension;

        results.add(_ComprehensionStep(
          step: i + 1,
          input: input,
          comprehensionScore: comp,
          emotion: response.emotionState.name,
          modality: response.selectedModality.name,
          visualTriggered: response.learningResponse.visualRequired,
          teachingStrategy: response.learningResponse.teachingStrategy,
          recommendation: response.comprehensionRecommendation,
          responseSnippet: response.learningResponse.response.length > 100
              ? '${response.learningResponse.response.substring(0, 100)}...'
              : response.learningResponse.response,
        ));

        prevComprehension = comp;
      } catch (e) {
        results.add(_ComprehensionStep(
          step: i + 1,
          input: input,
          comprehensionScore: 0,
          emotion: 'error',
          modality: 'error',
          visualTriggered: false,
          teachingStrategy: 'error',
          recommendation: 'error',
          responseSnippet: 'ERROR: $e',
        ));
        _logger.error('ComprehensionTest', 'Step ${i + 1} failed: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Score: did the system adapt?
    int adaptations = 0;
    for (int i = 1; i < results.length; i++) {
      if (results[i].visualTriggered && !results[i - 1].visualTriggered) {
        adaptations++; // visual escalation
      }
      if (results[i].recommendation == 'simplify' ||
          results[i].recommendation == 'simplify_drastically') {
        adaptations++; // simplification triggered
      }
      if (results[i].recommendation == 'try_visual') {
        adaptations++; // visual recommendation
      }
    }

    return ComprehensionTestReport(
      steps: results,
      totalSteps: sequence.length,
      adaptationCount: adaptations,
      adaptiveScore: (adaptations / sequence.length).clamp(0.0, 1.0),
    );
  }
}

class _ComprehensionStep {
  final int step;
  final String input;
  final double comprehensionScore;
  final String emotion;
  final String modality;
  final bool visualTriggered;
  final String teachingStrategy;
  final String recommendation;
  final String responseSnippet;

  _ComprehensionStep({
    required this.step,
    required this.input,
    required this.comprehensionScore,
    required this.emotion,
    required this.modality,
    required this.visualTriggered,
    required this.teachingStrategy,
    required this.recommendation,
    required this.responseSnippet,
  });
}

class ComprehensionTestReport {
  final List<_ComprehensionStep> steps;
  final int totalSteps;
  final int adaptationCount;
  final double adaptiveScore;

  ComprehensionTestReport({
    required this.steps,
    required this.totalSteps,
    required this.adaptationCount,
    required this.adaptiveScore,
  });

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   COMPREHENSION ADAPTIVE TEST        ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Steps: $totalSteps | Adaptations: $adaptationCount');
    buf.writeln('Adaptive score: ${(adaptiveScore * 100).toStringAsFixed(1)}%');
    buf.writeln('\n--- Step-by-step ---');
    for (final s in steps) {
      buf.writeln('Step ${s.step}: "${s.input}"');
      buf.writeln('  Comp: ${s.comprehensionScore.toStringAsFixed(2)} '
          'Emotion: ${s.emotion} Modality: ${s.modality}');
      buf.writeln('  Visual: ${s.visualTriggered} Strategy: ${s.teachingStrategy}');
      buf.writeln('  Recommendation: ${s.recommendation}');
    }
    return buf.toString();
  }
}
