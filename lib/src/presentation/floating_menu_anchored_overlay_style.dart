import 'package:flutter/material.dart';

class FloatingMenuAnchoredOverlayStyle {
  /// Whether to show a full-screen barrier when open.
  final bool showBarrierWhenOpen;

  /// Whether tapping the barrier closes the overlay.
  final bool barrierDismissible;

  /// Barrier color (scrim).
  final Color barrierColor;

  /// Blur strength behind the barrier.
  final double barrierBlurSigmaX;
  final double barrierBlurSigmaY;

  /// Panel decoration.
  final Decoration? panelDecoration;

  /// Panel border radius.
  final BorderRadius panelBorderRadius;

  /// Panel clip behavior.
  final Clip panelClipBehavior;

  const FloatingMenuAnchoredOverlayStyle({
    this.showBarrierWhenOpen = true,
    this.barrierDismissible = true,
    this.barrierColor = const Color(0x66000000),
    this.barrierBlurSigmaX = 10,
    this.barrierBlurSigmaY = 10,
    this.panelDecoration,
    this.panelBorderRadius = const BorderRadius.all(Radius.circular(18)),
    this.panelClipBehavior = Clip.antiAlias,
  });
}
