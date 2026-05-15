/// Kalvin AI — Comprehension Engine
///
/// Tracks and estimates learner understanding per topic.
/// Detects repeated confusion, uncertain replies, and
/// generates confidence scores and retry recommendations.

import 'learner_profile.dart';

/// Comprehension level thresholds.
class ComprehensionLevel {
  static const double excellent = 0.85;
  static const double good = 0.65;
  static const double struggling = 0.4;
  static const double failing = 0.2;
}

/// Tracks and estimates learner comprehension.
class ComprehensionEngine {
  /// Per-topic confusion counter (resets on successful comprehension)
  final Map<String, int> _confusionStreak = {};

  /// Per-topic question count
  final Map<String, int> _topicQuestionCount = {};

  /// Recent response qualities (for trend analysis)
  final List<_ComprehensionSignal> _recentSignals = [];

  /// Analyze a user message for comprehension signals.
  ComprehensionResult analyze({
    required String userMessage,
    required String currentTopic,
    required LearnerProfile profile,
  }) {
    final lower = userMessage.toLowerCase().trim();

    // Track topic questions
    _topicQuestionCount[currentTopic] =
        (_topicQuestionCount[currentTopic] ?? 0) + 1;

    // Detect comprehension signals
    double score = 0.5; // neutral baseline
    String recommendation = 'continue';

    // ── Positive signals ──
    if (_isPositiveResponse(lower)) {
      score += 0.2;
      _resetConfusion(currentTopic);
    }

    // ── Negative signals ──
    if (_isConfusionSignal(lower)) {
      score -= 0.3;
      _incrementConfusion(currentTopic);
    }

    if (_isUncertainResponse(lower)) {
      score -= 0.15;
    }

    // ── Very short replies suggest disengagement ──
    if (lower.length < 4 && !_isAffirmative(lower)) {
      score -= 0.1;
    }

    // ── Repeated same-topic questions ──
    final topicCount = _topicQuestionCount[currentTopic] ?? 0;
    if (topicCount > 3) {
      score -= 0.1; // learner keeps asking about same topic
    }

    // ── Confusion streak analysis ──
    final streak = _confusionStreak[currentTopic] ?? 0;
    if (streak >= 3) {
      score -= 0.2;
      recommendation = 'simplify_drastically';
    } else if (streak >= 2) {
      recommendation = 'try_visual';
    }

    // Clamp score
    score = score.clamp(0.0, 1.0);

    // Update profile
    profile.updateComprehension(currentTopic, score);

    // Record signal
    _recentSignals.add(_ComprehensionSignal(
      topic: currentTopic,
      score: score,
      timestamp: DateTime.now(),
    ));
    _pruneSignals();

    // Generate recommendation
    if (score < ComprehensionLevel.failing) {
      recommendation = 'simplify_drastically';
    } else if (score < ComprehensionLevel.struggling) {
      recommendation = streak >= 2 ? 'try_visual' : 'simplify';
    } else if (score > ComprehensionLevel.good) {
      recommendation = 'advance';
    }

    return ComprehensionResult(
      score: score,
      confusionStreak: streak,
      recommendation: recommendation,
      topicQuestionCount: topicCount,
    );
  }

  /// Get consecutive confusion count for a topic.
  int getConfusionStreak(String topic) {
    return _confusionStreak[topic] ?? 0;
  }

  /// Check if the learner seems to understand.
  bool isComprehending(String topic, LearnerProfile profile) {
    final score = profile.comprehensionScores[topic] ?? 0.5;
    return score >= ComprehensionLevel.struggling;
  }

  // ── Signal detection methods ──

  bool _isConfusionSignal(String message) {
    const signals = [
      'don\'t understand', 'dont understand', 'confused',
      'what do you mean', 'not clear', 'explain again',
      'repeat', 'huh', 'i don\'t get it', 'too hard',
      'makes no sense', 'i\'m lost', 'what',
    ];
    return signals.any((s) => message.contains(s));
  }

  bool _isUncertainResponse(String message) {
    const signals = [
      'maybe', 'i think', 'not sure', 'i guess',
      'probably', 'kind of', 'sort of',
    ];
    return signals.any((s) => message.contains(s));
  }

  bool _isPositiveResponse(String message) {
    const signals = [
      'i understand', 'got it', 'makes sense', 'i see',
      'oh i get it', 'that\'s clear', 'understood',
      'now i know', 'thank you', 'thanks', 'helpful',
      'interesting', 'cool', 'great explanation',
    ];
    return signals.any((s) => message.contains(s));
  }

  bool _isAffirmative(String message) {
    const words = ['yes', 'yeah', 'ok', 'yep', 'sure', 'right'];
    return words.contains(message);
  }

  void _incrementConfusion(String topic) {
    _confusionStreak[topic] = (_confusionStreak[topic] ?? 0) + 1;
  }

  void _resetConfusion(String topic) {
    _confusionStreak[topic] = 0;
  }

  void _pruneSignals() {
    if (_recentSignals.length > 50) {
      _recentSignals.removeRange(0, _recentSignals.length - 50);
    }
  }

  /// Get overall learning trend (improving, stable, declining).
  String getLearningTrend() {
    if (_recentSignals.length < 3) return 'stable';

    final recent = _recentSignals
        .sublist(_recentSignals.length - 3)
        .map((s) => s.score)
        .toList();

    final avg = recent.reduce((a, b) => a + b) / recent.length;
    final first = recent.first;

    if (avg > first + 0.1) return 'improving';
    if (avg < first - 0.1) return 'declining';
    return 'stable';
  }
}

/// Result of comprehension analysis.
class ComprehensionResult {
  final double score;
  final int confusionStreak;
  final String recommendation;
  final int topicQuestionCount;

  const ComprehensionResult({
    required this.score,
    required this.confusionStreak,
    required this.recommendation,
    required this.topicQuestionCount,
  });
}

class _ComprehensionSignal {
  final String topic;
  final double score;
  final DateTime timestamp;

  _ComprehensionSignal({
    required this.topic,
    required this.score,
    required this.timestamp,
  });
}
