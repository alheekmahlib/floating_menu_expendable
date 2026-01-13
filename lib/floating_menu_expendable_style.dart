part of 'floating_menu_expendable.dart';

@immutable
class FloatingMenuPanelStyle {
  /// Whether to show a blurred, colored barrier when the panel is open.
  final bool showBarrierWhenOpen;

  /// If true, tapping the barrier closes the panel.
  final bool barrierDismissible;

  /// Blur amount on X axis for the barrier.
  final double barrierBlurSigmaX;

  /// Blur amount on Y axis for the barrier.
  final double barrierBlurSigmaY;

  /// Color of the barrier overlay.
  final Color barrierColor;

  /// The panel corner radius.
  final BorderRadiusGeometry panelBorderRadius;

  /// Clip behavior used for the panel.
  final Clip panelClipBehavior;

  /// Optional decoration painted behind [FloatingMenuPanel.panelChild].
  ///
  /// If null, no decoration is painted.
  final Decoration? panelDecoration;

  /// Material color behind the handle (usually transparent).
  final Color handleMaterialColor;

  /// InkWell border radius for the handle.
  ///
  /// If [handleInkCustomBorder] is provided, it takes precedence.
  final BorderRadius? handleInkBorderRadius;

  /// InkWell custom border for the handle.
  final ShapeBorder? handleInkCustomBorder;

  /// Optional InkWell splash color for the handle.
  final Color? handleSplashColor;

  /// Optional InkWell highlight color for the handle.
  final Color? handleHighlightColor;

  /// Optional InkWell overlay color for the handle.
  final WidgetStateProperty<Color?>? handleOverlayColor;

  const FloatingMenuPanelStyle({
    this.showBarrierWhenOpen = true,
    this.barrierDismissible = true,
    this.barrierBlurSigmaX = 5,
    this.barrierBlurSigmaY = 5,
    this.barrierColor = const Color(0x4D000000),
    this.panelBorderRadius = const BorderRadius.all(Radius.circular(12)),
    this.panelClipBehavior = Clip.antiAlias,
    this.panelDecoration,
    this.handleMaterialColor = Colors.transparent,
    this.handleInkBorderRadius,
    this.handleInkCustomBorder,
    this.handleSplashColor,
    this.handleHighlightColor,
    this.handleOverlayColor,
  });

  FloatingMenuPanelStyle copyWith({
    bool? showBarrierWhenOpen,
    bool? barrierDismissible,
    double? barrierBlurSigmaX,
    double? barrierBlurSigmaY,
    Color? barrierColor,
    BorderRadiusGeometry? panelBorderRadius,
    Clip? panelClipBehavior,
    Decoration? panelDecoration,
    Color? handleMaterialColor,
    BorderRadius? handleInkBorderRadius,
    ShapeBorder? handleInkCustomBorder,
    Color? handleSplashColor,
    Color? handleHighlightColor,
    WidgetStateProperty<Color?>? handleOverlayColor,
  }) {
    return FloatingMenuPanelStyle(
      showBarrierWhenOpen: showBarrierWhenOpen ?? this.showBarrierWhenOpen,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      barrierBlurSigmaX: barrierBlurSigmaX ?? this.barrierBlurSigmaX,
      barrierBlurSigmaY: barrierBlurSigmaY ?? this.barrierBlurSigmaY,
      barrierColor: barrierColor ?? this.barrierColor,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      panelClipBehavior: panelClipBehavior ?? this.panelClipBehavior,
      panelDecoration: panelDecoration ?? this.panelDecoration,
      handleMaterialColor: handleMaterialColor ?? this.handleMaterialColor,
      handleInkBorderRadius:
          handleInkBorderRadius ?? this.handleInkBorderRadius,
      handleInkCustomBorder:
          handleInkCustomBorder ?? this.handleInkCustomBorder,
      handleSplashColor: handleSplashColor ?? this.handleSplashColor,
      handleHighlightColor: handleHighlightColor ?? this.handleHighlightColor,
      handleOverlayColor: handleOverlayColor ?? this.handleOverlayColor,
    );
  }
}
