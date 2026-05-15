/// Kalvin AI — Learning Orchestrator (Gemma 2B Optimized)
///
/// SIMPLIFIED pipeline for small local models.
///
/// Pipeline: Input → Short Prompt → Gemma → Clean → Quality Check → UI
///
/// NO: JSON parsing, nested reasoning, giant contexts, emotional metadata injection

import 'package:flutter/foundation.dart';
import 'llama_service.dart';
import 'prompt_builder.dart';
import 'response_parser.dart';
import 'simple_quality_filter.dart';
import 'advanced_voice_engine.dart';
import 'life_companion_engine.dart';

class LearningOrchestrator {
  final LlamaService _llama;
  final PromptBuilder _promptBuilder;
  final ResponseParser _responseParser;
  final SimpleQualityFilter _qualityFilter;
  final AdvancedVoiceEngine _voiceEngine;
  final LifeCompanionEngine _lifeCompanion;

  // Simple conversation history (last 3 turns)
  final List<_Turn> _history = [];
  String _currentTopic = '';
  bool _initialized = false;
  int _turnCount = 0;

  void Function(String js)? onExecuteJS;
  void Function(bool speaking)? onSpeakingStateChanged;
  void Function(LifeCompanionMessage message)? onCompanionMessage;

  LearningOrchestrator({
    LlamaService? llamaService,
    PromptBuilder? promptBuilder,
    ResponseParser? responseParser,
    SimpleQualityFilter? qualityFilter,
    AdvancedVoiceEngine? voiceEngine,
    LifeCompanionEngine? lifeCompanion,
  })  : _llama = llamaService ?? LlamaService(),
        _promptBuilder = promptBuilder ?? PromptBuilder(),
        _responseParser = responseParser ?? ResponseParser(),
        _qualityFilter = qualityFilter ?? SimpleQualityFilter(),
        _voiceEngine = voiceEngine ?? AdvancedVoiceEngine(),
        _lifeCompanion = lifeCompanion ?? LifeCompanionEngine();

  Future<void> init() async {
    if (_initialized) return;
    try { await _voiceEngine.init(); } catch (_) {}
    try { await _promptBuilder.init(); } catch (_) {}

    _voiceEngine.onSpeakingStart = () => onSpeakingStateChanged?.call(true);
    _voiceEngine.onSpeakingEnd = () => onSpeakingStateChanged?.call(false);

    _initialized = true;
    debugPrint('[Orchestrator] Initialized (Gemma 2B mode)');
  }

  Future<bool> isLLMAvailable() => _llama.isAvailable();

  AdvancedVoiceEngine get voiceEngine => _voiceEngine;
  LifeCompanionEngine get lifeCompanion => _lifeCompanion;
  String get currentTopic => _currentTopic;
  int get turnCount => _turnCount;

  /// Process user input through the SIMPLIFIED pipeline.
  Future<OrchestratedResponse> processUserInput(String userInput) async {
    if (!_initialized) await init();
    _turnCount++;

    // 1. Detect topic
    _currentTopic = _detectTopic(userInput);

    // 2. Build short history string (last 3 turns only)
    final historyStr = _buildHistoryString();

    // 3. Build simple prompt
    final prompt = await _promptBuilder.buildSimple(
      userInput: userInput,
      history: historyStr,
      topic: _currentTopic,
    );

    // 4. Call Gemma
    String rawResponse;
    try {
      rawResponse = await _llama.generateResponse(prompt);
      debugPrint('[Orchestrator] Raw response length: ${rawResponse.length}');
    } catch (e) {
      debugPrint('[Orchestrator] LLM error: $e');
      rawResponse = '';
    }

    // 5. Parse and clean
    final parsed = _responseParser.parse(rawResponse);
    var finalText = parsed.response;

    // 6. Quality check
    final quality = _qualityFilter.check(finalText);
    if (!quality.passed) {
      debugPrint('[Orchestrator] Quality FAILED: ${quality.reason}');

      // Retry once with a direct prompt
      try {
        final retryPrompt = 'Answer directly and naturally: $userInput';
        final retryRaw = await _llama.generateResponse(retryPrompt);
        final retryParsed = _responseParser.parse(retryRaw);
        final retryQuality = _qualityFilter.check(retryParsed.response);

        if (retryQuality.passed) {
          finalText = retryParsed.response;
        } else {
          finalText = _getSmartFallback(userInput);
        }
      } catch (_) {
        finalText = _getSmartFallback(userInput);
      }
    }

    // 7. Record in history
    _qualityFilter.recordResponse(finalText);
    _history.add(_Turn(user: userInput, assistant: finalText));
    if (_history.length > 3) _history.removeAt(0);

    // 8. Check life companion
    final companionMsg = _lifeCompanion.checkForMessage();
    if (companionMsg != null) onCompanionMessage?.call(companionMsg);

    // 9. Speak (background)
    _voiceEngine.speak(finalText, emotion: parsed.emotion);

    // 10. Visual triggers (only for explicit spatial topics)
    List<String> jsCommands = [];
    if (parsed.visualRequired && parsed.visualScene.isNotEmpty) {
      jsCommands = ["loadScene('${parsed.visualScene}')"];
      for (final cmd in jsCommands) {
        onExecuteJS?.call(cmd);
      }
    }

    return OrchestratedResponse(
      learningResponse: LearningResponse(
        response: finalText,
        emotion: parsed.emotion,
        visualRequired: parsed.visualRequired,
        visualScene: parsed.visualScene,
      ),
      topic: _currentTopic,
      companionMessage: companionMsg,
      jsCommands: jsCommands,
    );
  }

  /// Build a short history string (max 3 turns).
  String _buildHistoryString() {
    if (_history.isEmpty) return '';
    final buf = StringBuffer();
    for (final turn in _history) {
      buf.writeln('Student: ${turn.user}');
      buf.writeln('Kalvin: ${turn.assistant}');
    }
    return buf.toString();
  }

  /// Smart fallback based on input type.
  String _getSmartFallback(String input) {
    final lower = input.toLowerCase().trim();
    if (lower == 'hi' || lower == 'hello' || lower == 'hey') {
      return 'Hey! What would you like to learn about today? I love science, space, nature, math — you name it! 🌟';
    }
    if (lower.contains('solar') || lower.contains('planet')) {
      return 'The solar system is like a big family! The Sun is at the center, and eight planets orbit around it. Earth is the third planet from the Sun. Want to know about a specific planet? 🪐';
    }
    if (lower.contains('volcano')) {
      return 'Volcanoes are like mountains with a hot temper! Deep underground, rock gets so hot it melts into magma. When pressure builds up, the magma erupts through the top. Pretty powerful, right? 🌋';
    }
    if (lower.contains('water cycle') || lower.contains('rain')) {
      return 'Water is always on the move! The sun heats water in rivers and oceans, turning it into vapor that rises up. High in the sky, it cools into clouds, then falls back as rain. This cycle never stops! 💧';
    }
    return 'That is a great topic! Let me think about the best way to explain it. Could you tell me a bit more about what you would like to know? 🤔';
  }

  String _detectTopic(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('volcano') || lower.contains('lava') || lower.contains('eruption')) return 'volcano';
    if (lower.contains('solar') || lower.contains('planet') || lower.contains('sun') || lower.contains('earth') || lower.contains('space')) return 'solar_system';
    if (lower.contains('water cycle') || lower.contains('rain') || lower.contains('evaporation')) return 'water_cycle';
    return _currentTopic.isNotEmpty ? _currentTopic : 'general';
  }

  void newConversation() {
    _history.clear();
    _qualityFilter.reset();
    _currentTopic = '';
    _turnCount = 0;
    _lifeCompanion.resetSessionTimer();
  }

  String generateSessionTitle() {
    if (_history.isEmpty) return 'New Chat';
    final firstQuery = _history.first.user;
    if (firstQuery.length > 30) return '${firstQuery.substring(0, 30)}...';
    return firstQuery;
  }

  Future<void> stopNarration() => _voiceEngine.stop();

  void dispose() {
    _llama.dispose();
    _voiceEngine.dispose();
  }
}

class _Turn {
  final String user;
  final String assistant;
  _Turn({required this.user, required this.assistant});
}

class OrchestratedResponse {
  final LearningResponse learningResponse;
  final String topic;
  final LifeCompanionMessage? companionMessage;
  final List<String> jsCommands;

  const OrchestratedResponse({
    required this.learningResponse,
    required this.topic,
    this.companionMessage,
    this.jsCommands = const [],
  });
}
