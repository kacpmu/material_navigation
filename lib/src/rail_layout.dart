// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

import 'rail.dart';

/// When a slot of a [NavigationRailLayout] shows.
///
/// Slots shown only while collapsed, next to slots shown only while expanded,
/// take their turns in one room, which changes from the height of the one to
/// that of the other as the rail expands: a search button that becomes a
/// search bar moves nothing when the two are as tall.
enum NavigationRailSlotVisibility {
  /// Always.
  always,

  /// Only while the rail is expanded, in place or as a modal. The slot
  /// appears whole halfway through the expansion and fades in, together with
  /// the slots shown with it.
  expanded,

  /// Only while the rail is collapsed. The slot fades out over the first half
  /// of the expansion, together with the slots hidden with it.
  collapsed,
}

/// An entry of a [NavigationRailLayout]: one of the rail's own parts, or a
/// widget.
///
/// ```dart
/// NavigationRailLayout(
///   group: [
///     NavigationRailSlot.destinations,
///     const NavigationRailSlot.widget(
///       Divider(),
///       visibility: NavigationRailSlotVisibility.expanded,
///     ),
///     NavigationRailSlot.secondaryDestinations,
///   ],
/// )
/// ```
@immutable
sealed class NavigationRailSlot {
  const NavigationRailSlot._();

  /// A widget, as wide as the rail.
  const factory NavigationRailSlot.widget(
    Widget child, {
    NavigationRailSlotVisibility visibility,
  }) = WidgetRailSlot;

  /// [NavigationRail.leading], centered in the collapsed rail's width, where
  /// it stays as the rail expands.
  static const NavigationRailSlot leading = NamedRailSlot.leading;

  /// [NavigationRail.floatingActionButton], centered in the collapsed rail
  /// and moving to the destinations' start as the rail expands.
  static const NavigationRailSlot floatingActionButton =
      NamedRailSlot.floatingActionButton;

  /// [NavigationRail.destinations].
  static const NavigationRailSlot destinations = NamedRailSlot.destinations;

  /// [NavigationRail.secondaryDestinations], shown only while the rail is
  /// expanded.
  static const NavigationRailSlot secondaryDestinations =
      NamedRailSlot.secondaryDestinations;

  /// [NavigationRail.expandedBody], shown only while the rail is expanded.
  static const NavigationRailSlot expandedBody = NamedRailSlot.expandedBody;

  /// [NavigationRail.trailing].
  static const NavigationRailSlot trailing = NamedRailSlot.trailing;
}

/// The slots that show the rail's own parts.
enum NamedRailSlot implements NavigationRailSlot {
  /// See [NavigationRailSlot.leading].
  leading,

  /// See [NavigationRailSlot.floatingActionButton].
  floatingActionButton,

  /// See [NavigationRailSlot.destinations].
  destinations,

  /// See [NavigationRailSlot.secondaryDestinations].
  secondaryDestinations,

  /// See [NavigationRailSlot.expandedBody].
  expandedBody,

  /// See [NavigationRailSlot.trailing].
  trailing,
}

/// A slot that shows a widget.
final class WidgetRailSlot extends NavigationRailSlot {
  /// Creates a slot for [child].
  const WidgetRailSlot(
    this.child, {
    this.visibility = NavigationRailSlotVisibility.always,
  }) : super._();

  /// The widget.
  final Widget child;

  /// When it shows.
  final NavigationRailSlotVisibility visibility;

  @override
  bool operator ==(Object other) =>
      other is WidgetRailSlot &&
      other.child == child &&
      other.visibility == visibility;

  @override
  int get hashCode => Object.hash(child, visibility);
}

/// Where a [NavigationRail] places its content, top to bottom, in three
/// regions.
///
/// The [header] is pinned to the top, below the rail's top space.
/// The [group] sits at the rail's group alignment and scrolls when
/// it does not fit. The [footer] is pinned to the bottom.
///
/// ```dart
/// NavigationRailLayout(
///   group: [
///     NavigationRailSlot.destinations,
///     NavigationRailSlot.trailing,
///   ],
///   footer: const [],
/// )
/// ```
@immutable
final class NavigationRailLayout with Diagnosticable {
  /// Creates a layout.
  ///
  /// The defaults put the menu button and the floating action button in the
  /// header, the destinations, secondary destinations and expanded body in
  /// the group, and the trailing widget in the footer.
  const NavigationRailLayout({
    this.header = const [
      NavigationRailSlot.leading,
      NavigationRailSlot.floatingActionButton,
    ],
    this.group = const [
      NavigationRailSlot.destinations,
      NavigationRailSlot.secondaryDestinations,
      NavigationRailSlot.expandedBody,
    ],
    this.footer = const [NavigationRailSlot.trailing],
  });

  /// The slots pinned to the top.
  final List<NavigationRailSlot> header;

  /// The slots placed by the group alignment.
  final List<NavigationRailSlot> group;

  /// The slots pinned to the bottom.
  final List<NavigationRailSlot> footer;

  /// A copy of this layout with the given regions replaced.
  NavigationRailLayout copyWith({
    List<NavigationRailSlot>? header,
    List<NavigationRailSlot>? group,
    List<NavigationRailSlot>? footer,
  }) => NavigationRailLayout(
    header: header ?? this.header,
    group: group ?? this.group,
    footer: footer ?? this.footer,
  );

  @override
  bool operator ==(Object other) =>
      other is NavigationRailLayout &&
      listEquals(other.header, header) &&
      listEquals(other.group, group) &&
      listEquals(other.footer, footer);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(header),
    Object.hashAll(group),
    Object.hashAll(footer),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<NavigationRailSlot>('header', header))
      ..add(IterableProperty<NavigationRailSlot>('group', group))
      ..add(IterableProperty<NavigationRailSlot>('footer', footer));
  }
}

/// How far a slot shows at expansion progress [m]: whole in its half of the
/// expansion, growing or shrinking through the other.
double revealFor(NavigationRailSlotVisibility visibility, double m) =>
    switch (visibility) {
      NavigationRailSlotVisibility.always => 1,
      NavigationRailSlotVisibility.expanded => (2 * m - 1).clamp(0.0, 1.0),
      NavigationRailSlotVisibility.collapsed => (1 - 2 * m).clamp(0.0, 1.0),
    };

/// The room around a rail's group, measured by its [RailFrame] and read, in
/// the same layout pass, by the group's [RailColumn], which places the group
/// against the rail's whole height.
class RailMetrics {
  /// The room above the group: the top space, the header and the space after
  /// it.
  double top = 0;

  /// The room below the group: the footer.
  double bottom = 0;

  /// The height left for the group.
  double viewport = 0;

  // The group laid out against these metrics. It sits inside a scroll view,
  // which passes it only width constraints, so the frame marks it for layout
  // when the metrics change.
  RenderBox? _group;

  // Records new metrics, reporting whether they changed.
  bool _update(double top, double bottom, double viewport) {
    if (top == this.top && bottom == this.bottom && viewport == this.viewport) {
      return false;
    }
    this.top = top;
    this.bottom = bottom;
    this.viewport = viewport;
    return true;
  }
}

/// The regions of a [RailFrame].
enum RailRegion {
  /// The header.
  header,

  /// The group.
  group,

  /// The footer.
  footer,
}

/// Sizes a rail by its expansion and places its three regions.
///
/// Collapsed, the rail is [collapsedWidth] wide. Expanded, it is
/// [expandedWidth] wide when that is given, and otherwise as wide as
/// [fitWidth] within [minExpandedWidth] and [maxExpandedWidth].
class RailFrame
    extends SlottedMultiChildRenderObjectWidget<RailRegion, RenderBox> {
  /// Creates a frame.
  const RailFrame({
    super.key,
    required this.morph,
    required this.collapsedWidth,
    required this.expandedWidth,
    required this.fitWidth,
    required this.minExpandedWidth,
    required this.maxExpandedWidth,
    required this.topSpace,
    required this.metrics,
    required this.header,
    required this.group,
    required this.footer,
  });

  /// The expansion progress.
  final Animation<double> morph;

  /// The collapsed width.
  final double collapsedWidth;

  /// A fixed expanded width, or null to fit.
  final double? expandedWidth;

  /// The width the widest destination needs.
  final double fitWidth;

  /// The narrowest fitted expanded width.
  final double minExpandedWidth;

  /// The widest fitted expanded width.
  final double maxExpandedWidth;

  /// The space above the header.
  final double topSpace;

  /// Where the frame publishes the room around the group.
  final RailMetrics metrics;

  /// The header.
  final Widget header;

  /// The group.
  final Widget group;

  /// The footer.
  final Widget footer;

  @override
  Iterable<RailRegion> get slots => RailRegion.values;

  @override
  Widget? childForSlot(RailRegion slot) => switch (slot) {
    RailRegion.header => header,
    RailRegion.group => group,
    RailRegion.footer => footer,
  };

  @override
  SlottedContainerRenderObjectMixin<RailRegion, RenderBox> createRenderObject(
    BuildContext context,
  ) => _RenderRailFrame(
    morph: morph,
    collapsedWidth: collapsedWidth,
    expandedWidth: expandedWidth,
    fitWidth: fitWidth,
    minExpandedWidth: minExpandedWidth,
    maxExpandedWidth: maxExpandedWidth,
    topSpace: topSpace,
    metrics: metrics,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    SlottedContainerRenderObjectMixin<RailRegion, RenderBox> renderObject,
  ) {
    (renderObject as _RenderRailFrame)
      ..morph = morph
      ..collapsedWidth = collapsedWidth
      ..expandedWidth = expandedWidth
      ..fitWidth = fitWidth
      ..minExpandedWidth = minExpandedWidth
      ..maxExpandedWidth = maxExpandedWidth
      ..topSpace = topSpace
      ..metrics = metrics;
  }
}

class _RenderRailFrame extends RenderBox
    with SlottedContainerRenderObjectMixin<RailRegion, RenderBox> {
  _RenderRailFrame({
    required this._morph,
    required this._collapsedWidth,
    required this._expandedWidth,
    required this._fitWidth,
    required this._minExpandedWidth,
    required this._maxExpandedWidth,
    required this._topSpace,
    required this._metrics,
  });

  Animation<double> _morph;
  set morph(Animation<double> value) {
    if (value == _morph) return;
    if (attached) _morph.removeListener(markNeedsLayout);
    _morph = value;
    if (attached) _morph.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  double _collapsedWidth;
  set collapsedWidth(double value) {
    if (value == _collapsedWidth) return;
    _collapsedWidth = value;
    markNeedsLayout();
  }

  double? _expandedWidth;
  set expandedWidth(double? value) {
    if (value == _expandedWidth) return;
    _expandedWidth = value;
    markNeedsLayout();
  }

  double _fitWidth;
  set fitWidth(double value) {
    if (value == _fitWidth) return;
    _fitWidth = value;
    markNeedsLayout();
  }

  double _minExpandedWidth;
  set minExpandedWidth(double value) {
    if (value == _minExpandedWidth) return;
    _minExpandedWidth = value;
    markNeedsLayout();
  }

  double _maxExpandedWidth;
  set maxExpandedWidth(double value) {
    if (value == _maxExpandedWidth) return;
    _maxExpandedWidth = value;
    markNeedsLayout();
  }

  double _topSpace;
  set topSpace(double value) {
    if (value == _topSpace) return;
    _topSpace = value;
    markNeedsLayout();
  }

  RailMetrics _metrics;
  set metrics(RailMetrics value) {
    if (value == _metrics) return;
    _metrics = value;
    markNeedsLayout();
  }

  RenderBox? get _header => childForSlot(RailRegion.header);
  RenderBox? get _group => childForSlot(RailRegion.group);
  RenderBox? get _footer => childForSlot(RailRegion.footer);

  @override
  Iterable<RenderBox> get children => [?_header, ?_group, ?_footer];

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

  // The width at expansion progress m. A fitted width follows the
  // collapsed-to-maximum range, capped at the fit, so a fit that changes
  // mid-expansion does not make the width jump.
  double get _width {
    final m = _morph.value.clamp(0.0, 1.0);
    final fixed = _expandedWidth;
    if (fixed != null) return lerpDouble(_collapsedWidth, fixed, m)!;
    // A minimum above the maximum wins.
    final max = math.max(_minExpandedWidth, _maxExpandedWidth);
    final fit = _fitWidth.clamp(_minExpandedWidth, max);
    return math.min(
      lerpDouble(_collapsedWidth, max, m)!,
      math.max(lerpDouble(_collapsedWidth, _minExpandedWidth, m)!, fit),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => _width;

  @override
  double computeMaxIntrinsicWidth(double height) => _width;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = _width;
    if (constraints.maxHeight.isFinite) {
      return constraints.constrain(Size(width, constraints.maxHeight));
    }
    final region = BoxConstraints.tightFor(width: width);
    final header = _header?.getDryLayout(region).height ?? 0;
    final group = _group?.getDryLayout(region).height ?? 0;
    final footer = _footer?.getDryLayout(region).height ?? 0;
    return constraints.constrain(
      Size(width, _topSpace + header + group + footer),
    );
  }

  @override
  void performLayout() {
    final width = _width;
    final region = BoxConstraints.tightFor(width: width);
    final header = _header!..layout(region, parentUsesSize: true);
    final footer = _footer!..layout(region, parentUsesSize: true);
    final top = _topSpace + header.size.height;
    final bounded = constraints.maxHeight.isFinite;
    final viewport = bounded
        ? math.max(0.0, constraints.maxHeight - top - footer.size.height)
        : double.infinity;
    final metrics = _metrics;
    if (metrics._update(top, footer.size.height, bounded ? viewport : 0)) {
      invokeLayoutCallback<BoxConstraints>(
        (_) => metrics._group?.markNeedsLayout(),
      );
    }
    final group = _group!
      ..layout(
        BoxConstraints(minWidth: width, maxWidth: width, maxHeight: viewport),
        parentUsesSize: true,
      );
    final height = bounded
        ? constraints.maxHeight
        : top + group.size.height + footer.size.height;
    size = constraints.constrain(Size(width, height));
    (header.parentData! as BoxParentData).offset = Offset(0, _topSpace);
    (group.parentData! as BoxParentData).offset = Offset(0, top);
    (footer.parentData! as BoxParentData).offset = Offset(
      0,
      size.height - footer.size.height,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [?_footer, ?_group, ?_header]) {
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// Marks a child of a [RailColumn] with its slot's visibility.
class RailColumnChild extends ParentDataWidget<RailColumnParentData> {
  /// Creates the marker.
  const RailColumnChild({
    super.key,
    required this.visibility,
    required super.child,
  });

  /// When the child shows.
  final NavigationRailSlotVisibility visibility;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as RailColumnParentData;
    if (data.visibility == visibility) return;
    data.visibility = visibility;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => RailColumn;
}

/// The parent data of a child of a [RailColumn].
class RailColumnParentData extends ContainerBoxParentData<RenderBox> {
  /// When the child shows.
  NavigationRailSlotVisibility visibility = NavigationRailSlotVisibility.always;

  double _reveal = 1;

  // The layers the child is painted in while partly revealed, or cut at the
  // rail's edge, kept from frame to frame.
  final LayerHandle<OpacityLayer> _opacityLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<ClipRectLayer> _clipLayer = LayerHandle<ClipRectLayer>();

  @override
  void detach() {
    _opacityLayer.layer = null;
    _clipLayer.layer = null;
    super.detach();
  }
}

// Adjacent slots of a [RailColumn] that show together, and where each sits
// in the run.
class _Run {
  _Run(this.visibility, this.width);

  final NavigationRailSlotVisibility visibility;

  // The width the run's slots are laid out at.
  final double width;

  final List<(RenderBox, double)> slots = [];
  double height = 0;

  // Whether this run and [other] show in turn: one only while collapsed, the
  // other only while expanded.
  bool swapsWith(_Run other) => switch ((visibility, other.visibility)) {
    (
      NavigationRailSlotVisibility.collapsed,
      NavigationRailSlotVisibility.expanded,
    ) ||
    (
      NavigationRailSlotVisibility.expanded,
      NavigationRailSlotVisibility.collapsed,
    ) => true,
    _ => false,
  };
}

/// Stacks the slots of one region of a rail, revealing those that show only
/// while expanded or collapsed as the rail expands.
///
/// With an [alignment], the column is a rail's group: it fills the room its
/// [RailFrame] leaves, and places its content at [alignment] along the rail's
/// whole height.
class RailColumn extends MultiChildRenderObjectWidget {
  /// Creates a column.
  const RailColumn({
    super.key,
    required this.morph,
    required this.spacing,
    this.trailingSpace = 0,
    required this.revealWidth,
    this.alignment,
    this.metrics,
    this.clip = false,
    required super.children,
  });

  /// The expansion progress.
  final Animation<double> morph;

  /// The space between shown slots.
  final double spacing;

  /// The space after the shown slots, opening with the most revealed of
  /// them, such as the space between a rail's header and its group.
  final double trailingSpace;

  /// The width slots that show only while expanded are laid out at, so they
  /// do not rewrap as the rail widens; what exceeds the rail is clipped.
  final double revealWidth;

  /// Where the content sits along the rail's height, from -1 (top) to 1
  /// (bottom), or null to stack from the top.
  final double? alignment;

  /// The room around the group, for [alignment].
  final RailMetrics? metrics;

  /// Whether content that does not fit is clipped, with an overflow warning
  /// in debug builds, rather than scrolled by an enclosing scroll view.
  final bool clip;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderRailColumn(
    morph: morph,
    spacing: spacing,
    trailingSpace: trailingSpace,
    revealWidth: revealWidth,
    alignment: alignment,
    metrics: metrics,
    clip: clip,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRailColumn)
      ..morph = morph
      ..spacing = spacing
      ..trailingSpace = trailingSpace
      ..revealWidth = revealWidth
      ..alignment = alignment
      ..metrics = metrics
      ..clip = clip
      ..textDirection = Directionality.of(context);
  }
}

class _RenderRailColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, RailColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, RailColumnParentData>,
        DebugOverflowIndicatorMixin {
  _RenderRailColumn({
    required this._morph,
    required this._spacing,
    required this._trailingSpace,
    required this._revealWidth,
    required this._alignment,
    required this._metrics,
    required this._clip,
    required this._textDirection,
  });

  Animation<double> _morph;
  set morph(Animation<double> value) {
    if (value == _morph) return;
    if (attached) _morph.removeListener(markNeedsLayout);
    _morph = value;
    if (attached) _morph.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _trailingSpace;
  set trailingSpace(double value) {
    if (value == _trailingSpace) return;
    _trailingSpace = value;
    markNeedsLayout();
  }

  double _revealWidth;
  set revealWidth(double value) {
    if (value == _revealWidth) return;
    _revealWidth = value;
    markNeedsLayout();
  }

  double? _alignment;
  set alignment(double? value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsLayout();
  }

  RailMetrics? _metrics;
  set metrics(RailMetrics? value) {
    if (value == _metrics) return;
    if (_metrics?._group == this) _metrics!._group = null;
    _metrics = value;
    if (attached) value?._group = this;
    markNeedsLayout();
  }

  bool _clip;
  set clip(bool value) {
    if (value == _clip) return;
    _clip = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double _overflow = 0;
  // Whether a slot is partly revealed, and so painted in an opacity layer,
  // which ancestor clips only reach through composited layers.
  bool _revealing = false;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _morph.addListener(markNeedsLayout);
    _metrics?._group = this;
  }

  @override
  void detach() {
    _morph.removeListener(markNeedsLayout);
    if (_metrics?._group == this) _metrics!._group = null;
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => _revealing;

  @override
  bool paintsChild(RenderBox child) =>
      (child.parentData! as RailColumnParentData)._reveal > 0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! RailColumnParentData) {
      child.parentData = RailColumnParentData();
    }
  }

  double _content(
    BoxConstraints constraints,
    ChildLayouter layoutChild, {
    required bool dry,
  }) {
    final width = constraints.maxWidth;
    final m = _morph.value.clamp(0.0, 1.0);

    // Adjacent slots that show together are revealed as one run: whole,
    // fading in over the second half of the expansion while its room opens,
    // and drifting up into place as the destinations above it shrink, as the
    // expanded body of version 0.1 did.
    final runs = <_Run>[];
    var child = firstChild;
    while (child != null) {
      final visibility = (child.parentData! as RailColumnParentData).visibility;
      final run = _Run(
        visibility,
        visibility == NavigationRailSlotVisibility.expanded
            ? math.max(width, _revealWidth)
            : width,
      );
      RenderBox? next = child;
      while (next != null) {
        final data = next.parentData! as RailColumnParentData;
        if (data.visibility != visibility) break;
        // Hidden slots are laid out too, as an offstage child is, so they
        // are ready the moment they show.
        final size = layoutChild(
          next,
          BoxConstraints.tightFor(width: run.width),
        );
        if (run.slots.isNotEmpty) run.height += _spacing;
        run.slots.add((next, run.height));
        run.height += size.height;
        next = data.nextSibling;
        if (visibility == NavigationRailSlotVisibility.always) break;
      }
      runs.add(run);
      child = next;
    }

    var revealing = false;
    var y = 0.0;
    // The runs shown so far, how far the first of them is revealed, and how
    // far the most revealed one is.
    var shownRuns = 0;
    var lead = 0.0;
    var most = 0.0;
    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      // A run shown only while collapsed and one shown only while expanded,
      // side by side, take turns in one room, which changes from the one's
      // height to the other's as the rail expands. What follows moves only
      // by the difference, not out and back as two rooms closing and
      // opening would move it.
      final partner = i + 1 < runs.length && run.swapsWith(runs[i + 1])
          ? runs[++i]
          : null;
      final double room;
      final double shown;
      if (partner == null) {
        shown = revealFor(run.visibility, m);
        room = run.height * shown;
      } else {
        final (
          collapsed,
          expanded,
        ) = run.visibility == NavigationRailSlotVisibility.collapsed
            ? (run, partner)
            : (partner, run);
        shown = 1;
        room = lerpDouble(collapsed.height, expanded.height, m)!;
      }
      if (shown > 0) {
        // The gap before a run opens with it; the gap after the first run
        // opens with that run too, as nothing comes before it.
        if (shownRuns == 1) {
          y += _spacing * math.min(shown, lead);
        } else if (shownRuns > 1) {
          y += _spacing * shown;
        }
        if (shownRuns == 0) lead = shown;
        shownRuns++;
        most = math.max(most, shown);
      }
      if (!dry) {
        for (final part in [run, ?partner]) {
          final reveal = revealFor(part.visibility, m);
          final x = _textDirection == TextDirection.ltr
              ? 0.0
              : width - part.width;
          for (final (slot, offset) in part.slots) {
            (slot.parentData! as RailColumnParentData)
              .._reveal = reveal
              ..offset = Offset(x, y + offset);
          }
          revealing = revealing || (reveal > 0 && reveal < 1);
        }
      }
      y += room;
    }
    if (!dry && revealing != _revealing) {
      _revealing = revealing;
      markNeedsCompositingBitsUpdate();
    }
    return y + _trailingSpace * most;
  }

  double _top(double content) {
    final alignment = _alignment;
    final metrics = _metrics;
    if (alignment == null || metrics == null) return 0;
    final rail = metrics.viewport + metrics.top + metrics.bottom;
    return ((rail - content) * (alignment + 1) / 2 - metrics.top)
        .clamp(0.0, math.max(0.0, metrics.viewport - content))
        .toDouble();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return constraints.smallest;
    final content = _content(
      constraints,
      ChildLayoutHelper.dryLayoutChild,
      dry: true,
    );
    final viewport = _alignment == null ? 0.0 : (_metrics?.viewport ?? 0);
    return constraints.constrain(
      Size(constraints.maxWidth, math.max(viewport, _top(content) + content)),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    final content = _content(
      constraints,
      ChildLayoutHelper.layoutChild,
      dry: false,
    );
    final top = _top(content);
    if (top > 0) {
      var child = firstChild;
      while (child != null) {
        final data = child.parentData! as RailColumnParentData;
        data.offset = data.offset.translate(0, top);
        child = data.nextSibling;
      }
    }
    final viewport = _alignment == null ? 0.0 : (_metrics?.viewport ?? 0);
    size = constraints.constrain(
      Size(constraints.maxWidth, math.max(viewport, top + content)),
    );
    _overflow = math.max(0.0, top + content - size.height);
  }

  void _paintChildren(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as RailColumnParentData;
      final reveal = data._reveal;
      final current = child;
      void paintFaded(PaintingContext context, Offset offset) {
        if (reveal >= 1) {
          data._opacityLayer.layer = null;
          context.paintChild(current, offset + data.offset);
          return;
        }
        data._opacityLayer.layer = context.pushOpacity(
          offset,
          (reveal * 255).round(),
          (context, layerOffset) =>
              context.paintChild(current, layerOffset + data.offset),
          oldLayer: data._opacityLayer.layer,
        );
      }

      if (reveal <= 0) {
        data._opacityLayer.layer = null;
        data._clipLayer.layer = null;
      } else if (child.size.width > size.width + precisionErrorTolerance) {
        // A slot laid out wider than the rail, to keep its lines as the rail
        // widens, is cut at the rail's edge.
        data._clipLayer.layer = context.pushClipRect(
          needsCompositing,
          offset,
          Rect.fromLTWH(0, data.offset.dy, size.width, child.size.height),
          paintFaded,
          oldLayer: data._clipLayer.layer,
        );
      } else {
        data._clipLayer.layer = null;
        paintFaded(context, offset);
      }
      child = data.nextSibling;
    }
  }

  final LayerHandle<ClipRectLayer> _overflowClipLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _overflowClipLayer.layer = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_clip || _overflow <= precisionErrorTolerance) {
      _overflowClipLayer.layer = null;
      _paintChildren(context, offset);
      return;
    }
    _overflowClipLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      _paintChildren,
      oldLayer: _overflowClipLayer.layer,
    );
    assert(() {
      paintOverflowIndicator(
        context,
        offset,
        Offset.zero & size,
        Offset.zero & Size(size.width, size.height + _overflow),
        overflowHints: [
          ErrorDescription(
            "The group of a NavigationRail does not fit, and the rail's "
            'scrollable is false.',
          ),
        ],
      );
      return true;
    }());
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final data = child.parentData! as RailColumnParentData;
      final visible = Rect.fromLTWH(
        0,
        data.offset.dy,
        size.width,
        child.size.height,
      );
      if (data._reveal >= 0.5 && visible.contains(position)) {
        final hit = result.addWithPaintOffset(
          offset: data.offset,
          position: position,
          hitTest: (result, transformed) =>
              child!.hitTest(result, position: transformed),
        );
        if (hit) return true;
      }
      child = data.previousSibling;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as RailColumnParentData;
      if (data._reveal > 0) visitor(child);
      child = data.nextSibling;
    }
  }
}

/// Stacks a rail's destinations with the space between them closing as the
/// rail expands. A tab bar when [isTabBar].
class RailDestinationList extends MultiChildRenderObjectWidget {
  /// Creates a destination list.
  const RailDestinationList({
    super.key,
    required this.morph,
    required this.itemSpace,
    required this.isTabBar,
    required super.children,
  });

  /// The expansion progress.
  final Animation<double> morph;

  /// The space between collapsed destinations.
  final double itemSpace;

  /// Whether the list is a tab bar for assistive technology.
  final bool isTabBar;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRailDestinationList(
        morph: morph,
        itemSpace: itemSpace,
        isTabBar: isTabBar,
      );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRailDestinationList)
      ..morph = morph
      ..itemSpace = itemSpace
      ..isTabBar = isTabBar;
  }
}

class _RenderRailDestinationList extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ListParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ListParentData> {
  _RenderRailDestinationList({
    required this._morph,
    required this._itemSpace,
    required this._isTabBar,
  });

  Animation<double> _morph;
  set morph(Animation<double> value) {
    if (value == _morph) return;
    if (attached) _morph.removeListener(markNeedsLayout);
    _morph = value;
    if (attached) _morph.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  double _itemSpace;
  set itemSpace(double value) {
    if (value == _itemSpace) return;
    _itemSpace = value;
    markNeedsLayout();
  }

  bool _isTabBar;
  set isTabBar(bool value) {
    if (value == _isTabBar) return;
    _isTabBar = value;
    markNeedsSemanticsUpdate();
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
    if (child.parentData is! _ListParentData) {
      child.parentData = _ListParentData();
    }
  }

  double get _gap => lerpDouble(_itemSpace, 0, _morph.value.clamp(0.0, 1.0))!;

  Size _measure(
    BoxConstraints constraints,
    ChildLayouter layoutChild, {
    required bool dry,
  }) {
    final width = constraints.maxWidth;
    final gap = _gap;
    var y = 0.0;
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _ListParentData;
      if (child != firstChild) y += gap;
      final size = layoutChild(child, BoxConstraints.tightFor(width: width));
      if (!dry) data.offset = Offset(0, y);
      y += size.height;
      child = data.nextSibling;
    }
    return constraints.constrain(Size(width, y));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.hasBoundedWidth
      ? _measure(constraints, ChildLayoutHelper.dryLayoutChild, dry: true)
      : constraints.smallest;

  @override
  double computeMinIntrinsicHeight(double width) =>
      getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    size = _measure(constraints, ChildLayoutHelper.layoutChild, dry: false);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (!_isTabBar || firstChild == null) return;
    config
      ..isSemanticBoundary = true
      ..explicitChildNodes = true
      ..role = SemanticsRole.tabBar;
  }
}

class _ListParentData extends ContainerBoxParentData<RenderBox> {}

/// Places a header widget of a rail: centered in the collapsed rail's
/// [pinWidth], and, with an [expandedInset], moving to that inset from the
/// start as the rail expands.
///
/// With an inset, the widget is never centered nearer the start than the
/// inset, so that one wider than the collapsed rail leaves room for, such as
/// a floating action button that extends with the rail, keeps its start
/// still as it widens.
class RailHeaderAlign extends SingleChildRenderObjectWidget {
  /// Creates the placement.
  const RailHeaderAlign({
    super.key,
    required this.morph,
    required this.pinWidth,
    this.expandedInset,
    super.child,
  });

  /// The expansion progress.
  final Animation<double> morph;

  /// The width the child centers in while collapsed.
  final double pinWidth;

  /// The child's distance from the start once expanded, or null to stay
  /// centered in [pinWidth].
  final double? expandedInset;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRailHeaderAlign(
        morph: morph,
        pinWidth: pinWidth,
        expandedInset: expandedInset,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRailHeaderAlign)
      ..morph = morph
      ..pinWidth = pinWidth
      ..expandedInset = expandedInset
      ..textDirection = Directionality.of(context);
  }
}

class _RenderRailHeaderAlign extends RenderShiftedBox {
  _RenderRailHeaderAlign({
    required this._morph,
    required this._pinWidth,
    required this._expandedInset,
    required this._textDirection,
  }) : super(null);

  Animation<double> _morph;
  set morph(Animation<double> value) {
    if (value == _morph) return;
    if (attached) _morph.removeListener(markNeedsLayout);
    _morph = value;
    if (attached) _morph.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  double _pinWidth;
  set pinWidth(double value) {
    if (value == _pinWidth) return;
    _pinWidth = value;
    markNeedsLayout();
  }

  double? _expandedInset;
  set expandedInset(double? value) {
    if (value == _expandedInset) return;
    _expandedInset = value;
    markNeedsLayout();
  }

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
  Size computeDryLayout(BoxConstraints constraints) {
    final childSize = child?.getDryLayout(constraints.loosen()) ?? Size.zero;
    return constraints.constrain(Size(constraints.maxWidth, childSize.height));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(constraints.maxWidth, 0));
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    final width = constraints.maxWidth;
    final centered = (_pinWidth - child.size.width) / 2;
    final inset = _expandedInset;
    final x = inset == null
        ? centered
        : lerpDouble(
            math.max(centered, inset),
            inset,
            _morph.value.clamp(0.0, 1.0),
          )!;
    (child.parentData! as BoxParentData).offset = Offset(
      _textDirection == TextDirection.ltr ? x : width - x - child.size.width,
      0,
    );
    size = constraints.constrain(Size(width, child.size.height));
  }
}
