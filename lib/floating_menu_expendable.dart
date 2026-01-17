library;

import 'dart:ui';

import 'package:flutter/material.dart';

export 'src/floating_menu_anchored_overlay.dart';

part 'floating_menu_expendable_controller.dart';
part 'floating_menu_expendable_style.dart';

enum FloatingMenuExpendableOpenMode {
  /// يفتح اللوحة من الجانب (يمين/يسار) حسب الدوك و RTL/LTR.
  side,

  /// يفتح اللوحة أسفل المقبض، وإذا كان المقبض قريبًا من أسفل الشاشة يفتح للأعلى.
  vertical,
}

enum _DockSideDirectional { start, end }

class FloatingMenuExpendable extends StatefulWidget {
  final FloatingMenuExpendableController controller;

  /// Visual customization for the panel/handle/barrier.
  final FloatingMenuExpendableStyle style;

  /// العرض النهائي للمحتوى عند الفتح.
  final double panelWidth;

  /// الارتفاع النهائي للمحتوى عند الفتح.
  final double panelHeight;

  /// الويدجت التي تظهر داخل اللوحة عند الفتح.
  final Widget panelChild;

  /// زر/مقبض اللوحة الذي يبقى دائمًا ظاهرًا.
  final Widget handleChild;

  /// When true, the panel expands as part of the handle container
  /// (a single unified widget), instead of being a separate sibling widget.
  ///
  /// This is useful when you want the handle itself to "expand" into the panel.
  final bool expandPanelFromHandle;

  /// Optional widget to show inside the handle while the panel is open.
  /// If null, a default close icon is used.
  final Widget? handleOpenChild;

  /// حجم زر/مقبض اللوحة.
  final double handleHeight;
  final double handleWidth;

  /// الهامش الأدنى عن حواف الشاشة.
  final EdgeInsetsGeometry screenPadding;

  /// الموضع الابتدائي (Top-Left) قبل الدوك.
  final Offset initialPosition;

  final Duration animationDuration;
  final Curve animationCurve;

  /// هل يبدأ ملاصقًا لحافة البداية (start)؟
  /// start = يسار في LTR، يمين في RTL.
  final bool dockToStartInitially;

  /// طريقة فتح اللوحة: جانبي (افتراضي) أو عمودي.
  final FloatingMenuExpendableOpenMode openMode;

  const FloatingMenuExpendable({
    super.key,
    required this.controller,
    required this.panelWidth,
    required this.panelHeight,
    required this.panelChild,
    required this.handleChild,
    this.expandPanelFromHandle = false,
    this.handleOpenChild,
    this.style = const FloatingMenuExpendableStyle(),
    this.handleWidth = 52,
    this.handleHeight = 52,
    this.screenPadding = const EdgeInsetsDirectional.only(
      start: 12,
      top: 12,
      end: 12,
      bottom: 12,
    ),
    this.initialPosition = const Offset(12, 150),
    this.animationDuration = const Duration(milliseconds: 220),
    this.animationCurve = Curves.easeOut,
    this.dockToStartInitially = true,
    this.openMode = FloatingMenuExpendableOpenMode.side,
  });

  @override
  State<FloatingMenuExpendable> createState() => _FloatingMenuExpendableState();
}

class _FloatingMenuExpendableState extends State<FloatingMenuExpendable>
    with SingleTickerProviderStateMixin {
  late Offset _position;
  late _DockSideDirectional _dockSide;
  bool _isDragging = false;
  bool _isDocked = true;

  Offset? _lastDragGlobalPosition;

  double _layoutPanelWidth = 0;
  double _layoutPanelHeight = 0;

  late final AnimationController _openController;
  late Animation<double> _openCurve;

  // يمنع أنيميشن الموضع لفريم واحد عند اكتمال الفتح/الإغلاق لتفادي "حركة" مفاجئة
  // ناتجة عن تغيّر العرض/الارتفاع في نفس الفريم.
  bool _suppressPositionAnimationOnce = false;

  bool _verticalOpensUp = false;
  bool _lastIsOpen = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _dockSide = widget.dockToStartInitially
        ? _DockSideDirectional.start
        : _DockSideDirectional.end;

    _openController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: widget.controller.isOpen ? 1.0 : 0.0,
    );
    _openCurve = CurvedAnimation(
      parent: _openController,
      curve: widget.animationCurve,
    );
    _openController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    _openController.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _suppressPositionAnimationOnce = true;
      }
    });

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant FloatingMenuExpendable oldWidget) {
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
    _openController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    if (widget.controller.isOpen) {
      _openController.forward();
    } else {
      _openController.reverse();
    }

    setState(() {});
  }

  EdgeInsets _resolvedPadding(BuildContext context) {
    final padding = widget.screenPadding;
    final direction = Directionality.of(context);
    return padding.resolve(direction);
  }

  double _currentWidth() {
    final t = _openCurve.value;
    if (widget.openMode == FloatingMenuExpendableOpenMode.vertical) {
      // عمودي: عند الإغلاق لا يظهر إلا المقبض، لذا نسمح له بالتحرك أفقيًا
      // بحسب عرض المقبض فقط.
      // عند الفتح (t > 0) تصبح اللوحة مرئية بعرضها الكامل.
      if (widget.expandPanelFromHandle) {
        final targetWidth = (_layoutPanelWidth > widget.handleWidth)
            ? _layoutPanelWidth
            : widget.handleWidth;
        return widget.handleWidth + ((targetWidth - widget.handleWidth) * t);
      }

      if (t == 0) return widget.handleWidth;
      return (_layoutPanelWidth > widget.handleWidth)
          ? _layoutPanelWidth
          : widget.handleWidth;
    }

    final panelWidth = _layoutPanelWidth * t;
    return widget.handleWidth + panelWidth;
  }

  double _currentHeight() {
    final t = _openCurve.value;
    if (widget.openMode == FloatingMenuExpendableOpenMode.vertical) {
      return widget.handleHeight + (_layoutPanelHeight * t);
    }

    return widget.controller.isOpen
        ? (_layoutPanelHeight > widget.handleHeight
              ? _layoutPanelHeight
              : widget.handleHeight)
        : widget.handleHeight;
  }

  Offset _clampPosition({
    required BuildContext context,
    required BoxConstraints constraints,
    required Offset position,
  }) {
    final padding = _resolvedPadding(context);
    // في الوضع العمودي نعامل position.dx كموضع المقبض، لذا نقيد X بعرض المقبض
    // حتى لو كان عرض اللوحة أكبر عند الفتح.
    final width = widget.openMode == FloatingMenuExpendableOpenMode.vertical
        ? widget.handleWidth
        : _currentWidth();
    final height = _currentHeight();

    final minX = padding.left;
    final maxX = (constraints.maxWidth - width - padding.right).clamp(
      minX,
      double.infinity,
    );

    final minY = padding.top;
    double maxY = (constraints.maxHeight - height - padding.bottom).clamp(
      minY,
      double.infinity,
    );

    // في الوضع العمودي عند الفتح للأعلى: نعامل position.dy كموضع المقبض (وليس أعلى الكونتينر)
    // لأن أعلى الكونتينر سيتحرك مع t للحفاظ على ثبات المقبض بصريًا.
    if (widget.openMode == FloatingMenuExpendableOpenMode.vertical &&
        _verticalOpensUp) {
      final t = _openCurve.value;
      final minHandleY = (padding.top + (_layoutPanelHeight * t)).clamp(
        padding.top,
        double.infinity,
      );
      final maxHandleY =
          (constraints.maxHeight - widget.handleHeight - padding.bottom).clamp(
            minHandleY,
            double.infinity,
          );
      return Offset(
        position.dx.clamp(minX, maxX),
        position.dy.clamp(minHandleY, maxHandleY),
      );
    }

    return Offset(position.dx.clamp(minX, maxX), position.dy.clamp(minY, maxY));
  }

  void _snapToNearestEdge({
    required BuildContext context,
    required BoxConstraints constraints,
  }) {
    final padding = _resolvedPadding(context);
    final isVertical =
        widget.openMode == FloatingMenuExpendableOpenMode.vertical;
    final widthForSnap = isVertical ? widget.handleWidth : _currentWidth();

    final leftEdgeX = padding.left;
    final rightEdgeX = (constraints.maxWidth - widthForSnap - padding.right)
        .clamp(leftEdgeX, double.infinity);

    bool snappedToLeft;

    // إذا كان الكونتينر لا يمكنه التحرك أفقيًا (مثلاً لأن العرض يملأ الشاشة)
    // فالمقارنة بالمسافة إلى الحواف ستعطي دائمًا نفس النتيجة.
    // عندها نحدد الجهة بناءً على مكان السحب الأخير.
    if ((rightEdgeX - leftEdgeX).abs() < 0.5 &&
        _lastDragGlobalPosition != null) {
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox) {
        final local = renderObject.globalToLocal(_lastDragGlobalPosition!);
        snappedToLeft = local.dx <= (constraints.maxWidth / 2);
      } else {
        snappedToLeft = true;
      }
    } else {
      final distanceToLeft = (_position.dx - leftEdgeX).abs();
      final distanceToRight = (_position.dx - rightEdgeX).abs();
      snappedToLeft = distanceToLeft <= distanceToRight;
    }

    final direction = Directionality.of(context);
    final dockSide = _dockSideFromPhysicalEdge(
      direction: direction,
      snappedToLeft: snappedToLeft,
    );

    final snappedX = snappedToLeft ? leftEdgeX : rightEdgeX;

    setState(() {
      _isDocked = true;
      _dockSide = dockSide;
      _position = Offset(snappedX, _position.dy);
    });
  }

  _DockSideDirectional _dockSideFromPhysicalEdge({
    required TextDirection direction,
    required bool snappedToLeft,
  }) {
    // في LTR: اليسار = start، اليمين = end
    // في RTL: اليمين = start، اليسار = end
    if (direction == TextDirection.ltr) {
      return snappedToLeft
          ? _DockSideDirectional.start
          : _DockSideDirectional.end;
    }
    return snappedToLeft
        ? _DockSideDirectional.end
        : _DockSideDirectional.start;
  }

  Widget _buildHandle(BuildContext context) {
    final isOpen = widget.controller.isOpen;
    final openChild = widget.handleOpenChild ?? const Icon(Icons.close_rounded);
    return SizedBox(
      key: const Key('floating_menu_panel_handle'),
      width: widget.handleWidth,
      height: widget.handleHeight,
      child: Material(
        color: widget.style.handleMaterialColor,
        child: InkWell(
          onTap: widget.controller.toggle,
          customBorder: widget.style.handleInkCustomBorder,
          borderRadius: widget.style.handleInkCustomBorder == null
              ? widget.style.handleInkBorderRadius
              : null,
          splashColor: widget.style.handleSplashColor,
          highlightColor: widget.style.handleHighlightColor,
          overlayColor: widget.style.handleOverlayColor,
          child: Center(
            child: AnimatedSwitcher(
              duration: widget.animationDuration,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              child: KeyedSubtree(
                key: ValueKey<bool>(isOpen),
                child: isOpen ? openChild : widget.handleChild,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandFromHandleLayout({
    required BuildContext context,
    required double t,
    required bool dockOnPhysicalLeft,
    required bool panelAndHandleInRow,
    required Widget handle,
  }) {
    final isOpen = widget.controller.isOpen;

    Widget buildPanelSlice() {
      // When closed, keep the slice fully collapsed so the unified container
      // matches the handle size.
      if (!isOpen && t == 0) return const SizedBox.shrink();

      if (panelAndHandleInRow) {
        final expandToRight = dockOnPhysicalLeft;
        final alignment = expandToRight
            ? Alignment.centerLeft
            : Alignment.centerRight;

        final targetHeight = (_layoutPanelHeight > widget.handleHeight)
            ? _layoutPanelHeight
            : widget.handleHeight;
        final animatedHeight =
            widget.handleHeight + ((targetHeight - widget.handleHeight) * t);
        final animatedWidth = _layoutPanelWidth * t;

        return SizedBox(
          width: animatedWidth,
          height: animatedHeight,
          child: ClipRect(
            child: Align(
              alignment: alignment,
              child: OverflowBox(
                minWidth: _layoutPanelWidth,
                maxWidth: _layoutPanelWidth,
                minHeight: _layoutPanelHeight,
                maxHeight: _layoutPanelHeight,
                child: SizedBox(
                  width: _layoutPanelWidth,
                  height: _layoutPanelHeight,
                  child: widget.panelChild,
                ),
              ),
            ),
          ),
        );
      }

      // Vertical: animate height AND width (so it doesn't jump to full width
      // the moment t becomes > 0).
      final targetWidth = (_layoutPanelWidth > widget.handleWidth)
          ? _layoutPanelWidth
          : widget.handleWidth;
      final animatedWidth =
          widget.handleWidth + ((targetWidth - widget.handleWidth) * t);
      final animatedHeight = _layoutPanelHeight * t;

      final expandDown = !_verticalOpensUp;
      final alignment = expandDown
          ? Alignment.topCenter
          : Alignment.bottomCenter;

      return SizedBox(
        width: animatedWidth,
        height: animatedHeight,
        child: ClipRect(
          child: Align(
            alignment: alignment,
            child: OverflowBox(
              minWidth: _layoutPanelWidth,
              maxWidth: _layoutPanelWidth,
              minHeight: _layoutPanelHeight,
              maxHeight: _layoutPanelHeight,
              child: SizedBox(
                width: _layoutPanelWidth,
                height: _layoutPanelHeight,
                child: widget.panelChild,
              ),
            ),
          ),
        ),
      );
    }

    final panelSlice = buildPanelSlice();

    final children = <Widget>[];
    if (panelAndHandleInRow) {
      final showPanelFirst = dockOnPhysicalLeft ? false : true;
      if (showPanelFirst) {
        children.add(panelSlice);
        children.add(handle);
      } else {
        children.add(handle);
        children.add(panelSlice);
      }
    } else {
      if (_verticalOpensUp) {
        children.add(panelSlice);
        children.add(handle);
      } else {
        children.add(handle);
        children.add(panelSlice);
      }
    }

    return ClipRRect(
      borderRadius: widget.style.panelBorderRadius,
      clipBehavior: widget.style.panelClipBehavior,
      child: DecoratedBox(
        decoration: widget.style.panelDecoration ?? const BoxDecoration(),
        child: panelAndHandleInRow
            ? Row(mainAxisSize: MainAxisSize.min, children: children)
            : Column(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                crossAxisAlignment: dockOnPhysicalLeft
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: children,
              ),
      ),
    );
  }

  Widget _buildPanelContainer(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.style.panelBorderRadius,
      clipBehavior: widget.style.panelClipBehavior,
      child: DecoratedBox(
        decoration: widget.style.panelDecoration ?? const BoxDecoration(),
        child: widget.panelChild,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Barrier ضبابي يغطي كامل الشاشة
        if (widget.controller.isOpen && widget.style.showBarrierWhenOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.style.barrierDismissible
                  ? () => widget.controller.close()
                  : null,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.style.barrierBlurSigmaX,
                  sigmaY: widget.style.barrierBlurSigmaY,
                ),
                child: Container(color: widget.style.barrierColor),
              ),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isRtl = Directionality.of(context) == TextDirection.rtl;

            final padding = _resolvedPadding(context);
            final maxInsideWidth =
                (constraints.maxWidth - padding.left - padding.right).clamp(
                  0.0,
                  double.infinity,
                );
            final maxInsideHeight =
                (constraints.maxHeight - padding.top - padding.bottom).clamp(
                  0.0,
                  double.infinity,
                );

            final maxPanelWidth =
                widget.openMode == FloatingMenuExpendableOpenMode.side
                ? (maxInsideWidth - widget.handleWidth).clamp(
                    0.0,
                    double.infinity,
                  )
                : maxInsideWidth;
            final maxPanelHeight =
                widget.openMode == FloatingMenuExpendableOpenMode.vertical
                ? (maxInsideHeight - widget.handleHeight).clamp(
                    0.0,
                    double.infinity,
                  )
                : maxInsideHeight;

            _layoutPanelWidth = widget.panelWidth.clamp(0.0, maxPanelWidth);
            _layoutPanelHeight = widget.panelHeight.clamp(0.0, maxPanelHeight);

            final isOpen = widget.controller.isOpen;
            final t = _openCurve.value;

            // عند الفتح العمودي، نقرر هل يفتح للأعلى أو للأسفل.
            // مهم: نجعل _position.dy هو موضع المقبض (anchor) دائمًا.
            // وعند الفتح للأعلى نحسب top ديناميكيًا بـ t حتى لا يتحرك المقبض أثناء الفتح/الإغلاق.
            if (widget.openMode == FloatingMenuExpendableOpenMode.vertical &&
                isOpen != _lastIsOpen) {
              if (isOpen) {
                final handleCenterY = _position.dy + (widget.handleHeight / 2);
                _verticalOpensUp = handleCenterY > (constraints.maxHeight / 2);
              }
              _lastIsOpen = isOpen;
            }

            if (_isDocked && !_isDragging) {
              // أبقِ اللوحة ملتصقة بالحافة (start/end) حتى لو تغيّر عرضها عند الفتح/الإغلاق.
              final width =
                  widget.openMode == FloatingMenuExpendableOpenMode.vertical
                  ? widget.handleWidth
                  : _currentWidth();
              final leftX = padding.left;
              final rightX = (constraints.maxWidth - width - padding.right)
                  .clamp(leftX, double.infinity);

              final dockOnPhysicalLeft = isRtl
                  ? (_dockSide == _DockSideDirectional.end)
                  : (_dockSide == _DockSideDirectional.start);

              _position = Offset(
                dockOnPhysicalLeft ? leftX : rightX,
                _position.dy,
              );
            }

            _position = _clampPosition(
              context: context,
              constraints: constraints,
              position: _position,
            );

            final handle = _buildHandle(context);

            final panel = (t == 0)
                ? const SizedBox.shrink()
                : ClipRect(
                    child: SizedBox(
                      key: const Key('floating_menu_panel_panel'),
                      width:
                          widget.openMode == FloatingMenuExpendableOpenMode.side
                          ? (_layoutPanelWidth * t)
                          : _layoutPanelWidth,
                      height:
                          widget.openMode ==
                              FloatingMenuExpendableOpenMode.vertical
                          ? (_layoutPanelHeight * t)
                          : _layoutPanelHeight,
                      child: _buildPanelContainer(context),
                    ),
                  );

            final dockOnPhysicalLeft = isRtl
                ? (_dockSide == _DockSideDirectional.end)
                : (_dockSide == _DockSideDirectional.start);

            final containerWidth = _currentWidth();

            final animatedTop =
                (widget.openMode == FloatingMenuExpendableOpenMode.vertical &&
                    _verticalOpensUp)
                ? (_position.dy - (_layoutPanelHeight * t))
                : _position.dy;

            // في الوضع العمودي: _position.dx يمثل موضع المقبض، ونحرّك left للكونتينر
            // عند الدوك يمينًا حتى يبقى المقبض ثابتًا أثناء تغيّر عرض الكونتينر.
            final animatedLeft =
                widget.openMode == FloatingMenuExpendableOpenMode.vertical
                ? (dockOnPhysicalLeft
                      ? _position.dx
                      : (_position.dx + widget.handleWidth - containerWidth))
                : _position.dx;

            // تحديث جهة المقبض أفقياً (left/right) كما هو متوقع من الاستخدام الحالي.
            // نستخدم الدوك عندما يكون مثبتًا لتجنب التذبذب أثناء أنيميشن الحجم.
            if (_isDocked) {
              widget.controller.updatePhysicalSide(
                dockOnPhysicalLeft
                    ? FloatingMenuPanelPhysicalSide.left
                    : FloatingMenuPanelPhysicalSide.right,
              );
            } else {
              final handleLeftX =
                  widget.openMode == FloatingMenuExpendableOpenMode.vertical
                  ? _position.dx
                  : _position.dx +
                        ((_dockSide == _DockSideDirectional.end)
                            ? (_layoutPanelWidth * t)
                            : 0);
              final handleCenterX = handleLeftX + (widget.handleWidth / 2);
              widget.controller.updatePhysicalSide(
                handleCenterX <= (constraints.maxWidth / 2)
                    ? FloatingMenuPanelPhysicalSide.left
                    : FloatingMenuPanelPhysicalSide.right,
              );
            }

            // تحديث جهة المقبض عموديًا (top/bottom) في الوضع العمودي.
            if (widget.openMode == FloatingMenuExpendableOpenMode.vertical) {
              final handleCenterY = _position.dy + (widget.handleHeight / 2);
              widget.controller.updateVerticalSide(
                handleCenterY <= (constraints.maxHeight / 2)
                    ? FloatingMenuPanelPhysicalSide.top
                    : FloatingMenuPanelPhysicalSide.bottom,
              );
            }

            if (_suppressPositionAnimationOnce) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_suppressPositionAnimationOnce) {
                  setState(() => _suppressPositionAnimationOnce = false);
                }
              });
            }

            final children = <Widget>[];
            final panelAndHandleInRow =
                widget.openMode == FloatingMenuExpendableOpenMode.side;

            if (!widget.expandPanelFromHandle) {
              if (panelAndHandleInRow) {
                final showPanelFirst = _dockSide == _DockSideDirectional.end;
                if (showPanelFirst) {
                  children.add(panel);
                  children.add(handle);
                } else {
                  children.add(handle);
                  children.add(panel);
                }
              } else {
                // عمودي: يفتح أسفل المقبض، وإذا كان المقبض قريبًا من الأسفل يفتح للأعلى.
                if (_verticalOpensUp) {
                  children.add(panel);
                  children.add(handle);
                } else {
                  children.add(handle);
                  children.add(panel);
                }
              }
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedPositioned(
                  // أثناء أنيميشن الفتح/الإغلاق، نقوم بتحديث الموضع في كل فريم لإبقاء
                  // اللوحة ملتصقة بالحافة. لو تركنا AnimatedPositioned يحرّك left/top
                  // في نفس الوقت سيظهر "اهتزاز" خصوصًا عند الدوك يمينًا.
                  duration:
                      (_isDragging ||
                          _openController.isAnimating ||
                          _suppressPositionAnimationOnce)
                      ? Duration.zero
                      : widget.animationDuration,
                  curve: widget.animationCurve,
                  left: animatedLeft,
                  top: animatedTop,
                  child: GestureDetector(
                    onPanStart: (_) {
                      setState(() {
                        _isDragging = true;
                        _isDocked = false;
                        _lastDragGlobalPosition = null;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _lastDragGlobalPosition = details.globalPosition;
                        _position = _clampPosition(
                          context: context,
                          constraints: constraints,
                          position: _position + details.delta,
                        );
                      });
                    },
                    onPanEnd: (_) {
                      setState(() => _isDragging = false);
                      _snapToNearestEdge(
                        context: context,
                        constraints: constraints,
                      );
                    },
                    child: panelAndHandleInRow
                        ? (widget.expandPanelFromHandle
                              ? _buildExpandFromHandleLayout(
                                  context: context,
                                  t: t,
                                  dockOnPhysicalLeft: dockOnPhysicalLeft,
                                  panelAndHandleInRow: true,
                                  handle: handle,
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: children,
                                ))
                        : (widget.expandPanelFromHandle
                              ? _buildExpandFromHandleLayout(
                                  context: context,
                                  t: t,
                                  dockOnPhysicalLeft: dockOnPhysicalLeft,
                                  panelAndHandleInRow: false,
                                  handle: handle,
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  // نثبت اتجاه الـ Flex هنا فقط حتى تكون start/end = يسار/يمين
                                  // بشكل فيزيائي، بدون التأثير على Directionality داخل الأبناء.
                                  textDirection: TextDirection.ltr,
                                  // عمودي: عند الدوك يسارًا نثبّت العناصر يسارًا، وعند الدوك
                                  // يمينًا نثبّتها يمينًا.
                                  crossAxisAlignment: dockOnPhysicalLeft
                                      ? CrossAxisAlignment.start
                                      : CrossAxisAlignment.end,
                                  children: children,
                                )),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
