import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'floating_menu_anchored_overlay_placement.dart';

class FloatingMenuAnchoredOverlayResolvedPlacement {
  final FloatingMenuAnchoredOverlayPlacement placement;
  final double maxWidth;
  final double maxHeight;

  const FloatingMenuAnchoredOverlayResolvedPlacement({
    required this.placement,
    required this.maxWidth,
    required this.maxHeight,
  });
}

class FloatingMenuAnchoredOverlayPlacementResolver {
  const FloatingMenuAnchoredOverlayPlacementResolver();

  FloatingMenuAnchoredOverlayResolvedPlacement resolve({
    required FloatingMenuAnchoredOverlayPlacement placement,
    required TextDirection textDirection,
    required Rect anchorRect,
    required Size overlaySize,
    required EdgeInsets safeArea,
    required double gap,
    required double desiredPanelWidth,
    required double desiredPanelHeight,
  }) {
    if (placement != FloatingMenuAnchoredOverlayPlacement.auto) {
      final maxSize = _availableSizeFor(
        placement: placement,
        textDirection: textDirection,
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        safeArea: safeArea,
        gap: gap,
      );
      return FloatingMenuAnchoredOverlayResolvedPlacement(
        placement: placement,
        maxWidth: maxSize.width,
        maxHeight: maxSize.height,
      );
    }

    const candidates = <FloatingMenuAnchoredOverlayPlacement>[
      FloatingMenuAnchoredOverlayPlacement.bottom,
      FloatingMenuAnchoredOverlayPlacement.top,
      FloatingMenuAnchoredOverlayPlacement.end,
      FloatingMenuAnchoredOverlayPlacement.start,
    ];

    FloatingMenuAnchoredOverlayPlacement best =
        FloatingMenuAnchoredOverlayPlacement.bottom;
    double bestScore = -1;
    double bestMaxW = 0;
    double bestMaxH = 0;

    for (final c in candidates) {
      final size = _availableSizeFor(
        placement: c,
        textDirection: textDirection,
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        safeArea: safeArea,
        gap: gap,
      );
      final maxW = size.width;
      final maxH = size.height;

      final wScore = desiredPanelWidth <= 0
          ? 1.0
          : (maxW / desiredPanelWidth).clamp(0.0, 1.0);
      final hScore = desiredPanelHeight <= 0
          ? 1.0
          : (maxH / desiredPanelHeight).clamp(0.0, 1.0);

      // Primary: how well it fits. Secondary: available area.
      final fitScore = (wScore * 0.6) + (hScore * 0.4);
      final areaScore =
          (maxW * maxH) / math.max(1.0, desiredPanelWidth * desiredPanelHeight);
      final score = fitScore + (areaScore * 0.05);

      if (score > bestScore) {
        bestScore = score;
        best = c;
        bestMaxW = maxW;
        bestMaxH = maxH;
      }
    }

    return FloatingMenuAnchoredOverlayResolvedPlacement(
      placement: best,
      maxWidth: bestMaxW,
      maxHeight: bestMaxH,
    );
  }

  Size _availableSizeFor({
    required FloatingMenuAnchoredOverlayPlacement placement,
    required TextDirection textDirection,
    required Rect anchorRect,
    required Size overlaySize,
    required EdgeInsets safeArea,
    required double gap,
  }) {
    final leftLimit = safeArea.left;
    final topLimit = safeArea.top;
    final rightLimit = overlaySize.width - safeArea.right;
    final bottomLimit = overlaySize.height - safeArea.bottom;

    switch (placement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
        return const Size(0, 0);
      case FloatingMenuAnchoredOverlayPlacement.top:
        return Size(
          (rightLimit - leftLimit).clamp(0.0, double.infinity),
          (anchorRect.top - topLimit - gap).clamp(0.0, double.infinity),
        );
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        return Size(
          (rightLimit - leftLimit).clamp(0.0, double.infinity),
          (bottomLimit - anchorRect.bottom - gap).clamp(0.0, double.infinity),
        );
      case FloatingMenuAnchoredOverlayPlacement.start:
      case FloatingMenuAnchoredOverlayPlacement.end:
        final isStartPhysicalLeft = (textDirection == TextDirection.ltr)
            ? (placement == FloatingMenuAnchoredOverlayPlacement.start)
            : (placement == FloatingMenuAnchoredOverlayPlacement.end);

        if (isStartPhysicalLeft) {
          return Size(
            (anchorRect.left - leftLimit - gap).clamp(0.0, double.infinity),
            (bottomLimit - topLimit).clamp(0.0, double.infinity),
          );
        }

        return Size(
          (rightLimit - anchorRect.right - gap).clamp(0.0, double.infinity),
          (bottomLimit - topLimit).clamp(0.0, double.infinity),
        );
    }
  }
}
