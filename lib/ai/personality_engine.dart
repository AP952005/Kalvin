/// Kalvin AI — Personality Engine
///
/// Transforms clean AI responses into warm, emotionally intelligent,
/// child-friendly educational text. Kalvin is never robotic, never
/// corporate, never generic. He is a curious, supportive learning friend.

class PersonalityEngine {
  /// Personality modes
  static const String supportive = 'supportive';
  static const String excited = 'excited';
  static const String calm = 'calm';
  static const String bedtime = 'bedtime';
  static const String motivational = 'motivational';
  static const String simplified = 'simplified';

  /// Track consecutive interactions to avoid repetitive phrases.
  int _interactionCount = 0;
  String _lastOpeningUsed = '';
  final Set<String> _recentOpenings = {};

  /// Apply personality to a clean response.
  String apply(String cleanText, {String emotion = 'supportive'}) {
    if (cleanText.trim().isEmpty) return cleanText;

    _interactionCount++;
    var text = cleanText;

    // Remove generic chatbot intros
    text = _suppressGenericIntros(text);

    // Add warmth if response is too dry
    if (_isTooRobotic(text)) {
      text = _addWarmth(text, emotion);
    }

    // Ensure conversational flow
    text = _ensureConversationalTone(text);

    return text;
  }

  /// Remove generic chatbot-style openings.
  String _suppressGenericIntros(String text) {
    final genericPatterns = [
      RegExp(r"^Sure!?\s*,?\s*(I('d| would) (love|be happy) to help[.!]?\s*)?",
          caseSensitive: false),
      RegExp(r"^Of course!?\s*(Let me help[.!]?\s*)?", caseSensitive: false),
      RegExp(r"^(That'?s? a )?(great|good|wonderful|excellent) question!?\s*",
          caseSensitive: false),
      RegExp(r"^I('d| would) be happy to (help|explain|assist)[.!]?\s*",
          caseSensitive: false),
      RegExp(r"^Let me (help|explain|tell) you[.!]?\s*",
          caseSensitive: false),
      RegExp(r"^Here is (some )?information about[.!]?\s*",
          caseSensitive: false),
      RegExp(r"^Hello!?\s*(How can I help[.?!]?\s*)?", caseSensitive: false),
      RegExp(r"^Hi there!?\s*", caseSensitive: false),
      RegExp(r"^Welcome!?\s*", caseSensitive: false),
      RegExp(r"^Absolutely!?\s*", caseSensitive: false),
      RegExp(r"^Certainly!?\s*", caseSensitive: false),
    ];

    for (final pattern in genericPatterns) {
      text = text.replaceFirst(pattern, '');
    }

    return text.trim();
  }

  /// Check if text sounds robotic.
  bool _isTooRobotic(String text) {
    final roboticIndicators = [
      'here is',
      'the following',
      'as follows',
      'it should be noted',
      'it is important to',
      'in conclusion',
      'to summarize',
      'please note that',
    ];

    final lower = text.toLowerCase();
    int score = 0;
    for (final indicator in roboticIndicators) {
      if (lower.contains(indicator)) score++;
    }

    // If no emoji and very formal language
    if (!RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(text)) {
      score++;
    }

    return score >= 2;
  }

  /// Add warmth markers to dry text.
  String _addWarmth(String text, String emotion) {
    // Don't over-apply
    if (text.length > 300) return text;

    // Add a subtle emoji at end if none exists
    if (!RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(text)) {
      final warmEmojis = {
        'supportive': ' 💙',
        'excited': ' ✨',
        'calm': ' 🌿',
        'curious': ' 🔍',
        'encouraging': ' 💪',
        'gentle': ' 🌸',
        'bedtime': ' 🌙',
      };
      final emoji = warmEmojis[emotion] ?? '';
      if (emoji.isNotEmpty && !text.endsWith(emoji)) {
        text = '$text$emoji';
      }
    }

    return text;
  }

  /// Ensure the response reads conversationally.
  String _ensureConversationalTone(String text) {
    // Replace overly formal phrases with warm alternatives
    final replacements = {
      'It is important to note that': 'Something cool to know is that',
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
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(
        RegExp(RegExp.escape(entry.key), caseSensitive: false),
        entry.value,
      );
    }

    return text;
  }

  /// Get a non-repetitive opening for a given emotion.
  String getOpening(String emotion) {
    final openings = {
      'supportive': [
        'Let me explain this in a fun way —',
        'This is actually really interesting!',
        'I love this topic!',
        'Here\'s something cool —',
        'Let me share something with you —',
      ],
      'excited': [
        'Oh this is SO cool!',
        'You\'re going to love this!',
        'This is one of my favorites!',
        'Wow, great choice!',
        'This is amazing —',
      ],
      'calm': [
        'Let\'s take this step by step.',
        'No rush — let me walk you through it.',
        'Let\'s explore this together.',
        'Take a deep breath, and let\'s learn —',
      ],
      'encouraging': [
        'You\'re doing great! Let me help —',
        'Don\'t worry, this gets easier!',
        'You\'re on the right track!',
        'Keep going, you\'re getting it!',
      ],
    };

    final options = openings[emotion] ?? openings['supportive']!;

    // Pick one that wasn't recently used
    for (final opening in options) {
      if (!_recentOpenings.contains(opening) && opening != _lastOpeningUsed) {
        _lastOpeningUsed = opening;
        _recentOpenings.add(opening);
        if (_recentOpenings.length > 5) {
          _recentOpenings.remove(_recentOpenings.first);
        }
        return opening;
      }
    }

    // Reset if all used
    _recentOpenings.clear();
    _lastOpeningUsed = options.first;
    return options.first;
  }

  /// Reset interaction tracking (for new sessions).
  void reset() {
    _interactionCount = 0;
    _lastOpeningUsed = '';
    _recentOpenings.clear();
  }
}
