/// Kalvin AI — UI Response Formatter
///
/// Creates clean, mobile-friendly educational text blocks.
/// Splits paragraphs, prevents text walls, formats for
/// child-friendly readability on small screens.

class UIResponseFormatter {
  /// Format a clean response for mobile display.
  static String format(String cleanText) {
    if (cleanText.trim().isEmpty) return '';

    var text = cleanText;

    // 1. Normalize line breaks
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 2. Split long paragraphs for readability
    text = _splitLongParagraphs(text);

    // 3. Ensure proper spacing between paragraphs
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 4. Clean up trailing whitespace
    text = text
        .split('\n')
        .map((l) => l.trimRight())
        .join('\n')
        .trim();

    return text;
  }

  /// Split paragraphs that are too long for mobile reading.
  static String _splitLongParagraphs(String text) {
    final paragraphs = text.split('\n\n');
    final result = <String>[];

    for (final para in paragraphs) {
      if (para.length > 250) {
        // Split at sentence boundaries
        final sentences = para
            .split(RegExp(r'(?<=[.!?])\s+'))
            .where((s) => s.trim().isNotEmpty)
            .toList();

        if (sentences.length > 2) {
          // Group into chunks of 2-3 sentences
          final chunks = <String>[];
          var current = <String>[];
          var currentLen = 0;

          for (final sentence in sentences) {
            current.add(sentence);
            currentLen += sentence.length;

            if (currentLen > 120 || current.length >= 3) {
              chunks.add(current.join(' '));
              current = [];
              currentLen = 0;
            }
          }
          if (current.isNotEmpty) {
            chunks.add(current.join(' '));
          }

          result.add(chunks.join('\n\n'));
        } else {
          result.add(para);
        }
      } else {
        result.add(para);
      }
    }

    return result.join('\n\n');
  }

  /// Extract follow-up suggestions from response text.
  /// Returns list of suggested follow-up questions.
  static List<String> extractFollowUps(String text, String topic) {
    final followUps = <String>[];

    // Topic-specific follow-ups
    switch (topic.toLowerCase()) {
      case 'volcanoes':
        followUps.addAll([
          'Show me a volcano erupting',
          'Why is lava so hot?',
          'What happens after an eruption?',
        ]);
        break;
      case 'solar system':
        followUps.addAll([
          'Show me the planets',
          'Why is Mars red?',
          'How big is Jupiter?',
        ]);
        break;
      case 'water cycle':
        followUps.addAll([
          'Show me visually',
          'Why does water evaporate?',
          'How do clouds form?',
        ]);
        break;
      case 'atoms':
        followUps.addAll([
          'What are electrons?',
          'Explain with an example',
          'How small is an atom?',
        ]);
        break;
      default:
        followUps.addAll([
          'Explain with an example',
          'Tell me a story about it',
          'Quiz me!',
        ]);
    }

    return followUps.take(3).toList();
  }

  /// Create a short preview of a response (for session list).
  static String preview(String text, {int maxLength = 60}) {
    if (text.isEmpty) return '';

    final clean = text
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength - 3)}...';
  }
}
