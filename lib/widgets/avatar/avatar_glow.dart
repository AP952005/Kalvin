/// Kalvin AI — Avatar Glow Effect
///
/// Animated glow aura that changes color and intensity
/// based on avatar state and emotion.

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'avatar_state_controller.dart';

class AvatarGlow extends StatefulWidget {
  final KalvinAvatarState state;
  final String emotion;
  final double size;
  final Widget child;

  const AvatarGlow({
    super.key,
    required this.state,
    required this.emotion,
    required this.child,
    this.size = 52,
  });

  @override
  State<AvatarGlow> createState() => _AvatarGlowState();
}

class _AvatarGlowState extends State<AvatarGlow>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(AvatarGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state || oldWidget.emotion != widget.emotion) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    switch (widget.state) {
      case KalvinAvatarState.speaking:
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
        break;
      case KalvinAvatarState.thinking:
        _pulseController.repeat(reverse: true);
        _glowController.stop();
        _glowController.animateTo(0.5);
        break;
      case KalvinAvatarState.listening:
        _pulseController.stop();
        _pulseController.animateTo(1.0);
        _glowController.repeat(reverse: true);
        break;
      case KalvinAvatarState.celebrating:
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
        break;
      case KalvinAvatarState.waking:
        _pulseController.forward();
        _glowController.forward();
        break;
      default:
        _pulseController.stop();
        _pulseController.animateTo(0.0);
        _glowController.stop();
        _glowController.animateTo(0.0);
    }
  }

  Color _getGlowColor() {
    switch (widget.emotion) {
      case 'excited':
        return AppColors.primaryOrange;
      case 'calm':
        return const Color(0xFF4ECDC4);
      case 'encouraging':
        return const Color(0xFFFFD93D);
      case 'curious':
        return const Color(0xFF6C5CE7);
      case 'gentle':
        return const Color(0xFFFF6B9D);
      case 'bedtime':
      case 'sleepy':
        return const Color(0xFF6C5CE7).withValues(alpha: 0.5);
      case 'supportive':
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.state == KalvinAvatarState.speaking ||
        widget.state == KalvinAvatarState.thinking ||
        widget.state == KalvinAvatarState.listening ||
        widget.state == KalvinAvatarState.celebrating ||
        widget.state == KalvinAvatarState.waking;

    if (!isActive) return widget.child;

    final glowColor = _getGlowColor();

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // Primary glow
                BoxShadow(
                  color: glowColor.withValues(alpha: _glowAnimation.value * 0.6),
                  blurRadius: 20 + (_glowAnimation.value * 15),
                  spreadRadius: _glowAnimation.value * 8,
                ),
                // Secondary pulse ring
                if (widget.state == KalvinAvatarState.speaking)
                  BoxShadow(
                    color: glowColor.withValues(alpha: _glowAnimation.value * 0.3),
                    blurRadius: 35 + (_glowAnimation.value * 20),
                    spreadRadius: _glowAnimation.value * 12,
                  ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
