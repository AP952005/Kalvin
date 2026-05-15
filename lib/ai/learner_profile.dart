/// Kalvin AI — Learner Profile Model
///
/// Tracks learner intelligence: interests, familiarity, comprehension
/// scores, vocabulary level, preferred teaching styles, and emotional
/// patterns. Persisted via Hive.

/// Learner profile — the AI's understanding of who it's teaching.
class LearnerProfile {
  /// Topics the learner has shown interest in (topic → interest score 0-1)
  Map<String, double> interests;

  /// Familiarity with real-world domains (domain → score 0-1)
  /// Used for analogy selection
  Map<String, double> familiarityMap;

  /// Comprehension scores per topic (topic → score 0-1)
  Map<String, double> comprehensionScores;

  /// Vocabulary sophistication level (1=basic, 5=advanced)
  int vocabularyLevel;

  /// Teaching styles that worked well (strategy → success count)
  Map<String, int> preferredTeachingStyles;

  /// Recent emotional states (for pattern detection)
  List<String> emotionalHistory;

  /// Topics the learner struggled with
  List<String> difficultTopics;

  /// Total number of learning sessions
  int totalSessions;

  /// Age group hint (inferred, not asked)
  String ageGroup;

  LearnerProfile({
    Map<String, double>? interests,
    Map<String, double>? familiarityMap,
    Map<String, double>? comprehensionScores,
    this.vocabularyLevel = 2,
    Map<String, int>? preferredTeachingStyles,
    List<String>? emotionalHistory,
    List<String>? difficultTopics,
    this.totalSessions = 0,
    this.ageGroup = 'unknown',
  })  : interests = interests ?? {},
        familiarityMap = familiarityMap ?? _defaultFamiliarity(),
        comprehensionScores = comprehensionScores ?? {},
        preferredTeachingStyles = preferredTeachingStyles ?? {},
        emotionalHistory = emotionalHistory ?? [],
        difficultTopics = difficultTopics ?? [];

  /// Default familiarity map — all unknown initially
  static Map<String, double> _defaultFamiliarity() => {
        'farming': 0.5,
        'sports': 0.5,
        'machines': 0.5,
        'nature': 0.5,
        'city_life': 0.5,
        'village_life': 0.5,
        'science_exposure': 0.3,
        'vehicles': 0.5,
        'space': 0.3,
        'cooking': 0.5,
        'animals': 0.5,
        'water': 0.5,
        'weather': 0.5,
      };

  /// Update interest score for a topic.
  void updateInterest(String topic, {double delta = 0.1}) {
    final current = interests[topic] ?? 0.0;
    interests[topic] = (current + delta).clamp(0.0, 1.0);
  }

  /// Update comprehension score for a topic.
  void updateComprehension(String topic, double score) {
    comprehensionScores[topic] = score.clamp(0.0, 1.0);

    // Track difficult topics
    if (score < 0.4 && !difficultTopics.contains(topic)) {
      difficultTopics.add(topic);
    } else if (score > 0.7) {
      difficultTopics.remove(topic);
    }
  }

  /// Update familiarity with a real-world domain.
  void updateFamiliarity(String domain, double score) {
    familiarityMap[domain] = score.clamp(0.0, 1.0);
  }

  /// Record a teaching strategy that worked.
  void recordSuccessfulStrategy(String strategy) {
    preferredTeachingStyles[strategy] =
        (preferredTeachingStyles[strategy] ?? 0) + 1;
  }

  /// Record emotional state.
  void recordEmotion(String emotion) {
    emotionalHistory.add(emotion);
    // Keep only last 20
    if (emotionalHistory.length > 20) {
      emotionalHistory = emotionalHistory.sublist(emotionalHistory.length - 20);
    }
  }

  /// Get the strongest familiar context for analogies.
  String getStrongestContext() {
    if (familiarityMap.isEmpty) return 'everyday life';

    String best = 'everyday life';
    double bestScore = 0;

    familiarityMap.forEach((domain, score) {
      if (score > bestScore) {
        best = domain.replaceAll('_', ' ');
        bestScore = score;
      }
    });

    return best;
  }

  /// Get top interests as a readable string.
  String getInterestsSummary() {
    if (interests.isEmpty) return 'no specific interests detected yet';

    final sorted = interests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(3)
        .map((e) => e.key)
        .join(', ');
  }

  /// Get preferred teaching style.
  String getPreferredStyle() {
    if (preferredTeachingStyles.isEmpty) return 'step_by_step';

    String best = 'step_by_step';
    int bestCount = 0;

    preferredTeachingStyles.forEach((style, count) {
      if (count > bestCount) {
        best = style;
        bestCount = count;
      }
    });

    return best;
  }

  /// Check if learner is frequently confused about a topic.
  bool isStrugglingWith(String topic) {
    final score = comprehensionScores[topic] ?? 0.5;
    return score < 0.4 || difficultTopics.contains(topic);
  }

  /// Convert to a context string for prompt injection.
  String toPromptContext() {
    final buffer = StringBuffer();
    buffer.writeln('Vocabulary Level: $vocabularyLevel/5');
    buffer.writeln('Sessions completed: $totalSessions');

    if (interests.isNotEmpty) {
      buffer.writeln('Interests: ${getInterestsSummary()}');
    }

    if (difficultTopics.isNotEmpty) {
      buffer.writeln('Struggling with: ${difficultTopics.join(", ")}');
    }

    buffer.writeln('Preferred teaching style: ${getPreferredStyle()}');
    buffer.writeln('Strongest familiar context: ${getStrongestContext()}');

    return buffer.toString();
  }

  /// Serialize to JSON map for Hive storage.
  Map<String, dynamic> toJson() => {
        'interests': interests,
        'familiarityMap': familiarityMap,
        'comprehensionScores': comprehensionScores,
        'vocabularyLevel': vocabularyLevel,
        'preferredTeachingStyles': preferredTeachingStyles,
        'emotionalHistory': emotionalHistory,
        'difficultTopics': difficultTopics,
        'totalSessions': totalSessions,
        'ageGroup': ageGroup,
      };

  /// Deserialize from JSON map.
  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    return LearnerProfile(
      interests: Map<String, double>.from(json['interests'] ?? {}),
      familiarityMap: Map<String, double>.from(json['familiarityMap'] ?? {}),
      comprehensionScores:
          Map<String, double>.from(json['comprehensionScores'] ?? {}),
      vocabularyLevel: json['vocabularyLevel'] ?? 2,
      preferredTeachingStyles:
          Map<String, int>.from(json['preferredTeachingStyles'] ?? {}),
      emotionalHistory: List<String>.from(json['emotionalHistory'] ?? []),
      difficultTopics: List<String>.from(json['difficultTopics'] ?? []),
      totalSessions: json['totalSessions'] ?? 0,
      ageGroup: json['ageGroup'] ?? 'unknown',
    );
  }
}
