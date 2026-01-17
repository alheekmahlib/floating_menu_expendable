enum FloatingMenuAnchoredOverlayPlacement {
  /// Chooses the best placement (top/bottom/start/end) based on available space.
  auto,

  /// Shows the panel above the anchor.
  top,

  /// Shows the panel below the anchor.
  bottom,

  /// Shows the panel at the start side (left in LTR, right in RTL).
  start,

  /// Shows the panel at the end side (right in LTR, left in RTL).
  end,
}
