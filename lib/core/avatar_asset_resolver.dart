/// Avatar Asset Resolver — maps activity state + position to the correct asset path.
///
/// Actual assets available:
///   Static:  think.png, processing.png, leftideal.png, rightideal.png
///   Animated: leftvisual.webm, rightvisual.webm, speak.webm

import 'kalvin_activity_state.dart';
import 'avatar_position.dart';

class AvatarAsset {
  final String path;
  final bool isVideo;
  const AvatarAsset(this.path, {this.isVideo = false});
}

class AvatarAssetResolver {
  static AvatarAsset resolve({
    required KalvinActivityState state,
    required AvatarPosition position,
  }) {
    switch (state) {
      case KalvinActivityState.thinking:
        return const AvatarAsset('assets/avatars/think.png');

      case KalvinActivityState.processing:
        return const AvatarAsset('assets/avatars/processing.png');

      case KalvinActivityState.narrating:
        // One speak animation — used for both sides
        return const AvatarAsset('assets/avatars/speak.webm', isVideo: true);

      case KalvinActivityState.visualizingLeft:
      case KalvinActivityState.visualizingRight:
        return position == AvatarPosition.left
            ? const AvatarAsset('assets/avatars/leftvisual.webm', isVideo: true)
            : const AvatarAsset('assets/avatars/rightvisual.webm', isVideo: true);

      case KalvinActivityState.listening:
        // Use ideal PNG for listening, glow effect applied in widget
        return position == AvatarPosition.left
            ? const AvatarAsset('assets/avatars/leftideal.png')
            : const AvatarAsset('assets/avatars/rightideal.png');

      case KalvinActivityState.idle:
        return position == AvatarPosition.left
            ? const AvatarAsset('assets/avatars/leftideal.png')
            : const AvatarAsset('assets/avatars/rightideal.png');
    }
  }
}
