/// Avatar Layout Engine — resolves where the avatar should sit based on visual state.
///
/// Logic:
/// - No visual → avatar sits RIGHT
/// - Visual on LEFT → avatar sits RIGHT (so they don't overlap)
/// - Visual on RIGHT → avatar sits LEFT

import 'avatar_position.dart';

class AvatarLayoutEngine {
  /// Resolve the correct avatar position based on visual state.
  static AvatarPosition resolvePosition({
    required bool visualVisible,
    required bool visualOnLeft,
  }) {
    if (!visualVisible) return AvatarPosition.right;
    if (visualOnLeft) return AvatarPosition.right;
    return AvatarPosition.left; // visual is on right → avatar goes left
  }
}
