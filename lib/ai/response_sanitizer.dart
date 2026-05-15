/// Kalvin AI — Response Sanitizer
///
/// Final defensive cleanup layer that catches malformed JSON,
/// hallucinated labels, repeated intros, markdown artifacts,
/// system prompt leakage, and broken formatting.
/// Runs BEFORE any text reaches the UI.

class ResponseSanitizer {
  /// Patterns that must NEVER appear in user-facing text.
  static final List<RegExp> _forbiddenPatterns = [
    // Markdown headers and formatting
    RegExp(r'\*\*[^*]+\*\*:?\s*', multiLine: true),
    RegExp(r'#{1,6}\s+', multiLine: true),
    RegExp(r'```[\s\S]*?```', multiLine: true),
    RegExp(r'`[^`]+`'),

    // JSON artifacts
    RegExp(r'\{["\s]*response["\s]*:', caseSensitive: false),
    RegExp(r'["\s]*narration["\s]*:', caseSensitive: false),
    RegExp(r'["\s]*teaching_strategy["\s]*:', caseSensitive: false),
    RegExp(r'["\s]*visual_required["\s]*:', caseSensitive: false),
    RegExp(r'["\s]*emotion["\s]*:\s*"[^"]*"', caseSensitive: false),
    RegExp(r'["\s]*follow_up["\s]*:', caseSensitive: false),

    // Label patterns
    RegExp(r'^Narration:\s*', multiLine: true, caseSensitive: false),
    RegExp(r'^Teaching Strategy:\s*', multiLine: true, caseSensitive: false),
    RegExp(r'^Visual:\s*', multiLine: true, caseSensitive: false),
    RegExp(r'^Response:\s*', multiLine: true, caseSensitive: false),
    RegExp(r'^Emotion:\s*', multiLine: true, caseSensitive: false),
    RegExp(r'^Follow.?up:\s*', multiLine: true, caseSensitive: false),

    // Developer artifacts
    RegExp(r'</?s>'),
    RegExp(r'<\|.*?\|>'),
    RegExp(r'<start_of_turn>.*?<end_of_turn>', dotAll: true),
    RegExp(r'<bos>'),

    // System prompt leakage
    RegExp(r'You are Kalvin.*?\.', caseSensitive: false),
    RegExp(r'system prompt', caseSensitive: false),
    RegExp(r'JSON format', caseSensitive: false),
    RegExp(r'respond in JSON', caseSensitive: false),
  ];

  /// Repeated intro phrases to suppress.
  static final List<RegExp> _repetitiveIntros = [
    RegExp(r"^(Sure!?\s*,?\s*)?(I('d| would) (love|be happy) to help[.!]?\s*)",
        caseSensitive: false),
    RegExp(r"^(Of course!?\s*)?(Let me help[.!]?\s*)", caseSensitive: false),
    RegExp(r"^(Great question!?\s*){1,}", caseSensitive: false),
    RegExp(r"^(That'?s? a (great|good|wonderful) question!?\s*)",
        caseSensitive: false),
    RegExp(r"^(Hello!?\s*)?(What would you like to learn[.?!]?\s*)",
        caseSensitive: false),
    RegExp(r"^(Hi there!?\s*)", caseSensitive: false),
    RegExp(r"^(Welcome!?\s*)", caseSensitive: false),
    RegExp(r"^Sure,?\s+I can help[.!]?\s*", caseSensitive: false),
  ];

  /// Sanitize raw LLM text into clean user-facing text.
  static String sanitize(String raw) {
    if (raw.trim().isEmpty) return '';

    var text = raw;

    // 1. Remove forbidden patterns
    for (final pattern in _forbiddenPatterns) {
      text = text.replaceAll(pattern, '');
    }

    // 2. Remove "Kalvin:" prefix
    text = text.replaceAll(RegExp(r'^Kalvin:\s*', multiLine: true), '');

    // 3. Remove repetitive intros (only from the start)
    for (final intro in _repetitiveIntros) {
      text = text.replaceFirst(intro, '');
    }

    // 4. Clean up JSON braces/brackets left behind
    text = _cleanOrphanedJson(text);

    // 5. Fix repeated punctuation
    text = text.replaceAllMapped(RegExp(r'([.!?])\1{2,}'), (m) => m.group(1) ?? '.');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 6. Fix leading/trailing whitespace per line
    text = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');

    // 7. Remove empty result
    if (text.trim().isEmpty) {
      return '';
    }

    return text.trim();
  }

  /// Remove orphaned JSON characters left after pattern removal.
  static String _cleanOrphanedJson(String text) {
    // Remove lines that are just braces, brackets, commas, quotes
    text = text
        .split('\n')
        .where((line) {
          final trimmed = line.trim();
          return trimmed.isNotEmpty &&
              !RegExp(r'^[\s{}\[\],":]+$').hasMatch(trimmed);
        })
        .join('\n');

    // Remove isolated quotes and colons
    text = text.replaceAll(RegExp(r'^\s*"?\s*$', multiLine: true), '');

    return text;
  }

  /// Check if text contains any leaked developer content.
  static bool containsLeakage(String text) {
    final lower = text.toLowerCase();
    return lower.contains('narration:') ||
        lower.contains('teaching strategy:') ||
        lower.contains('teaching_strategy') ||
        lower.contains('visual_required') ||
        lower.contains('"response"') ||
        lower.contains('```') ||
        lower.contains('**') ||
        lower.contains('system prompt');
  }
}
