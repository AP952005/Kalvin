/// Kalvin AI — Avatar State Controller
///
/// Centralized state management for the Kalvin avatar.
/// Drives glow, pulse, particles, and animation transitions
/// based on the current interaction state.

import 'package:flutter/foundation.dart';

/// All possible avatar visual states.
enum KalvinAvatarState {
  idle,
  listening,
  thinking,
  speaking,
  sleeping,
  celebrating,
  encouraging,
  waking,
}

/// Controls avatar state transitions and notifies listeners.
class AvatarStateController extends ChangeNotifier {
  KalvinAvatarState _state = KalvinAvatarState.idle;
  String _emotion = 'supportive';
  double _speakingIntensity = 0.0;
  bool _glowActive = false;
  bool _particlesActive = false;

  KalvinAvatarState get state => _state;
  String get emotion => _emotion;
  double get speakingIntensity => _speakingIntensity;
  bool get glowActive => _glowActive;
  bool get particlesActive => _particlesActive;

  /// Transition to a new state.
  void setState(KalvinAvatarState newState) {
    if (_state == newState) return;
    _state = newState;

    // Update visual properties based on state
    switch (newState) {
      case KalvinAvatarState.idle:
        _glowActive = false;
        _particlesActive = false;
        _speakingIntensity = 0.0;
        break;
      case KalvinAvatarState.listening:
        _glowActive = true;
        _particlesActive = false;
        _speakingIntensity = 0.0;
        break;
      case KalvinAvatarState.thinking:
        _glowActive = true;
        _particlesActive = true;
        _speakingIntensity = 0.0;
        break;
      case KalvinAvatarState.speaking:
        _glowActive = true;
        _particlesActive = true;
        _speakingIntensity = 0.8;
        break;
      case KalvinAvatarState.sleeping:
        _glowActive = false;
        _particlesActive = false;
        _speakingIntensity = 0.0;
        break;
      case KalvinAvatarState.celebrating:
        _glowActive = true;
        _particlesActive = true;
        _speakingIntensity = 1.0;
        break;
      case KalvinAvatarState.encouraging:
        _glowActive = true;
        _particlesActive = false;
        _speakingIntensity = 0.5;
        break;
      case KalvinAvatarState.waking:
        _glowActive = true;
        _particlesActive = true;
        _speakingIntensity = 0.3;
        break;
    }

    notifyListeners();
  }

  /// Update the current emotion (affects glow color).
  void setEmotion(String emotion) {
    if (_emotion == emotion) return;
    _emotion = emotion;
    notifyListeners();
  }

  /// Update speaking intensity (0.0 - 1.0) for voice reactivity.
  void setSpeakingIntensity(double intensity) {
    _speakingIntensity = intensity.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Start speaking state.
  void startSpeaking({String emotion = 'supportive'}) {
    _emotion = emotion;
    setState(KalvinAvatarState.speaking);
  }

  /// Stop speaking and return to idle.
  void stopSpeaking() {
    setState(KalvinAvatarState.idle);
  }

  /// Enter thinking state.
  void startThinking() {
    setState(KalvinAvatarState.thinking);
  }

  /// Enter listening state.
  void startListening() {
    setState(KalvinAvatarState.listening);
  }

  /// Wake up animation (from sleeping or initial load).
  void wake() {
    setState(KalvinAvatarState.waking);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_state == KalvinAvatarState.waking) {
        setState(KalvinAvatarState.idle);
      }
    });
  }
}
