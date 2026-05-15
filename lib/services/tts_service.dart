import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline Text-to-Speech service for Kalvin assistant
class KalvinTTS {
  static final KalvinTTS _instance = KalvinTTS._internal();
  factory KalvinTTS() => _instance;
  KalvinTTS._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    if (_initialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // calm educational pace
    await _tts.setVolume(0.8);
    await _tts.setPitch(1.05); // slightly warm tone

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) => _isSpeaking = false);

    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!_initialized) await init();
    if (_isSpeaking) await stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Check if this is the first ever app launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('kalvin_first_launch') ?? true;
  }

  /// Mark first launch as completed
  static Future<void> markFirstLaunchDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kalvin_first_launch', false);
  }

  /// Check if avatar is enabled in settings
  static Future<bool> isAvatarEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('kalvin_avatar_enabled') ?? true;
  }

  /// Set avatar enabled state
  static Future<void> setAvatarEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kalvin_avatar_enabled', enabled);
  }
}
