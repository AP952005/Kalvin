/// Kalvin AI — Emotion Engine
///
/// Rule-based emotional state detection from user messages.
/// Lightweight — no ML required. Analyzes keywords, patterns,
/// and message characteristics to infer learner emotional state.

/// Emotional states the engine can detect.
enum EmotionState {
  neutral,
  confused,
  frustrated,
  excited,
  curious,
  bored,
  anxious,
  happy,
}

/// Analyzes user messages to detect emotional state.
class EmotionEngine {
  // Keyword maps for each emotion
  static const _confusionWords = [
    'confused', 'don\'t understand', 'dont understand', 'what do you mean',
    'huh', 'what', 'i don\'t get', 'not clear', 'explain again',
    'can you repeat', 'lost', 'makes no sense', 'difficult',
    'hard to understand', 'too complex', 'too difficult',
  ];

  static const _frustrationWords = [
    'frustrated', 'annoying', 'stupid', 'hate', 'angry', 'ugh',
    'this is dumb', 'waste of time', 'doesn\'t work', 'wrong',
    'stop', 'shut up', 'boring', 'useless', 'terrible',
    'i give up', 'too hard', 'impossible',
  ];

  static const _excitementWords = [
    'wow', 'amazing', 'awesome', 'cool', 'great', 'love',
    'incredible', 'fantastic', 'wonderful', 'brilliant',
    'that\'s so cool', 'mind blown', 'interesting', 'tell me more',
    'more', 'yes', 'yay', 'nice',
  ];

  static const _curiosityWords = [
    'why', 'how', 'what if', 'tell me about', 'explain',
    'what is', 'how does', 'can you show', 'i want to know',
    'i wonder', 'curious', 'what happens', 'show me',
    'teach me', 'learn about', 'help me understand',
  ];

  static const _boredomWords = [
    'bored', 'boring', 'whatever', 'ok', 'fine', 'meh',
    'not interested', 'skip', 'next', 'move on',
    'already know', 'too easy', 'know this',
  ];

  static const _anxietyWords = [
    'scared', 'afraid', 'nervous', 'worried', 'exam',
    'test', 'fail', 'will i pass', 'can\'t do', 'pressure',
    'stressed', 'panic', 'help me please',
  ];

  /// Analyze a user message and return detected emotion with confidence.
  EmotionAnalysis analyze(String message) {
    final lower = message.toLowerCase().trim();

    // Score each emotion
    final scores = <EmotionState, double>{};

    scores[EmotionState.confused] = _score(lower, _confusionWords);
    scores[EmotionState.frustrated] = _score(lower, _frustrationWords);
    scores[EmotionState.excited] = _score(lower, _excitementWords);
    scores[EmotionState.curious] = _score(lower, _curiosityWords);
    scores[EmotionState.bored] = _score(lower, _boredomWords);
    scores[EmotionState.anxious] = _score(lower, _anxietyWords);

    // Message length heuristics
    if (lower.length < 5) {
      // Very short replies suggest boredom or disengagement
      scores[EmotionState.bored] =
          (scores[EmotionState.bored] ?? 0) + 0.3;
    }

    // Question marks suggest curiosity
    final questionMarks = '?'.allMatches(lower).length;
    if (questionMarks > 0) {
      scores[EmotionState.curious] =
          (scores[EmotionState.curious] ?? 0) + (questionMarks * 0.2);
    }

    // Exclamation marks suggest excitement or frustration
    final exclamationMarks = '!'.allMatches(lower).length;
    if (exclamationMarks > 1) {
      scores[EmotionState.excited] =
          (scores[EmotionState.excited] ?? 0) + 0.15;
    }

    // ALL CAPS detection (frustration or excitement)
    if (message.length > 5 && message == message.toUpperCase()) {
      scores[EmotionState.frustrated] =
          (scores[EmotionState.frustrated] ?? 0) + 0.4;
    }

    // Find highest scoring emotion
    EmotionState best = EmotionState.neutral;
    double bestScore = 0.3; // minimum threshold

    scores.forEach((emotion, score) {
      if (score > bestScore) {
        best = emotion;
        bestScore = score;
      }
    });

    return EmotionAnalysis(
      state: best,
      confidence: bestScore.clamp(0.0, 1.0),
      scores: scores,
    );
  }

  /// Score a message against keyword list.
  double _score(String message, List<String> keywords) {
    double total = 0;
    for (final keyword in keywords) {
      if (message.contains(keyword)) {
        total += 0.4;
      }
    }
    return total.clamp(0.0, 1.0);
  }

  /// Convert emotion to a human-readable context string for the prompt.
  String toContextString(EmotionState state) {
    switch (state) {
      case EmotionState.confused:
        return 'The learner seems confused. Simplify your explanation. Use different words and analogies.';
      case EmotionState.frustrated:
        return 'The learner is frustrated. Be extra patient, encouraging, and gentle. Acknowledge their difficulty.';
      case EmotionState.excited:
        return 'The learner is excited and engaged! Match their energy. Dive deeper and share fascinating details.';
      case EmotionState.curious:
        return 'The learner is curious. Encourage exploration. Provide rich, interesting explanations.';
      case EmotionState.bored:
        return 'The learner seems disengaged. Make it more interactive. Use surprising facts or stories.';
      case EmotionState.anxious:
        return 'The learner is anxious or stressed. Be calm, reassuring, and supportive. Break things into tiny steps.';
      case EmotionState.happy:
        return 'The learner is happy and receptive. Great teaching moment — build on this positive energy.';
      case EmotionState.neutral:
        return 'The learner is in a neutral state. Teach normally with warmth and clarity.';
    }
  }
}

/// Result of emotion analysis.
class EmotionAnalysis {
  final EmotionState state;
  final double confidence;
  final Map<EmotionState, double> scores;

  const EmotionAnalysis({
    required this.state,
    required this.confidence,
    required this.scores,
  });
}
