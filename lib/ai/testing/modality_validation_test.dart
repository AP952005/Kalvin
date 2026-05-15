/// Kalvin AI — Modality Validation Test
///
/// Tests whether modality selection is educationally intelligent.
/// Verifies that visual, text, story, and quiz modes are
/// triggered appropriately for different query types.

import '../modality_selector.dart';
import '../emotion_engine.dart';
import '../learner_profile.dart';

class ModalityValidationTest {
  final ModalitySelector _selector = ModalitySelector();

  Future<ModalityValidationReport> runValidation() async {
    final results = <_ModalityTestCase>[];
    int correct = 0;

    // Test cases: input, expected modality type
    final cases = <Map<String, dynamic>>[
      {'input': 'What is 2+2?', 'topic': 'math', 'expect': 'text',
       'emotion': EmotionState.neutral},
      {'input': 'Explain how volcanoes erupt', 'topic': 'volcano', 'expect': 'visual',
       'emotion': EmotionState.curious},
      {'input': 'Show me the solar system', 'topic': 'solar_system', 'expect': 'visual',
       'emotion': EmotionState.curious},
      {'input': 'I still don\'t understand gravity', 'topic': 'gravity', 'expect': 'visual',
       'emotion': EmotionState.confused},
      {'input': 'This is boring', 'topic': 'general', 'expect': 'quiz',
       'emotion': EmotionState.bored},
      {'input': 'Define photosynthesis', 'topic': 'biology', 'expect': 'text',
       'emotion': EmotionState.neutral},
      {'input': 'I\'m so frustrated', 'topic': 'general', 'expect': 'story',
       'emotion': EmotionState.frustrated},
      {'input': 'How does rain form?', 'topic': 'water_cycle', 'expect': 'visual',
       'emotion': EmotionState.curious},
      {'input': 'Who invented the telephone?', 'topic': 'history', 'expect': 'text',
       'emotion': EmotionState.neutral},
      {'input': 'Can I see how earthquakes work?', 'topic': 'geology', 'expect': 'visual',
       'emotion': EmotionState.curious},
    ];

    for (final tc in cases) {
      final profile = LearnerProfile();
      final result = _selector.select(
        topic: tc['topic'] as String,
        userMessage: tc['input'] as String,
        profile: profile,
        emotionState: tc['emotion'] as EmotionState,
      );

      final expectType = tc['expect'] as String;
      final actualType = _categorize(result.modality);
      final pass = actualType == expectType;
      if (pass) correct++;

      results.add(_ModalityTestCase(
        input: tc['input'] as String,
        expectedType: expectType,
        actualModality: result.modality.name,
        actualType: actualType,
        reason: result.reason,
        visualScore: result.visualScore,
        passed: pass,
      ));
    }

    return ModalityValidationReport(
      totalTests: cases.length,
      correct: correct,
      results: results,
    );
  }

  String _categorize(LearningModality m) {
    switch (m) {
      case LearningModality.textOnly:
      case LearningModality.narrationOnly:
        return 'text';
      case LearningModality.visual3D:
      case LearningModality.narrationWithVisual:
        return 'visual';
      case LearningModality.diagram:
        return 'visual';
      case LearningModality.storyMode:
        return 'story';
      case LearningModality.quizMode:
        return 'quiz';
    }
  }
}

class _ModalityTestCase {
  final String input;
  final String expectedType;
  final String actualModality;
  final String actualType;
  final String reason;
  final double visualScore;
  final bool passed;

  _ModalityTestCase({
    required this.input,
    required this.expectedType,
    required this.actualModality,
    required this.actualType,
    required this.reason,
    required this.visualScore,
    required this.passed,
  });
}

class ModalityValidationReport {
  final int totalTests;
  final int correct;
  final List<_ModalityTestCase> results;

  ModalityValidationReport({
    required this.totalTests,
    required this.correct,
    required this.results,
  });

  double get qualityScore => totalTests > 0 ? correct / totalTests : 0;

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   MODALITY VALIDATION REPORT         ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Tests: $totalTests | Correct: $correct');
    buf.writeln('Quality: ${(qualityScore * 100).toStringAsFixed(1)}%');
    buf.writeln('\n--- Results ---');
    for (final r in results) {
      final icon = r.passed ? '✅' : '❌';
      buf.writeln('$icon "${r.input}"');
      buf.writeln('   Expected: ${r.expectedType} | Got: ${r.actualModality} (${r.actualType})');
      buf.writeln('   Reason: ${r.reason} | VisualScore: ${r.visualScore.toStringAsFixed(2)}');
    }
    return buf.toString();
  }
}
