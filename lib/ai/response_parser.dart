/// Kalvin AI — Response Parser (Gemma 2B Optimized)
///
/// Handles PLAIN TEXT output from the model. No JSON parsing.
/// Gemma 2B outputs plain conversational text, NOT JSON.

class LearningResponse {
  final String response;
  final String emotion;
  final String teachingStrategy;
  final bool visualRequired;
  final String visualScene;
  final String followUpQuestion;

  const LearningResponse({
    required this.response,
    this.emotion = 'supportive',
    this.teachingStrategy = 'conversational',
    this.visualRequired = false,
    this.visualScene = '',
    this.followUpQuestion = '',
  });
}

/// Parses raw Gemma 2B output into a clean LearningResponse.
/// No JSON. No schema. Just clean text extraction.
class ResponseParser {
  LearningResponse parse(String rawOutput) {
    if (rawOutput.trim().isEmpty) {
      return const LearningResponse(
        response: 'Could you say that again? I want to make sure I understand.',
      );
    }

    // Clean the raw output
    var text = _cleanRawOutput(rawOutput);

    // Detect emotion from content
    final emotion = _detectEmotion(text);

    // Detect if visual is needed
    final visual = _detectVisual(text);

    // Final safety check
    if (text.trim().isEmpty || text.trim().length < 3) {
      text = 'That is an interesting question! Let me think about that differently.';
    }

    return LearningResponse(
      response: text.trim(),
      emotion: emotion,
      visualRequired: visual.isNotEmpty,
      visualScene: visual,
    );
  }

  /// Clean raw Gemma 2B output.
  String _cleanRawOutput(String raw) {
    var text = raw;

    // Remove special tokens
    text = text.replaceAll(RegExp(r'</?s>'), '');
    text = text.replaceAll(RegExp(r'<\|.*?\|>'), '');
    text = text.replaceAll(RegExp(r'<bos>'), '');
    text = text.replaceAll(RegExp(r'<eos>'), '');
    text = text.replaceAll(RegExp(r'<start_of_turn>.*?<end_of_turn>', dotAll: true), '');
    text = text.replaceAll(RegExp(r'<start_of_turn>'), '');
    text = text.replaceAll(RegExp(r'<end_of_turn>'), '');

    // Remove "Kalvin:" prefix
    text = text.replaceAll(RegExp(r'^Kalvin:\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^Student:\s*.*$', multiLine: true), '');

    // Remove any JSON artifacts that leaked
    text = text.replaceAll(RegExp(r'\{[^}]*"response"[^}]*\}', dotAll: true), '');
    text = text.replaceAll(RegExp(r'"response"\s*:\s*"?'), '');
    text = text.replaceAll(RegExp(r'"emotion"\s*:\s*"[^"]*"'), '');
    text = text.replaceAll(RegExp(r'"visual_required"\s*:\s*(true|false)'), '');
    text = text.replaceAll(RegExp(r'"visual_scene"\s*:\s*"[^"]*"'), '');
    text = text.replaceAll(RegExp(r'"follow_up"\s*:\s*"[^"]*"'), '');
    text = text.replaceAll(RegExp(r'"teaching_strategy"\s*:\s*"[^"]*"'), '');

    // Remove markdown
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '');
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), '');

    // Remove section labels
    text = text.replaceAll(RegExp(r'^(Narration|Teaching Strategy|Visual|Emotion|Response|Follow.?up|Strategy|Explanation):\s*', multiLine: true, caseSensitive: false), '');

    // Remove orphaned JSON chars
    text = text.replaceAll(RegExp(r'^\s*[{}\[\]",]+\s*$', multiLine: true), '');

    // Remove repeated greetings
    text = text.replaceFirst(RegExp(r"^(Sure[,!]?\s*)?(I'?d?\s*(love|be happy)\s*to\s*help[.!]?\s*)?", caseSensitive: false), '');
    text = text.replaceFirst(RegExp(r'^(Great|Good|Wonderful|Excellent)\s*question[!.]?\s*', caseSensitive: false), '');
    text = text.replaceFirst(RegExp(r'^(Hello|Hi there|Welcome|Hey)[!]?\s*', caseSensitive: false), '');
    text = text.replaceFirst(RegExp(r'^What would you like to learn[.?!]?\s*', caseSensitive: false), '');

    // Remove "system prompt" leakage
    text = text.replaceAll(RegExp(r'You are Kalvin.*?\.', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'system prompt', caseSensitive: false), '');

    // Fix repeated punctuation (use actual dollar-sign escape)
    text = text.replaceAll(RegExp(r'([.!?])\1{2,}'), '.');

    // Fix whitespace
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).join('\n');

    return text.trim();
  }

  /// Detect emotion from text content.
  String _detectEmotion(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('!') && (lower.contains('amazing') || lower.contains('cool') || lower.contains('wow'))) return 'excited';
    if (lower.contains('don\'t worry') || lower.contains('it\'s okay') || lower.contains('no rush')) return 'encouraging';
    if (lower.contains('interesting') || lower.contains('curious') || lower.contains('wonder')) return 'curious';
    if (lower.contains('relax') || lower.contains('slowly') || lower.contains('gently')) return 'calm';
    return 'supportive';
  }

  /// Detect if the response mentions a visual topic.
  String _detectVisual(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('solar system') || lower.contains('planet') || lower.contains('orbit')) return 'solar_system';
    if (lower.contains('volcano') || lower.contains('eruption') || lower.contains('lava')) return 'volcano';
    if (lower.contains('water cycle') || lower.contains('evaporation') || lower.contains('condensation')) return 'water_cycle';
    return '';
  }
}
