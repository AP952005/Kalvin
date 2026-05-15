/// Kalvin AI — Narration Engine
///
/// Integrates flutter_tts for voice narration of all responses.
/// Supports emotional tones, child-friendly pacing, and
/// control methods (speak, stop, pause).

import 'package:flutter_tts/flutter_tts.dart';

/// Narration tone for emotional context.
enum NarrationTone {
  supportive,
  excited,
  calm,
  motivational,
  curious,
  gentle,
}

/// Text-to-speech narration engine for Kalvin.
class NarrationEngine {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  NarrationTone _currentTone = NarrationTone.supportive;

  /// Callback when speaking starts
  void Function()? onSpeakingStart;

  /// Callback when speaking ends
  void Function()? onSpeakingEnd;

  bool get isSpeaking => _isSpeaking;

  /// Initialize TTS engine with defaults.
  Future<void> init() async {
    if (_initialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setVolume(0.85);
    await _applyTone(NarrationTone.supportive);

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
  }

  /// Speak text with optional emotional tone.
  Future<void> speak(String text, {NarrationTone? tone}) async {
    if (!_initialized) await init();

    // Stop any current speech
    if (_isSpeaking) await stop();

    // Apply tone if changed
    final targetTone = tone ?? NarrationTone.supportive;
    if (targetTone != _currentTone) {
      await _applyTone(targetTone);
    }

    // Clean text for speech (remove special characters, emojis)
    final cleaned = _cleanForSpeech(text);
    if (cleaned.isEmpty) return;

    await _tts.speak(cleaned);
  }

  /// Stop speaking immediately.
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Pause speaking (if supported by platform).
  Future<void> pause() async {
    await _tts.pause();
  }

  /// Apply emotional tone via speech rate and pitch.
  Future<void> _applyTone(NarrationTone tone) async {
    _currentTone = tone;

    switch (tone) {
      case NarrationTone.supportive:
        await _tts.setSpeechRate(0.42);
        await _tts.setPitch(1.05);
        break;
      case NarrationTone.excited:
        await _tts.setSpeechRate(0.50);
        await _tts.setPitch(1.15);
        break;
      case NarrationTone.calm:
        await _tts.setSpeechRate(0.38);
        await _tts.setPitch(0.95);
        break;
      case NarrationTone.motivational:
        await _tts.setSpeechRate(0.45);
        await _tts.setPitch(1.10);
        break;
      case NarrationTone.curious:
        await _tts.setSpeechRate(0.44);
        await _tts.setPitch(1.08);
        break;
      case NarrationTone.gentle:
        await _tts.setSpeechRate(0.36);
        await _tts.setPitch(1.0);
        break;
    }
  }

  /// Map emotion string from AI response to narration tone.
  NarrationTone emotionToTone(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'excited':
        return NarrationTone.excited;
      case 'calm':
        return NarrationTone.calm;
      case 'encouraging':
      case 'motivational':
        return NarrationTone.motivational;
      case 'curious':
        return NarrationTone.curious;
      case 'gentle':
        return NarrationTone.gentle;
      case 'supportive':
      default:
        return NarrationTone.supportive;
    }
  }

  /// Clean text for TTS — remove markdown, emojis, special chars.
  String _cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '') // bold/italic markers
        .replaceAll(RegExp(r'#+\s*'), '') // headings
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '') // links
        .replaceAll(RegExp(r'[^\x20-\x7E\s]'), '') // non-ASCII (emojis)
        .replaceAll(RegExp(r'\s+'), ' ') // multiple spaces
        .trim();
  }

  /// Dispose TTS resources.
  void dispose() {
    _tts.stop();
  }
}
