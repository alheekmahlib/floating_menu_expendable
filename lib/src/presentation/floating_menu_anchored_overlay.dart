import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../domain/floating_menu_anchored_overlay_controller.dart';
import '../domain/floating_menu_anchored_overlay_placement.dart';
import '../domain/floating_menu_anchored_overlay_resolver.dart';
import 'floating_menu_anchored_overlay_style.dart';

typedef FloatingMenuAnchoredOverlayAnchorBuilder =
    Widget Function(BuildContext context, VoidCallback toggle);

class FloatingMenuAnchoredOverlay extends StatefulWidget {
  final FloatingMenuAnchoredOverlayController controller;

  /// The widget in your grid/list.
  final Widget child;

  /// Optional builder to wire your own onTap (InkWell, GestureDetector, etc)
  /// without interfering with the child's gesture arena.
  final FloatingMenuAnchoredOverlayAnchorBuilder? anchorBuilder;

  /// Visual customization for the overlay barrier and panel.
  final FloatingMenuAnchoredOverlayStyle style;

  /// Desired panel size (will be clamped to available space).
  final double panelWidth;
  final double panelHeight;

  /// Content shown inside the panel.
  final Widget panelChild;

  /// Placement of the panel relative to the anchor.
  final FloatingMenuAnchoredOverlayPlacement placement;

  /// If true, the panel will be positioned on top of the anchor and animated
  /// to expand from the anchor's size (instead of appearing as a separate
  /// popover above/below/side).
  ///
  /// This is useful when you want the visual effect of "the item expands"
  /// while still keeping grid/list layout fixed (because the panel is in an
  /// overlay).
  final bool expandFromAnchor;

  /// Spacing between the anchor and the panel.
  final double gap;

  /// Extra padding inside the overlay bounds (in addition to SafeArea).
  final EdgeInsetsGeometry overlayPadding;

  /// Whether to close when the nearest Scrollable is scrolled.
  final bool closeOnScroll;

  /// Animation.
  final Duration animationDuration;
  final Curve animationCurve;

  /// Whether to use the root overlay.
  final bool useRootOverlay;

  const FloatingMenuAnchoredOverlay({
    super.key,
    required this.controller,
    required this.child,
    required this.panelWidth,
    required this.panelHeight,
    required this.panelChild,
    this.anchorBuilder,
    this.style = const FloatingMenuAnchoredOverlayStyle(),
    this.placement = FloatingMenuAnchoredOverlayPlacement.auto,
    this.expandFromAnchor = false,
    this.gap = 8,
    this.overlayPadding = const EdgeInsets.all(12),
    this.closeOnScroll = false,
    this.animationDuration = const Duration(milliseconds: 220),
    this.animationCurve = Curves.easeOut,
    this.useRootOverlay = true,
  });

  @override
  State<FloatingMenuAnchoredOverlay> createState() =>
      _FloatingMenuAnchoredOverlayState();
}

class _FloatingMenuAnchoredOverlayState
    extends State<FloatingMenuAnchoredOverlay>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  final GlobalKey _anchorRepaintKey = GlobalKey();

  final _resolver = const FloatingMenuAnchoredOverlayPlacementResolver();

  OverlayEntry? _entry;

  ui.Image? _anchorSnapshot;

  late final AnimationController _openController;
  late Animation<double> _openCurve;

  VoidCallback? _removeScrollListener;

  @override
  void initState() {
    super.initState();

    _openController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: widget.controller.isOpen ? 1 : 0,
    );
    _openCurve = CurvedAnimation(
      parent: _openController,
      curve: widget.animationCurve,
    );

    widget.controller.addListener(_onControllerChanged);

    if (widget.controller.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _show();
      });
    }
  }

  @override
  void didUpdateWidget(covariant FloatingMenuAnchoredOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }

    if (oldWidget.animationDuration != widget.animationDuration) {
      _openController.duration = widget.animationDuration;
    }

    if (oldWidget.animationCurve != widget.animationCurve) {
      _openCurve = CurvedAnimation(
        parent: _openController,
        curve: widget.animationCurve,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _removeScrollListener?.call();
    _removeScrollListener = null;
    _removeEntry();
    _anchorSnapshot?.dispose();
    _anchorSnapshot = null;
    _openController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    if (widget.controller.isOpen) {
      _show();
    } else {
      _hide();
    }
  }

  void _show() {
    if (_entry != null) {
      _openController.forward();
      return;
    }

    _refreshAnchorSnapshotIfNeeded();

    final overlay = Overlay.of(context, rootOverlay: widget.useRootOverlay);

    _entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _openController,
          builder: (context, _) {
            return _OverlayContent(
              link: _link,
              anchorKey: _anchorKey,
              resolver: _resolver,
              style: widget.style,
              openCurve: _openCurve,
              expandFromAnchor: widget.expandFromAnchor,
              anchorSnapshot: _anchorSnapshot,
              closeOnScroll: widget.closeOnScroll,
              desiredPanelWidth: widget.panelWidth,
              desiredPanelHeight: widget.panelHeight,
              panelChild: widget.panelChild,
              placement: widget.placement,
              gap: widget.gap,
              overlayPadding: widget.overlayPadding,
              onCloseRequest: () => widget.controller.close(),
              onBarrierTap: widget.style.barrierDismissible
                  ? () => widget.controller.close()
                  : null,
            );
          },
        );
      },
    );

    overlay.insert(_entry!);

    _openController.forward();

    _attachCloseOnScrollIfNeeded();
  }

  void _hide() {
    _removeScrollListener?.call();
    _removeScrollListener = null;

    if (_entry == null) return;

    _openController.reverse().whenComplete(() {
      if (!mounted) return;
      if (widget.controller.isOpen) return;
      _removeEntry();
    });
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  void _refreshAnchorSnapshotIfNeeded() {
    if (!widget.expandFromAnchor) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!widget.controller.isOpen) return;

      final boundaryContext = _anchorRepaintKey.currentContext;
      if (boundaryContext == null) return;

      final boundary = boundaryContext.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;
      if (boundary.debugNeedsPaint) return;

      try {
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final uiImage = await boundary.toImage(pixelRatio: pixelRatio);

        _anchorSnapshot?.dispose();
        _anchorSnapshot = uiImage;

        // Rebuild overlay to show the snapshot.
        _entry?.markNeedsBuild();
      } catch (_) {
        // Snapshot is a best-effort visual enhancement.
      }
    });
  }

  void _attachCloseOnScrollIfNeeded() {
    if (!widget.closeOnScroll) return;

    final scrollable = Scrollable.maybeOf(context);
    final position = scrollable?.position;
    if (position == null) return;

    void listener() {
      if (!widget.controller.isOpen) return;
      // Close on any active scroll activity.
      if (position.isScrollingNotifier.value) {
        widget.controller.close();
      }
    }

    position.isScrollingNotifier.addListener(listener);
    _removeScrollListener = () {
      position.isScrollingNotifier.removeListener(listener);
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final hideAnchor = widget.expandFromAnchor && widget.controller.isOpen;

        final anchorChild =
            widget.anchorBuilder?.call(context, widget.controller.toggle) ??
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.controller.toggle,
              child: widget.child,
            );

        return CompositedTransformTarget(
          link: _link,
          child: RepaintBoundary(
            key: _anchorRepaintKey,
            child: KeyedSubtree(
              key: _anchorKey,
              child: IgnorePointer(
                ignoring: hideAnchor,
                child: Opacity(opacity: hideAnchor ? 0 : 1, child: anchorChild),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverlayContent extends StatelessWidget {
  final LayerLink link;
  final GlobalKey anchorKey;
  final FloatingMenuAnchoredOverlayPlacementResolver resolver;
  final FloatingMenuAnchoredOverlayStyle style;
  final Animation<double> openCurve;
  final bool expandFromAnchor;
  final ui.Image? anchorSnapshot;
  final bool closeOnScroll;
  final double desiredPanelWidth;
  final double desiredPanelHeight;
  final Widget panelChild;
  final FloatingMenuAnchoredOverlayPlacement placement;
  final double gap;
  final EdgeInsetsGeometry overlayPadding;
  final VoidCallback onCloseRequest;
  final VoidCallback? onBarrierTap;

  const _OverlayContent({
    required this.link,
    required this.anchorKey,
    required this.resolver,
    required this.style,
    required this.openCurve,
    required this.expandFromAnchor,
    required this.anchorSnapshot,
    required this.closeOnScroll,
    required this.desiredPanelWidth,
    required this.desiredPanelHeight,
    required this.panelChild,
    required this.placement,
    required this.gap,
    required this.overlayPadding,
    required this.onCloseRequest,
    required this.onBarrierTap,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: openCurve.value == 0,
      child: Stack(
        children: [
          if (style.showBarrierWhenOpen)
            Positioned.fill(
              child: GestureDetector(
                key: const Key('floating_menu_anchored_overlay_barrier'),
                behavior: HitTestBehavior.opaque,
                onTap: onBarrierTap,
                onPanStart: closeOnScroll ? (_) => onCloseRequest() : null,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: style.barrierBlurSigmaX,
                    sigmaY: style.barrierBlurSigmaY,
                  ),
                  child: ColoredBox(color: style.barrierColor),
                ),
              ),
            ),
          _buildPanelFollower(context),
        ],
      ),
    );
  }

  Widget _buildPanelFollower(BuildContext context) {
    final t = openCurve.value;

    final anchorContext = anchorKey.currentContext;
    if (anchorContext == null) return const SizedBox.shrink();

    final box = anchorContext.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return const SizedBox.shrink();

    final overlayBox = Overlay.of(context).context.findRenderObject();
    if (overlayBox is! RenderBox || !overlayBox.hasSize) {
      return const SizedBox.shrink();
    }

    final textDirection = Directionality.of(context);
    final anchorTopLeft = box.localToGlobal(Offset.zero);
    final anchorRect = anchorTopLeft & box.size;
    final overlaySize = overlayBox.size;

    // Physical screen side (not text direction). Used to decide horizontal
    // expansion direction when expandFromAnchor is enabled.
    final pinToRight = anchorRect.center.dx > (overlaySize.width / 2);

    final safe = MediaQuery.paddingOf(context);
    final extra = overlayPadding.resolve(textDirection);
    final safeArea = EdgeInsets.only(
      left: safe.left + extra.left,
      top: safe.top + extra.top,
      right: safe.right + extra.right,
      bottom: safe.bottom + extra.bottom,
    );

    final leftLimit = safeArea.left;
    final topLimit = safeArea.top;
    final rightLimit = overlaySize.width - safeArea.right;
    final bottomLimit = overlaySize.height - safeArea.bottom;

    final resolved = resolver.resolve(
      placement: placement,
      textDirection: textDirection,
      anchorRect: anchorRect,
      overlaySize: overlaySize,
      safeArea: safeArea,
      gap: gap,
      desiredPanelWidth: desiredPanelWidth,
      desiredPanelHeight: desiredPanelHeight,
    );

    final anchorW = box.size.width;
    final anchorH = box.size.height;

    final resolvedPlacement = resolved.placement;

    final maxW = _maxWidthFor(
      resolved: resolved,
      resolvedPlacement: resolvedPlacement,
      textDirection: textDirection,
      anchorW: anchorW,
      anchorH: anchorH,
      gap: gap,
    );
    final maxH = _maxHeightFor(
      resolved: resolved,
      resolvedPlacement: resolvedPlacement,
      textDirection: textDirection,
      anchorW: anchorW,
      anchorH: anchorH,
      gap: gap,
    );

    double targetW = desiredPanelWidth.clamp(0.0, maxW);
    double targetH = desiredPanelHeight.clamp(0.0, maxH);

    if (expandFromAnchor) {
      // Ensure the expanded panel is at least as large as the anchor.
      targetW = targetW < anchorW ? anchorW : targetW;
      targetH = targetH < anchorH ? anchorH : targetH;
    }

    if (targetW <= 0 || targetH <= 0) return const SizedBox.shrink();

    final anchors = expandFromAnchor
        ? _anchorsForExpandFromAnchor(
            placement: resolvedPlacement,
            pinToRight: pinToRight,
          )
        : _anchorsForPlacement(
            placement: resolvedPlacement,
            textDirection: textDirection,
          );

    final offset = expandFromAnchor
        ? Offset.zero
        : _offsetForPlacement(
            placement: resolvedPlacement,
            textDirection: textDirection,
            gap: gap,
          );

    final baseTopLeft = _panelTopLeftFor(
      placement: resolvedPlacement,
      anchorRect: anchorRect,
      panelWidth: targetW,
      panelHeight: targetH,
      gap: gap,
      expandFromAnchor: expandFromAnchor,
      pinToRight: pinToRight,
    );

    final clampedTopLeft = Offset(
      baseTopLeft.dx.clamp(
        leftLimit,
        (rightLimit - targetW).clamp(leftLimit, rightLimit),
      ),
      baseTopLeft.dy.clamp(
        topLimit,
        (bottomLimit - targetH).clamp(topLimit, bottomLimit),
      ),
    );

    final clampDelta = clampedTopLeft - baseTopLeft;
    final followerOffset = offset + clampDelta;

    final animatedW = expandFromAnchor
        ? ui.lerpDouble(anchorW, targetW, t)!
        : targetW * t;
    final animatedH = expandFromAnchor
        ? ui.lerpDouble(anchorH, targetH, t)!
        : targetH * t;

    final content = (expandFromAnchor && anchorSnapshot != null)
        ? _buildExpandedContentWithSnapshot(
            t: t,
            placement: resolvedPlacement,
            pinToRight: pinToRight,
            targetW: targetW,
            targetH: targetH,
            anchorW: anchorW,
            anchorH: anchorH,
            child: panelChild,
          )
        : panelChild;

    final panel = SizedBox(
      key: const Key('floating_menu_anchored_overlay_panel'),
      width: animatedW,
      height: animatedH,
      child: ClipRect(
        child: Align(
          alignment: expandFromAnchor
              ? _panelAlignForExpandFromAnchor(
                  placement: resolvedPlacement,
                  pinToRight: pinToRight,
                )
              : _panelAlignForPlacement(resolvedPlacement, textDirection),
          child: OverflowBox(
            minWidth: targetW,
            maxWidth: targetW,
            minHeight: targetH,
            maxHeight: targetH,
            child: ClipRRect(
              borderRadius: style.panelBorderRadius,
              clipBehavior: style.panelClipBehavior,
              child: DecoratedBox(
                decoration: style.panelDecoration ?? const BoxDecoration(),
                child: SizedBox(
                  width: targetW,
                  height: targetH,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return CompositedTransformFollower(
      link: link,
      showWhenUnlinked: false,
      targetAnchor: anchors.targetAnchor,
      followerAnchor: anchors.followerAnchor,
      offset: followerOffset,
      child: FadeTransition(opacity: openCurve, child: panel),
    );
  }

  Offset _panelTopLeftFor({
    required FloatingMenuAnchoredOverlayPlacement placement,
    required Rect anchorRect,
    required double panelWidth,
    required double panelHeight,
    required double gap,
    required bool expandFromAnchor,
    required bool pinToRight,
  }) {
    switch (placement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        // Bottom placement: panel sits below the anchor in popover mode,
        // or grows from the anchor edge in expand mode.
        final top = expandFromAnchor
            ? anchorRect.top
            : (anchorRect.bottom + gap);
        final left = expandFromAnchor
            ? (pinToRight ? (anchorRect.right - panelWidth) : anchorRect.left)
            : anchorRect.left;
        return Offset(left, top);

      case FloatingMenuAnchoredOverlayPlacement.top:
        // Top placement: panel sits above the anchor in popover mode,
        // or grows upward from the anchor edge in expand mode.
        final top = expandFromAnchor
            ? (anchorRect.bottom - panelHeight)
            : (anchorRect.top - gap - panelHeight);
        final left = expandFromAnchor
            ? (pinToRight ? (anchorRect.right - panelWidth) : anchorRect.left)
            : anchorRect.left;
        return Offset(left, top);

      case FloatingMenuAnchoredOverlayPlacement.start:
        // Start placement: panel is to the start side in popover mode,
        // or grows towards start while keeping the opposite edge pinned.
        if (!expandFromAnchor) {
          final center = anchorRect.centerLeft + Offset(-gap, 0);
          return Offset(
            center.dx - (panelWidth / 2),
            center.dy - (panelHeight / 2),
          );
        }

        // Expand horizontally from the anchor side.
        final top = anchorRect.center.dy - (panelHeight / 2);
        final left = pinToRight
            ? (anchorRect.right - panelWidth)
            : anchorRect.left;
        return Offset(left, top);

      case FloatingMenuAnchoredOverlayPlacement.end:
        if (!expandFromAnchor) {
          final center = anchorRect.centerRight + Offset(gap, 0);
          return Offset(
            center.dx - (panelWidth / 2),
            center.dy - (panelHeight / 2),
          );
        }

        final top = anchorRect.center.dy - (panelHeight / 2);
        final left = pinToRight
            ? (anchorRect.right - panelWidth)
            : anchorRect.left;
        return Offset(left, top);
    }
  }

  _FollowerAnchors _anchorsForPlacement({
    required FloatingMenuAnchoredOverlayPlacement placement,
    required TextDirection textDirection,
  }) {
    final start = textDirection == TextDirection.ltr
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final end = textDirection == TextDirection.ltr
        ? Alignment.centerRight
        : Alignment.centerLeft;

    switch (placement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
        return const _FollowerAnchors(
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
        );
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        return textDirection == TextDirection.ltr
            ? const _FollowerAnchors(
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
              )
            : const _FollowerAnchors(
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
              );
      case FloatingMenuAnchoredOverlayPlacement.top:
        return textDirection == TextDirection.ltr
            ? const _FollowerAnchors(
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.bottomLeft,
              )
            : const _FollowerAnchors(
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.bottomRight,
              );
      case FloatingMenuAnchoredOverlayPlacement.start:
        return _FollowerAnchors(targetAnchor: start, followerAnchor: end);
      case FloatingMenuAnchoredOverlayPlacement.end:
        return _FollowerAnchors(targetAnchor: end, followerAnchor: start);
    }
  }

  _FollowerAnchors _anchorsForExpandFromAnchor({
    required FloatingMenuAnchoredOverlayPlacement placement,
    required bool pinToRight,
  }) {
    switch (placement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        return pinToRight
            ? const _FollowerAnchors(
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.topRight,
              )
            : const _FollowerAnchors(
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.topLeft,
              );
      case FloatingMenuAnchoredOverlayPlacement.top:
        return pinToRight
            ? const _FollowerAnchors(
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.bottomRight,
              )
            : const _FollowerAnchors(
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.bottomLeft,
              );
      case FloatingMenuAnchoredOverlayPlacement.start:
      case FloatingMenuAnchoredOverlayPlacement.end:
        // Expand horizontally from the anchor's physical side.
        return pinToRight
            ? const _FollowerAnchors(
                targetAnchor: Alignment.centerRight,
                followerAnchor: Alignment.centerRight,
              )
            : const _FollowerAnchors(
                targetAnchor: Alignment.centerLeft,
                followerAnchor: Alignment.centerLeft,
              );
    }
  }

  Widget _buildExpandedContentWithSnapshot({
    required double t,
    required FloatingMenuAnchoredOverlayPlacement placement,
    required bool pinToRight,
    required double targetW,
    required double targetH,
    required double anchorW,
    required double anchorH,
    required Widget child,
  }) {
    final snapshot = anchorSnapshot;
    if (snapshot == null) return child;

    final snapOpacity = (1 - t).clamp(0.0, 1.0);
    final anchorOffset = _anchorOffsetInsideExpandedPanel(
      placement: placement,
      pinToRight: pinToRight,
      targetW: targetW,
      targetH: targetH,
      anchorW: anchorW,
      anchorH: anchorH,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (snapOpacity > 0)
          Positioned(
            left: anchorOffset.dx,
            top: anchorOffset.dy,
            width: anchorW,
            height: anchorH,
            child: IgnorePointer(
              child: Opacity(
                opacity: snapOpacity,
                child: RawImage(image: snapshot, fit: BoxFit.fill),
              ),
            ),
          ),
      ],
    );
  }

  Offset _anchorOffsetInsideExpandedPanel({
    required FloatingMenuAnchoredOverlayPlacement placement,
    required bool pinToRight,
    required double targetW,
    required double targetH,
    required double anchorW,
    required double anchorH,
  }) {
    final dx = pinToRight ? (targetW - anchorW) : 0.0;

    switch (placement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        return Offset(dx, 0);
      case FloatingMenuAnchoredOverlayPlacement.top:
        return Offset(dx, targetH - anchorH);
      case FloatingMenuAnchoredOverlayPlacement.start:
      case FloatingMenuAnchoredOverlayPlacement.end:
        return Offset(dx, (targetH - anchorH) / 2);
    }
  }

  Alignment _panelAlignForExpandFromAnchor({
    required FloatingMenuAnchoredOverlayPlacement placement,
    required bool pinToRight,
  }) {
    switch (placement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        return pinToRight ? Alignment.topRight : Alignment.topLeft;
      case FloatingMenuAnchoredOverlayPlacement.top:
        return pinToRight ? Alignment.bottomRight : Alignment.bottomLeft;
      case FloatingMenuAnchoredOverlayPlacement.start:
      case FloatingMenuAnchoredOverlayPlacement.end:
        return pinToRight ? Alignment.centerRight : Alignment.centerLeft;
    }
  }

  double _maxWidthFor({
    required FloatingMenuAnchoredOverlayResolvedPlacement resolved,
    required FloatingMenuAnchoredOverlayPlacement resolvedPlacement,
    required TextDirection textDirection,
    required double anchorW,
    required double anchorH,
    required double gap,
  }) {
    if (!expandFromAnchor) return resolved.maxWidth;

    switch (resolvedPlacement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
      case FloatingMenuAnchoredOverlayPlacement.top:
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        // Width is already full available width.
        return resolved.maxWidth;
      case FloatingMenuAnchoredOverlayPlacement.start:
      case FloatingMenuAnchoredOverlayPlacement.end:
        // Convert "available side space" into "available from anchor edge".
        return resolved.maxWidth + anchorW + gap;
    }
  }

  double _maxHeightFor({
    required FloatingMenuAnchoredOverlayResolvedPlacement resolved,
    required FloatingMenuAnchoredOverlayPlacement resolvedPlacement,
    required TextDirection textDirection,
    required double anchorW,
    required double anchorH,
    required double gap,
  }) {
    if (!expandFromAnchor) return resolved.maxHeight;

    switch (resolvedPlacement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
      case FloatingMenuAnchoredOverlayPlacement.start:
      case FloatingMenuAnchoredOverlayPlacement.end:
        // Height is already full available height.
        return resolved.maxHeight;
      case FloatingMenuAnchoredOverlayPlacement.top:
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        // Convert "available vertical space" into "available from anchor edge".
        return resolved.maxHeight + anchorH + gap;
    }
  }

  Offset _offsetForPlacement({
    required FloatingMenuAnchoredOverlayPlacement placement,
    required TextDirection textDirection,
    required double gap,
  }) {
    final isLtr = textDirection == TextDirection.ltr;

    switch (placement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
        return Offset(0, gap);
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        return Offset(0, gap);
      case FloatingMenuAnchoredOverlayPlacement.top:
        return Offset(0, -gap);
      case FloatingMenuAnchoredOverlayPlacement.start:
        return Offset(isLtr ? -gap : gap, 0);
      case FloatingMenuAnchoredOverlayPlacement.end:
        return Offset(isLtr ? gap : -gap, 0);
    }
  }

  Alignment _panelAlignForPlacement(
    FloatingMenuAnchoredOverlayPlacement placement,
    TextDirection textDirection,
  ) {
    final start = textDirection == TextDirection.ltr
        ? Alignment.topLeft
        : Alignment.topRight;
    final end = textDirection == TextDirection.ltr
        ? Alignment.topRight
        : Alignment.topLeft;

    switch (placement) {
      case FloatingMenuAnchoredOverlayPlacement.auto:
      case FloatingMenuAnchoredOverlayPlacement.bottom:
        return start;
      case FloatingMenuAnchoredOverlayPlacement.top:
        return start;
      case FloatingMenuAnchoredOverlayPlacement.start:
        return end;
      case FloatingMenuAnchoredOverlayPlacement.end:
        return start;
    }
  }
}

class _FollowerAnchors {
  final Alignment targetAnchor;
  final Alignment followerAnchor;

  const _FollowerAnchors({
    required this.targetAnchor,
    required this.followerAnchor,
  });
}
