import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationRail, NavigationDestination;
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;

import 'navigation_destination.dart';
import 'navigation_motion.dart';

/// An imperative handle to the nearest [NavigationRail].
///
/// Obtained with [NavigationRail.of]. A descendant — typically a menu button in
/// the rail's [NavigationRail.leading] slot — uses the handle to expand the rail
/// [open] inline or as a [openModal] overlay, and to [close] it again. The
/// modality is chosen at the moment of opening rather than fixed when the rail
/// is built.
///
/// ```dart
/// IconButton(
///   icon: const Icon(Icons.menu),
///   onPressed: NavigationRail.of(context).toggle,
/// )
/// ```
abstract class NavigationRailHandle {
  /// Expands the rail in place, pushing the adjacent content aside.
  ///
  /// The expanded rail is persistent until [close] is called.
  void open();

  /// Expands the rail as a temporary modal surface drawn over the content,
  /// behind a scrim.
  ///
  /// The body does not reflow. The overlay is dismissed by tapping the scrim or,
  /// per Material 3, by selecting a destination. Requires an [Overlay] ancestor
  /// (provided by every [MaterialApp]) and a rail at the leading edge of the
  /// window.
  void openModal();

  /// Collapses the rail, whether it was opened with [open] or [openModal].
  void close();

  /// Calls [close] if the rail is open, otherwise [open].
  void toggle();

  /// Calls [close] if the rail is open, otherwise [openModal].
  void toggleModal();

  /// Whether the rail is currently expanded, inline or modal.
  bool get isOpen;

  /// Whether the rail is currently expanded as a modal overlay.
  bool get isModal;

  /// The collapsed-to-expanded animation, where 0 is collapsed and 1 is
  /// expanded.
  ///
  /// Drive a [NavigationRail.leading] menu button or a floating action button
  /// that should morph in sync with the rail from this animation.
  Animation<double> get expandAnimation;
}

/// A Material 3 Expressive navigation rail with collapsed and expanded states.
///
/// The rail morphs smoothly between two forms:
///
///  * Collapsed ([expanded] is `false`): destinations are laid out vertically,
///    each an icon in a pill-shaped indicator with the label below it.
///  * Expanded ([expanded] is `true`): destinations are laid out horizontally,
///    the icon and label side by side inside a pill that hugs the content or
///    fills the rail (see [NavigationRailStyle.expandedIndicatorSize]).
///
/// As the rail expands, the indicator grows from its collapsed pill to its
/// expanded form, the label slides in beside the icon, and the below-label
/// collapses away. Destinations scroll when they do not fit (see
/// [NavigationRailStyle.scrollable]).
///
/// The rail owns its expand state; [expanded] only seeds the initial value.
/// Drive it imperatively through [NavigationRail.of]: a descendant — typically
/// a menu button in [leading] — calls [NavigationRailHandle.open] to widen it
/// in place, [NavigationRailHandle.openModal] to open it as a scrimmed overlay,
/// or [NavigationRailHandle.close] for either. The modality is chosen when the rail
/// is opened, not fixed at construction.
///
/// See also:
///
///  * [NavigationRailStyle], the Material 3 token bundle that drives the rail's
///    appearance.
///  * [NavigationMotion], which controls how the collapsed-to-expanded
///    transition animates.
class NavigationRail extends StatefulWidget {
  /// Creates a Material 3 Expressive navigation rail.
  ///
  /// The [selectedIndex], if non-null, must be a valid index into
  /// [destinations]. [minWidth] and [expandedWidth], if given, must be positive.
  const NavigationRail({
    super.key,
    required this.destinations,
    this.selectedIndex,
    this.onDestinationSelected,
    this.expanded = false,
    this.onExpandedChanged,
    this.style,
    this.motion = const NavigationMotion.expressive(),
    this.modalMotion =
        const NavigationMotion.expressive(spring: NavigationMotion.fastSpatial),
    this.minWidth,
    this.expandedWidth,
    this.expandedIndicatorSize,
    this.groupAlignment,
    this.labelBehavior = NavigationLabelBehavior.all,
    this.leading,
    this.floatingActionButton,
    this.trailing,
    this.expandedBody,
    this.backgroundColor,
    this.indicatorColor,
    this.scrimColor,
  })  : assert(
            selectedIndex == null ||
                (selectedIndex >= 0 && selectedIndex < destinations.length),
            'selectedIndex must be null or a valid index into destinations.'),
        assert(minWidth == null || minWidth > 0, 'minWidth must be positive.'),
        assert(expandedWidth == null || expandedWidth > 0,
            'expandedWidth must be positive.');

  /// The destinations displayed in the rail.
  final List<NavigationDestination> destinations;

  /// The index of the currently selected destination, or null if none is selected.
  final int? selectedIndex;

  /// Called with the index of a destination when it is tapped.
  final ValueChanged<int>? onDestinationSelected;

  /// Whether the rail starts expanded inline.
  ///
  /// The rail starts collapsed when `false`. It owns its expand state once
  /// built; open and close it through [NavigationRail.of]. Changing this value
  /// later reseeds the state, forcing the rail open or closed.
  final bool expanded;

  /// Called with the new open state whenever it changes, whether from an
  /// open/close call or a reseed of [expanded].
  ///
  /// Optional. The rail manages its own state, so nothing needs to be fed back;
  /// use this to persist the user's preference if desired.
  final ValueChanged<bool>? onExpandedChanged;

  /// The tokens that drive the rail's appearance, applied over the ambient
  /// theme's [NavigationRailStyle] extension and the Material 3 defaults.
  ///
  /// Only the tokens set here take effect; the rest resolve as described in
  /// [NavigationRailStyle.of]. By default the rail is the Material 3 Expressive
  /// one: 96dp collapsed, expanding to fit its destinations within 220-360dp.
  final NavigationRailStyle? style;

  /// How the collapsed-to-expanded transition animates for an inline rail.
  ///
  /// Material 3 Expressive spatial spring physics drive the morph
  /// ([NavigationMotion.expressive] with [NavigationMotion.defaultSpatial]);
  /// pass [NavigationMotion.standard] for a fixed emphasized duration and
  /// curve.
  final NavigationMotion motion;

  /// How the rail animates while opening and closing as a modal overlay.
  ///
  /// Material 3 Expressive uses the quicker fast spatial spring
  /// ([NavigationMotion.fastSpatial]) for the modal rail.
  final NavigationMotion modalMotion;

  /// Overrides the collapsed width.
  ///
  /// When null, falls back to the [style]'s [NavigationRailStyle.minWidth]
  /// (Material 3 Expressive: 96dp, baseline: 80dp). Must be positive.
  final double? minWidth;

  /// Overrides the expanded width.
  ///
  /// When null, falls back to the [style]'s [NavigationRailStyle.expandedWidth],
  /// and when that is unset too, the rail is as wide as its widest destination
  /// within [NavigationRailStyle.expandedMinWidth] and
  /// [NavigationRailStyle.expandedMaxWidth] (Material 3: 220-360dp). Must be
  /// positive.
  final double? expandedWidth;

  /// Overrides how the expanded active indicator is sized.
  ///
  /// Either [NavigationIndicatorSize.fill] for full width or
  /// [NavigationIndicatorSize.label] to hug the icon and label content. When
  /// null, falls back to the [style]'s
  /// [NavigationRailStyle.expandedIndicatorSize].
  final NavigationIndicatorSize? expandedIndicatorSize;

  /// Overrides where the destinations sit vertically along the rail, from -1.0
  /// (top) through 0.0 (centered in the rail) to 1.0 (bottom).
  ///
  /// Measured against the rail's whole height, as Material 3 does, but kept
  /// clear of the [leading] and [floatingActionButton] header and of
  /// [trailing]: when the position asked for would overlap them, the
  /// destinations are placed as close to it as the room allows. [expandedBody]
  /// follows below them without moving them. When null, falls back to the
  /// [style]'s [NavigationRailStyle.groupAlignment].
  final double? groupAlignment;

  /// Whether collapsed below-labels are always shown, shown only for the
  /// selected destination, or hidden.
  ///
  /// Expanded destinations always show their label beside the icon
  /// regardless of this value.
  final NavigationLabelBehavior labelBehavior;

  /// A widget pinned at the very top of the rail, such as a menu button that
  /// toggles the rail open, or a custom header.
  final Widget? leading;

  /// A widget shown just below the [leading] widget. Usually a [FloatingActionButton].
  final Widget? floatingActionButton;

  /// A widget pinned at the bottom of the rail, below the destinations.
  final Widget? trailing;

  /// Content shown only while the rail is expanded.
  ///
  /// Per Material 3, an expanded rail can reveal secondary destinations that
  /// are not visible when collapsed; this slot is where they go.
  ///
  /// Revealed below the destinations as the rail expands and removed when fully
  /// collapsed. Unlike [trailing], which is always visible and pinned at the
  /// bottom, this is for content that only makes sense at full width — secondary
  /// links, a section list, an account row — and it scrolls with the
  /// destinations, which stay where [groupAlignment] puts them however tall it
  /// grows.
  final Widget? expandedBody;

  /// The container color.
  ///
  /// When null, falls back to the [style]'s [NavigationRailStyle.containerColor]
  /// for the inline rail (Material 3 surface) or
  /// [NavigationRailStyle.modalColor] for the modal overlay (Material 3
  /// surfaceContainer).
  final Color? backgroundColor;

  /// The active indicator color.
  ///
  /// When null, falls back to the [style]'s
  /// [NavigationRailStyle.indicatorColor] (Material 3 secondaryContainer).
  final Color? indicatorColor;

  /// The scrim painted over the content while the rail is open via
  /// [NavigationRailHandle.openModal].
  ///
  /// Its opacity is scaled by the open progress. Ignored for an inline rail.
  /// When null, falls back to the [style]'s [NavigationRailStyle.scrimColor].
  final Color? scrimColor;

  /// The [NavigationRailHandle] for the nearest [NavigationRail] enclosing the
  /// given [context].
  ///
  /// Asserts if there is no rail above [context]. Use the handle to open, open
  /// as a modal, or close the rail, or to read its
  /// [NavigationRailHandle.expandAnimation].
  ///
  /// See also [maybeOf], which returns null instead of asserting.
  static NavigationRailHandle of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_RailScope>();
    assert(scope != null, 'No NavigationRail above this context.');
    return scope!;
  }

  /// The [NavigationRailHandle] for the nearest [NavigationRail] enclosing the
  /// given [context], or null if there is none.
  ///
  /// See also [of], which asserts instead of returning null.
  static NavigationRailHandle? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RailScope>();

  @override
  State<NavigationRail> createState() => _NavigationRailState();
}

class _NavigationRailState extends State<NavigationRail>
    with TickerProviderStateMixin {
  // One controller per destination drives the active indicator's scale/fade.
  late List<AnimationController> _destinationControllers;
  late List<Animation<double>> _destinationAnimations;
  // Drives the collapsed↔expanded morph (width, indicator, label reveal). It is
  // unbounded so the expressive spring can overshoot for the modal overlay;
  // [_expandClamped] is the settled 0..1 view handed to destinations and the
  // handle, which doesn't follow the spring's settling bounces.
  late AnimationController _expandController;
  late Animation<double> _expandClamped;
  // The same view for the inline rail, pinned at 0 while the rail is modal
  // (the overlay does the morphing then). One object for the rail's lifetime,
  // so a handle read before a modal opening keeps working after it.
  late Animation<double> _inlineExpand;
  // The room the header and the trailing widget take, measured by [_RailLayout]
  // and read by [_RenderRailGroup] in the same layout pass.
  final _RailInsets _insets = _RailInsets();
  // The rail owns its expand state; [widget.expanded] only seeds it.
  late bool _open;
  // Whether the open rail is shown as a modal overlay (vs inline).
  bool _modal = false;
  // The modal overlay surface (scrim + expanded rail). It is painted into the
  // nearest Overlay but built in this rail's own subtree, so it rebuilds with
  // the rail and inherits what the rail inherits.
  final OverlayPortalController _modalOverlay = OverlayPortalController();
  // Whether the modal overlay should be showing; [_syncModalOverlay] applies it.
  bool _modalShown = false;

  bool get _modalOpen => _open && _modal;

  // Imperative control, delegated to _RailScope (the handle).

  void open() => _applyOpen(true, false);

  void openModal() => _applyOpen(true, true);

  void close() => _applyOpen(false, _modal);

  void toggle() => _open ? close() : open();

  void toggleModal() => _open ? close() : openModal();

  @override
  void initState() {
    super.initState();
    _open = widget.expanded;
    _initDestinationControllers();
    // Created once for the rail's lifetime, so the animations handed out
    // through NavigationRail.of stay live. Both motions pass their timing when
    // they animate, so a new [NavigationRail.motion] needs no new controller.
    _expandController = widget.motion
        .createController(this, _open ? 1.0 : 0.0, bounded: false)
      ..addListener(_rebuild);
    _expandClamped = _SettledAnimation(_expandController, () => _open);
    _inlineExpand = _SettledAnimation(_expandController, () => _open,
        collapsed: () => _modal);
    if (_modalOpen) _showModalOverlay();
  }

  @override
  void didUpdateWidget(NavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A changed [expanded] reseeds the open state (forcing it open or closed),
    // keeping the current modality.
    if (widget.expanded != oldWidget.expanded) {
      _applyOpen(widget.expanded, _modal);
    }
    if (widget.destinations.length != oldWidget.destinations.length) {
      _disposeDestinationControllers();
      _initDestinationControllers();
      return;
    }
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      if (oldWidget.selectedIndex != null) {
        _destinationControllers[oldWidget.selectedIndex!].reverse();
      }
      if (widget.selectedIndex != null) {
        _destinationControllers[widget.selectedIndex!].forward();
      }
    }
  }

  @override
  void dispose() {
    _disposeDestinationControllers();
    _expandController.dispose();
    super.dispose();
  }

  void _applyOpen(bool open, bool modal) {
    if (open == _open && modal == _modal) return;
    final openChanged = open != _open;
    setState(() {
      _open = open;
      _modal = modal;
    });
    (modal ? widget.modalMotion : widget.motion)
        .animateTo(_expandController, open ? 1.0 : 0.0);
    if (openChanged) widget.onExpandedChanged?.call(open);
    _reconcileOverlay();
  }

  void _reconcileOverlay() {
    if (_modalOpen) {
      _showModalOverlay();
    } else if (_open) {
      // Switched to inline while open — drop the overlay now (the morph stays
      // forward, so the collapse callback won't fire to remove it).
      _hideModalOverlay();
    }
    // Closing: the overlay fades out and is removed when the collapse settles.
  }

  // Collapse-on-select for the modal rail (M3): selecting fires the callback
  // and dismisses the temporary surface. An inline rail stays put.
  void _onDestinationSelected(int index) {
    widget.onDestinationSelected?.call(index);
    if (_modalOpen) close();
  }

  void _initDestinationControllers() {
    _destinationControllers = List<AnimationController>.generate(
      widget.destinations.length,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      )..addListener(_rebuild),
    );
    _destinationAnimations =
        _destinationControllers.map((c) => c.view).toList();
    if (widget.selectedIndex != null) {
      _destinationControllers[widget.selectedIndex!].value = 1.0;
    }
  }

  void _disposeDestinationControllers() {
    for (final c in _destinationControllers) {
      c.dispose();
    }
  }

  void _rebuild() {
    if (_modalShown && !_open && _expandController.value <= 0.001) {
      _hideModalOverlay();
    }
    setState(() {});
  }

  void _showModalOverlay() {
    if (_modalShown) return;
    _modalShown = true;
    _syncModalOverlay();
  }

  void _hideModalOverlay() {
    if (!_modalShown) return;
    _modalShown = false;
    _syncModalOverlay();
  }

  void _syncModalOverlay() {
    // Showing or hiding the overlay during build (e.g. from didUpdateWidget)
    // throws; defer to the next frame in that case, otherwise apply it at once
    // so a user tap opens it without a frame of lag.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncModalOverlay();
      });
      return;
    }
    if (_modalShown == _modalOverlay.isShowing) return;
    if (_modalShown) {
      _modalOverlay.show();
    } else {
      _modalOverlay.hide();
    }
  }

  // Resolves the active style: [NavigationRail.style] over the theme's
  // extension over the variant's defaults.
  NavigationRailStyle _resolveStyle(BuildContext context) =>
      NavigationRailStyle.of(context, widget.style);

  // The expanded width: fixed by the widget or the style, or else just wide
  // enough for the widest destination, within the style's bounds.
  double _expandedWidth(BuildContext context, NavigationRailStyle style) {
    final fixed = widget.expandedWidth ?? style.expandedWidth;
    if (fixed != null) return fixed;
    final labelStyle = style.horizontalLabelStyle!
        .copyWith(fontWeight: style.activeLabelWeight);
    var widest = 0.0;
    for (final destination in widget.destinations) {
      final painter = TextPainter(
        text: TextSpan(text: destination.label, style: labelStyle),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    final fit = 2 * style.expandedPillHorizontalMargin! +
        _besideLabelStart(style) +
        widest +
        style.horizontalTrailingSpace!;
    final min = style.expandedMinWidth!;
    return fit.clamp(min, math.max(min, style.expandedMaxWidth!));
  }

  // Pins a top widget to a collapsed-width box at the rail's start, centered — so
  // it sits over the collapsed rail and doesn't drift as the rail extends.
  Widget _pinned(Widget child, double minWidth) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: minWidth,
          child: Center(child: child),
        ),
      );

  // The rail's content column, shared by the inline surface and the modal
  // overlay. [expandAnimation] drives each destination's morph; [expandValue]
  // (the 0→1 progress to use for width/padding/reveal lerps) lets the inline
  // copy stay pinned collapsed in modal mode while the overlay copy morphs.
  Widget _railColumn({
    required NavigationRailStyle style,
    required double minWidth,
    required double expandedWidth,
    required Animation<double> expandAnimation,
    required double expandValue,
    required bool includeExpandedBody,
    required Color indicatorColor,
  }) {
    final expandedBodyReveal =
        const Interval(0.5, 1.0).transform(expandValue.clamp(0.0, 1.0));
    final itemStyle = _destinationStyle(style);
    final hasHeader =
        widget.leading != null || widget.floatingActionButton != null;
    final destinationsColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.destinations.length; i++)
          NavigationDestination.custom(
            icon: widget.destinations[i].icon,
            selectedIcon: widget.destinations[i].selectedIcon,
            label: widget.destinations[i].label,
            tooltip: widget.destinations[i].tooltip,
            disabled: widget.destinations[i].disabled,
            selected: widget.selectedIndex == i,
            labelBehavior: widget.labelBehavior,
            indicatorColor: indicatorColor,
            iconSize: style.iconSize!,
            minWidth: minWidth,
            expandedWidth: expandedWidth,
            collapsedIndicatorWidth: style.collapsedIndicatorWidth!,
            collapsedIndicatorHeight: style.verticalIndicatorHeight!,
            expandedIndicatorHeight: style.horizontalIndicatorHeight!,
            besideLabelStart: _besideLabelStart(style),
            labelTrailingSpace: style.horizontalTrailingSpace!,
            belowLabelSpacing: style.verticalIconLabelSpacing!,
            horizontalMargin: style.expandedPillHorizontalMargin!,
            indicatorSize:
                widget.expandedIndicatorSize ?? style.expandedIndicatorSize!,
            centered: false,
            itemSpace: style.itemSpace!,
            collapsedMinHeight: style.collapsedItemMinHeight!,
            expandedMinHeight: style.expandedItemMinHeight!,
            style: itemStyle,
            destinationAnimation: _destinationAnimations[i],
            expandAnimation: expandAnimation,
            onTap: !widget.destinations[i].disabled &&
                    widget.onDestinationSelected != null
                ? () => _onDestinationSelected(i)
                : null,
          ),
      ],
    );
    // Revealed below the destinations, which stay where [groupAlignment] puts
    // them; it scrolls into view rather than pushing them around.
    final body = includeExpandedBody &&
            widget.expandedBody != null &&
            expandedBodyReveal > 0
        ? ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: expandedBodyReveal,
                child: widget.expandedBody!,
              ),
            ),
          )
        : null;
    // Plain destinations in the rail's slots (trailing, expandedBody) take the
    // same layout and style as its own.
    NavigationDestinationLayout destinationLayout({
      required Widget child,
      double? itemSpace,
      double? collapsedMinHeight,
      double? expandedMinHeight,
    }) =>
        NavigationDestinationLayout(
          labelBehavior: widget.labelBehavior,
          indicatorSize:
              widget.expandedIndicatorSize ?? style.expandedIndicatorSize!,
          indicatorColor: indicatorColor,
          iconSize: style.iconSize!,
          minWidth: minWidth,
          expandedWidth: expandedWidth,
          collapsedIndicatorHeight: style.verticalIndicatorHeight!,
          collapsedIndicatorWidth: style.collapsedIndicatorWidth!,
          expandedIndicatorHeight: style.horizontalIndicatorHeight!,
          belowLabelSpacing: style.verticalIconLabelSpacing!,
          besideLabelStart: _besideLabelStart(style),
          horizontalMargin: style.expandedPillHorizontalMargin!,
          itemSpace: itemSpace ?? style.itemSpace!,
          collapsedMinHeight:
              collapsedMinHeight ?? style.collapsedItemMinHeight!,
          expandedMinHeight: expandedMinHeight ?? style.expandedItemMinHeight!,
          labelTrailingSpace: style.horizontalTrailingSpace!,
          style: itemStyle,
          child: child,
        );
    return destinationLayout(
      child: CustomMultiChildLayout(
        delegate: _RailLayout(
            headerSpace: hasHeader ? style.headerSpace! : 0, insets: _insets),
        children: [
          LayoutId(
            id: _RailSlot.header,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: style.topSpace),
                if (widget.leading != null) _pinned(widget.leading!, minWidth),
                if (widget.floatingActionButton != null) ...[
                  if (widget.leading != null) SizedBox(height: style.fabSpace),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: lerpDouble(
                          (minWidth - style.collapsedIndicatorWidth!) / 2,
                          style.expandedPillHorizontalMargin,
                          expandValue,
                        )!
                            .clamp(0.0, double.infinity),
                      ),
                      child: widget.floatingActionButton!,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Scrolls when the destinations don't fit, unless the style turns
          // that off.
          LayoutId(
            id: _RailSlot.destinations,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final children = <Widget>[destinationsColumn];
                if (body != null) children.add(body);
                final group = _RailGroup(
                  alignment: widget.groupAlignment ?? style.groupAlignment!,
                  viewportHeight: constraints.maxHeight,
                  insets: _insets,
                  children: children,
                );
                return style.scrollable!
                    ? SingleChildScrollView(child: group)
                    : group;
              },
            ),
          ),
          if (widget.trailing != null)
            LayoutId(
              id: _RailSlot.trailing,
              // Pinned to the bottom, so a destination here keeps one height
              // through the morph and has no gap to a neighbour: otherwise it
              // would shrink from the top and its content would slide down
              // while the rail's own destinations stay put.
              child: destinationLayout(
                itemSpace: 0,
                expandedMinHeight: style.collapsedItemMinHeight!,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expanded vertical trailing space (M3 20dp), revealed as
                    // it extends.
                    SizedBox(
                        height:
                            style.trailingSpace! * expandValue.clamp(0.0, 1.0)),
                    widget.trailing!,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // The scrimmed, full-height overlay shown while modal-open. The expanded-width
  // surface slides in from the leading edge.
  Widget _buildModalOverlay(BuildContext context) {
    final style = _resolveStyle(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final indicatorColor = widget.indicatorColor ?? style.indicatorColor!;
    final minWidth = widget.minWidth ?? style.minWidth!;
    final expandedWidth = _expandedWidth(context, style);
    // The surface's trailing edge follows the raw spring, overshoot included;
    // everything else follows the settled 0..1 progress.
    final raw = _expandController.value;
    final t = _expandClamped.value;
    final start = lerpDouble(-expandedWidth, 0, t)!;
    final contentWidth = lerpDouble(minWidth, expandedWidth, t)!;
    // The spring overshoots past 1 on open; let the surface's inner (trailing)
    // edge spring a touch past its rest width then settle, while its leading
    // edge stays pinned to the screen edge (no gap).
    final surfaceWidth = expandedWidth * raw.clamp(1.0, style.modalOvershoot!);
    final scrim = Color.lerp(
        Colors.transparent, widget.scrimColor ?? style.scrimColor, t)!;
    // Modal surface (M3): surface-container, elevation 3dp, 16dp large rounding
    // on the trailing (inner) edge.
    final radius = Radius.circular(style.modalCornerRadius!);

    return _RailScope(
      state: this,
      expandAnimation: _expandClamped,
      isOpen: _open,
      isModal: _modal,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
              child: ColoredBox(color: scrim),
            ),
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: start,
            child: Material(
              color: widget.backgroundColor ?? style.modalColor,
              elevation: style.modalElevation!,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.horizontal(end: radius),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(width: surfaceWidth),
            ),
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: 0,
            child: Material(
              type: MaterialType.transparency,
              child: SafeArea(
                right: isRtl,
                left: !isRtl,
                bottom: false,
                child: SizedBox(
                  width: contentWidth,
                  child: _railColumn(
                    style: style,
                    minWidth: minWidth,
                    expandedWidth: expandedWidth,
                    expandAnimation: _expandClamped,
                    expandValue: t,
                    includeExpandedBody: true,
                    indicatorColor: indicatorColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final indicatorColor = widget.indicatorColor ?? style.indicatorColor!;
    final minWidth = widget.minWidth ?? style.minWidth!;
    final expandedWidth = _expandedWidth(context, style);
    for (final controller in _destinationControllers) {
      controller.duration = style.selectionDuration;
    }
    // Inline footprint: morphs in place when open inline; pinned collapsed when
    // modal (the expanded form lives in the overlay) or closed. Uses the clamped
    // value so an inline rail never overshoots its width and jostles the body.
    final inlineValue = _inlineExpand.value;
    final width = lerpDouble(minWidth, expandedWidth, inlineValue)!;

    final rail = _RailScope(
      state: this,
      expandAnimation: _inlineExpand,
      isOpen: _open,
      isModal: _modal,
      child: Material(
        color: widget.backgroundColor ?? style.containerColor,
        elevation: style.elevation!,
        surfaceTintColor: Colors.transparent,
        child: SafeArea(
          right: isRtl,
          left: !isRtl,
          bottom: false,
          child: SizedBox(
            width: width,
            child: !_modalShown
                ? _railColumn(
                    style: style,
                    minWidth: minWidth,
                    expandedWidth: expandedWidth,
                    expandAnimation: _inlineExpand,
                    expandValue: inlineValue,
                    includeExpandedBody: !_modal,
                    indicatorColor: indicatorColor,
                  )
                : null,
          ),
        ),
      ),
    );
    return OverlayPortal(
      controller: _modalOverlay,
      overlayChildBuilder: _buildModalOverlay,
      child: rail,
    );
  }
}

// The rail's handle, exposed to descendants and backing NavigationRail.of /
// maybeOf. It carries each copy's expand animation (the inline copy is pinned
// collapsed under a modal overlay) and delegates control to the rail [state].
class _RailScope extends InheritedWidget implements NavigationRailHandle {
  const _RailScope({
    required this.state,
    required this.expandAnimation,
    required this.isOpen,
    required this.isModal,
    required super.child,
  });

  final _NavigationRailState state;

  @override
  final Animation<double> expandAnimation;

  @override
  final bool isOpen;

  @override
  final bool isModal;

  @override
  void open() => state.open();

  @override
  void openModal() => state.openModal();

  @override
  void close() => state.close();

  @override
  void toggle() => state.toggle();

  @override
  void toggleModal() => state.toggleModal();

  @override
  bool updateShouldNotify(_RailScope old) =>
      state != old.state ||
      expandAnimation != old.expandAnimation ||
      isOpen != old.isOpen ||
      isModal != old.isModal;
}

/// The visual tokens that drive a [NavigationRail].
///
/// Bundles every value the rail renders: its collapsed, expanded and modal
/// container, active indicator dimensions and shape, icon and label colors,
/// label text styles, state layers, and spacing.
///
/// Every token is optional. A rail resolves its style with [of]: the style
/// passed to [NavigationRail.style], over the [NavigationRailStyle] registered
/// in the ambient [ThemeData.extensions], over the Material 3 defaults for the
/// chosen [variant] computed from the theme's [ColorScheme] and [TextTheme]. So
/// the defaults follow light and dark themes, and an app can set a few tokens
/// once for every rail:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [NavigationRailStyle(expandedWidth: 320)],
///   ),
/// )
/// ```
///
/// [NavigationRailStyle.expressive] and [NavigationRailStyle.baseline] build a
/// complete style for a given [ColorScheme] and [TextTheme].
@immutable
class NavigationRailStyle extends ThemeExtension<NavigationRailStyle>
    with Diagnosticable {
  /// Creates a rail style.
  ///
  /// Every token is optional. Tokens left null fall back, when the style is
  /// resolved by [of], to the ambient theme's extension and then to the
  /// defaults of the chosen [variant].
  const NavigationRailStyle({
    this.variant,
    this.minWidth,
    this.expandedWidth,
    this.expandedMinWidth,
    this.expandedMaxWidth,
    this.containerColor,
    this.elevation,
    this.modalColor,
    this.modalElevation,
    this.modalCornerRadius,
    this.modalOvershoot,
    this.scrimColor,
    this.indicatorColor,
    this.indicatorShape,
    this.useIndicator,
    this.expandedIndicatorSize,
    this.iconSize,
    this.collapsedIndicatorWidth,
    this.verticalIndicatorHeight,
    this.horizontalIndicatorHeight,
    this.activeIconColor,
    this.inactiveIconColor,
    this.disabledColor,
    this.activeLabelColor,
    this.inactiveLabelColor,
    this.horizontalActiveLabelColor,
    this.activeLabelWeight,
    this.verticalLabelStyle,
    this.horizontalLabelStyle,
    this.labelPadding,
    this.iconLabelSpacing,
    this.verticalIconLabelSpacing,
    this.horizontalLeadingSpace,
    this.horizontalTrailingSpace,
    this.expandedPillHorizontalMargin,
    this.topSpace,
    this.fabSpace,
    this.headerSpace,
    this.itemSpace,
    this.collapsedItemMinHeight,
    this.expandedItemMinHeight,
    this.trailingSpace,
    this.groupAlignment,
    this.scrollable,
    this.stateLayerColor,
    this.hoverOpacity,
    this.focusPressOpacity,
    this.overlayColor,
    this.iconTheme,
    this.labelTextStyle,
    this.selectionDuration,
  });

  /// The complete Material 3 Expressive rail.
  ///
  /// A 96dp collapsed rail on [ColorScheme.surface] that expands to fit its
  /// destinations within 220-360dp, a [ColorScheme.secondaryContainer] active
  /// indicator, and a [ColorScheme.secondary] active label. Colors derive from
  /// [colors] and label styles from [text].
  factory NavigationRailStyle.expressive(ColorScheme colors, TextTheme text) {
    return NavigationRailStyle(
      variant: StyleVariant.material3Expressive,
      minWidth: 96, // spec: collapsed container width 96dp
      expandedMinWidth: 220, // spec: expanded width 220-360dp
      expandedMaxWidth: 360,
      containerColor: colors.surface,
      elevation: 0, // spec: collapsed/expanded elevation 0
      modalColor: colors.surfaceContainer, // spec: modal surface-container
      modalElevation: 3, // spec: modal elevation 3dp
      modalCornerRadius: 16, // spec: modal large rounding 16dp
      modalOvershoot: 1.2,
      scrimColor: colors.scrim.withValues(alpha: 0.32), // spec: scrim 32%
      indicatorColor: colors.secondaryContainer,
      indicatorShape: const StadiumBorder(), // spec: full rounding
      useIndicator: true,
      expandedIndicatorSize: NavigationIndicatorSize.label,
      iconSize: 24, // spec: nav rail item icon size 24dp
      collapsedIndicatorWidth: 56, // spec: vertical active indicator 56dp
      verticalIndicatorHeight: 32, // spec: vertical active indicator 32dp
      horizontalIndicatorHeight: 56, // spec: horizontal active indicator 56dp
      activeIconColor: colors.onSecondaryContainer,
      inactiveIconColor: colors.onSurfaceVariant,
      disabledColor: colors.onSurfaceVariant.withValues(alpha: 0.38),
      activeLabelColor: colors.secondary, // spec: active label secondary
      inactiveLabelColor: colors.onSurfaceVariant,
      horizontalActiveLabelColor: colors.onSecondaryContainer,
      verticalLabelStyle: text.labelMedium!, // spec: vertical label medium
      horizontalLabelStyle: text.labelLarge!, // spec: horizontal label large
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      iconLabelSpacing: 8, // spec: horizontal icon label space 8dp
      verticalIconLabelSpacing: 4, // spec: vertical icon label space 4dp
      horizontalLeadingSpace: 16, // spec: active indicator leading space 16dp
      horizontalTrailingSpace: 16, // spec: active indicator trailing space 16dp
      expandedPillHorizontalMargin: 20, // spec: item horizontal padding 20dp
      topSpace: 44, // spec: top space 44dp
      fabSpace: 8,
      headerSpace: 40, // spec: header space 40dp
      itemSpace: 4, // spec: collapsed item vertical space 4dp
      collapsedItemMinHeight: 64, // spec: collapsed item height 64dp
      expandedItemMinHeight: 48, // spec: expanded item height 48dp
      trailingSpace: 20, // spec: expanded vertical trailing space 20dp
      groupAlignment: -1,
      scrollable: true,
      stateLayerColor: colors.onSecondaryContainer,
      hoverOpacity: 0.08,
      focusPressOpacity: 0.1,
      selectionDuration: const Duration(milliseconds: 200),
    );
  }

  /// The complete Material 3 baseline (pre-Expressive) rail.
  ///
  /// An 80dp collapsed rail, an [ColorScheme.onSurface] active label, and
  /// inactive icons and labels that turn [ColorScheme.onSurface] while hovered,
  /// focused or pressed. The baseline spec has no expanded rail, so expanding
  /// follows the Expressive layout. Colors derive from [colors] and label
  /// styles from [text].
  factory NavigationRailStyle.baseline(ColorScheme colors, TextTheme text) {
    return NavigationRailStyle.expressive(colors, text).copyWith(
      variant: StyleVariant.material3,
      minWidth: 80, // spec: baseline container width 80dp
      activeLabelColor: colors.onSurface, // spec: baseline active label
      // spec: baseline label tracking 0.1pt (Material's labelMedium is 0.5).
      verticalLabelStyle: text.labelMedium!.copyWith(letterSpacing: 0.1),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          _inactiveInteraction(states)
              ? IconThemeData(color: colors.onSurface)
              : null),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          _inactiveInteraction(states)
              ? TextStyle(color: colors.onSurface)
              : null),
    );
  }

  /// The style a [NavigationRail] below [context] renders with.
  ///
  /// Applies [style] (typically [NavigationRail.style]) over the
  /// [NavigationRailStyle] in the ambient [ThemeData.extensions], over the
  /// complete defaults for the resulting [variant] built from the theme's
  /// [ColorScheme] and [TextTheme]. Every token of the result is non-null except
  /// [expandedWidth], [activeLabelWeight], [overlayColor], [iconTheme] and
  /// [labelTextStyle].
  static NavigationRailStyle of(BuildContext context,
      [NavigationRailStyle? style]) {
    final theme = Theme.of(context);
    final themed = theme.extension<NavigationRailStyle>();
    final variant =
        style?.variant ?? themed?.variant ?? StyleVariant.material3Expressive;
    final defaults = switch (variant) {
      StyleVariant.material3 =>
        NavigationRailStyle.baseline(theme.colorScheme, theme.textTheme),
      StyleVariant.material3Expressive =>
        NavigationRailStyle.expressive(theme.colorScheme, theme.textTheme),
    };
    return defaults.merge(themed).merge(style);
  }

  /// Which Material 3 variant supplies the defaults for tokens left null:
  /// [StyleVariant.material3Expressive] (the default) or
  /// [StyleVariant.material3] (baseline).
  ///
  /// Only read by [of], from the style passed in or the theme's extension.
  final StyleVariant? variant;

  /// The collapsed container width (Material 3 Expressive: 96dp; baseline:
  /// 80dp).
  final double? minWidth;

  /// A fixed expanded container width.
  ///
  /// Unset by default: the expanded rail is as wide as its widest destination,
  /// between [expandedMinWidth] and [expandedMaxWidth].
  final double? expandedWidth;

  /// The narrowest the expanded rail sizes itself to (Material 3: 220dp).
  final double? expandedMinWidth;

  /// The widest the expanded rail sizes itself to (Material 3: 360dp).
  final double? expandedMaxWidth;

  /// The inline container color (Material 3: [ColorScheme.surface]).
  final Color? containerColor;

  /// The inline container elevation (Material 3: 0).
  final double? elevation;

  /// The modal container color (Material 3: [ColorScheme.surfaceContainer]).
  final Color? modalColor;

  /// The modal container elevation (Material 3: 3dp).
  final double? modalElevation;

  /// The corner radius of the modal container's trailing edge (Material 3:
  /// 16dp).
  final double? modalCornerRadius;

  /// How far past its width the modal container may stretch while a spring
  /// overshoots on opening, as a factor of the width (1.2).
  final double? modalOvershoot;

  /// The scrim over the content while the rail is open as a modal; its opacity
  /// is scaled by the open progress (Material 3: [ColorScheme.scrim] at 32%
  /// opacity).
  final Color? scrimColor;

  /// The fill color of the active indicator (Material 3:
  /// [ColorScheme.secondaryContainer]).
  final Color? indicatorColor;

  /// The shape of the active indicator, also used to clip the ink drawn over it
  /// (Material 3: full rounding, a [StadiumBorder]).
  final ShapeBorder? indicatorShape;

  /// Whether the active indicator is drawn behind the selected destination
  /// (Material 3: true).
  final bool? useIndicator;

  /// How the expanded active indicator is sized: hugging the icon and label
  /// ([NavigationIndicatorSize.label], Material 3 Expressive) or filling the
  /// rail ([NavigationIndicatorSize.fill]).
  final NavigationIndicatorSize? expandedIndicatorSize;

  /// The size of each destination icon (Material 3: 24dp).
  final double? iconSize;

  /// The width of the collapsed (vertical) active indicator (Material 3: 56dp).
  final double? collapsedIndicatorWidth;

  /// The height of the collapsed (vertical) active indicator (Material 3:
  /// 32dp).
  final double? verticalIndicatorHeight;

  /// The height of the expanded (horizontal) active indicator (Material 3:
  /// 56dp).
  final double? horizontalIndicatorHeight;

  /// The color of the selected destination's icon (Material 3:
  /// [ColorScheme.onSecondaryContainer]).
  final Color? activeIconColor;

  /// The color of unselected destinations' icons (Material 3:
  /// [ColorScheme.onSurfaceVariant]).
  final Color? inactiveIconColor;

  /// The color of a disabled destination's icon and label (Material 3:
  /// [ColorScheme.onSurfaceVariant] at 38% opacity).
  final Color? disabledColor;

  /// The color of the selected destination's below-label (Material 3
  /// Expressive: [ColorScheme.secondary]; baseline: [ColorScheme.onSurface]).
  final Color? activeLabelColor;

  /// The color of unselected destinations' labels (Material 3:
  /// [ColorScheme.onSurfaceVariant]).
  final Color? inactiveLabelColor;

  /// The color of the selected destination's beside-label, which sits inside
  /// the active indicator (Material 3 Expressive: the selected icon color,
  /// [ColorScheme.onSecondaryContainer]).
  final Color? horizontalActiveLabelColor;

  /// The font weight applied to the selected destination's labels.
  ///
  /// Unset by default: Material 3 keeps the label style's own weight.
  final FontWeight? activeLabelWeight;

  /// The label text style in the vertical (icon above label) layout (Material
  /// 3: [TextTheme.labelMedium]).
  final TextStyle? verticalLabelStyle;

  /// The label text style in the horizontal (icon beside label) layout
  /// (Material 3: [TextTheme.labelLarge]).
  final TextStyle? horizontalLabelStyle;

  /// The padding around the below-label, added to [verticalIconLabelSpacing]
  /// above it (4dp on each side).
  final EdgeInsetsGeometry? labelPadding;

  /// The gap between the icon and the label in the horizontal layout (Material
  /// 3: 8dp).
  final double? iconLabelSpacing;

  /// The gap between the active indicator and the below-label in the vertical
  /// layout (Material 3: 4dp).
  final double? verticalIconLabelSpacing;

  /// The space before the icon inside the horizontal active indicator (Material
  /// 3: 16dp).
  final double? horizontalLeadingSpace;

  /// The space after the label inside the horizontal active indicator (Material
  /// 3: 16dp).
  final double? horizontalTrailingSpace;

  /// The inset of the expanded active indicator from the rail's edges (Material
  /// 3 Expressive: 20dp, which keeps the icons in place as the rail expands).
  final double? expandedPillHorizontalMargin;

  /// The space above the rail's content, including the [NavigationRail.leading]
  /// and [NavigationRail.floatingActionButton] header (Material 3: 44dp).
  final double? topSpace;

  /// The gap between [NavigationRail.leading] and
  /// [NavigationRail.floatingActionButton] when both are present (8dp).
  final double? fabSpace;

  /// The gap between the header ([NavigationRail.leading] and
  /// [NavigationRail.floatingActionButton]) and the first destination, when
  /// there is a header (Material 3: 40dp).
  final double? headerSpace;

  /// The gap between collapsed destinations, easing to 0 as the rail expands
  /// (Material 3: 4dp).
  final double? itemSpace;

  /// The minimum height of a collapsed destination (Material 3: 64dp).
  final double? collapsedItemMinHeight;

  /// The minimum height of an expanded destination (Material 3: 48dp).
  final double? expandedItemMinHeight;

  /// The space above [NavigationRail.trailing] once the rail is expanded
  /// (Material 3: 20dp).
  final double? trailingSpace;

  /// Where the destinations sit vertically along the rail's height, from -1.0
  /// (top) through 0.0 (centered in the rail) to 1.0 (bottom). Defaults to
  /// -1.0.
  ///
  /// Measured against the rail's whole height, as Material 3 does, but kept
  /// clear of the header and the trailing widget: when the position asked for
  /// would overlap them, the destinations are placed as close to it as the
  /// room allows. [NavigationRail.expandedBody] follows below them without
  /// moving them.
  final double? groupAlignment;

  /// Whether the destinations scroll when they do not fit (true). When false,
  /// destinations that do not fit overflow.
  final bool? scrollable;

  /// The color of the hover, focus and pressed state layers (Material 3:
  /// [ColorScheme.onSecondaryContainer]).
  ///
  /// Ignored when [overlayColor] is set.
  final Color? stateLayerColor;

  /// The opacity of the hover state layer (Material 3: 0.08).
  final double? hoverOpacity;

  /// The opacity of the focus and pressed state layers (Material 3: 0.10).
  final double? focusPressOpacity;

  /// The state layer color per [WidgetState], replacing the one built from
  /// [stateLayerColor], [hoverOpacity] and [focusPressOpacity].
  final WidgetStateProperty<Color?>? overlayColor;

  /// Per-state icon theme, merged over the icon's resolved size and color.
  ///
  /// Resolved against [WidgetState.selected], [WidgetState.disabled],
  /// [WidgetState.hovered], [WidgetState.focused] and [WidgetState.pressed].
  /// The baseline variant uses it to turn inactive icons
  /// [ColorScheme.onSurface] while they are hovered, focused or pressed.
  final WidgetStateProperty<IconThemeData?>? iconTheme;

  /// Per-state label text style, merged over both labels' resolved styles.
  ///
  /// Resolved against the same states as [iconTheme].
  final WidgetStateProperty<TextStyle?>? labelTextStyle;

  /// How long the active indicator takes to appear on a newly selected
  /// destination and fade from the previous one (200ms).
  final Duration? selectionDuration;

  /// A copy of this style with every non-null token of [other] applied over it.
  ///
  /// Returns this style when [other] is null.
  NavigationRailStyle merge(NavigationRailStyle? other) {
    if (other == null) return this;
    return copyWith(
      variant: other.variant,
      minWidth: other.minWidth,
      expandedWidth: other.expandedWidth,
      expandedMinWidth: other.expandedMinWidth,
      expandedMaxWidth: other.expandedMaxWidth,
      containerColor: other.containerColor,
      elevation: other.elevation,
      modalColor: other.modalColor,
      modalElevation: other.modalElevation,
      modalCornerRadius: other.modalCornerRadius,
      modalOvershoot: other.modalOvershoot,
      scrimColor: other.scrimColor,
      indicatorColor: other.indicatorColor,
      indicatorShape: other.indicatorShape,
      useIndicator: other.useIndicator,
      expandedIndicatorSize: other.expandedIndicatorSize,
      iconSize: other.iconSize,
      collapsedIndicatorWidth: other.collapsedIndicatorWidth,
      verticalIndicatorHeight: other.verticalIndicatorHeight,
      horizontalIndicatorHeight: other.horizontalIndicatorHeight,
      activeIconColor: other.activeIconColor,
      inactiveIconColor: other.inactiveIconColor,
      disabledColor: other.disabledColor,
      activeLabelColor: other.activeLabelColor,
      inactiveLabelColor: other.inactiveLabelColor,
      horizontalActiveLabelColor: other.horizontalActiveLabelColor,
      activeLabelWeight: other.activeLabelWeight,
      verticalLabelStyle: other.verticalLabelStyle,
      horizontalLabelStyle: other.horizontalLabelStyle,
      labelPadding: other.labelPadding,
      iconLabelSpacing: other.iconLabelSpacing,
      verticalIconLabelSpacing: other.verticalIconLabelSpacing,
      horizontalLeadingSpace: other.horizontalLeadingSpace,
      horizontalTrailingSpace: other.horizontalTrailingSpace,
      expandedPillHorizontalMargin: other.expandedPillHorizontalMargin,
      topSpace: other.topSpace,
      fabSpace: other.fabSpace,
      headerSpace: other.headerSpace,
      itemSpace: other.itemSpace,
      collapsedItemMinHeight: other.collapsedItemMinHeight,
      expandedItemMinHeight: other.expandedItemMinHeight,
      trailingSpace: other.trailingSpace,
      groupAlignment: other.groupAlignment,
      scrollable: other.scrollable,
      stateLayerColor: other.stateLayerColor,
      hoverOpacity: other.hoverOpacity,
      focusPressOpacity: other.focusPressOpacity,
      overlayColor: other.overlayColor,
      iconTheme: other.iconTheme,
      labelTextStyle: other.labelTextStyle,
      selectionDuration: other.selectionDuration,
    );
  }

  /// Creates a copy of this style with the given tokens replaced by the
  /// non-null arguments.
  @override
  NavigationRailStyle copyWith({
    StyleVariant? variant,
    double? minWidth,
    double? expandedWidth,
    double? expandedMinWidth,
    double? expandedMaxWidth,
    Color? containerColor,
    double? elevation,
    Color? modalColor,
    double? modalElevation,
    double? modalCornerRadius,
    double? modalOvershoot,
    Color? scrimColor,
    Color? indicatorColor,
    ShapeBorder? indicatorShape,
    bool? useIndicator,
    NavigationIndicatorSize? expandedIndicatorSize,
    double? iconSize,
    double? collapsedIndicatorWidth,
    double? verticalIndicatorHeight,
    double? horizontalIndicatorHeight,
    Color? activeIconColor,
    Color? inactiveIconColor,
    Color? disabledColor,
    Color? activeLabelColor,
    Color? inactiveLabelColor,
    Color? horizontalActiveLabelColor,
    FontWeight? activeLabelWeight,
    TextStyle? verticalLabelStyle,
    TextStyle? horizontalLabelStyle,
    EdgeInsetsGeometry? labelPadding,
    double? iconLabelSpacing,
    double? verticalIconLabelSpacing,
    double? horizontalLeadingSpace,
    double? horizontalTrailingSpace,
    double? expandedPillHorizontalMargin,
    double? topSpace,
    double? fabSpace,
    double? headerSpace,
    double? itemSpace,
    double? collapsedItemMinHeight,
    double? expandedItemMinHeight,
    double? trailingSpace,
    double? groupAlignment,
    bool? scrollable,
    Color? stateLayerColor,
    double? hoverOpacity,
    double? focusPressOpacity,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateProperty<IconThemeData?>? iconTheme,
    WidgetStateProperty<TextStyle?>? labelTextStyle,
    Duration? selectionDuration,
  }) {
    return NavigationRailStyle(
      variant: variant ?? this.variant,
      minWidth: minWidth ?? this.minWidth,
      expandedWidth: expandedWidth ?? this.expandedWidth,
      expandedMinWidth: expandedMinWidth ?? this.expandedMinWidth,
      expandedMaxWidth: expandedMaxWidth ?? this.expandedMaxWidth,
      containerColor: containerColor ?? this.containerColor,
      elevation: elevation ?? this.elevation,
      modalColor: modalColor ?? this.modalColor,
      modalElevation: modalElevation ?? this.modalElevation,
      modalCornerRadius: modalCornerRadius ?? this.modalCornerRadius,
      modalOvershoot: modalOvershoot ?? this.modalOvershoot,
      scrimColor: scrimColor ?? this.scrimColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorShape: indicatorShape ?? this.indicatorShape,
      useIndicator: useIndicator ?? this.useIndicator,
      expandedIndicatorSize:
          expandedIndicatorSize ?? this.expandedIndicatorSize,
      iconSize: iconSize ?? this.iconSize,
      collapsedIndicatorWidth:
          collapsedIndicatorWidth ?? this.collapsedIndicatorWidth,
      verticalIndicatorHeight:
          verticalIndicatorHeight ?? this.verticalIndicatorHeight,
      horizontalIndicatorHeight:
          horizontalIndicatorHeight ?? this.horizontalIndicatorHeight,
      activeIconColor: activeIconColor ?? this.activeIconColor,
      inactiveIconColor: inactiveIconColor ?? this.inactiveIconColor,
      disabledColor: disabledColor ?? this.disabledColor,
      activeLabelColor: activeLabelColor ?? this.activeLabelColor,
      inactiveLabelColor: inactiveLabelColor ?? this.inactiveLabelColor,
      horizontalActiveLabelColor:
          horizontalActiveLabelColor ?? this.horizontalActiveLabelColor,
      activeLabelWeight: activeLabelWeight ?? this.activeLabelWeight,
      verticalLabelStyle: verticalLabelStyle ?? this.verticalLabelStyle,
      horizontalLabelStyle: horizontalLabelStyle ?? this.horizontalLabelStyle,
      labelPadding: labelPadding ?? this.labelPadding,
      iconLabelSpacing: iconLabelSpacing ?? this.iconLabelSpacing,
      verticalIconLabelSpacing:
          verticalIconLabelSpacing ?? this.verticalIconLabelSpacing,
      horizontalLeadingSpace:
          horizontalLeadingSpace ?? this.horizontalLeadingSpace,
      horizontalTrailingSpace:
          horizontalTrailingSpace ?? this.horizontalTrailingSpace,
      expandedPillHorizontalMargin:
          expandedPillHorizontalMargin ?? this.expandedPillHorizontalMargin,
      topSpace: topSpace ?? this.topSpace,
      fabSpace: fabSpace ?? this.fabSpace,
      headerSpace: headerSpace ?? this.headerSpace,
      itemSpace: itemSpace ?? this.itemSpace,
      collapsedItemMinHeight:
          collapsedItemMinHeight ?? this.collapsedItemMinHeight,
      expandedItemMinHeight:
          expandedItemMinHeight ?? this.expandedItemMinHeight,
      trailingSpace: trailingSpace ?? this.trailingSpace,
      groupAlignment: groupAlignment ?? this.groupAlignment,
      scrollable: scrollable ?? this.scrollable,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      hoverOpacity: hoverOpacity ?? this.hoverOpacity,
      focusPressOpacity: focusPressOpacity ?? this.focusPressOpacity,
      overlayColor: overlayColor ?? this.overlayColor,
      iconTheme: iconTheme ?? this.iconTheme,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      selectionDuration: selectionDuration ?? this.selectionDuration,
    );
  }

  @override
  NavigationRailStyle lerp(
      covariant ThemeExtension<NavigationRailStyle>? other, double t) {
    if (other is! NavigationRailStyle) return this;
    return NavigationRailStyle(
      variant: t < 0.5 ? variant : other.variant,
      minWidth: lerpDouble(minWidth, other.minWidth, t),
      expandedWidth: lerpDouble(expandedWidth, other.expandedWidth, t),
      expandedMinWidth: lerpDouble(expandedMinWidth, other.expandedMinWidth, t),
      expandedMaxWidth: lerpDouble(expandedMaxWidth, other.expandedMaxWidth, t),
      containerColor: Color.lerp(containerColor, other.containerColor, t),
      elevation: lerpDouble(elevation, other.elevation, t),
      modalColor: Color.lerp(modalColor, other.modalColor, t),
      modalElevation: lerpDouble(modalElevation, other.modalElevation, t),
      modalCornerRadius:
          lerpDouble(modalCornerRadius, other.modalCornerRadius, t),
      modalOvershoot: lerpDouble(modalOvershoot, other.modalOvershoot, t),
      scrimColor: Color.lerp(scrimColor, other.scrimColor, t),
      indicatorColor: Color.lerp(indicatorColor, other.indicatorColor, t),
      indicatorShape: ShapeBorder.lerp(indicatorShape, other.indicatorShape, t),
      useIndicator: t < 0.5 ? useIndicator : other.useIndicator,
      expandedIndicatorSize:
          t < 0.5 ? expandedIndicatorSize : other.expandedIndicatorSize,
      iconSize: lerpDouble(iconSize, other.iconSize, t),
      collapsedIndicatorWidth:
          lerpDouble(collapsedIndicatorWidth, other.collapsedIndicatorWidth, t),
      verticalIndicatorHeight:
          lerpDouble(verticalIndicatorHeight, other.verticalIndicatorHeight, t),
      horizontalIndicatorHeight: lerpDouble(
          horizontalIndicatorHeight, other.horizontalIndicatorHeight, t),
      activeIconColor: Color.lerp(activeIconColor, other.activeIconColor, t),
      inactiveIconColor:
          Color.lerp(inactiveIconColor, other.inactiveIconColor, t),
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t),
      activeLabelColor: Color.lerp(activeLabelColor, other.activeLabelColor, t),
      inactiveLabelColor:
          Color.lerp(inactiveLabelColor, other.inactiveLabelColor, t),
      horizontalActiveLabelColor: Color.lerp(
          horizontalActiveLabelColor, other.horizontalActiveLabelColor, t),
      activeLabelWeight:
          FontWeight.lerp(activeLabelWeight, other.activeLabelWeight, t),
      verticalLabelStyle:
          TextStyle.lerp(verticalLabelStyle, other.verticalLabelStyle, t),
      horizontalLabelStyle:
          TextStyle.lerp(horizontalLabelStyle, other.horizontalLabelStyle, t),
      labelPadding:
          EdgeInsetsGeometry.lerp(labelPadding, other.labelPadding, t),
      iconLabelSpacing: lerpDouble(iconLabelSpacing, other.iconLabelSpacing, t),
      verticalIconLabelSpacing: lerpDouble(
          verticalIconLabelSpacing, other.verticalIconLabelSpacing, t),
      horizontalLeadingSpace:
          lerpDouble(horizontalLeadingSpace, other.horizontalLeadingSpace, t),
      horizontalTrailingSpace:
          lerpDouble(horizontalTrailingSpace, other.horizontalTrailingSpace, t),
      expandedPillHorizontalMargin: lerpDouble(
          expandedPillHorizontalMargin, other.expandedPillHorizontalMargin, t),
      topSpace: lerpDouble(topSpace, other.topSpace, t),
      fabSpace: lerpDouble(fabSpace, other.fabSpace, t),
      headerSpace: lerpDouble(headerSpace, other.headerSpace, t),
      itemSpace: lerpDouble(itemSpace, other.itemSpace, t),
      collapsedItemMinHeight:
          lerpDouble(collapsedItemMinHeight, other.collapsedItemMinHeight, t),
      expandedItemMinHeight:
          lerpDouble(expandedItemMinHeight, other.expandedItemMinHeight, t),
      trailingSpace: lerpDouble(trailingSpace, other.trailingSpace, t),
      groupAlignment: lerpDouble(groupAlignment, other.groupAlignment, t),
      scrollable: t < 0.5 ? scrollable : other.scrollable,
      stateLayerColor: Color.lerp(stateLayerColor, other.stateLayerColor, t),
      hoverOpacity: lerpDouble(hoverOpacity, other.hoverOpacity, t),
      focusPressOpacity:
          lerpDouble(focusPressOpacity, other.focusPressOpacity, t),
      overlayColor: WidgetStateProperty.lerp<Color?>(
          overlayColor, other.overlayColor, t, Color.lerp),
      iconTheme: WidgetStateProperty.lerp<IconThemeData?>(
          iconTheme, other.iconTheme, t, IconThemeData.lerp),
      labelTextStyle: WidgetStateProperty.lerp<TextStyle?>(
          labelTextStyle, other.labelTextStyle, t, TextStyle.lerp),
      selectionDuration: t < 0.5 ? selectionDuration : other.selectionDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationRailStyle &&
        other.variant == variant &&
        other.minWidth == minWidth &&
        other.expandedWidth == expandedWidth &&
        other.expandedMinWidth == expandedMinWidth &&
        other.expandedMaxWidth == expandedMaxWidth &&
        other.containerColor == containerColor &&
        other.elevation == elevation &&
        other.modalColor == modalColor &&
        other.modalElevation == modalElevation &&
        other.modalCornerRadius == modalCornerRadius &&
        other.modalOvershoot == modalOvershoot &&
        other.scrimColor == scrimColor &&
        other.indicatorColor == indicatorColor &&
        other.indicatorShape == indicatorShape &&
        other.useIndicator == useIndicator &&
        other.expandedIndicatorSize == expandedIndicatorSize &&
        other.iconSize == iconSize &&
        other.collapsedIndicatorWidth == collapsedIndicatorWidth &&
        other.verticalIndicatorHeight == verticalIndicatorHeight &&
        other.horizontalIndicatorHeight == horizontalIndicatorHeight &&
        other.activeIconColor == activeIconColor &&
        other.inactiveIconColor == inactiveIconColor &&
        other.disabledColor == disabledColor &&
        other.activeLabelColor == activeLabelColor &&
        other.inactiveLabelColor == inactiveLabelColor &&
        other.horizontalActiveLabelColor == horizontalActiveLabelColor &&
        other.activeLabelWeight == activeLabelWeight &&
        other.verticalLabelStyle == verticalLabelStyle &&
        other.horizontalLabelStyle == horizontalLabelStyle &&
        other.labelPadding == labelPadding &&
        other.iconLabelSpacing == iconLabelSpacing &&
        other.verticalIconLabelSpacing == verticalIconLabelSpacing &&
        other.horizontalLeadingSpace == horizontalLeadingSpace &&
        other.horizontalTrailingSpace == horizontalTrailingSpace &&
        other.expandedPillHorizontalMargin == expandedPillHorizontalMargin &&
        other.topSpace == topSpace &&
        other.fabSpace == fabSpace &&
        other.headerSpace == headerSpace &&
        other.itemSpace == itemSpace &&
        other.collapsedItemMinHeight == collapsedItemMinHeight &&
        other.expandedItemMinHeight == expandedItemMinHeight &&
        other.trailingSpace == trailingSpace &&
        other.groupAlignment == groupAlignment &&
        other.scrollable == scrollable &&
        other.stateLayerColor == stateLayerColor &&
        other.hoverOpacity == hoverOpacity &&
        other.focusPressOpacity == focusPressOpacity &&
        other.overlayColor == overlayColor &&
        other.iconTheme == iconTheme &&
        other.labelTextStyle == labelTextStyle &&
        other.selectionDuration == selectionDuration;
  }

  @override
  int get hashCode => Object.hashAll([
        variant,
        minWidth,
        expandedWidth,
        expandedMinWidth,
        expandedMaxWidth,
        containerColor,
        elevation,
        modalColor,
        modalElevation,
        modalCornerRadius,
        modalOvershoot,
        scrimColor,
        indicatorColor,
        indicatorShape,
        useIndicator,
        expandedIndicatorSize,
        iconSize,
        collapsedIndicatorWidth,
        verticalIndicatorHeight,
        horizontalIndicatorHeight,
        activeIconColor,
        inactiveIconColor,
        disabledColor,
        activeLabelColor,
        inactiveLabelColor,
        horizontalActiveLabelColor,
        activeLabelWeight,
        verticalLabelStyle,
        horizontalLabelStyle,
        labelPadding,
        iconLabelSpacing,
        verticalIconLabelSpacing,
        horizontalLeadingSpace,
        horizontalTrailingSpace,
        expandedPillHorizontalMargin,
        topSpace,
        fabSpace,
        headerSpace,
        itemSpace,
        collapsedItemMinHeight,
        expandedItemMinHeight,
        trailingSpace,
        groupAlignment,
        scrollable,
        stateLayerColor,
        hoverOpacity,
        focusPressOpacity,
        overlayColor,
        iconTheme,
        labelTextStyle,
        selectionDuration,
      ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        EnumProperty<StyleVariant>('variant', variant, defaultValue: null));
    properties.add(DoubleProperty('minWidth', minWidth, defaultValue: null));
    properties.add(
        DoubleProperty('expandedWidth', expandedWidth, defaultValue: null));
    properties.add(DoubleProperty('expandedMinWidth', expandedMinWidth,
        defaultValue: null));
    properties.add(DoubleProperty('expandedMaxWidth', expandedMaxWidth,
        defaultValue: null));
    properties.add(
        ColorProperty('containerColor', containerColor, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(ColorProperty('modalColor', modalColor, defaultValue: null));
    properties.add(
        DoubleProperty('modalElevation', modalElevation, defaultValue: null));
    properties.add(DoubleProperty('modalCornerRadius', modalCornerRadius,
        defaultValue: null));
    properties.add(
        DoubleProperty('modalOvershoot', modalOvershoot, defaultValue: null));
    properties.add(ColorProperty('scrimColor', scrimColor, defaultValue: null));
    properties.add(
        ColorProperty('indicatorColor', indicatorColor, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>(
        'indicatorShape', indicatorShape,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('useIndicator', useIndicator,
        defaultValue: null));
    properties.add(EnumProperty<NavigationIndicatorSize>(
        'expandedIndicatorSize', expandedIndicatorSize,
        defaultValue: null));
    properties.add(DoubleProperty('iconSize', iconSize, defaultValue: null));
    properties.add(DoubleProperty(
        'collapsedIndicatorWidth', collapsedIndicatorWidth,
        defaultValue: null));
    properties.add(DoubleProperty(
        'verticalIndicatorHeight', verticalIndicatorHeight,
        defaultValue: null));
    properties.add(DoubleProperty(
        'horizontalIndicatorHeight', horizontalIndicatorHeight,
        defaultValue: null));
    properties.add(
        ColorProperty('activeIconColor', activeIconColor, defaultValue: null));
    properties.add(ColorProperty('inactiveIconColor', inactiveIconColor,
        defaultValue: null));
    properties
        .add(ColorProperty('disabledColor', disabledColor, defaultValue: null));
    properties.add(ColorProperty('activeLabelColor', activeLabelColor,
        defaultValue: null));
    properties.add(ColorProperty('inactiveLabelColor', inactiveLabelColor,
        defaultValue: null));
    properties.add(ColorProperty(
        'horizontalActiveLabelColor', horizontalActiveLabelColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<FontWeight>(
        'activeLabelWeight', activeLabelWeight,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>(
        'verticalLabelStyle', verticalLabelStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>(
        'horizontalLabelStyle', horizontalLabelStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>(
        'labelPadding', labelPadding,
        defaultValue: null));
    properties.add(DoubleProperty('iconLabelSpacing', iconLabelSpacing,
        defaultValue: null));
    properties.add(DoubleProperty(
        'verticalIconLabelSpacing', verticalIconLabelSpacing,
        defaultValue: null));
    properties.add(DoubleProperty(
        'horizontalLeadingSpace', horizontalLeadingSpace,
        defaultValue: null));
    properties.add(DoubleProperty(
        'horizontalTrailingSpace', horizontalTrailingSpace,
        defaultValue: null));
    properties.add(DoubleProperty(
        'expandedPillHorizontalMargin', expandedPillHorizontalMargin,
        defaultValue: null));
    properties.add(DoubleProperty('topSpace', topSpace, defaultValue: null));
    properties.add(DoubleProperty('fabSpace', fabSpace, defaultValue: null));
    properties
        .add(DoubleProperty('headerSpace', headerSpace, defaultValue: null));
    properties.add(DoubleProperty('itemSpace', itemSpace, defaultValue: null));
    properties.add(DoubleProperty(
        'collapsedItemMinHeight', collapsedItemMinHeight,
        defaultValue: null));
    properties.add(DoubleProperty(
        'expandedItemMinHeight', expandedItemMinHeight,
        defaultValue: null));
    properties.add(
        DoubleProperty('trailingSpace', trailingSpace, defaultValue: null));
    properties.add(
        DoubleProperty('groupAlignment', groupAlignment, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('scrollable', scrollable,
        defaultValue: null));
    properties.add(
        ColorProperty('stateLayerColor', stateLayerColor, defaultValue: null));
    properties
        .add(DoubleProperty('hoverOpacity', hoverOpacity, defaultValue: null));
    properties.add(DoubleProperty('focusPressOpacity', focusPressOpacity,
        defaultValue: null));
    properties.add(DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'overlayColor', overlayColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<WidgetStateProperty<IconThemeData?>>(
        'iconTheme', iconTheme,
        defaultValue: null));
    properties.add(DiagnosticsProperty<WidgetStateProperty<TextStyle?>>(
        'labelTextStyle', labelTextStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>(
        'selectionDuration', selectionDuration,
        defaultValue: null));
  }
}

// The x offset, from the pill's leading edge, at which the horizontal label
// begins: the leading space, the icon and the icon-to-label gap.
double _besideLabelStart(NavigationRailStyle style) =>
    style.horizontalLeadingSpace! + style.iconSize! + style.iconLabelSpacing!;

// The per-destination style handed to each destination of a resolved style.
NavigationDestinationStyle _destinationStyle(NavigationRailStyle style) =>
    NavigationDestinationStyle(
      activeIconColor: style.activeIconColor,
      inactiveIconColor: style.inactiveIconColor,
      disabledColor: style.disabledColor,
      activeLabelColor: style.activeLabelColor,
      inactiveLabelColor: style.inactiveLabelColor,
      horizontalActiveLabelColor: style.horizontalActiveLabelColor,
      activeLabelWeight: style.activeLabelWeight,
      verticalLabelStyle: style.verticalLabelStyle,
      horizontalLabelStyle: style.horizontalLabelStyle,
      labelPadding: style.labelPadding,
      indicatorShape: style.indicatorShape,
      useIndicator: style.useIndicator,
      overlayColor: style.overlayColor ??
          NavigationDestinationStyle.overlayFor(style.stateLayerColor!,
              style.hoverOpacity!, style.focusPressOpacity!),
      iconTheme: style.iconTheme,
      labelTextStyle: style.labelTextStyle,
    );

// Whether an enabled, unselected destination is hovered, focused or pressed,
// when the baseline variant turns its icon and label on-surface.
bool _inactiveInteraction(Set<WidgetState> states) =>
    !states.contains(WidgetState.selected) &&
    !states.contains(WidgetState.disabled) &&
    (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused) ||
        states.contains(WidgetState.pressed));

enum _RailSlot { header, destinations, trailing }

// Lays out the rail's content: the header at the top, the trailing widget at
// the bottom, and the destinations in the room between them. [_RailGroup]
// places them within that room.
class _RailLayout extends MultiChildLayoutDelegate {
  _RailLayout({required this.headerSpace, required this.insets});

  final double headerSpace;
  final _RailInsets insets;

  @override
  void performLayout(Size size) {
    final header = layoutChild(_RailSlot.header, BoxConstraints.loose(size));
    positionChild(_RailSlot.header, Offset((size.width - header.width) / 2, 0));
    final top = header.height + headerSpace;
    var bottom = size.height;
    if (hasChild(_RailSlot.trailing)) {
      final trailing =
          layoutChild(_RailSlot.trailing, BoxConstraints.loose(size));
      bottom -= trailing.height;
      positionChild(_RailSlot.trailing,
          Offset((size.width - trailing.width) / 2, bottom));
    }
    // Recorded before the destinations are laid out, which is when
    // [_RenderRailGroup] reads them.
    insets
      ..top = top
      ..bottom = size.height - bottom;
    final group = layoutChild(
      _RailSlot.destinations,
      BoxConstraints(
          maxWidth: size.width, maxHeight: math.max(0.0, bottom - top)),
    );
    positionChild(
        _RailSlot.destinations, Offset((size.width - group.width) / 2, top));
  }

  @override
  bool shouldRelayout(_RailLayout oldDelegate) =>
      oldDelegate.headerSpace != headerSpace || oldDelegate.insets != insets;
}

// The room above and below the rail's destinations: the header, and the
// trailing widget. [_RailLayout] measures them, and [_RenderRailGroup] reads
// them in the same layout pass to place the destinations against the rail's
// whole height, as Material 3 does.
class _RailInsets {
  double top = 0;
  double bottom = 0;
}

// The destinations, and the expanded body below them. The destinations sit at
// [alignment] along the rail's whole height — clear of the header and the
// trailing widget — whatever the body's height, so revealing the body leaves
// them where they are and scrolls on past them instead.
class _RailGroup extends MultiChildRenderObjectWidget {
  const _RailGroup({
    required this.alignment,
    required this.viewportHeight,
    required this.insets,
    required super.children,
  });

  final double alignment;
  final double viewportHeight;
  final _RailInsets insets;

  @override
  _RenderRailGroup createRenderObject(BuildContext context) =>
      _RenderRailGroup(alignment, viewportHeight, insets);

  @override
  void updateRenderObject(BuildContext context, _RenderRailGroup renderObject) {
    renderObject
      ..alignment = alignment
      ..viewportHeight = viewportHeight
      ..insets = insets;
  }
}

class _RailGroupParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderRailGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RailGroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RailGroupParentData> {
  _RenderRailGroup(this._alignment, this._viewportHeight, this._insets);

  double get alignment => _alignment;
  double _alignment;
  set alignment(double value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsLayout();
  }

  double get viewportHeight => _viewportHeight;
  double _viewportHeight;
  set viewportHeight(double value) {
    if (value == _viewportHeight) return;
    _viewportHeight = value;
    markNeedsLayout();
  }

  _RailInsets get insets => _insets;
  _RailInsets _insets;
  set insets(_RailInsets value) {
    if (value == _insets) return;
    _insets = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RailGroupParentData) {
      child.parentData = _RailGroupParentData();
    }
  }

  @override
  void performLayout() {
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    var child = firstChild;
    var destinationsHeight = 0.0;
    var content = 0.0;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      if (child == firstChild) destinationsHeight = child.size.height;
      content += child.size.height;
      child = childAfter(child);
    }
    // Placed against the rail's whole height, then kept within the room the
    // header and the trailing widget leave.
    final railHeight = viewportHeight + insets.top + insets.bottom;
    final top =
        ((railHeight - destinationsHeight) * (alignment + 1) / 2 - insets.top)
            .clamp(0.0, math.max(0.0, viewportHeight - destinationsHeight))
            .toDouble();
    var y = top;
    child = firstChild;
    while (child != null) {
      (child.parentData! as _RailGroupParentData).offset = Offset(0, y);
      y += child.size.height;
      child = childAfter(child);
    }
    size = constraints.constrain(
        Size(constraints.maxWidth, math.max(viewportHeight, top + content)));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

// A 0..1 view of an unbounded controller that only moves toward the open
// state's target: forward while opening, backward while closing. The expand
// spring overshoots its target and then settles back; destinations and the
// public handle hold at the target through that settling instead of wiggling.
// Reversing the open state lets the view move the other way from where it is.
// While [collapsed] reports true, the view holds at 0.
class _SettledAnimation extends Animation<double> {
  _SettledAnimation(this._parent, this._opening, {this.collapsed});

  final Animation<double> _parent;
  final bool Function() _opening;
  final bool Function()? collapsed;
  bool? _latchedOpening;
  double _latched = 0;

  @override
  void addListener(VoidCallback listener) => _parent.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _parent.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) =>
      _parent.addStatusListener(listener);

  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      _parent.removeStatusListener(listener);

  bool get _isCollapsed => collapsed?.call() ?? false;

  @override
  AnimationStatus get status =>
      _isCollapsed ? AnimationStatus.dismissed : _parent.status;

  @override
  double get value {
    if (_isCollapsed) {
      // Start over from the controller's position once released.
      _latchedOpening = null;
      return 0;
    }
    final current = _parent.value.clamp(0.0, 1.0);
    final opening = _opening();
    if (opening != _latchedOpening) {
      _latchedOpening = opening;
      _latched = current;
    } else {
      _latched =
          opening ? math.max(_latched, current) : math.min(_latched, current);
    }
    return _latched;
  }
}
