/// Kalvin AI — Clean Response Formatter
///
/// Production-grade response cleanup that ensures NO raw LLM
/// artifacts, markdown, JSON fragments, labels, or repetitive
/// intros ever reach the user interface.
///
/// This is the FINAL gate before text is displayed.

class CleanResponseFormatter {
  /// Phrases that indicate repetitive onboarding.
  static final List<RegExp> _repetitivePatterns = [
    RegExp(r"^Sure[,!]?\s*(I('d| would) (love|be happy) to help)?[.!]?\s*", caseSensitive: false),
    RegExp(r"^Of course[!,]?\s*(Let me help)?[.!]?\s*", caseSensitive: false),
    RegExp(r"^(That'?s? a )?(great|good|wonderful|excellent|interesting) question[!.]?\s*", caseSensitive: false),
    RegExp(r"^Hello[!]?\s*(How can I help[.?!]?)?\s*", caseSensitive: false),
    RegExp(r"^Hi there[!]?\s*", caseSensitive: false),
    RegExp(r"^Welcome[!]?\s*", caseSensitive: false),
    RegExp(r"^Absolutely[!]?\s*", caseSensitive: false),
    RegExp(r"^Certainly[!]?\s*", caseSensitive: false),
    RegExp(r"^I('d| would) be happy to (help|explain|assist)[.!]?\s*", caseSensitive: false),
    RegExp(r"^Let me (help|explain|tell) you[.!]?\s*", caseSensitive: false),
    RegExp(r"^What would you like to learn[.?!]?\s*", caseSensitive: false),
    RegExp(r"^What (shall|should|would you like to) we (explore|learn|study)[.?!]?\s*", caseSensitive: false),
    RegExp(r"^I'?m Kalvin[,.]?\s*(your (learning|educational|AI) (companion|friend|assistant))?[.!]?\s*", caseSensitive: false),
    RegExp(r"^Hey there[!]?\s*", caseSensitive: false),
    RegExp(r"^Good (morning|afternoon|evening)[!]?\s*", caseSensitive: false),
  ];

  /// Full cleanup pipeline.
  static String cleanResponse(String raw) {
    if (raw.trim().isEmpty) return '';

    var text = raw;

    // 1. Extract from JSON if wrapped
    text = _extractResponseField(text);

    // 2. Remove prompt artifacts
    text = removePromptArtifacts(text);

    // 3. Remove markdown
    text = _removeMarkdown(text);

    // 4. Remove repeated patterns
    text = removeRepeatedPatterns(text);

    // 5. Normalize tone
    text = normalizeTone(text);

    // 6. Final cleanup
    text = _finalCleanup(text);

    return text.trim();
  }

  /// Extract "response" field value from JSON text.
  static String _extractResponseField(String text) {
    // Try to find "response": "..." pattern
    final match = RegExp(
      r'"response"\s*:\s*"((?:[^"\\]|\\.)*)"',
      dotAll: true,
    ).firstMatch(text);

    if (match != null) {
      var extracted = match.group(1) ?? '';
      extracted = extracted
          .replaceAll(r'\"', '"')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\\', r'\');
      return extracted;
    }

    return text;
  }

  /// Remove all developer/prompt artifacts from text.
  static String removePromptArtifacts(String text) {
    // Remove section labels
    text = text.replaceAll(
      RegExp(r'\*\*(Narration|Teaching Strategy|Visual|Emotion|Response|Follow.?up|Strategy|Explanation):\*\*\s*', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'^(Narration|Teaching Strategy|Visual|Emotion|Response|Follow.?up|Strategy|Explanation):\s*', multiLine: true, caseSensitive: false),
      '',
    );

    // Remove "Kalvin:" prefix
    text = text.replaceAll(RegExp(r'^Kalvin:\s*', multiLine: true), '');

    // Remove special tokens
    text = text.replaceAll(RegExp(r'</?s>'), '');
    text = text.replaceAll(RegExp(r'<\|.*?\|>'), '');
    text = text.replaceAll(RegExp(r'<bos>'), '');
    text = text.replaceAll(RegExp(r'<start_of_turn>.*?<end_of_turn>', dotAll: true), '');

    // Remove JSON field names that leaked
    text = text.replaceAll(
      RegExp(r'"(response|narration|emotion|visual_required|teaching_strategy|follow_up|visual_scene)"\s*:\s*'),
      '',
    );

    // Remove standalone true/false/null
    text = text.replaceAll(
      RegExp(r'^\s*(true|false|null)\s*,?\s*$', multiLine: true),
      '',
    );

    // Remove "Use analogy" type teaching directives
    text = text.replaceAll(
      RegExp(r'^Use\s+(analogy|step.?by.?step|visual|storytelling|simplification|scaffolding)\.?\s*$', multiLine: true, caseSensitive: false),
      '',
    );

    // Remove system prompt leakage
    text = text.replaceAll(RegExp(r'You are Kalvin.*?\.', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'system prompt', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'respond in JSON', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'JSON format', caseSensitive: false), '');

    return text;
  }

  /// Remove markdown formatting, keeping text content.
  static String _removeMarkdown(String text) {
    // Bold
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    // Italic
    text = text.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');
    // Code blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    // Inline code
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '');
    // Headers
    text = text.replaceAllMapped(RegExp(r'^#{1,6}\s+(.+)$', multiLine: true), (m) => m.group(1) ?? '');
    // Bullet points
    text = text.replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '');
    // Numbered lists
    text = text.replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), '');

    return text;
  }

  /// Remove repetitive greeting/intro patterns.
  static String removeRepeatedPatterns(String text) {
    for (final pattern in _repetitivePatterns) {
      text = text.replaceFirst(pattern, '');
    }
    return text.trim();
  }

  /// Replace overly formal language with warm conversational alternatives.
  static String normalizeTone(String text) {
    const replacements = {
      'It is important to note that': 'Something cool is',
      'It should be noted that': 'Here\'s something interesting —',
      'In conclusion': 'So basically',
      'To summarize': 'In short',
      'Furthermore': 'And also',
      'Therefore': 'So',
      'However': 'But',
      'Nevertheless': 'Still',
      'Consequently': 'Because of this',
      'Additionally': 'Also',
      'Moreover': 'Plus',
      'Utilizing': 'Using',
      'Subsequently': 'Then',
      'Aforementioned': 'this',
      'In order to': 'To',
      'It is imperative': 'It\'s important',
      'With regard to': 'About',
      'In the event that': 'If',
      'Prior to': 'Before',
      'Subsequent to': 'After',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(
        RegExp(RegExp.escape(entry.key), caseSensitive: false),
        entry.value,
      );
    }

    return text;
  }

  /// Final cleanup pass.
  static String _finalCleanup(String text) {
    // Remove orphaned JSON characters
    text = text.replaceAll(RegExp(r'^\s*[{}\[\],":]+\s*$', multiLine: true), '');

    // Fix multiple newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Fix repeated punctuation
    text = text.replaceAllMapped(RegExp(r'([.!?])\1{2,}'), (m) => m.group(1) ?? '.');

    // Remove trailing commas
    text = text.replaceAll(RegExp(r',\s*$', multiLine: true), '');

    // Clean up whitespace
    text = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');

    // Minimum quality check
    if (text.length < 5) return '';

    return text;
  }

  /// Check if response contains any leaked developer content.
  static bool hasLeakage(String text) {
    final lower = text.toLowerCase();
    return lower.contains('narration:') ||
        lower.contains('teaching strategy:') ||
        lower.contains('teaching_strategy') ||
        lower.contains('visual_required') ||
        lower.contains('"response"') ||
        lower.contains('```') ||
        lower.contains('**') ||
        lower.contains('system prompt') ||
        lower.contains('"emotion"') ||
        lower.contains('"follow_up"');
  }
}
