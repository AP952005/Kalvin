/// Kalvin AI — Simple Quality Filter
///
/// Last-gate filter that catches bad responses before they reach UI.
/// Validates: not empty, not placeholder, not repeated, not malformed.

class SimpleQualityFilter {
  final List<String> _recentResponses = [];

  /// Check if a response passes quality standards.
  QualityResult check(String response) {
    if (response.trim().isEmpty) {
      return QualityResult.fail('Empty response');
    }

    if (response.trim().length < 5) {
      return QualityResult.fail('Response too short');
    }

    // Check for placeholder leaks
    final lower = response.toLowerCase();
    if (lower.contains('thinking about this') ||
        lower.contains('\$1') ||
        lower.contains('\$2') ||
        lower.contains('{response}') ||
        lower.contains('{input}')) {
      return QualityResult.fail('Placeholder leak detected');
    }

    // Check for raw JSON
    if (response.contains('"response"') ||
        response.contains('"emotion"') ||
        response.contains('"visual_required"')) {
      return QualityResult.fail('JSON leak detected');
    }

    // Check for system prompt leakage
    if (lower.contains('you are kalvin') ||
        lower.contains('system prompt') ||
        lower.contains('respond in json')) {
      return QualityResult.fail('System prompt leak');
    }

    // Check for repeated response
    if (_recentResponses.contains(response.trim())) {
      return QualityResult.fail('Duplicate response');
    }

    // Check for pure greeting with no content
    if (_isPureGreeting(lower)) {
      return QualityResult.fail('Pure greeting, no content');
    }

    return QualityResult.pass();
  }

  /// Record a response as sent (for duplicate detection).
  void recordResponse(String response) {
    _recentResponses.add(response.trim());
    if (_recentResponses.length > 10) {
      _recentResponses.removeAt(0);
    }
  }

  /// Reset for new conversation.
  void reset() {
    _recentResponses.clear();
  }

  bool _isPureGreeting(String lower) {
    final greetings = [
      'sure i can help',
      'what would you like to learn',
      'how can i help you',
      'hello! how can i',
      'hi there!',
    ];
    for (final g in greetings) {
      if (lower.startsWith(g) && lower.length < g.length + 20) return true;
    }
    return false;
  }
}

class QualityResult {
  final bool passed;
  final String reason;

  const QualityResult._(this.passed, this.reason);

  factory QualityResult.pass() => const QualityResult._(true, '');
  factory QualityResult.fail(String reason) => QualityResult._(false, reason);
}
