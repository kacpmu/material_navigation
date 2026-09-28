// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

/// The measurements of a destination, resolved from a bar's or rail's style.
///
/// An item lays itself out in two forms and interpolates between them by its
/// morph progress: the top form, with the label below the icon, and the start
/// form, with the label beside it.
@immutable
class ItemGeometry {
  /// Creates the measurements of a destination.
  const ItemGeometry({
    required this.topIndicatorSize,
    required this.labelPadding,
    required this.topPadding,
    required this.topMinHeight,
    required this.topBoxWidth,
    required this.topAnchored,
    required this.startIndicatorHeight,
    required this.startLeadingSpace,
    required this.startTrailingSpace,
    required this.startIconLabelSpacing,
    required this.startBadgeSpacing,
    required this.startInset,
    required this.startAnchored,
    required this.startFill,
    required this.startMinHeight,
    required this.expandedWidth,
    required this.labelShownInStartForm,
  });

  /// The active indicator of the top form.
  final Size topIndicatorSize;

  /// The padding around the label of the top form.
  final EdgeInsets labelPadding;

  /// The space above and below the content of the top form.
  final double topPadding;

  /// The minimum height of the top form.
  final double topMinHeight;

  /// The width the top form centers in, from the item's start edge, or null
  /// for the item's whole width.
  ///
  /// A rail sets its collapsed width, so the top form stays in place while the
  /// rail widens.
  final double? topBoxWidth;

  /// Whether a shown label anchors the top form's content to [topPadding]
  /// rather than centering it.
  final bool topAnchored;

  /// The height of the start form's active indicator.
  final double startIndicatorHeight;

  /// The space before the icon inside the start form's indicator.
  final double startLeadingSpace;

  /// The space after the label inside the start form's indicator.
  final double startTrailingSpace;

  /// The space between the icon and the label of the start form.
  final double startIconLabelSpacing;

  /// The space between the label and a badge of the start form, or null to
  /// keep the badge on the icon.
  final double? startBadgeSpacing;

  /// The space between the item's edges and the start form's indicator.
  final double startInset;

  /// Whether the start form's indicator starts at [startInset] and grows from
  /// there, rather than centering.
  final bool startAnchored;

  /// Whether the start form's indicator fills the item rather than hugging
  /// its content.
  final bool startFill;

  /// The minimum height of the start form.
  final double startMinHeight;

  /// The width the item has in its start form, which the label wraps to, or
  /// null for the item's current width.
  final double? expandedWidth;

  /// Whether the start form always shows its label, whatever the label
  /// visibility.
  final bool labelShownInStartForm;

  @override
  bool operator ==(Object other) =>
      other is ItemGeometry &&
      other.topIndicatorSize == topIndicatorSize &&
      other.labelPadding == labelPadding &&
      other.topPadding == topPadding &&
      other.topMinHeight == topMinHeight &&
      other.topBoxWidth == topBoxWidth &&
      other.topAnchored == topAnchored &&
      other.startIndicatorHeight == startIndicatorHeight &&
      other.startLeadingSpace == startLeadingSpace &&
      other.startTrailingSpace == startTrailingSpace &&
      other.startIconLabelSpacing == startIconLabelSpacing &&
      other.startBadgeSpacing == startBadgeSpacing &&
      other.startInset == startInset &&
      other.startAnchored == startAnchored &&
      other.startFill == startFill &&
      other.startMinHeight == startMinHeight &&
      other.expandedWidth == expandedWidth &&
      other.labelShownInStartForm == labelShownInStartForm;

  @override
  int get hashCode => Object.hash(
    topIndicatorSize,
    labelPadding,
    topPadding,
    topMinHeight,
    topBoxWidth,
    topAnchored,
    startIndicatorHeight,
    startLeadingSpace,
    startTrailingSpace,
    startIconLabelSpacing,
    startBadgeSpacing,
    startInset,
    startAnchored,
    startFill,
    startMinHeight,
    expandedWidth,
    labelShownInStartForm,
  );
}

/// The full-size active indicator rectangle of an item, in the item's
/// coordinates, shared with the ink response that draws its state layer.
class ItemInkGeometry {
  /// The rectangle, updated on every layout of the item.
  Rect indicator = Rect.zero;
}

/// The slots of a [NavigationItem].
enum ItemSlot {
  /// The ink response, filling the item: the touch target.
  ink,

  /// The icon.
  icon,

  /// The label.
  label,

  /// The badge.
  badge,
}

/// Lays out one destination: its icon, label, badge and active indicator,
/// interpolated between the top and start forms.
///
/// The item paints its active indicator below its children, so the ink
/// response in the [ItemSlot.ink] slot, which hosts its own transparent
/// [Material], draws the state layer and the ripple over the indicator.
class NavigationItem
    extends SlottedMultiChildRenderObjectWidget<ItemSlot, RenderBox> {
  /// Creates an item.
  const NavigationItem({
    super.key,
    required this.geometry,
    required this.morph,
    required this.selection,
    required this.labelVisibility,
    required this.measureOtherFormLabel,
    required this.indicatorColor,
    required this.indicatorShape,
    required this.showIndicator,
    required this.inkGeometry,
    required this.semanticsLabel,
    required this.selected,
    required this.enabled,
    required this.isTab,
    required this.ink,
    required this.icon,
    required this.label,
    this.badge,
  });

  /// The item's measurements.
  final ItemGeometry geometry;

  /// The progress from the top form (0) to the start form (1).
  final Animation<double> morph;

  /// The selection progress, from 0 to 1; may overshoot.
  final Animation<double> selection;

  /// How far the label shows in the top form, from 0 to 1.
  final Animation<double> labelVisibility;

  /// Measures the label, at a maximum width, in the style of the form it is
  /// not laid out in: the start form's while the item is nearer the top
  /// form, the top form's otherwise. When null, the label's dry
  /// layout.
  final Size Function(double maxWidth)? measureOtherFormLabel;

  /// The active indicator's color.
  final Color indicatorColor;

  /// The active indicator's shape.
  final ShapeBorder indicatorShape;

  /// Whether the active indicator is painted.
  final bool showIndicator;

  /// Where the item publishes its indicator for the state layer.
  final ItemInkGeometry inkGeometry;

  /// The item's accessible name.
  final String semanticsLabel;

  /// Whether the item is selected.
  final bool selected;

  /// Whether the item is enabled.
  final bool enabled;

  /// Whether the item takes the tab role.
  final bool isTab;

  /// The ink response filling the item.
  final Widget ink;

  /// The icon.
  final Widget icon;

  /// The label.
  final Widget label;

  /// The badge, if any.
  final Widget? badge;

  @override
  Iterable<ItemSlot> get slots => ItemSlot.values;

  @override
  Widget? childForSlot(ItemSlot slot) => switch (slot) {
    ItemSlot.ink => ink,
    ItemSlot.icon => icon,
    ItemSlot.label => label,
    ItemSlot.badge => badge,
  };

  @override
  SlottedContainerRenderObjectMixin<ItemSlot, RenderBox> createRenderObject(
    BuildContext context,
  ) => _RenderNavigationItem(
    geometry: geometry,
    morph: morph,
    selection: selection,
    labelVisibility: labelVisibility,
    measureOtherFormLabel: measureOtherFormLabel,
    indicatorColor: indicatorColor,
    indicatorShape: indicatorShape,
    showIndicator: showIndicator,
    inkGeometry: inkGeometry,
    textDirection: Directionality.of(context),
    semanticsLabel: semanticsLabel,
    selected: selected,
    enabled: enabled,
    isTab: isTab,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    SlottedContainerRenderObjectMixin<ItemSlot, RenderBox> renderObject,
  ) {
    (renderObject as _RenderNavigationItem)
      ..geometry = geometry
      ..morph = morph
      ..selection = selection
      ..labelVisibility = labelVisibility
      ..measureOtherFormLabel = measureOtherFormLabel
      ..indicatorColor = indicatorColor
      ..indicatorShape = indicatorShape
      ..showIndicator = showIndicator
      ..inkGeometry = inkGeometry
      ..textDirection = Directionality.of(context)
      ..semanticsLabel = semanticsLabel
      ..selected = selected
      ..enabled = enabled
      ..isTab = isTab;
  }
}

// Where each part of an item goes, in start-based coordinates: x runs from
// the item's start edge.
class _ItemLayout {
  _ItemLayout({
    required this.size,
    required this.indicator,
    required this.icon,
    required this.label,
    required this.labelOpacity,
    required this.badge,
    required this.badgeOpacity,
  });

  final Size size;
  final Rect indicator;
  final Offset icon;
  final Offset label;
  final double labelOpacity;
  final Offset badge;
  final double badgeOpacity;
}

// The render object of a [NavigationItem].
//
// Its intrinsic widths describe its two forms: the minimum is the top form's
// indicator, and the maximum the start form's hugged indicator with its
// insets, which a bar's centered arrangement sizes its items by.
class _RenderNavigationItem extends RenderBox
    with SlottedContainerRenderObjectMixin<ItemSlot, RenderBox> {
  _RenderNavigationItem({
    required this._geometry,
    required this._morph,
    required this._selection,
    required this._labelVisibility,
    required this._measureOtherFormLabel,
    required this._indicatorColor,
    required this._indicatorShape,
    required this._showIndicator,
    required this._inkGeometry,
    required this._textDirection,
    required this._semanticsLabel,
    required this._selected,
    required this._enabled,
    required this._isTab,
  });

  ItemGeometry get geometry => _geometry;
  ItemGeometry _geometry;
  set geometry(ItemGeometry value) {
    if (value == _geometry) return;
    _geometry = value;
    markNeedsLayout();
  }

  Animation<double> get morph => _morph;
  Animation<double> _morph;
  set morph(Animation<double> value) {
    if (value == _morph) return;
    if (attached) _morph.removeListener(markNeedsLayout);
    _morph = value;
    if (attached) _morph.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  Animation<double> get selection => _selection;
  Animation<double> _selection;
  set selection(Animation<double> value) {
    if (value == _selection) return;
    if (attached) _selection.removeListener(markNeedsPaint);
    _selection = value;
    if (attached) _selection.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Animation<double> get labelVisibility => _labelVisibility;
  Animation<double> _labelVisibility;
  set labelVisibility(Animation<double> value) {
    if (value == _labelVisibility) return;
    if (attached) _labelVisibility.removeListener(markNeedsLayout);
    _labelVisibility = value;
    if (attached) _labelVisibility.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  Size Function(double maxWidth)? get measureOtherFormLabel =>
      _measureOtherFormLabel;
  Size Function(double maxWidth)? _measureOtherFormLabel;
  set measureOtherFormLabel(Size Function(double maxWidth)? value) {
    if (value == _measureOtherFormLabel) return;
    _measureOtherFormLabel = value;
    markNeedsLayout();
  }

  Color get indicatorColor => _indicatorColor;
  Color _indicatorColor;
  set indicatorColor(Color value) {
    if (value == _indicatorColor) return;
    _indicatorColor = value;
    markNeedsPaint();
  }

  ShapeBorder get indicatorShape => _indicatorShape;
  ShapeBorder _indicatorShape;
  set indicatorShape(ShapeBorder value) {
    if (value == _indicatorShape) return;
    _indicatorShape = value;
    markNeedsPaint();
  }

  bool get showIndicator => _showIndicator;
  bool _showIndicator;
  set showIndicator(bool value) {
    if (value == _showIndicator) return;
    _showIndicator = value;
    markNeedsPaint();
  }

  ItemInkGeometry get inkGeometry => _inkGeometry;
  ItemInkGeometry _inkGeometry;
  set inkGeometry(ItemInkGeometry value) {
    if (value == _inkGeometry) return;
    _inkGeometry = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  String get semanticsLabel => _semanticsLabel;
  String _semanticsLabel;
  set semanticsLabel(String value) {
    if (value == _semanticsLabel) return;
    _semanticsLabel = value;
    markNeedsSemanticsUpdate();
  }

  bool get selected => _selected;
  bool _selected;
  set selected(bool value) {
    if (value == _selected) return;
    _selected = value;
    markNeedsSemanticsUpdate();
  }

  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    markNeedsSemanticsUpdate();
  }

  bool get isTab => _isTab;
  bool _isTab;
  set isTab(bool value) {
    if (value == _isTab) return;
    _isTab = value;
    markNeedsSemanticsUpdate();
  }

  RenderBox? get _ink => childForSlot(ItemSlot.ink);
  RenderBox? get _icon => childForSlot(ItemSlot.icon);
  RenderBox? get _label => childForSlot(ItemSlot.label);
  RenderBox? get _badge => childForSlot(ItemSlot.badge);

  @override
  Iterable<RenderBox> get children => [?_ink, ?_icon, ?_label, ?_badge];

  final LayerHandle<OpacityLayer> _labelLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<OpacityLayer> _badgeLayer = LayerHandle<OpacityLayer>();
  _ItemLayout? _layout;
  bool _fading = false;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _morph.addListener(markNeedsLayout);
    _labelVisibility.addListener(markNeedsLayout);
    _selection.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _morph.removeListener(markNeedsLayout);
    _labelVisibility.removeListener(markNeedsLayout);
    _selection.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _labelLayer.layer = null;
    _badgeLayer.layer = null;
    super.dispose();
  }

  double get _m => _morph.value.clamp(0.0, 1.0);

  double get _v {
    final visibility = _labelVisibility.value.clamp(0.0, 1.0);
    return _geometry.labelShownInStartForm
        ? lerpDouble(visibility, 1, _m)!
        : visibility;
  }

  // The label's maximum width in the top form.
  double _topLabelMaxWidth(double width) => math.max(
    0.0,
    (_geometry.topBoxWidth ?? width) - _geometry.labelPadding.horizontal,
  );

  // The label's maximum width in the start form, which leaves room for what
  // shares the indicator with it.
  double _startLabelMaxWidth(double width, Size icon, double badgeRoom) {
    final g = _geometry;
    return math.max(
      0.0,
      (g.expandedWidth ?? width) -
          2 * g.startInset -
          g.startLeadingSpace -
          icon.width -
          g.startIconLabelSpacing -
          g.startTrailingSpace -
          badgeRoom,
    );
  }

  _ItemLayout _computeLayout(
    BoxConstraints constraints,
    ChildLayouter layoutChild,
  ) {
    final g = _geometry;
    final width = constraints.maxWidth;
    assert(width.isFinite, 'A navigation item needs a bounded width.');
    final m = _m;
    final v = _v;

    final icon = _icon == null
        ? Size.zero
        : layoutChild(_icon!, BoxConstraints.loose(Size(width, width)));
    final badge = _badge == null
        ? Size.zero
        : layoutChild(_badge!, const BoxConstraints());
    // A badge with nothing to show, such as a Badge whose label is not
    // visible, takes no room beside the label.
    final badgeBeside = g.startBadgeSpacing != null && badge != Size.zero;
    final badgeRoom = badgeBeside ? g.startBadgeSpacing! + badge.width : 0.0;
    final topLabelMax = _topLabelMaxWidth(width);
    final startLabelMax = _startLabelMaxWidth(width, icon, badgeRoom);
    final label = _label == null
        ? Size.zero
        : layoutChild(
            _label!,
            BoxConstraints(maxWidth: m < 0.5 ? topLabelMax : startLabelMax),
          );
    // The label is laid out in the style of the form the item is nearer; its
    // size in the other form's style is measured, and needed only while the
    // item is not wholly in the nearer form.
    Size other(double maxWidth) =>
        _measureOtherFormLabel?.call(maxWidth) ??
        _label!.getDryLayout(BoxConstraints(maxWidth: maxWidth));
    final topLabel = m < 0.5 || m == 1 || _label == null
        ? label
        : other(topLabelMax);
    final startLabel = m >= 0.5 || m == 0 || _label == null
        ? label
        : other(startLabelMax);

    // The top form (m = 0).
    final topBox = g.topBoxWidth ?? width;
    final indicatorWidth0 = math.min(g.topIndicatorSize.width, topBox);
    final indicatorHeight0 = g.topIndicatorSize.height;
    final labelBlock0 = v * (g.labelPadding.vertical + topLabel.height);
    final content0 = indicatorHeight0 + labelBlock0;
    final height0 = math.max(g.topMinHeight, content0 + 2 * g.topPadding);

    // The start form (m = 1).
    final verticalPadding1 = math.max(
      0.0,
      (g.startIndicatorHeight - icon.height) / 2,
    );
    final labelShown1 = g.labelShownInStartForm ? 1.0 : v;
    final hug =
        g.startLeadingSpace +
        icon.width +
        labelShown1 * (g.startIconLabelSpacing + startLabel.width) +
        badgeRoom +
        g.startTrailingSpace;
    final room = math.max(0.0, width - 2 * g.startInset);
    final indicatorWidth1 = g.startFill ? room : math.min(hug, room);
    final indicatorHeight1 = math.max(
      g.startIndicatorHeight,
      math.max(
            labelShown1 * startLabel.height,
            badgeBeside ? badge.height : 0,
          ) +
          2 * verticalPadding1,
    );
    final height1 = math.max(g.startMinHeight, indicatorHeight1);

    final height = constraints.constrainHeight(
      lerpDouble(height0, height1, m)!,
    );

    final centered0 = (height - content0) / 2;
    final y0 = g.topAnchored
        ? lerpDouble(centered0, g.topPadding, v)!
        : centered0;
    final x0 = (topBox - indicatorWidth0) / 2;
    final x1 = g.startAnchored ? g.startInset : (width - indicatorWidth1) / 2;
    final y1 = (height - indicatorHeight1) / 2;

    final indicator = Rect.fromLTWH(
      lerpDouble(x0, x1, m)!,
      lerpDouble(y0, y1, m)!,
      lerpDouble(indicatorWidth0, indicatorWidth1, m)!,
      lerpDouble(indicatorHeight0, indicatorHeight1, m)!,
    );

    final icon0 = Offset(
      x0 + (indicatorWidth0 - icon.width) / 2,
      y0 + (indicatorHeight0 - icon.height) / 2,
    );
    final icon1 = Offset(
      x1 + g.startLeadingSpace,
      y1 + (indicatorHeight1 - icon.height) / 2,
    );
    final iconOffset = Offset.lerp(icon0, icon1, m)!;

    // One label moves between the forms, invisible at the midpoint where its
    // style switches.
    final morphAlpha = 4 * (m - 0.5) * (m - 0.5);
    final Offset labelOffset;
    if (m < 0.5) {
      // Centered below the indicator, within the label padding.
      final ltr = _textDirection == TextDirection.ltr;
      final padding = g.labelPadding;
      final paddingStart = ltr ? padding.left : padding.right;
      labelOffset = Offset(
        paddingStart + (topBox - padding.horizontal - label.width) / 2,
        indicator.bottom + padding.top,
      );
    } else {
      // Beside the icon wherever the icon is, sliding out from its edge.
      labelOffset = Offset(
        iconOffset.dx + icon.width + g.startIconLabelSpacing * (2 * m - 1),
        indicator.top + (indicator.height - label.height) / 2,
      );
    }
    final labelOpacity = (morphAlpha * v).clamp(0.0, 1.0);

    Offset onIcon(Offset iconAt) => badge.width <= 8
        ? Offset(iconAt.dx + icon.width - badge.width, iconAt.dy)
        : Offset(iconAt.dx + icon.width - 12, iconAt.dy + 14 - badge.height);
    // A badge beside the label moves between the forms as the label does.
    final badgeOffset = badgeBeside && m >= 0.5
        ? Offset(
            labelOffset.dx + label.width + g.startBadgeSpacing!,
            indicator.top + (indicator.height - badge.height) / 2,
          )
        : onIcon(iconOffset);
    final badgeOpacity = badgeBeside ? morphAlpha : 1.0;

    return _ItemLayout(
      size: constraints.constrain(Size(width, height)),
      indicator: indicator,
      icon: iconOffset,
      label: labelOffset,
      labelOpacity: labelOpacity,
      badge: badgeOffset,
      badgeOpacity: badgeOpacity,
    );
  }

  // Converts a start-based rectangle to the item's coordinates.
  Rect _directional(Rect rect, double width) =>
      _textDirection == TextDirection.ltr
      ? rect
      : Rect.fromLTWH(width - rect.right, rect.top, rect.width, rect.height);

  Offset _directionalOffset(Offset offset, Size child, double width) =>
      _textDirection == TextDirection.ltr
      ? offset
      : Offset(width - offset.dx - child.width, offset.dy);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _computeLayout(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _geometry.topIndicatorSize.width;

  @override
  double computeMaxIntrinsicWidth(double height) {
    final g = _geometry;
    final icon = _icon?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    final label = _label?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    final badge = _badge?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    final shown = g.labelShownInStartForm
        ? 1.0
        : _labelVisibility.value.clamp(0.0, 1.0);
    return g.startLeadingSpace +
        icon +
        shown * (g.startIconLabelSpacing + label) +
        (g.startBadgeSpacing != null && badge > 0
            ? g.startBadgeSpacing! + badge
            : 0) +
        g.startTrailingSpace +
        2 * g.startInset;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      width.isFinite ? getDryLayout(BoxConstraints(maxWidth: width)).height : 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    final layout = _computeLayout(constraints, ChildLayoutHelper.layoutChild);
    _layout = layout;
    size = layout.size;
    final width = size.width;
    void place(RenderBox? child, Offset offset) {
      if (child == null) return;
      (child.parentData! as BoxParentData).offset = _directionalOffset(
        offset,
        child.size,
        width,
      );
    }

    if (_ink != null) {
      _ink!.layout(BoxConstraints.tight(size));
      (_ink!.parentData! as BoxParentData).offset = Offset.zero;
    }
    place(_icon, layout.icon);
    place(_label, layout.label);
    place(_badge, layout.badge);
    _inkGeometry.indicator = _directional(layout.indicator, width);
    // A fading label or badge is painted in an opacity layer, which ancestor
    // clips only reach through composited layers.
    bool partial(double opacity) => opacity > 0 && opacity < 1;
    final fading =
        (_label != null && partial(layout.labelOpacity)) ||
        (_badge != null && partial(layout.badgeOpacity));
    if (fading != _fading) {
      _fading = fading;
      markNeedsCompositingBitsUpdate();
    }
  }

  // The indicator as the selection shows it: as wide as the selection
  // progress, from the center or, in the anchored start form, from the start.
  Rect? get _selectedIndicator {
    final layout = _layout;
    if (layout == null) return null;
    final progress = math.max(0.0, _selection.value);
    if (progress == 0) return null;
    final full = layout.indicator;
    final width = full.width * progress;
    final fromStart = _geometry.startAnchored ? _m : 0.0;
    final left = full.left + (full.width - width) / 2 * (1 - fromStart);
    return _directional(
      Rect.fromLTWH(left, full.top, width, full.height),
      size.width,
    );
  }

  void _paintIndicator(Canvas canvas, Offset offset) {
    if (!_showIndicator) return;
    final rect = _selectedIndicator;
    if (rect == null) return;
    final alpha = _selection.value.clamp(0.0, 1.0);
    canvas.drawPath(
      _indicatorShape.getOuterPath(
        rect.shift(offset),
        textDirection: _textDirection,
      ),
      Paint()
        ..color = _indicatorColor.withValues(alpha: _indicatorColor.a * alpha),
    );
  }

  void _paintChild(PaintingContext context, Offset offset, RenderBox? child) {
    if (child == null) return;
    context.paintChild(
      child,
      offset + (child.parentData! as BoxParentData).offset,
    );
  }

  void _paintFaded(
    PaintingContext context,
    Offset offset,
    RenderBox? child,
    double opacity,
    LayerHandle<OpacityLayer> handle,
  ) {
    if (child == null || opacity <= 0) {
      handle.layer = null;
      return;
    }
    if (opacity >= 1) {
      handle.layer = null;
      _paintChild(context, offset, child);
      return;
    }
    handle.layer = context.pushOpacity(
      offset,
      (opacity * 255).round(),
      (context, offset) => _paintChild(context, offset, child),
      oldLayer: handle.layer,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final layout = _layout;
    if (layout == null) return;
    _paintIndicator(context.canvas, offset);
    _paintChild(context, offset, _ink);
    _paintChild(context, offset, _icon);
    _paintFaded(context, offset, _label, layout.labelOpacity, _labelLayer);
    _paintFaded(context, offset, _badge, layout.badgeOpacity, _badgeLayer);
  }

  @override
  bool get alwaysNeedsCompositing => _fading;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final ink = _ink;
    if (ink == null) return false;
    // The icon, label and badge take no input, but are reported under the
    // pointer too, so a hit on them is also a hit on what they show.
    for (final child in [?_badge, ?_label, ?_icon]) {
      result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
    }
    return result.addWithPaintOffset(
      offset: (ink.parentData! as BoxParentData).offset,
      position: position,
      hitTest: (result, transformed) =>
          ink.hitTest(result, position: transformed),
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true
      ..isSelected = _selected
      ..isEnabled = _enabled
      ..isButton = true
      ..label = _semanticsLabel
      ..textDirection = _textDirection;
    if (_isTab) config.role = SemanticsRole.tab;
  }
}
