/// Kalvin AI — Voice Personality Engine
///
/// Maps emotional states to TTS voice configurations.
/// Makes narration sound warm, child-friendly, and
/// emotionally appropriate instead of robotic.

import 'package:flutter_tts/flutter_tts.dart';

/// Voice configuration for a specific emotion.
class VoiceConfig {
  final double rate;
  final double pitch;
  final double volume;
  final int pauseBeforeMs;

  const VoiceConfig({
    required this.rate,
    required this.pitch,
    this.volume = 0.9,
    this.pauseBeforeMs = 0,
  });
}

class VoicePersonalityEngine {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;

  // Callbacks
  void Function()? onSpeakingStart;
  void Function()? onSpeakingEnd;

  /// Emotion → Voice config mapping.
  static const Map<String, VoiceConfig> _voiceConfigs = {
    'supportive': VoiceConfig(rate: 0.42, pitch: 1.05, volume: 0.85),
    'excited': VoiceConfig(rate: 0.52, pitch: 1.15, volume: 0.95),
    'calm': VoiceConfig(rate: 0.38, pitch: 0.95, volume: 0.75),
    'bedtime': VoiceConfig(rate: 0.32, pitch: 0.90, volume: 0.65, pauseBeforeMs: 300),
    'motivational': VoiceConfig(rate: 0.48, pitch: 1.10, volume: 0.90),
    'simplified': VoiceConfig(rate: 0.35, pitch: 1.00, volume: 0.80),
    'curious': VoiceConfig(rate: 0.45, pitch: 1.08, volume: 0.85),
    'encouraging': VoiceConfig(rate: 0.45, pitch: 1.10, volume: 0.90),
    'gentle': VoiceConfig(rate: 0.38, pitch: 1.00, volume: 0.75),
    'neutral': VoiceConfig(rate: 0.42, pitch: 1.00, volume: 0.85),
  };

  bool get isSpeaking => _isSpeaking;

  /// Initialize TTS with child-friendly defaults.
  Future<void> init() async {
    if (_initialized) return;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.05);
      await _tts.setVolume(0.85);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        onSpeakingStart?.call();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakingEnd?.call();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        onSpeakingEnd?.call();
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        onSpeakingEnd?.call();
      });

      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  /// Speak text with emotional voice configuration.
  Future<void> speak(String text, {String emotion = 'supportive'}) async {
    if (!_initialized || text.trim().isEmpty) return;

    // Stop any current speech
    await stop();

    // Apply voice config for this emotion
    final config = _voiceConfigs[emotion] ?? _voiceConfigs['neutral']!;

    try {
      await _tts.setSpeechRate(config.rate);
      await _tts.setPitch(config.pitch);
      await _tts.setVolume(config.volume);

      // Optional pause for bedtime/calm modes
      if (config.pauseBeforeMs > 0) {
        await Future.delayed(Duration(milliseconds: config.pauseBeforeMs));
      }

      // Break long text into sentences for more natural pacing
      final sentences = _splitIntoSentences(text);
      if (sentences.length <= 3) {
        await _tts.speak(text);
      } else {
        // Speak first 3 sentences (avoid very long TTS)
        final truncated = sentences.take(3).join(' ');
        await _tts.speak(truncated);
      }
    } catch (_) {
      _isSpeaking = false;
      onSpeakingEnd?.call();
    }
  }

  /// Stop speaking immediately.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
    onSpeakingEnd?.call();
  }

  /// Split text into sentences.
  List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  /// Get the voice config for a given emotion.
  static VoiceConfig getConfig(String emotion) {
    return _voiceConfigs[emotion] ?? _voiceConfigs['neutral']!;
  }

  /// Dispose TTS.
  void dispose() {
    stop();
  }
}
