// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

import 'animation.dart';
import 'bar_style.dart';
import 'destination.dart';
import 'item.dart';
import 'motion.dart';

/// Where the items of a [NavigationBar] place their label.
enum NavigationBarItemLayout {
  /// Below the icon, the items sharing the bar's width equally. For compact
  /// windows, narrower than 600dp.
  vertical,

  /// Beside the icon, inside the active indicator, the items centered as a
  /// group. For medium windows, 600dp to 839dp wide.
  horizontal,
}

/// A Material 3 Expressive navigation bar: three to five destinations at the
/// bottom of a compact or medium window.
///
/// Exactly one destination is selected at a time, given by [selectedIndex];
/// tapping another calls [onDestinationSelected]. The constructor is Flutter's
/// own [NavigationBar]'s, plus [itemLayout], [style] and [motion].
///
/// The bar never adapts itself to the window: it uses the [itemLayout] it is
/// given. Material 3 recommends horizontal items from 600dp:
///
/// ```dart
/// NavigationBar(
///   itemLayout: MediaQuery.sizeOf(context).width >= 600
///       ? NavigationBarItemLayout.horizontal
///       : NavigationBarItemLayout.vertical,
///   selectedIndex: _index,
///   onDestinationSelected: (index) => setState(() => _index = index),
///   destinations: const [
///     NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
///     NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
///     NavigationDestination(icon: Icon(Icons.person_outline), label: 'You'),
///   ],
/// )
/// ```
final class NavigationBar extends StatefulWidget {
  /// Creates a navigation bar.
  const NavigationBar({
    super.key,
    this.animationDuration,
    this.selectedIndex = 0,
    required this.destinations,
    this.onDestinationSelected,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.indicatorColor,
    this.indicatorShape,
    this.height,
    this.labelBehavior,
    this.overlayColor,
    this.labelTextStyle,
    this.labelPadding,
    this.maintainBottomViewPadding = false,
    this.itemLayout = NavigationBarItemLayout.vertical,
    this.style,
    this.motion,
  });

  /// The duration of the selection animation.
  ///
  /// When null, the selection springs with [motion]. When given, it eases over
  /// this duration with [NavigationMotion.easing]'s curve.
  final Duration? animationDuration;

  /// The index of the selected destination; none is selected when it is out
  /// of range.
  final int selectedIndex;

  /// The destinations, three to five.
  final List<NavigationDestination> destinations;

  /// Called with a destination's index when it is tapped.
  ///
  /// When null, the destinations cannot be selected.
  final ValueChanged<int>? onDestinationSelected;

  /// Overrides [NavigationBarStyle.backgroundColor].
  final Color? backgroundColor;

  /// Overrides [NavigationBarStyle.elevation].
  final double? elevation;

  /// Overrides [NavigationBarStyle.shadowColor].
  final Color? shadowColor;

  /// Overrides [NavigationBarStyle.surfaceTintColor].
  final Color? surfaceTintColor;

  /// Overrides [NavigationBarStyle.indicatorColor].
  final Color? indicatorColor;

  /// Overrides [NavigationBarStyle.indicatorShape].
  final ShapeBorder? indicatorShape;

  /// Overrides [NavigationBarStyle.height].
  final double? height;

  /// Overrides [NavigationBarStyle.labelBehavior].
  final NavigationDestinationLabelBehavior? labelBehavior;

  /// Overrides [NavigationBarStyle.overlayColor].
  final WidgetStateProperty<Color?>? overlayColor;

  /// Overrides [NavigationBarStyle.labelTextStyle].
  final WidgetStateProperty<TextStyle?>? labelTextStyle;

  /// Overrides [NavigationBarStyle.labelPadding].
  final EdgeInsetsGeometry? labelPadding;

  /// Whether the bar keeps the bottom view padding when the bottom view
  /// inset, such as the keyboard, covers it. See
  /// [SafeArea.maintainBottomViewPadding].
  final bool maintainBottomViewPadding;

  /// Where the items place their label. A change animates.
  final NavigationBarItemLayout itemLayout;

  /// The bar's tokens, over the theme's [NavigationBarStyle] and the
  /// defaults.
  final NavigationBarStyle? style;

  /// Overrides [NavigationBarStyle.motion].
  final NavigationMotion? motion;

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar>
    with TickerProviderStateMixin {
  late final AnimationController _layout = createMotionController(
    this,
    _layoutTarget,
  );
  late double _appliedLayout = _layoutTarget;
  final List<AnimationController> _selection = [];
  final List<AnimationController> _labels = [];
  final List<double> _selectionTargets = [];
  final List<double> _labelTargets = [];

  double get _layoutTarget =>
      widget.itemLayout == NavigationBarItemLayout.horizontal ? 1 : 0;

  @override
  void dispose() {
    _layout.dispose();
    for (final controller in [..._selection, ..._labels]) {
      controller.dispose();
    }
    super.dispose();
  }

  NavigationBarStyle _resolveStyle(BuildContext context) {
    final w = widget;
    return NavigationBarStyle.of(context, w.style).merge(
      NavigationBarStyle(
        backgroundColor: w.backgroundColor,
        elevation: w.elevation,
        shadowColor: w.shadowColor,
        surfaceTintColor: w.surfaceTintColor,
        indicatorColor: w.indicatorColor,
        indicatorShape: w.indicatorShape,
        height: w.height,
        labelBehavior: w.labelBehavior,
        overlayColor: w.overlayColor,
        labelTextStyle: w.labelTextStyle,
        labelPadding: w.labelPadding,
        motion: w.motion,
      ),
    );
  }

  static double _labelTarget(
    NavigationDestinationLabelBehavior behavior,
    bool selected,
  ) => switch (behavior) {
    NavigationDestinationLabelBehavior.alwaysShow => 1,
    NavigationDestinationLabelBehavior.onlyShowSelected => selected ? 1 : 0,
    NavigationDestinationLabelBehavior.alwaysHide => 0,
  };

  // Moves every animation toward what the widget and its style now ask for.
  // Done while building, so a change of the theme's style animates too.
  void _sync(NavigationBarStyle style) {
    final count = widget.destinations.length;
    final behavior = style.labelBehavior!;
    if (_selection.length > count) {
      final removed = [..._selection.sublist(count), ..._labels.sublist(count)];
      _selection.removeRange(count, _selection.length);
      _labels.removeRange(count, _labels.length);
      _selectionTargets.removeRange(count, _selectionTargets.length);
      _labelTargets.removeRange(count, _labelTargets.length);
      // Their destinations still listen until this build replaces them.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final controller in removed) {
          controller.dispose();
        }
      });
    }
    for (var i = _selection.length; i < count; i++) {
      final selected = i == widget.selectedIndex;
      final label = _labelTarget(behavior, selected);
      _selection.add(createMotionController(this, selected ? 1 : 0));
      _labels.add(createMotionController(this, label));
      _selectionTargets.add(selected ? 1 : 0);
      _labelTargets.add(label);
    }
    final selectionMotion = widget.animationDuration == null
        ? style.motion!
        : NavigationMotion.easing(duration: widget.animationDuration!);
    for (var i = 0; i < count; i++) {
      final selected = i == widget.selectedIndex;
      final selection = selected ? 1.0 : 0.0;
      if (selection != _selectionTargets[i]) {
        _selectionTargets[i] = selection;
        animateWithMotion(
          _selection[i],
          selectionMotion,
          MotionRole.defaultSpatial,
          selection,
        );
      }
      final label = _labelTarget(behavior, selected);
      if (label != _labelTargets[i]) {
        _labelTargets[i] = label;
        animateWithMotion(
          _labels[i],
          style.motion!,
          MotionRole.defaultEffects,
          label,
        );
      }
    }
    if (_layoutTarget != _appliedLayout) {
      _appliedLayout = _layoutTarget;
      animateWithMotion(
        _layout,
        style.motion!,
        MotionRole.defaultSpatial,
        _layoutTarget,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(context);
    _sync(style);
    final textDirection = Directionality.of(context);
    final geometry = ItemGeometry(
      topIndicatorSize: Size(
        style.verticalIndicatorWidth!,
        style.verticalIndicatorHeight!,
      ),
      labelPadding: style.labelPadding!.resolve(textDirection),
      topPadding: style.verticalItemPadding!,
      topMinHeight: 0,
      topBoxWidth: null,
      topAnchored: true,
      startIndicatorHeight: style.horizontalIndicatorHeight!,
      startLeadingSpace: style.horizontalLeadingSpace!,
      startTrailingSpace: style.horizontalTrailingSpace!,
      startIconLabelSpacing: style.horizontalIconLabelSpacing!,
      startBadgeSpacing: null,
      startInset: 0,
      startAnchored: false,
      startFill: false,
      startMinHeight: 0,
      expandedWidth: null,
      labelShownInStartForm: false,
    );
    final itemStyle = ItemStyle(
      iconSize: style.iconSize!,
      selectedIconColor: style.selectedIconColor!,
      unselectedIconColor: style.unselectedIconColor!,
      selectedLabelColor: style.selectedLabelColor!,
      horizontalSelectedLabelColor: style.horizontalSelectedLabelColor!,
      unselectedLabelColor: style.unselectedLabelColor!,
      disabledColor: style.disabledColor!,
      labelStyle: style.labelStyle!,
      horizontalLabelStyle: style.horizontalLabelStyle!,
      labelMaxLines: style.labelMaxLines,
      labelOverflow: style.labelOverflow!,
      maxLabelScale: style.maxLabelScale,
      indicatorColor: style.indicatorColor!,
      indicatorShape: style.indicatorShape!,
      useIndicator: style.useIndicator!,
      overlayColor: ItemStyle.stateLayer(
        color: style.stateLayerColor!,
        hoverOpacity: style.hoverOpacity!,
        focusOpacity: style.focusOpacity!,
        pressedOpacity: style.pressedOpacity!,
        custom: style.overlayColor,
      ),
      iconTheme: style.iconTheme,
      labelTextStyle: style.labelTextStyle,
      motion: style.motion!,
    );
    final count = widget.destinations.length;
    final select = widget.onDestinationSelected;
    Widget items = _BarLayout(
      morph: _layout,
      minHeight: style.height!,
      children: [
        for (var i = 0; i < count; i++)
          DestinationScope(
            data: DestinationData(
              index: i,
              count: count,
              selected: i == widget.selectedIndex,
              onTap: select == null ? null : () => select(i),
              morph: _layout,
              selection: _selection[i],
              labelVisibility: _labels[i],
              geometry: geometry,
              style: itemStyle,
            ),
            child: widget.destinations[i],
          ),
      ],
    );
    // A tab bar must hold tabs, and a tab must be selectable.
    if (count > 0 && select != null) {
      items = Semantics(
        role: SemanticsRole.tabBar,
        container: true,
        explicitChildNodes: true,
        child: items,
      );
    }
    return Material(
      color: style.backgroundColor,
      elevation: style.elevation!,
      shadowColor: style.shadowColor,
      surfaceTintColor: style.surfaceTintColor,
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: widget.maintainBottomViewPadding,
        child: items,
      ),
    );
  }
}

// Lays out the items across the bar: equal widths for vertical items, centered
// with elastic widths for horizontal ones, interpolated by the item layout's
// progress. The bar is as tall as its tallest item, and at least [minHeight].
class _BarLayout extends MultiChildRenderObjectWidget {
  const _BarLayout({
    required this.morph,
    required this.minHeight,
    required super.children,
  });

  final Animation<double> morph;
  final double minHeight;

  @override
  _RenderBarLayout createRenderObject(BuildContext context) => _RenderBarLayout(
    morph: morph,
    minHeight: minHeight,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderBarLayout renderObject) {
    renderObject
      ..morph = morph
      ..minHeight = minHeight
      ..textDirection = Directionality.of(context);
  }
}

class _BarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBarLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BarParentData> {
  _RenderBarLayout({
    required this._morph,
    required this._minHeight,
    required this._textDirection,
  });

  Animation<double> get morph => _morph;
  Animation<double> _morph;
  set morph(Animation<double> value) {
    if (value == _morph) return;
    if (attached) _morph.removeListener(markNeedsLayout);
    _morph = value;
    if (attached) _morph.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  double get minHeight => _minHeight;
  double _minHeight;
  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _morph.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _morph.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BarParentData) {
      child.parentData = _BarParentData();
    }
  }

  // The side padding of the centered arrangement, as a fraction of the bar's
  // width, for [count] items.
  static double _centeredPadding(int count) =>
      count > 6 ? 0 : (100 - 10 * (count + 3)) / 2 / 100;

  // Each item's start and width.
  List<(double, double)> _slots(double width) {
    final children = getChildrenAsList();
    final count = children.length;
    final m = _morph.value.clamp(0.0, 1.0);
    final equal = width / count;
    final slots = <(double, double)>[
      for (var i = 0; i < count; i++) (i * equal, equal),
    ];
    if (m == 0) return slots;
    var padding = _centeredPadding(count) * width;
    final minItem = (width - 2 * padding) / count;
    final widths = <double>[];
    for (final child in children) {
      final hug = child.getMaxIntrinsicWidth(double.infinity);
      final itemWidth = hug > minItem ? math.min(hug, equal) : minItem;
      padding -= (itemWidth - minItem) / 2;
      widths.add(itemWidth);
    }
    var x = padding;
    for (var i = 0; i < count; i++) {
      slots[i] = (
        lerpDouble(slots[i].$1, x, m)!,
        lerpDouble(slots[i].$2, widths[i], m)!,
      );
      x += widths[i];
    }
    return slots;
  }

  double _height(double width, List<(double, double)> slots) {
    var height = _minHeight;
    var child = firstChild;
    var i = 0;
    while (child != null) {
      height = math.max(
        height,
        child.getDryLayout(BoxConstraints.tightFor(width: slots[i].$2)).height,
      );
      child = childAfter(child);
      i++;
    }
    return height;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (firstChild == null) {
      return constraints.constrain(Size(width, _minHeight));
    }
    return constraints.constrain(Size(width, _height(width, _slots(width))));
  }

  @override
  double computeMinIntrinsicHeight(double width) => width.isFinite
      ? getDryLayout(BoxConstraints(maxWidth: width)).height
      : _minHeight;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    var width = 0.0;
    var child = firstChild;
    while (child != null) {
      width += child.getMaxIntrinsicWidth(height);
      child = childAfter(child);
    }
    return width;
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    assert(width.isFinite, 'A NavigationBar needs a bounded width.');
    if (firstChild == null) {
      size = constraints.constrain(Size(width, _minHeight));
      return;
    }
    final slots = _slots(width);
    final height = constraints.constrainHeight(_height(width, slots));
    var child = firstChild;
    var i = 0;
    while (child != null) {
      final (x, itemWidth) = slots[i];
      child.layout(BoxConstraints.tight(Size(itemWidth, height)));
      (child.parentData! as _BarParentData).offset = Offset(
        _textDirection == TextDirection.ltr ? x : width - x - itemWidth,
        0,
      );
      child = childAfter(child);
      i++;
    }
    size = Size(width, height);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
