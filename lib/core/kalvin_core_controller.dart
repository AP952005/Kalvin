/// Kalvin Core Controller (Gemma 2B Optimized)
///
/// Coordinates orchestrator → UI and drives the KalvinActivityController.

import 'package:flutter/foundation.dart';
import '../ai/learning_orchestrator.dart';
import '../ai/life_companion_engine.dart';
import 'kalvin_activity_controller.dart';

class KalvinCoreController {
  static final KalvinCoreController _instance = KalvinCoreController._();
  factory KalvinCoreController() => _instance;
  KalvinCoreController._();

  LearningOrchestrator? _orchestrator;
  bool _initialized = false;
  bool _processing = false;

  final ValueNotifier<bool> isThinking = ValueNotifier(false);
  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  final ValueNotifier<bool> llmAvailable = ValueNotifier(false);

  /// Avatar activity controller — drives visual avatar states
  final KalvinActivityController avatar = KalvinActivityController();

  void Function(String js)? onExecuteJS;
  void Function(LifeCompanionMessage message)? onCompanionMessage;

  bool get initialized => _initialized;
  bool get processing => _processing;
  LearningOrchestrator? get orchestrator => _orchestrator;

  Future<void> init() async {
    if (_initialized) return;

    try {
      _orchestrator = LearningOrchestrator();
      await _orchestrator!.init();

      _orchestrator!.onExecuteJS = (js) => onExecuteJS?.call(js);

      _orchestrator!.onSpeakingStateChanged = (speaking) {
        isSpeaking.value = speaking;
        if (speaking) {
          avatar.startNarration();
        } else {
          avatar.stopNarration();
        }
      };

      _orchestrator!.onCompanionMessage = (msg) {
        onCompanionMessage?.call(msg);
      };

      try {
        llmAvailable.value = await _orchestrator!.isLLMAvailable();
      } catch (_) {
        llmAvailable.value = false;
      }

      _initialized = true;
      debugPrint('[KalvinCore] Init OK. LLM: ${llmAvailable.value}');
    } catch (e) {
      debugPrint('[KalvinCore] Init ERROR: $e');
      _initialized = true;
    }
  }

  Future<OrchestratedResponse?> processMessage(String input) async {
    if (_orchestrator == null || _processing || input.trim().isEmpty) return null;

    _processing = true;
    isThinking.value = true;
    avatar.beginThinking(); // ← drive avatar

    try {
      final response = await _orchestrator!.processUserInput(input);
      _processing = false;
      isThinking.value = false;
      avatar.finishThinking(); // ← avatar stops thinking, narration starts via onSpeakingStateChanged
      return response;
    } catch (e) {
      debugPrint('[KalvinCore] Process ERROR: $e');
      _processing = false;
      isThinking.value = false;
      avatar.finishThinking();
      return null;
    }
  }

  void newConversation() {
    _orchestrator?.newConversation();
    avatar.reset(); // ← full avatar reset on new chat
  }

  Future<void> stopNarration() async {
    try { await _orchestrator?.stopNarration(); } catch (_) {}
    isSpeaking.value = false;
    avatar.stopNarration();
  }

  void dispose() {
    _orchestrator?.dispose();
    isThinking.dispose();
    isSpeaking.dispose();
    llmAvailable.dispose();
  }
}
