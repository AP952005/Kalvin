/// Kalvin AI — Avatar Voice Reactor
///
/// Visual particle and wave effects that react to
/// the avatar's speaking state, creating a feeling
/// of the avatar being alive.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'avatar_state_controller.dart';

class AvatarVoiceReactor extends StatefulWidget {
  final KalvinAvatarState state;
  final String emotion;
  final double size;

  const AvatarVoiceReactor({
    super.key,
    required this.state,
    required this.emotion,
    this.size = 80,
  });

  @override
  State<AvatarVoiceReactor> createState() => _AvatarVoiceReactorState();
}

class _AvatarVoiceReactorState extends State<AvatarVoiceReactor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(AvatarVoiceReactor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.state == KalvinAvatarState.speaking ||
        widget.state == KalvinAvatarState.thinking ||
        widget.state == KalvinAvatarState.celebrating) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.animateTo(0.0, duration: const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getParticleColor() {
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
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.state == KalvinAvatarState.speaking ||
        widget.state == KalvinAvatarState.thinking ||
        widget.state == KalvinAvatarState.celebrating;

    if (!isActive) return SizedBox(width: widget.size, height: widget.size);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ParticlePainter(
            progress: _controller.value,
            color: _getParticleColor(),
            particleCount: widget.state == KalvinAvatarState.speaking ? 6 : 3,
            random: _random,
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount;
  final Random random;

  _ParticlePainter({
    required this.progress,
    required this.color,
    required this.particleCount,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw pulse rings
    for (var i = 0; i < 3; i++) {
      final ringProgress = ((progress + i * 0.33) % 1.0);
      final radius = maxRadius * 0.6 + (maxRadius * 0.8 * ringProgress);
      final opacity = (1.0 - ringProgress) * 0.3;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }

    // Draw floating particles
    for (var i = 0; i < particleCount; i++) {
      final angle = (progress * 2 * pi) + (i * 2 * pi / particleCount);
      final particleRadius = maxRadius * 0.7 + sin(progress * pi * 2 + i) * 8;
      final x = center.dx + cos(angle) * particleRadius;
      final y = center.dy + sin(angle) * particleRadius;
      final particleOpacity = (0.4 + 0.4 * sin(progress * pi * 4 + i)).clamp(0.0, 1.0);

      final particlePaint = Paint()
        ..color = color.withValues(alpha: particleOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 2.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
