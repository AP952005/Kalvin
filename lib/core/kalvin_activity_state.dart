/// Kalvin Activity State — All possible runtime states of the Kalvin avatar.

enum KalvinActivityState {
  /// Default idle state — avatar is waiting
  idle,

  /// User is speaking into the mic
  listening,

  /// AI is generating a response
  thinking,

  /// Kalvin is speaking / narrating the response
  narrating,

  /// Heavy processing (model loading etc.)
  processing,

  /// Visual panel is active on the left
  visualizingLeft,

  /// Visual panel is active on the right
  visualizingRight,
}
