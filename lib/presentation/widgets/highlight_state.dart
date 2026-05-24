/// Visual highlight state for words and chords in the player.
enum HighlightState {
  /// Currently being sung / played.
  active,

  /// Upcoming (next).
  pending,

  /// Already passed.
  inactive,
}
