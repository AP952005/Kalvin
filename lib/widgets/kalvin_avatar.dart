import 'package:flutter/material.dart';
import '../core/kalvin_activity_controller.dart';
import '../core/kalvin_activity_state.dart';
import '../core/avatar_asset_resolver.dart';
import '../core/avatar_position.dart';
import 'avatar/animated_avatar_player.dart';

/// Global floating Kalvin avatar — uses actual PNG/webm assets.
/// Draggable, state-aware, synchronized with KalvinActivityController.
class KalvinAvatar extends StatefulWidget {
  final VoidCallback? onTap;
  final bool visible;
  final VoidCallback? onDismiss;

  const KalvinAvatar({
    super.key,
    this.onTap,
    this.visible = true,
    this.onDismiss,
  });

  @override
  State<KalvinAvatar> createState() => KalvinAvatarState();
}

class KalvinAvatarState extends State<KalvinAvatar>
    with TickerProviderStateMixin {
  // Position
  double _posX = 16;
  double _posY = 0;
  bool _posInitialized = false;
  bool _isDragging = false;
  bool _isOverDismissZone = false;

  // Activity controller
  final KalvinActivityController _ctrl = KalvinActivityController();

  // Animations
  late AnimationController _breathController;
  late AnimationController _glowController;
  late AnimationController _entranceController;
  late Animation<double> _breathAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _entranceScale;
  late Animation<double> _entranceFade;



  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    if (widget.visible) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _entranceController.forward();
      });
    }

    _ctrl.addListener(_onStateChanged);
  }

  AvatarPosition _lastPosition = AvatarPosition.right;

  void _onStateChanged() {
    if (!mounted) return;
    
    // Auto-slide when position changes due to visuals
    if (_ctrl.currentPosition != _lastPosition) {
      _lastPosition = _ctrl.currentPosition;
      if (_ctrl.currentPosition == AvatarPosition.left) {
        _posX = 16;
      } else {
        _posX = MediaQuery.of(context).size.width - 86; // width - avatar size
      }
    }

    final asset = AvatarAssetResolver.resolve(
      state: _ctrl.currentState,
      position: _ctrl.currentPosition,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _breathController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    _ctrl.removeListener(_onStateChanged);
    super.dispose();
  }

  // Public API (called from learn_screen)
  void setSpeaking(bool speaking) {
    if (speaking) {
      _ctrl.startNarration();
    } else {
      _ctrl.stopNarration();
    }
  }

  void setThinking(bool thinking) {
    if (thinking) {
      _ctrl.beginThinking();
    } else {
      _ctrl.finishThinking();
    }
  }

  void setEmotion(String emotion) {} // kept for API compat

  // ── Glow color per state ─────────────────────────────────────
  Color get _glowColor {
    switch (_ctrl.currentState) {
      case KalvinActivityState.narrating:
        return const Color(0xFF00B4D8);
      case KalvinActivityState.thinking:
      case KalvinActivityState.processing:
        return const Color(0xFF7B5EA7);
      case KalvinActivityState.listening:
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF1565C0);
    }
  }

  double get _glowBlur {
    switch (_ctrl.currentState) {
      case KalvinActivityState.narrating:
        return 8 + (_glowAnim.value * 18);
      case KalvinActivityState.thinking:
        return 14;
      case KalvinActivityState.listening:
        return 16;
      default:
        return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _entranceController.isDismissed) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (!_posInitialized) {
      _posY = screenSize.height - 180 - bottomPadding;
      _posInitialized = true;
    }

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dismiss drop zone
          if (_isDragging)
            Positioned(
              top: topPadding + 4,
              left: 48,
              right: 48,
              child: AnimatedOpacity(
                opacity: _isOverDismissZone ? 1.0 : 0.55,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isOverDismissZone
                        ? Colors.red.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isOverDismissZone
                          ? Colors.red.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _isOverDismissZone ? 'Release to dismiss' : 'Drag here to dismiss',
                      style: TextStyle(
                        fontSize: 10,
                        color: _isOverDismissZone ? Colors.red : Colors.grey,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Floating avatar
          AnimatedBuilder(
            animation: Listenable.merge([_breathController, _glowController, _entranceController]),
            builder: (context, _) {
              final scale = _entranceScale.value.clamp(0.0, 1.5);
              final opacity = _entranceFade.value.clamp(0.0, 1.0);
              if (opacity < 0.01) return const SizedBox.shrink();

              return AnimatedPositioned(
                duration: Duration(milliseconds: _isDragging ? 0 : 400),
                curve: Curves.easeInOut,
                left: _posX,
                top: (_posY - _breathAnim.value).clamp(topPadding, screenSize.height - 80),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTap: widget.onTap,
                      onPanStart: (_) => setState(() => _isDragging = true),
                      onPanUpdate: (details) {
                        setState(() {
                          _posX = (_posX + details.delta.dx).clamp(0.0, screenSize.width - 70);
                          _posY = (_posY + details.delta.dy).clamp(topPadding, screenSize.height - 120);
                          _isOverDismissZone = _posY < topPadding + 56;
                        });
                      },
                      onPanEnd: (_) {
                        if (_isOverDismissZone) widget.onDismiss?.call();
                        setState(() {
                          _isDragging = false;
                          _isOverDismissZone = false;
                        });
                      },
                      child: _buildAvatarBody(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarBody() {
    // ── Dynamic Physical Position Tracking ──
    // Determine which side of the screen the avatar is physically on right now
    final screenWidth = MediaQuery.of(context).size.width;
    final physicalPosition = _posX < (screenWidth / 2) 
        ? AvatarPosition.left 
        : AvatarPosition.right;

    // Resolve the asset using the physical physicalPosition
    final asset = AvatarAssetResolver.resolve(
      state: _ctrl.currentState,
      position: physicalPosition,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow ring
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _glowColor.withValues(
                  alpha: _ctrl.currentState == KalvinActivityState.narrating
                      ? 0.3 + _glowAnim.value * 0.3
                      : 0.2,
                ),
                blurRadius: _glowBlur,
                spreadRadius: _ctrl.currentState == KalvinActivityState.narrating ? 3 : 1,
              ),
            ],
          ),
        ),

        // Avatar image/video — 60×60
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 60,
            height: 60,
            child: asset.isVideo
                ? AnimatedAvatarPlayer(
                    key: ValueKey(asset.path),
                    assetPath: asset.path,
                    size: 60,
                    fallbackAsset: physicalPosition == AvatarPosition.left
                        ? 'assets/avatars/leftideal.png'
                        : 'assets/avatars/rightideal.png',
                  )
                : Image.asset(
                    asset.path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      physicalPosition == AvatarPosition.left
                          ? 'assets/avatars/leftideal.png'
                          : 'assets/avatars/rightideal.png',
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),

        // State badge
        Positioned(
          bottom: 0,
          right: 0,
          child: _buildBadge(),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    IconData icon;
    Color color;
    switch (_ctrl.currentState) {
      case KalvinActivityState.narrating:
        icon = Icons.graphic_eq_rounded;
        color = const Color(0xFF00B4D8);
        break;
      case KalvinActivityState.thinking:
      case KalvinActivityState.processing:
        icon = Icons.psychology_rounded;
        color = const Color(0xFF7B5EA7);
        break;
      case KalvinActivityState.listening:
        icon = Icons.mic_rounded;
        color = const Color(0xFF4CAF50);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(icon, size: 9, color: Colors.white),
    );
  }
}
