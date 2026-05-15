/// Kalvin AI — Modality Selector
///
/// Decides the best learning modality for a response based on
/// topic type, learner state, comprehension history, and
/// emotional context. Visuals are NOT the default.

import 'emotion_engine.dart';
import 'learner_profile.dart';

/// Learning modalities available in Kalvin.
enum LearningModality {
  textOnly,
  narrationOnly,
  visual3D,
  diagram,
  storyMode,
  quizMode,
  narrationWithVisual,
}

/// Decides which modality to use for a given learning context.
class ModalitySelector {
  /// Select the best modality for the current context.
  ModalityResult select({
    required String topic,
    required String userMessage,
    required LearnerProfile profile,
    required EmotionState emotionState,
    int consecutiveConfusions = 0,
  }) {
    double visualScore = 0;
    double storyScore = 0;
    double quizScore = 0;
    String reason = 'default';

    // ── Rule 1: Abstract/spatial topics benefit from visuals ──
    if (_isVisualTopic(topic)) {
      visualScore += 0.4;
      reason = 'topic benefits from visualization';
    }

    // ── Rule 2: Repeated confusion → escalate to visuals ──
    if (consecutiveConfusions >= 2) {
      visualScore += 0.3;
      reason = 'repeated confusion — visual aid needed';
    }

    // ── Rule 3: Learner struggling with this topic ──
    if (profile.isStrugglingWith(topic)) {
      visualScore += 0.2;
      storyScore += 0.15;
      reason = 'learner struggling — try different approach';
    }

    // ── Rule 4: Emotional state influences modality ──
    switch (emotionState) {
      case EmotionState.confused:
        visualScore += 0.2;
        storyScore += 0.1;
        break;
      case EmotionState.frustrated:
        storyScore += 0.3; // stories reduce frustration
        break;
      case EmotionState.bored:
        quizScore += 0.3; // quizzes re-engage
        visualScore += 0.2;
        break;
      case EmotionState.curious:
        visualScore += 0.15; // feed curiosity with visuals
        break;
      case EmotionState.excited:
        visualScore += 0.1;
        break;
      default:
        break;
    }

    // ── Rule 5: User explicitly asks for visual/show ──
    final lower = userMessage.toLowerCase();
    if (lower.contains('show me') ||
        lower.contains('visualize') ||
        lower.contains('can i see') ||
        lower.contains('picture') ||
        lower.contains('3d')) {
      visualScore += 0.5;
      reason = 'user requested visualization';
    }

    // ── Rule 6: Simple factual questions stay text-only ──
    if (_isSimpleFactual(lower)) {
      visualScore -= 0.3;
      reason = 'simple factual question — text sufficient';
    }

    // ── Select modality based on scores ──
    LearningModality modality;

    if (quizScore > 0.25 && quizScore >= visualScore) {
      modality = LearningModality.quizMode;
      reason = 'quiz mode to re-engage learner';
    } else if (storyScore > 0.25 && storyScore >= visualScore) {
      modality = LearningModality.storyMode;
      reason = 'story mode for emotional support';
    } else if (visualScore > 0.5) {
      modality = LearningModality.narrationWithVisual;
    } else if (visualScore > 0.3) {
      modality = LearningModality.visual3D;
    } else {
      modality = LearningModality.narrationOnly;
    }

    return ModalityResult(
      modality: modality,
      visualScore: visualScore,
      reason: reason,
    );
  }

  /// Check if a topic naturally benefits from 3D visualization.
  bool _isVisualTopic(String topic) {
    const visualTopics = [
      'solar_system', 'planets', 'sun', 'earth', 'moon', 'orbit',
      'volcano', 'eruption', 'lava', 'magma', 'tectonic',
      'water_cycle', 'evaporation', 'condensation', 'rain',
      'atmosphere', 'layers', 'geology', 'geography',
      'space', 'stars', 'galaxy', 'universe',
    ];

    final lower = topic.toLowerCase();
    return visualTopics.any((t) => lower.contains(t));
  }

  /// Check if the message is a simple factual question.
  bool _isSimpleFactual(String message) {
    // Short questions about dates, definitions, names
    if (message.length < 30) {
      if (message.startsWith('what is ') ||
          message.startsWith('who is ') ||
          message.startsWith('when ') ||
          message.startsWith('define ')) {
        return true;
      }
    }
    return false;
  }

  /// Convert modality to prompt context string.
  String toPromptContext(LearningModality modality) {
    switch (modality) {
      case LearningModality.textOnly:
        return 'Respond with text only. No visuals needed.';
      case LearningModality.narrationOnly:
        return 'Respond with a narration-friendly explanation. Keep it conversational.';
      case LearningModality.visual3D:
        return 'A 3D visualization would help. Set visual_required to true if appropriate.';
      case LearningModality.diagram:
        return 'A diagram would help. Set diagram_required to true.';
      case LearningModality.storyMode:
        return 'Tell a short, relatable story or analogy to explain this concept.';
      case LearningModality.quizMode:
        return 'Turn this into an interactive question. Ask the learner to think.';
      case LearningModality.narrationWithVisual:
        return 'Explain with narration AND trigger a 3D visual scene. Set visual_required to true.';
    }
  }
}

/// Result of modality selection.
class ModalityResult {
  final LearningModality modality;
  final double visualScore;
  final String reason;

  const ModalityResult({
    required this.modality,
    this.visualScore = 0,
    this.reason = '',
  });
}
