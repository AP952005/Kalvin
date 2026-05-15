/// Kalvin AI — Clean Response Engine
///
/// Production-grade cleanup pipeline that transforms raw LLM output
/// into clean, child-friendly educational text. Removes all developer
/// artifacts, markdown, labels, JSON fragments, and formatting noise.

import 'response_sanitizer.dart';

class CleanResponseEngine {
  /// Full cleanup pipeline: raw LLM text → clean conversational text.
  static String clean(String rawResponse) {
    if (rawResponse.trim().isEmpty) return '';

    var text = rawResponse;

    // Step 1: Extract clean text from JSON if response is JSON-wrapped
    text = _extractFromJson(text);

    // Step 2: Remove section labels (Narration:, Teaching Strategy:, etc.)
    text = _removeSectionLabels(text);

    // Step 3: Remove markdown formatting
    text = _removeMarkdown(text);

    // Step 4: Remove developer artifacts
    text = _removeDeveloperArtifacts(text);

    // Step 5: Clean up structure
    text = _cleanStructure(text);

    // Step 6: Run final sanitizer pass
    text = ResponseSanitizer.sanitize(text);

    // Step 7: Ensure minimum quality
    if (text.length < 5) {
      return '';
    }

    return text;
  }

  /// Extract the "response" field from JSON-wrapped text.
  static String _extractFromJson(String text) {
    // Try to find "response": "..." pattern
    final responseMatch = RegExp(
      r'"response"\s*:\s*"((?:[^"\\]|\\.)*)"\s*[,}]',
      dotAll: true,
    ).firstMatch(text);

    if (responseMatch != null) {
      var extracted = responseMatch.group(1) ?? '';
      // Unescape JSON strings
      extracted = extracted
          .replaceAll(r'\"', '"')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\\', r'\');
      return extracted;
    }

    // If not JSON-wrapped, return as-is
    return text;
  }

  /// Remove labeled sections like **Narration:** etc.
  static String _removeSectionLabels(String text) {
    // Remove bold-labeled sections and keep only the content
    text = text.replaceAllMapped(
      RegExp(
        r'\*\*(Narration|Teaching Strategy|Visual|Emotion|Response|Follow.?up|Strategy|Explanation):\*\*\s*',
        caseSensitive: false,
      ),
      (_) => '',
    );

    // Remove plain-labeled sections
    text = text.replaceAllMapped(
      RegExp(
        r'^(Narration|Teaching Strategy|Visual|Emotion|Response|Follow.?up|Strategy|Explanation):\s*',
        multiLine: true,
        caseSensitive: false,
      ),
      (_) => '',
    );

    // Remove "Use analogy", "Use step-by-step" etc. teaching directives
    text = text.replaceAll(
      RegExp(
        r'^Use\s+(analogy|step.?by.?step|visual|storytelling|simplification|scaffolding)\.?\s*$',
        multiLine: true,
        caseSensitive: false,
      ),
      '',
    );

    return text;
  }

  /// Remove markdown formatting but keep the text content.
  static String _removeMarkdown(String text) {
    // Remove bold markers, keep content
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (m) => m.group(1) ?? '',
    );

    // Remove italic markers
    text = text.replaceAllMapped(
      RegExp(r'\*([^*]+)\*'),
      (m) => m.group(1) ?? '',
    );

    // Remove code blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // Remove inline code
    text = text.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (m) => m.group(1) ?? '',
    );

    // Remove headers, keep text
    text = text.replaceAllMapped(
      RegExp(r'^#{1,6}\s+(.+)$', multiLine: true),
      (m) => m.group(1) ?? '',
    );

    // Remove bullet points formatting (keep text)
    text = text.replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '');

    // Remove numbered list formatting (keep text)
    text = text.replaceAllMapped(
      RegExp(r'^\s*\d+[.)]\s+', multiLine: true),
      (_) => '',
    );

    return text;
  }

  /// Remove developer-facing artifacts.
  static String _removeDeveloperArtifacts(String text) {
    // Remove special tokens
    text = text.replaceAll(RegExp(r'</?s>'), '');
    text = text.replaceAll(RegExp(r'<\|.*?\|>'), '');
    text = text.replaceAll(RegExp(r'<bos>'), '');
    text = text.replaceAll(
      RegExp(r'<start_of_turn>.*?<end_of_turn>', dotAll: true), '',
    );

    // Remove "Kalvin:" prefix
    text = text.replaceAll(RegExp(r'^Kalvin:\s*', multiLine: true), '');

    // Remove JSON field patterns that leaked
    text = text.replaceAll(
      RegExp(r'"(response|narration|emotion|visual_required|teaching_strategy|follow_up)":\s*'),
      '',
    );

    // Remove true/false/null literals standing alone
    text = text.replaceAll(
      RegExp(r'^\s*(true|false|null)\s*,?\s*$', multiLine: true),
      '',
    );

    return text;
  }

  /// Clean up paragraph structure.
  static String _cleanStructure(String text) {
    // Remove excessive newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove trailing commas
    text = text.replaceAll(RegExp(r',\s*$', multiLine: true), '');

    // Remove orphaned braces/brackets
    text = text.replaceAll(RegExp(r'^\s*[{}\[\]]\s*$', multiLine: true), '');

    // Remove orphaned quotes
    text = text.replaceAll(RegExp(r'^\s*"\s*$', multiLine: true), '');

    // Trim each line
    text = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');

    return text;
  }

  /// Extract narration text from response (for TTS).
  /// Returns the cleanest possible narration-ready text.
  static String extractNarration(String response) {
    var narration = clean(response);

    // Remove emojis for TTS (they cause glitches)
    narration = narration.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{FE00}-\u{FE0F}]|[\u{1F000}-\u{1F02F}]',
        unicode: true,
      ),
      '',
    );

    // Clean up whitespace left by emoji removal
    narration = narration.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return narration;
  }
}
