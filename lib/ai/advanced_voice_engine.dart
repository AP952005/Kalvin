/// Kalvin AI — Advanced Voice Engine
///
/// Production-quality TTS with emotion-aware speech modulation.
/// Makes Kalvin sound soft, expressive, youthful, and emotionally warm.

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Voice profile for a specific emotional state.
class EmotionVoiceProfile {
  final double rate;
  final double pitch;
  final double volume;
  final int pauseBeforeMs;
  final int pauseBetweenSentencesMs;

  const EmotionVoiceProfile({
    required this.rate,
    required this.pitch,
    this.volume = 0.85,
    this.pauseBeforeMs = 0,
    this.pauseBetweenSentencesMs = 200,
  });
}

class AdvancedVoiceEngine {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  String _currentEmotion = 'supportive';

  // Callbacks for avatar integration
  void Function()? onSpeakingStart;
  void Function()? onSpeakingEnd;
  void Function(double progress)? onSpeakingProgress;

  /// Emotion → voice profile mapping for warm, youthful narration.
  static const Map<String, EmotionVoiceProfile> _profiles = {
    'supportive': EmotionVoiceProfile(
      rate: 0.48,
      pitch: 1.20,
      volume: 0.85,
      pauseBetweenSentencesMs: 250,
    ),
    'excited': EmotionVoiceProfile(
      rate: 0.55,
      pitch: 1.25,
      volume: 0.92,
      pauseBetweenSentencesMs: 150,
    ),
    'calm': EmotionVoiceProfile(
      rate: 0.42,
      pitch: 1.15,
      volume: 0.78,
      pauseBetweenSentencesMs: 350,
    ),
    'encouraging': EmotionVoiceProfile(
      rate: 0.50,
      pitch: 1.22,
      volume: 0.90,
      pauseBetweenSentencesMs: 200,
    ),
    'curious': EmotionVoiceProfile(
      rate: 0.50,
      pitch: 1.20,
      volume: 0.85,
      pauseBetweenSentencesMs: 200,
    ),
    'gentle': EmotionVoiceProfile(
      rate: 0.42,
      pitch: 1.18,
      volume: 0.75,
      pauseBetweenSentencesMs: 300,
    ),
    'bedtime': EmotionVoiceProfile(
      rate: 0.38,
      pitch: 1.10,
      volume: 0.65,
      pauseBeforeMs: 400,
      pauseBetweenSentencesMs: 450,
    ),
    'playful': EmotionVoiceProfile(
      rate: 0.54,
      pitch: 1.25,
      volume: 0.88,
      pauseBetweenSentencesMs: 150,
    ),
    'caring': EmotionVoiceProfile(
      rate: 0.45,
      pitch: 1.18,
      volume: 0.80,
      pauseBetweenSentencesMs: 300,
    ),
    'sleepy': EmotionVoiceProfile(
      rate: 0.35,
      pitch: 1.08,
      volume: 0.60,
      pauseBeforeMs: 500,
      pauseBetweenSentencesMs: 500,
    ),
    'motivational': EmotionVoiceProfile(
      rate: 0.52,
      pitch: 1.22,
      volume: 0.92,
      pauseBetweenSentencesMs: 180,
    ),
    'neutral': EmotionVoiceProfile(
      rate: 0.48,
      pitch: 1.18,
      volume: 0.85,
      pauseBetweenSentencesMs: 250,
    ),
  };

  bool get isSpeaking => _isSpeaking;
  String get currentEmotion => _currentEmotion;

  /// Initialize TTS with warm, youthful defaults.
  Future<void> init() async {
    if (_initialized) return;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.20);
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
        debugPrint('[AdvancedVoice] TTS Error: $msg');
        _isSpeaking = false;
        onSpeakingEnd?.call();
      });

      _initialized = true;
      debugPrint('[AdvancedVoice] Initialized with warm youthful voice.');
    } catch (e) {
      debugPrint('[AdvancedVoice] Init error: $e');
      _initialized = false;
    }
  }

  /// Speak text with emotion-aware modulation.
  Future<void> speak(String text, {String emotion = 'supportive'}) async {
    if (!_initialized || text.trim().isEmpty) return;

    await stop();

    _currentEmotion = emotion;
    final profile = _profiles[emotion] ?? _profiles['neutral']!;

    try {
      await _tts.setSpeechRate(profile.rate);
      await _tts.setPitch(profile.pitch);
      await _tts.setVolume(profile.volume);

      // Pre-speech pause for calm/bedtime modes
      if (profile.pauseBeforeMs > 0) {
        await Future.delayed(Duration(milliseconds: profile.pauseBeforeMs));
      }

      // Clean text for TTS (remove emojis, special chars)
      final cleanText = _prepareForSpeech(text);
      if (cleanText.isEmpty) return;

      // Break into sentences for natural pacing
      final sentences = _splitSentences(cleanText);

      if (sentences.length <= 4) {
        // Short response — speak all at once
        await _tts.speak(cleanText);
      } else {
        // Long response — speak first 4 sentences to avoid TTS overload
        final truncated = sentences.take(4).join(' ');
        await _tts.speak(truncated);
      }
    } catch (e) {
      debugPrint('[AdvancedVoice] Speak error: $e');
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

  /// Prepare text for speech — remove emojis, clean up.
  String _prepareForSpeech(String text) {
    var clean = text;

    // Remove emojis
    clean = clean.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{FE00}-\u{FE0F}]|[\u{1F000}-\u{1F02F}]|[\u{200D}]|[\u{20E3}]',
        unicode: true,
      ),
      '',
    );

    // Clean up multiple spaces
    clean = clean.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return clean;
  }

  /// Split text into sentences.
  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  /// Get the voice profile for an emotion.
  static EmotionVoiceProfile getProfile(String emotion) {
    return _profiles[emotion] ?? _profiles['neutral']!;
  }

  /// Determine emotion from time of day for life companion features.
  static String getTimeBasedEmotion() {
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 6) return 'sleepy';
    if (hour >= 6 && hour < 9) return 'gentle';
    if (hour >= 9 && hour < 12) return 'encouraging';
    if (hour >= 12 && hour < 14) return 'caring';
    if (hour >= 14 && hour < 17) return 'supportive';
    if (hour >= 17 && hour < 20) return 'calm';
    return 'gentle';
  }

  /// Dispose TTS resources.
  void dispose() {
    stop();
  }
}
