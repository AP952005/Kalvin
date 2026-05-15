/// Kalvin Activity Controller — Global source of truth for avatar state.
///
/// All UI components that drive the avatar should use this controller.
/// The avatar widget listens to it and rebuilds only itself.

import 'package:flutter/foundation.dart';
import 'kalvin_activity_state.dart';
import 'avatar_position.dart';
import 'avatar_layout_engine.dart';

class KalvinActivityController extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────
  static final KalvinActivityController _instance =
      KalvinActivityController._();
  factory KalvinActivityController() => _instance;
  KalvinActivityController._();

  // ── State ───────────────────────────────────────────────────
  KalvinActivityState _currentState = KalvinActivityState.idle;
  AvatarPosition _currentPosition = AvatarPosition.right;
  bool _isNarrating = false;
  bool _isVisualActive = false;
  bool _isProcessing = false;
  bool _visualOnLeft = false;

  // ── Getters ─────────────────────────────────────────────────
  KalvinActivityState get currentState => _currentState;
  AvatarPosition get currentPosition => _currentPosition;
  bool get isNarrating => _isNarrating;
  bool get isVisualActive => _isVisualActive;
  bool get isProcessing => _isProcessing;
  bool get isVisualOnLeft => _visualOnLeft;

  // ── Core State Updates ───────────────────────────────────────

  void setActivityState(KalvinActivityState state) {
    if (_currentState == state) return;
    _currentState = state;
    _recalculatePosition();
    notifyListeners();
    debugPrint('[AvatarCtrl] State → $state | Position → $_currentPosition');
  }

  void setPosition(AvatarPosition position) {
    if (_currentPosition == position) return;
    _currentPosition = position;
    notifyListeners();
  }

  // ── High-level Activity Methods ──────────────────────────────

  void beginThinking() {
    setActivityState(KalvinActivityState.thinking);
  }

  void finishThinking() {
    if (_currentState == KalvinActivityState.thinking) {
      setActivityState(KalvinActivityState.idle);
    }
  }

  void startListening() {
    setActivityState(KalvinActivityState.listening);
  }

  void stopListening() {
    if (_currentState == KalvinActivityState.listening) {
      setActivityState(KalvinActivityState.thinking);
    }
  }

  void startNarration() {
    _isNarrating = true;
    setActivityState(KalvinActivityState.narrating);
  }

  void stopNarration() {
    _isNarrating = false;
    if (_currentState == KalvinActivityState.narrating) {
      setActivityState(
        _isVisualActive
            ? (_visualOnLeft
                ? KalvinActivityState.visualizingLeft
                : KalvinActivityState.visualizingRight)
            : KalvinActivityState.idle,
      );
    }
  }

  void activateVisualLeft() {
    _isVisualActive = true;
    _visualOnLeft = true;
    setActivityState(KalvinActivityState.visualizingLeft);
  }

  void activateVisualRight() {
    _isVisualActive = true;
    _visualOnLeft = false;
    setActivityState(KalvinActivityState.visualizingRight);
  }

  void clearVisuals() {
    _isVisualActive = false;
    if (_currentState == KalvinActivityState.visualizingLeft ||
        _currentState == KalvinActivityState.visualizingRight) {
      setActivityState(KalvinActivityState.idle);
    } else {
      _recalculatePosition();
      notifyListeners();
    }
  }

  void beginProcessing() {
    _isProcessing = true;
    setActivityState(KalvinActivityState.processing);
  }

  void finishProcessing() {
    _isProcessing = false;
    if (_currentState == KalvinActivityState.processing) {
      setActivityState(KalvinActivityState.idle);
    }
  }

  void reset() {
    _currentState = KalvinActivityState.idle;
    _currentPosition = AvatarPosition.right;
    _isNarrating = false;
    _isVisualActive = false;
    _isProcessing = false;
    _visualOnLeft = false;
    notifyListeners();
    debugPrint('[AvatarCtrl] RESET complete');
  }

  // ── Internal ─────────────────────────────────────────────────

  void _recalculatePosition() {
    final newPos = AvatarLayoutEngine.resolvePosition(
      visualVisible: _isVisualActive,
      visualOnLeft: _visualOnLeft,
    );
    _currentPosition = newPos;
  }
}
