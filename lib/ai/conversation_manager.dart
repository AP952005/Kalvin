/// Kalvin AI — Conversation Manager
///
/// Prevents repetitive greetings, maintains topic continuity,
/// tracks active subjects, and ensures Kalvin responds
/// contextually instead of starting fresh every time.

class ConversationManager {
  /// Current active topic being discussed.
  String _activeTopic = '';

  /// Stack of recent topics for continuity.
  final List<String> _topicHistory = [];

  /// Number of messages in current topic.
  int _topicDepth = 0;

  /// Whether the first greeting has been sent.
  bool _hasGreeted = false;

  /// Recent user messages for context.
  final List<String> _recentUserMessages = [];

  /// Recent AI responses for duplicate detection.
  final List<String> _recentResponses = [];

  // ── Getters ──

  String get activeTopic => _activeTopic;
  bool get hasGreeted => _hasGreeted;
  int get topicDepth => _topicDepth;

  /// Record a user message and detect topic.
  void recordUserMessage(String message) {
    _recentUserMessages.add(message);
    if (_recentUserMessages.length > 10) {
      _recentUserMessages.removeAt(0);
    }

    final detectedTopic = _detectTopic(message);
    if (detectedTopic.isNotEmpty && detectedTopic != _activeTopic) {
      _topicHistory.add(_activeTopic);
      if (_topicHistory.length > 5) _topicHistory.removeAt(0);
      _activeTopic = detectedTopic;
      _topicDepth = 0;
    } else {
      _topicDepth++;
    }
  }

  /// Record an AI response for duplicate detection.
  void recordResponse(String response) {
    _recentResponses.add(response);
    if (_recentResponses.length > 8) {
      _recentResponses.removeAt(0);
    }
    _hasGreeted = true;
  }

  /// Check if a response is too similar to recent ones.
  bool isDuplicate(String response) {
    if (response.trim().isEmpty) return true;

    final normalized = _normalize(response);
    for (final recent in _recentResponses) {
      if (_similarity(normalized, _normalize(recent)) > 0.7) {
        return true;
      }
    }
    return false;
  }

  /// Get context injection string for the prompt.
  /// This helps the LLM maintain topic continuity.
  String getContextInjection() {
    final parts = <String>[];

    if (_activeTopic.isNotEmpty) {
      parts.add('Current topic: $_activeTopic');
    }

    if (_topicDepth > 0) {
      parts.add('Conversation depth: $_topicDepth messages on this topic');
    }

    if (_recentUserMessages.length >= 2) {
      parts.add(
        'Recent flow: "${_recentUserMessages[_recentUserMessages.length - 2]}" → '
        '"${_recentUserMessages.last}"',
      );
    }

    if (_hasGreeted) {
      parts.add('IMPORTANT: Do NOT greet again. Continue the conversation naturally.');
    }

    return parts.join('\n');
  }

  /// Determine if this is a follow-up question to the same topic.
  bool isFollowUp(String message) {
    if (_activeTopic.isEmpty) return false;

    final lower = message.toLowerCase();

    // Short messages are likely follow-ups
    if (message.split(' ').length <= 4) return true;

    // References to "it", "that", "this"
    if (lower.startsWith('what about') ||
        lower.startsWith('tell me more') ||
        lower.startsWith('explain') ||
        lower.startsWith('why') ||
        lower.startsWith('how') ||
        lower.contains('this') ||
        lower.contains('that')) {
      return true;
    }

    // Same topic keywords
    final topicKeywords = _getTopicKeywords(_activeTopic);
    return topicKeywords.any((kw) => lower.contains(kw));
  }

  /// Generate a session title from conversation content.
  String generateSessionTitle() {
    if (_activeTopic.isNotEmpty) {
      return _formatTopicTitle(_activeTopic);
    }

    if (_recentUserMessages.isNotEmpty) {
      final first = _recentUserMessages.first;
      if (first.length <= 40) return first;
      return '${first.substring(0, 37)}...';
    }

    return 'New Conversation';
  }

  /// Reset for a new conversation.
  void reset() {
    _activeTopic = '';
    _topicHistory.clear();
    _topicDepth = 0;
    _hasGreeted = false;
    _recentUserMessages.clear();
    _recentResponses.clear();
  }

  // ── Private Helpers ──

  String _detectTopic(String message) {
    final lower = message.toLowerCase();

    const topicKeywords = {
      'volcanoes': ['volcano', 'eruption', 'lava', 'magma', 'volcanic'],
      'solar system': ['solar', 'planet', 'sun', 'earth', 'moon', 'orbit', 'mercury', 'venus', 'mars', 'jupiter', 'saturn'],
      'water cycle': ['water cycle', 'rain', 'evaporation', 'cloud', 'condensation', 'precipitation'],
      'atoms': ['atom', 'electron', 'proton', 'neutron', 'nucleus'],
      'quantum physics': ['quantum', 'quark', 'particle', 'wave'],
      'biology': ['cell', 'dna', 'gene', 'organ', 'tissue', 'blood', 'heart'],
      'mathematics': ['math', 'algebra', 'geometry', 'equation', 'number', 'fraction', 'percentage'],
      'chemistry': ['chemical', 'element', 'molecule', 'reaction', 'periodic table'],
      'physics': ['force', 'gravity', 'energy', 'motion', 'speed', 'velocity', 'newton'],
      'space': ['star', 'galaxy', 'universe', 'asteroid', 'comet', 'nebula', 'black hole'],
      'weather': ['weather', 'storm', 'thunder', 'lightning', 'wind', 'tornado', 'hurricane'],
      'animals': ['animal', 'mammal', 'reptile', 'bird', 'fish', 'insect', 'dinosaur'],
      'plants': ['plant', 'tree', 'flower', 'photosynthesis', 'leaf', 'root', 'seed'],
      'history': ['history', 'ancient', 'civilization', 'king', 'queen', 'war', 'empire'],
      'geography': ['geography', 'continent', 'ocean', 'mountain', 'river', 'desert', 'island'],
    };

    for (final entry in topicKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }

    return '';
  }

  List<String> _getTopicKeywords(String topic) {
    const topicKeywords = {
      'volcanoes': ['volcano', 'eruption', 'lava', 'magma'],
      'solar system': ['planet', 'sun', 'earth', 'moon', 'orbit'],
      'water cycle': ['water', 'rain', 'evaporation', 'cloud'],
      'atoms': ['atom', 'electron', 'proton'],
      'quantum physics': ['quantum', 'particle', 'wave'],
    };
    return topicKeywords[topic] ?? [];
  }

  String _formatTopicTitle(String topic) {
    switch (topic) {
      case 'volcanoes': return 'Learning About Volcanoes';
      case 'solar system': return 'Solar System Journey';
      case 'water cycle': return 'The Water Cycle';
      case 'atoms': return 'Exploring Atoms';
      case 'quantum physics': return 'Quantum Physics Basics';
      case 'biology': return 'Biology Exploration';
      case 'mathematics': return 'Math Adventures';
      case 'chemistry': return 'Chemistry Discovery';
      case 'physics': return 'Physics Fundamentals';
      case 'space': return 'Journey Through Space';
      case 'weather': return 'Understanding Weather';
      case 'animals': return 'Animal Kingdom';
      case 'plants': return 'Plant Life';
      case 'history': return 'History Exploration';
      case 'geography': return 'Geography Discovery';
      default: return 'Learning Session';
    }
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final wordsA = a.split(' ').toSet();
    final wordsB = b.split(' ').toSet();
    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    return union > 0 ? intersection / union : 0;
  }
}
