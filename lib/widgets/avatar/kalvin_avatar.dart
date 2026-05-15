/// KalvinAvatar — The main dynamic avatar widget.
///
/// Listens to KalvinActivityController and:
/// - Displays the correct asset for each state
/// - Animates between positions using AnimatedAlign
/// - Shows speaking glow when narrating
/// - Shows thinking shimmer when processing
/// - Shows listening pulse when user is speaking

import 'package:flutter/material.dart';
import '../../core/kalvin_activity_controller.dart';
import '../../core/kalvin_activity_state.dart';
import '../../core/avatar_position.dart';
import '../../core/avatar_asset_resolver.dart';
import 'animated_avatar_player.dart';

class KalvinAvatar extends StatefulWidget {
  /// Height of the parent container so we can position correctly.
  final double parentHeight;
  final double size;

  const KalvinAvatar({
    super.key,
    this.parentHeight = 300,
    this.size = 110,
  });

  @override
  State<KalvinAvatar> createState() => _KalvinAvatarState();
}

class _KalvinAvatarState extends State<KalvinAvatar>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _floatController;
  late AnimationController _pulseController;

  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  final KalvinActivityController _ctrl = KalvinActivityController();

  @override
  void initState() {
    super.initState();

    // Glow breathing — for narrating
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 6.0, end: 20.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Float up/down — always on
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulse ring — for listening / thinking
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ctrl.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _ctrl.removeListener(_onStateChanged);
    super.dispose();
  }

  // ── Derived values ────────────────────────────────────────────

  bool get _isNarrating =>
      _ctrl.currentState == KalvinActivityState.narrating;

  bool get _isThinking =>
      _ctrl.currentState == KalvinActivityState.thinking ||
      _ctrl.currentState == KalvinActivityState.processing;

  bool get _isListening =>
      _ctrl.currentState == KalvinActivityState.listening;

  Color get _glowColor {
    switch (_ctrl.currentState) {
      case KalvinActivityState.narrating:
        return const Color(0xFF00B4D8); // Cyan
      case KalvinActivityState.thinking:
      case KalvinActivityState.processing:
        return const Color(0xFF7B5EA7); // Purple
      case KalvinActivityState.listening:
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF1565C0).withValues(alpha: 0.4); // Dim blue
    }
  }

  double get _glowBlur {
    switch (_ctrl.currentState) {
      case KalvinActivityState.narrating:
        return _glowAnim.value;
      case KalvinActivityState.thinking:
      case KalvinActivityState.processing:
        return 12;
      case KalvinActivityState.listening:
        return 16;
      default:
        return 4;
    }
  }

  Alignment get _alignment =>
      _ctrl.currentPosition == AvatarPosition.left
          ? Alignment.bottomLeft
          : Alignment.bottomRight;

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asset = AvatarAssetResolver.resolve(
      state: _ctrl.currentState,
      position: _ctrl.currentPosition,
    );

    return AnimatedAlign(
      alignment: _alignment,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Padding(
        padding: EdgeInsets.only(
          left: _ctrl.currentPosition == AvatarPosition.left ? 8 : 0,
          right: _ctrl.currentPosition == AvatarPosition.right ? 8 : 0,
          bottom: 6,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_glowController, _floatController, _pulseController]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: Transform.scale(
                scale: (_isListening || _isThinking)
                    ? _pulseAnim.value
                    : 1.0,
                child: _buildAvatarBody(asset),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarBody(AvatarAsset asset) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow ring
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.size + (_glowBlur * 2),
          height: widget.size + (_glowBlur * 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _glowColor.withValues(alpha: _isNarrating ? 0.45 : 0.2),
                blurRadius: _glowBlur,
                spreadRadius: _isNarrating ? 4 : 1,
              ),
            ],
          ),
        ),

        // Thinking rotating ring
        if (_isThinking) _buildThinkingRing(),

        // Avatar content
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.size * 0.15),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: asset.isVideo
                ? AnimatedAvatarPlayer(
                    key: ValueKey(asset.path),
                    assetPath: asset.path,
                    size: widget.size,
                    fallbackAsset:
                        _ctrl.currentPosition == AvatarPosition.left
                            ? 'assets/avatars/leftideal.png'
                            : 'assets/avatars/rightideal.png',
                  )
                : Image.asset(asset.path, fit: BoxFit.contain),
          ),
        ),

        // State label badge
        Positioned(
          bottom: 0,
          child: _buildStateBadge(),
        ),
      ],
    );
  }

  Widget _buildThinkingRing() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, _) {
        return Transform.rotate(
          angle: value * 6.283, // 2π
          child: Container(
            width: widget.size + 16,
            height: widget.size + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF7B5EA7).withValues(alpha: 0.4),
                width: 2,
              ),
              gradient: SweepGradient(
                colors: [
                  const Color(0xFF7B5EA7).withValues(alpha: 0.0),
                  const Color(0xFF7B5EA7).withValues(alpha: 0.6),
                  const Color(0xFF7B5EA7).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        );
      },
      // Repeat by re-keying
      key: ValueKey('thinking_${DateTime.now().second ~/ 2}'),
    );
  }

  Widget _buildStateBadge() {
    String label;
    Color color;
    switch (_ctrl.currentState) {
      case KalvinActivityState.thinking:
        label = 'Thinking...';
        color = const Color(0xFF7B5EA7);
        break;
      case KalvinActivityState.processing:
        label = 'Loading...';
        color = const Color(0xFFFF9800);
        break;
      case KalvinActivityState.narrating:
        label = 'Speaking';
        color = const Color(0xFF00B4D8);
        break;
      case KalvinActivityState.listening:
        label = 'Listening';
        color = const Color(0xFF4CAF50);
        break;
      case KalvinActivityState.visualizingLeft:
      case KalvinActivityState.visualizingRight:
        label = 'Visualizing';
        color = const Color(0xFFFF6F00);
        break;
      case KalvinActivityState.idle:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
