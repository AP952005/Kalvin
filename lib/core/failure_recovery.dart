/// Kalvin — Failure Recovery System
///
/// Graceful recovery for LLM timeout, malformed JSON, narration
/// failure, visual failure, and memory corruption. Kalvin must
/// NEVER appear broken.

import '../ai/response_parser.dart';

class FailureRecovery {
  static const _recoveryMessages = [
    "Let me think about that a bit differently. Can you try asking again?",
    "I'm having trouble with that one. Let's try a different approach!",
    "Hmm, my thinking circuits need a moment. Could you rephrase that?",
    "That's a great question! Let me try explaining it another way.",
    "I want to give you a really good answer. Let me try again!",
  ];

  static int _messageIndex = 0;

  /// Get a graceful recovery response for LLM failures.
  static LearningResponse recoverFromLLMFailure(String? errorDetail) {
    final msg = _recoveryMessages[_messageIndex % _recoveryMessages.length];
    _messageIndex++;

    return LearningResponse(
      response: msg,
      emotion: 'supportive',
      teachingStrategy: 'step_by_step',
    );
  }

  /// Get recovery response for visual failures.
  static LearningResponse recoverFromVisualFailure(String scene) {
    return LearningResponse(
      response: "I'm having trouble showing the $scene visualization right now, "
          "but let me explain it with words instead!",
      emotion: 'supportive',
      teachingStrategy: 'analogy',
    );
  }

  /// Get recovery response for narration failures.
  static String recoverNarrationText(String originalText) {
    // Strip special characters that might cause TTS issues
    return originalText
        .replaceAll(RegExp(r'[^\w\s.,!?\x27"-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Check if an error is recoverable.
  static bool isRecoverable(dynamic error) {
    final msg = error.toString().toLowerCase();
    // Network timeouts and parse errors are recoverable
    if (msg.contains('timeout') ||
        msg.contains('formatexception') ||
        msg.contains('connection refused') ||
        msg.contains('socket')) {
      return true;
    }
    return true; // Default: always try to recover gracefully
  }
}
