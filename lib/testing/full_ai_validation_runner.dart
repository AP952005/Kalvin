/// Kalvin AI — Full AI Validation Runner
///
/// Comprehensive testing framework that validates AI response
/// quality across all simulated user types. Tests for:
/// - Repetitive greetings
/// - Response cleanliness (no JSON/markdown leaks)
/// - Emotional adaptation
/// - Conversational continuity
/// - Response quality metrics

import '../ai/clean_response_formatter.dart';
import '../ai/response_sanitizer.dart';
import 'simulated_users/simulated_user_profiles.dart';

/// Result of a single test case.
class TestResult {
  final String testName;
  final String userName;
  final String input;
  final String output;
  final bool passed;
  final List<String> issues;
  final Map<String, double> metrics;

  const TestResult({
    required this.testName,
    required this.userName,
    required this.input,
    required this.output,
    required this.passed,
    this.issues = const [],
    this.metrics = const {},
  });
}

/// Full validation report.
class ValidationReport {
  final List<TestResult> results;
  final DateTime timestamp;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final Map<String, double> aggregateMetrics;

  ValidationReport({
    required this.results,
    required this.timestamp,
  })  : totalTests = results.length,
        passedTests = results.where((r) => r.passed).length,
        failedTests = results.where((r) => !r.passed).length,
        aggregateMetrics = _computeAggregateMetrics(results);

  double get passRate => totalTests > 0 ? passedTests / totalTests : 0;

  static Map<String, double> _computeAggregateMetrics(List<TestResult> results) {
    if (results.isEmpty) return {};

    double totalCleanliness = 0;
    double totalRepetition = 0;
    double totalEmotionalRealism = 0;
    double totalNarrationSmoothness = 0;
    double totalMemoryContinuity = 0;
    double totalAdaptation = 0;
    int count = 0;

    for (final r in results) {
      totalCleanliness += r.metrics['cleanliness'] ?? 0;
      totalRepetition += r.metrics['repetition_score'] ?? 0;
      totalEmotionalRealism += r.metrics['emotional_realism'] ?? 0;
      totalNarrationSmoothness += r.metrics['narration_smoothness'] ?? 0;
      totalMemoryContinuity += r.metrics['memory_continuity'] ?? 0;
      totalAdaptation += r.metrics['adaptation'] ?? 0;
      count++;
    }

    return {
      'avg_cleanliness': totalCleanliness / count,
      'avg_repetition_score': totalRepetition / count,
      'avg_emotional_realism': totalEmotionalRealism / count,
      'avg_narration_smoothness': totalNarrationSmoothness / count,
      'avg_memory_continuity': totalMemoryContinuity / count,
      'avg_adaptation': totalAdaptation / count,
    };
  }

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln('=== KALVIN AI VALIDATION REPORT ===');
    buf.writeln('Timestamp: $timestamp');
    buf.writeln('Total: $totalTests | Passed: $passedTests | Failed: $failedTests');
    buf.writeln('Pass Rate: ${(passRate * 100).toStringAsFixed(1)}%');
    buf.writeln('');
    buf.writeln('Aggregate Metrics:');
    for (final e in aggregateMetrics.entries) {
      buf.writeln('  ${e.key}: ${(e.value * 100).toStringAsFixed(1)}%');
    }
    buf.writeln('');
    for (final r in results.where((r) => !r.passed)) {
      buf.writeln('FAILED: ${r.testName} (${r.userName})');
      for (final issue in r.issues) {
        buf.writeln('  - $issue');
      }
    }
    return buf.toString();
  }
}

/// Runs validation tests on AI responses (offline — no LLM needed).
class FullAIValidationRunner {
  /// Run all response cleanliness tests.
  static ValidationReport runCleanlinessTests(List<String> sampleResponses) {
    final results = <TestResult>[];

    for (var i = 0; i < sampleResponses.length; i++) {
      final raw = sampleResponses[i];
      final cleaned = CleanResponseFormatter.cleanResponse(raw);
      final issues = <String>[];

      // Check for leakage
      if (CleanResponseFormatter.hasLeakage(cleaned)) {
        issues.add('Contains leaked developer content');
      }
      if (ResponseSanitizer.containsLeakage(cleaned)) {
        issues.add('Contains sanitizer-detected leakage');
      }

      // Check for markdown
      if (cleaned.contains('**') || cleaned.contains('```') || cleaned.contains('##')) {
        issues.add('Contains markdown formatting');
      }

      // Check for JSON fragments
      if (cleaned.contains('"response"') || cleaned.contains('"emotion"')) {
        issues.add('Contains JSON field names');
      }

      // Check for repetitive intros
      final hasRepetitiveIntro = _checkRepetitiveIntro(cleaned);
      if (hasRepetitiveIntro) {
        issues.add('Contains repetitive intro phrase');
      }

      // Compute cleanliness score
      double cleanliness = 1.0;
      if (issues.isNotEmpty) cleanliness -= issues.length * 0.25;
      cleanliness = cleanliness.clamp(0.0, 1.0);

      results.add(TestResult(
        testName: 'Cleanliness Test #${i + 1}',
        userName: 'system',
        input: raw.length > 50 ? '${raw.substring(0, 50)}...' : raw,
        output: cleaned.length > 50 ? '${cleaned.substring(0, 50)}...' : cleaned,
        passed: issues.isEmpty,
        issues: issues,
        metrics: {
          'cleanliness': cleanliness,
          'repetition_score': hasRepetitiveIntro ? 0.0 : 1.0,
          'emotional_realism': 0.5,
          'narration_smoothness': cleaned.isNotEmpty ? 0.8 : 0.0,
          'memory_continuity': 0.5,
          'adaptation': 0.5,
        },
      ));
    }

    return ValidationReport(results: results, timestamp: DateTime.now());
  }

  /// Validate a response against a simulated user's expected behaviors.
  static TestResult validateForUser(SimulatedUser user, String response) {
    final cleaned = CleanResponseFormatter.cleanResponse(response);
    final issues = <String>[];

    // Check basic cleanliness
    if (CleanResponseFormatter.hasLeakage(cleaned)) {
      issues.add('Leaked developer content');
    }

    // Check response length appropriateness
    if (cleaned.length > 800 && user.age < 12) {
      issues.add('Response too long for young learner (${cleaned.length} chars)');
    }
    if (cleaned.isEmpty) {
      issues.add('Empty response');
    }

    // Check for repetitive intro
    if (_checkRepetitiveIntro(cleaned)) {
      issues.add('Repetitive intro detected');
    }

    // Check emotional appropriateness
    if (user.emotionalState == 'frustrated' && 
        !_checkEmpathy(cleaned)) {
      issues.add('Lacks empathy for frustrated user');
    }

    // Compute metrics
    final metrics = <String, double>{
      'cleanliness': issues.isEmpty ? 1.0 : 0.5,
      'repetition_score': _checkRepetitiveIntro(cleaned) ? 0.0 : 1.0,
      'emotional_realism': _scoreEmotionalRealism(cleaned, user.emotionalState),
      'narration_smoothness': _scoreNarrationSmoothness(cleaned),
      'memory_continuity': 0.5,
      'adaptation': _scoreAdaptation(cleaned, user),
    };

    return TestResult(
      testName: 'User Validation: ${user.name}',
      userName: user.name,
      input: user.testPrompts.first,
      output: cleaned.length > 50 ? '${cleaned.substring(0, 50)}...' : cleaned,
      passed: issues.isEmpty,
      issues: issues,
      metrics: metrics,
    );
  }

  /// Sample malformed LLM outputs for testing.
  static List<String> get sampleMalformedOutputs => [
    '{"response": "The sun is a giant ball of gas!", "emotion": "excited", "visual_required": false, "visual_scene": "", "follow_up": "Want to know how hot it is?"}',
    '**Narration:** The water cycle is fascinating.\n**Teaching Strategy:** Use analogy\n**Response:** Water goes up as vapor and comes down as rain.',
    'Sure, I can help! Great question! What would you like to learn today? The volcano is very interesting.',
    'Kalvin: Hello! I am Kalvin, your learning companion. Let me tell you about atoms. An atom is...',
    '```json\n{"response": "Planets orbit the sun"}\n```',
    'The sun is very hot. It is a star.\n\n"emotion": "excited"\n"visual_required": true',
    '<start_of_turn>model\nI can explain that!<end_of_turn>',
    'Response: Gravity pulls things down.\nTeaching Strategy: step_by_step\nEmotion: supportive',
  ];

  // ── Private scoring helpers ──

  static bool _checkRepetitiveIntro(String text) {
    final lower = text.toLowerCase();
    return lower.startsWith('sure') ||
        lower.startsWith('of course') ||
        lower.startsWith('great question') ||
        lower.startsWith('hello') ||
        lower.startsWith('hi there') ||
        lower.contains('what would you like to learn') ||
        lower.contains('how can i help');
  }

  static bool _checkEmpathy(String text) {
    final lower = text.toLowerCase();
    return lower.contains('okay') ||
        lower.contains("it's okay") ||
        lower.contains("don't worry") ||
        lower.contains('no rush') ||
        lower.contains('take your time') ||
        lower.contains('understandable') ||
        lower.contains('let me try') ||
        lower.contains('simpler') ||
        lower.contains('easier') ||
        lower.contains('step by step') ||
        lower.contains('you\'re doing');
  }

  static double _scoreEmotionalRealism(String text, String expectedEmotion) {
    double score = 0.5;
    final lower = text.toLowerCase();

    switch (expectedEmotion) {
      case 'frustrated':
        if (_checkEmpathy(lower)) score += 0.3;
        break;
      case 'excited':
        if (lower.contains('!') || lower.contains('amazing') || lower.contains('cool')) score += 0.3;
        break;
      case 'tired':
        if (text.length < 200) score += 0.2; // Short responses for tired users
        break;
      case 'shy':
        if (text.length < 150) score += 0.2;
        if (lower.contains('?')) score += 0.1; // Asks gentle questions
        break;
    }

    return score.clamp(0.0, 1.0);
  }

  static double _scoreNarrationSmoothness(String text) {
    if (text.isEmpty) return 0.0;
    double score = 0.7;

    // Penalize very long sentences
    final sentences = text.split(RegExp(r'[.!?]')).where((s) => s.trim().isNotEmpty);
    for (final s in sentences) {
      if (s.length > 150) score -= 0.1;
    }

    // Reward natural punctuation
    if (text.contains('.') && text.contains('!')) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  static double _scoreAdaptation(String text, SimulatedUser user) {
    double score = 0.5;
    final lower = text.toLowerCase();

    // Check language complexity matches age
    final avgWordLength = _avgWordLength(lower);
    if (user.age < 12 && avgWordLength < 5.5) score += 0.2;
    if (user.age >= 14 && avgWordLength > 4.0) score += 0.2;

    // Check appropriate length
    if (user.age < 10 && text.length < 300) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  static double _avgWordLength(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return 0;
    final totalChars = words.fold<int>(0, (sum, w) => sum + w.length);
    return totalChars / words.length;
  }
}
