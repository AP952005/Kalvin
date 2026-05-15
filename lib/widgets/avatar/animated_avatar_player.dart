/// Animated Avatar Player — plays looping webm assets using video_player.
///
/// Falls back to a static image if the asset fails to load.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AnimatedAvatarPlayer extends StatefulWidget {
  final String assetPath;
  final double size;
  final bool muted;
  final String? fallbackAsset;

  const AnimatedAvatarPlayer({
    super.key,
    required this.assetPath,
    this.size = 120,
    this.muted = true,
    this.fallbackAsset,
  });

  @override
  State<AnimatedAvatarPlayer> createState() => _AnimatedAvatarPlayerState();
}

class _AnimatedAvatarPlayerState extends State<AnimatedAvatarPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _loadAsset(widget.assetPath);
  }

  @override
  void didUpdateWidget(AnimatedAvatarPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _loadAsset(widget.assetPath);
    }
  }

  Future<void> _loadAsset(String path) async {
    if (_currentPath == path) return;
    _currentPath = path;

    // Dispose old controller
    final old = _controller;
    _controller = null;
    _initialized = false;
    _failed = false;
    if (mounted) setState(() {});
    await old?.dispose();

    try {
      final ctrl = VideoPlayerController.asset(path);
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(widget.muted ? 0.0 : 1.0);
      ctrl.play();

      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _controller = ctrl;
        _initialized = true;
        _failed = false;
      });
    } catch (e) {
      debugPrint('[AnimatedAvatarPlayer] Failed to load $path: $e');
      if (mounted) {
        setState(() {
          _failed = true;
          _initialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      // Fallback to static image
      final fallback = widget.fallbackAsset ?? 'assets/avatars/leftideal.png';
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Image.asset(fallback, fit: BoxFit.contain),
      );
    }

    if (!_initialized || _controller == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Color(0xFF00B4D8),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.12),
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
