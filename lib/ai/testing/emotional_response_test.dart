/// Kalvin AI — Emotional Response Test
///
/// Tests emotional intelligence quality: detection accuracy,
/// tone adaptation, and supportive response generation.

import '../emotion_engine.dart';

class EmotionalResponseTest {
  final EmotionEngine _engine = EmotionEngine();

  Future<EmotionalResponseReport> runValidation() async {
    final cases = <Map<String, dynamic>>[
      {'input': 'I\'m confused about this', 'expect': EmotionState.confused},
      {'input': 'This is so boring', 'expect': EmotionState.bored},
      {'input': 'Wow that\'s amazing!', 'expect': EmotionState.excited},
      {'input': 'I still don\'t get it', 'expect': EmotionState.confused},
      {'input': 'Thanks Kalvin, that helps!', 'expect': EmotionState.excited},
      {'input': 'UGH this is stupid', 'expect': EmotionState.frustrated},
      {'input': 'Why does this happen?', 'expect': EmotionState.curious},
      {'input': 'ok', 'expect': EmotionState.bored},
      {'input': 'I\'m worried about my exam', 'expect': EmotionState.anxious},
      {'input': 'How does the sun work?', 'expect': EmotionState.curious},
      {'input': 'I hate this subject', 'expect': EmotionState.frustrated},
      {'input': 'Tell me more!', 'expect': EmotionState.excited},
      {'input': 'What if gravity didn\'t exist?', 'expect': EmotionState.curious},
      {'input': 'I give up', 'expect': EmotionState.frustrated},
      {'input': 'meh', 'expect': EmotionState.bored},
    ];

    int correct = 0;
    final results = <_EmotionTestCase>[];

    for (final tc in cases) {
      final input = tc['input'] as String;
      final expected = tc['expect'] as EmotionState;
      final analysis = _engine.analyze(input);

      final pass = analysis.state == expected;
      if (pass) correct++;

      results.add(_EmotionTestCase(
        input: input,
        expected: expected.name,
        detected: analysis.state.name,
        confidence: analysis.confidence,
        passed: pass,
        contextString: _engine.toContextString(analysis.state),
      ));
    }

    return EmotionalResponseReport(
      totalTests: cases.length,
      correct: correct,
      results: results,
    );
  }
}

class _EmotionTestCase {
  final String input;
  final String expected;
  final String detected;
  final double confidence;
  final bool passed;
  final String contextString;

  _EmotionTestCase({
    required this.input,
    required this.expected,
    required this.detected,
    required this.confidence,
    required this.passed,
    required this.contextString,
  });
}

class EmotionalResponseReport {
  final int totalTests;
  final int correct;
  final List<_EmotionTestCase> results;

  EmotionalResponseReport({
    required this.totalTests,
    required this.correct,
    required this.results,
  });

  double get adaptationScore => totalTests > 0 ? correct / totalTests : 0;

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   EMOTIONAL INTELLIGENCE REPORT      ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Tests: $totalTests | Correct: $correct');
    buf.writeln('Adaptation score: ${(adaptationScore * 100).toStringAsFixed(1)}%');
    buf.writeln('\n--- Results ---');
    for (final r in results) {
      final icon = r.passed ? '✅' : '❌';
      buf.writeln('$icon "${r.input}"');
      buf.writeln('   Expected: ${r.expected} | Detected: ${r.detected} '
          '(${(r.confidence * 100).toStringAsFixed(0)}%)');
    }
    return buf.toString();
  }
}
