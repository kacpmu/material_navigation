import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart'
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
///    the icon and label side by side inside a pill sized by
///    [expandedIndicatorSize] ([NavigationIndicatorSize.fill] for full width,
///    [NavigationIndicatorSize.label] to hug the content).
///
/// As the rail expands, the indicator grows from its collapsed pill to its
/// expanded form, the label slides in beside the icon, and the below-label
/// collapses away. Destinations scroll when they do not fit, so the rail never
/// overflows.
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
    this.minWidth,
    this.expandedWidth,
    this.expandedIndicatorSize = NavigationIndicatorSize.label,
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

  /// The Material 3 token bundle that drives the rail's appearance.
  ///
  /// When null, falls back to [NavigationRailStyle.expressive] built from the
  /// ambient [ColorScheme] and [TextTheme] — the recommended collapsible rail
  /// (Material 3 Expressive: 96dp collapsed, 280dp expanded). Pass
  /// [NavigationRailStyle.baseline] for the older fixed 80dp rail, or a
  /// `style.copyWith(...)` to tune individual tokens.
  final NavigationRailStyle? style;

  /// How the collapsed-to-expanded transition animates.
  ///
  /// Material 3 Expressive spatial spring physics drive the morph
  /// ([NavigationMotion.expressive]: an underdamped spring that overshoots
  /// slightly before settling); pass [NavigationMotion.standard] for a fixed
  /// emphasized duration and curve.
  final NavigationMotion motion;

  /// Overrides the collapsed width.
  ///
  /// When null, falls back to the [style]'s [NavigationRailStyle.minWidth]
  /// (Material 3 Expressive: 96dp, baseline: 80dp). Must be positive.
  final double? minWidth;

  /// Overrides the expanded width.
  ///
  /// When null, falls back to the [style]'s [NavigationRailStyle.expandedWidth]
  /// (Material 3 Expressive: 280dp, within the 220–360dp range). Must be
  /// positive.
  final double? expandedWidth;

  /// How the expanded active indicator is sized.
  ///
  /// Either [NavigationIndicatorSize.fill] for full width or
  /// [NavigationIndicatorSize.label] to hug the icon and label content.
  final NavigationIndicatorSize expandedIndicatorSize;

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
  /// destinations.
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
  // [_expandClamped] is the 0..1 view handed to destinations and the handle.
  late AnimationController _expandController;
  late Animation<double> _expandClamped;
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
    _initControllers();
    if (_modalOpen) _showModalOverlay();
  }

  @override
  void didUpdateWidget(NavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.motion != oldWidget.motion) {
      // Re-create the expand controller under the new motion, keeping progress.
      final value = _expandController.value;
      _expandController.dispose();
      _expandController = widget.motion
          .createController(this, value, bounded: false)
        ..addListener(_rebuild);
      _expandClamped = _ClampedAnimation(_expandController);
    }
    // A changed [expanded] reseeds the open state (forcing it open or closed),
    // keeping the current modality.
    if (widget.expanded != oldWidget.expanded) {
      _applyOpen(widget.expanded, _modal);
    }
    if (widget.destinations.length != oldWidget.destinations.length) {
      _disposeControllers();
      _initControllers();
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
    _disposeControllers();
    super.dispose();
  }

  void _applyOpen(bool open, bool modal) {
    if (open == _open && modal == _modal) return;
    final openChanged = open != _open;
    setState(() {
      _open = open;
      _modal = modal;
    });
    widget.motion.animateTo(_expandController, open ? 1.0 : 0.0);
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

  void _initControllers() {
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
    _expandController = widget.motion
        .createController(this, _open ? 1.0 : 0.0, bounded: false)
      ..addListener(_rebuild);
    _expandClamped = _ClampedAnimation(_expandController);
  }

  void _disposeControllers() {
    for (final c in _destinationControllers) {
      c.dispose();
    }
    _expandController.dispose();
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

  // Resolves the active style: an explicit [NavigationRail.style], else the
  // expressive factory default from the ambient ColorScheme / TextTheme.
  NavigationRailStyle _resolveStyle(BuildContext context) {
    if (widget.style != null) return widget.style!;
    final theme = Theme.of(context);
    return NavigationRailStyle.expressive(theme.colorScheme, theme.textTheme);
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
    final itemStyle = style.destinationStyle;
    return Column(
      children: [
        if (widget.leading != null) _pinned(widget.leading!, minWidth),
        if (widget.floatingActionButton != null) ...[
          if (widget.leading != null) const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: lerpDouble(
                  (minWidth - style.collapsedIndicatorWidth) / 2,
                  style.expandedPillHorizontalMargin,
                  expandValue,
                )!
                    .clamp(0.0, double.infinity),
              ),
              child: widget.floatingActionButton!,
            ),
          ),
        ],
        // Space above the first destination (M3 collapsed item top space 44dp).
        SizedBox(height: style.topSpace),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
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
                    iconSize: style.iconSize,
                    minWidth: minWidth,
                    expandedWidth: expandedWidth,
                    collapsedIndicatorWidth: style.collapsedIndicatorWidth,
                    collapsedIndicatorHeight: style.verticalIndicatorHeight,
                    expandedIndicatorHeight: style.horizontalIndicatorHeight,
                    besideLabelStart: style.besideLabelStart,
                    labelTrailingSpace: style.horizontalTrailingSpace,
                    belowLabelSpacing: style.verticalIconLabelSpacing,
                    horizontalMargin: style.expandedPillHorizontalMargin,
                    indicatorSize: widget.expandedIndicatorSize,
                    centered: false,
                    itemVerticalSpace: style.itemVerticalSpace,
                    style: itemStyle,
                    destinationAnimation: _destinationAnimations[i],
                    expandAnimation: expandAnimation,
                    onTap: !widget.destinations[i].disabled &&
                            widget.onDestinationSelected != null
                        ? () => _onDestinationSelected(i)
                        : null,
                  ),
                if (includeExpandedBody &&
                    widget.expandedBody != null &&
                    expandedBodyReveal > 0)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: expandedBodyReveal,
                        child: widget.expandedBody!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.trailing != null) ...[
          // Expanded vertical trailing space (M3 20dp), revealed as it extends.
          SizedBox(height: style.trailingSpace * expandValue.clamp(0.0, 1.0)),
          widget.trailing!,
        ],
      ],
    );
  }

  // The scrimmed, full-height overlay shown while modal-open. The expanded-width
  // surface slides in from the leading edge.
  Widget _buildModalOverlay(BuildContext context) {
    final style = _resolveStyle(context);
    final colors = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final indicatorColor = widget.indicatorColor ?? style.indicatorColor;
    final minWidth = widget.minWidth ?? style.minWidth;
    final expandedWidth = widget.expandedWidth ?? style.expandedWidth;
    final raw = _expandController.value;
    final t = raw.clamp(0.0, 1.0);
    final start = lerpDouble(-expandedWidth, 0, t)!;
    final contentWidth = lerpDouble(minWidth, expandedWidth, t)!;
    // The spring overshoots past 1 on open; let the surface's inner (trailing)
    // edge spring a touch past its rest width then settle, while its leading
    // edge stays pinned to the screen edge (no gap).
    final surfaceWidth = expandedWidth * raw.clamp(1.0, 1.2);
    final scrim = Color.lerp(Colors.transparent,
        widget.scrimColor ?? colors.scrim.withValues(alpha: 0.32), t)!;
    // Modal surface (M3): surface-container, elevation 3dp, 16dp large rounding
    // on the trailing (inner) edge.
    final radius = Radius.circular(style.modalCornerRadius);

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
              elevation: style.modalElevation,
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
    final indicatorColor = widget.indicatorColor ?? style.indicatorColor;
    final minWidth = widget.minWidth ?? style.minWidth;
    final expandedWidth = widget.expandedWidth ?? style.expandedWidth;
    // Inline footprint: morphs in place when open inline; pinned collapsed when
    // modal (the expanded form lives in the overlay) or closed. Uses the clamped
    // value so an inline rail never overshoots its width and jostles the body.
    final inlineValue = _modal ? 0.0 : _expandClamped.value;
    final width = lerpDouble(minWidth, expandedWidth, inlineValue)!;

    final rail = _RailScope(
      state: this,
      expandAnimation: _expandClamped,
      isOpen: _open,
      isModal: _modal,
      child: Material(
        color: widget.backgroundColor ?? style.containerColor,
        elevation: style.elevation,
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
                    expandAnimation: _expandClamped,
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

/// The Material 3 token bundle for a [NavigationRail].
///
/// Build one with [NavigationRailStyle.expressive] or
/// [NavigationRailStyle.baseline] from a [ColorScheme] and [TextTheme], then
/// pass it to [NavigationRail.style]. It drives the rail's widths, indicator
/// geometry, colors, label styles, state layers, spacing, and modal surface.
/// Tune individual tokens with [copyWith].
///
/// ```dart
/// final theme = Theme.of(context);
/// NavigationRail(
///   destinations: destinations,
///   style: NavigationRailStyle.expressive(theme.colorScheme, theme.textTheme)
///       .copyWith(expandedWidth: 320),
/// )
/// ```
///
/// Rail items size to their content; the Material 3 fixed item heights
/// (64dp/56dp) are not applied.
@immutable
class NavigationRailStyle {
  /// Creates a navigation rail style.
  ///
  /// Prefer the [NavigationRailStyle.expressive] or [NavigationRailStyle.baseline]
  /// factories, which fill in the Material 3 token values from a [ColorScheme]
  /// and [TextTheme].
  const NavigationRailStyle({
    required this.minWidth,
    required this.expandedWidth,
    required this.containerColor,
    required this.elevation,
    required this.modalColor,
    required this.modalElevation,
    required this.modalCornerRadius,
    required this.indicatorColor,
    required this.iconSize,
    required this.collapsedIndicatorWidth,
    required this.verticalIndicatorHeight,
    required this.horizontalIndicatorHeight,
    required this.activeIconColor,
    required this.inactiveIconColor,
    required this.disabledColor,
    required this.activeLabelColor,
    required this.inactiveLabelColor,
    required this.activeLabelWeight,
    required this.verticalLabelStyle,
    required this.horizontalLabelStyle,
    required this.iconLabelSpacing,
    required this.verticalIconLabelSpacing,
    required this.horizontalLeadingSpace,
    required this.horizontalTrailingSpace,
    required this.expandedPillHorizontalMargin,
    required this.topSpace,
    required this.itemVerticalSpace,
    required this.trailingSpace,
    required this.stateLayerColor,
    required this.hoverOpacity,
    required this.focusPressOpacity,
  });

  /// The recommended Material 3 Expressive style.
  ///
  /// Fills in the Expressive token values from [colors] and [text]: a 96dp
  /// collapsed / 280dp expanded rail on [ColorScheme.surface], a
  /// secondaryContainer active indicator, and a secondary active label.
  factory NavigationRailStyle.expressive(ColorScheme colors, TextTheme text) {
    return NavigationRailStyle(
      minWidth: 96, // spec: collapsed container width 96dp (80 = narrow)
      expandedWidth: 280, // spec: expanded width 220-360; 280 is in-range
      containerColor: colors.surface,
      elevation: 0, // spec: collapsed/expanded elevation 0
      modalColor:
          colors.surfaceContainer, // spec: modal container surface-container
      modalElevation: 3, // spec: modal elevation 3dp
      modalCornerRadius: 16, // spec: modal large rounding 16dp
      indicatorColor: colors.secondaryContainer,
      iconSize: 24, // spec: nav rail item icon size 24dp
      collapsedIndicatorWidth: 56, // spec: vertical active indicator width 56dp
      verticalIndicatorHeight:
          32, // spec: vertical active indicator height 32dp
      horizontalIndicatorHeight:
          56, // spec: horizontal active indicator height 56dp
      activeIconColor: colors.onSecondaryContainer,
      inactiveIconColor: colors.onSurfaceVariant,
      disabledColor: colors.onSurface.withValues(alpha: 0.38),
      activeLabelColor:
          colors.secondary, // spec: expressive active label secondary
      inactiveLabelColor: colors.onSurfaceVariant,
      activeLabelWeight: FontWeight.w500,
      verticalLabelStyle: text.labelMedium!, // spec: vertical label medium
      horizontalLabelStyle: text.labelLarge!, // spec: horizontal label large
      iconLabelSpacing: 8, // spec: horizontal icon-label space 8dp
      verticalIconLabelSpacing: 4, // spec: vertical icon label space 4dp
      horizontalLeadingSpace: 16, // spec: active indicator leading space 16dp
      horizontalTrailingSpace: 16, // spec: active indicator trailing space 16dp
      expandedPillHorizontalMargin:
          12, // internal: side breathing room for the morphed pill
      topSpace: 44, // spec: collapsed item top space 44dp
      itemVerticalSpace: 6, // spec: item container vertical space 6dp
      trailingSpace: 20, // spec: expanded vertical trailing space 20dp
      stateLayerColor: colors.onSecondaryContainer,
      hoverOpacity: 0.08,
      focusPressOpacity: 0.1,
    );
  }

  /// The older baseline Material 3 style.
  ///
  /// Fills in the baseline token values from [colors] and [text]: an 80dp
  /// collapsed rail and an onSurface active label at weight 700, where the
  /// Expressive style uses 96dp and a secondary label.
  factory NavigationRailStyle.baseline(ColorScheme colors, TextTheme text) {
    return NavigationRailStyle(
      minWidth: 80, // spec: baseline container width 80dp
      expandedWidth: 256,
      containerColor: colors.surface,
      elevation: 0,
      modalColor: colors.surfaceContainer,
      modalElevation: 3,
      modalCornerRadius: 16,
      indicatorColor: colors.secondaryContainer,
      iconSize: 24, // spec: navigation rail icon size 24dp
      collapsedIndicatorWidth: 56, // spec: indicator width 56dp
      verticalIndicatorHeight: 32, // spec: indicator height 32dp
      horizontalIndicatorHeight: 56,
      activeIconColor: colors.onSecondaryContainer,
      inactiveIconColor: colors.onSurfaceVariant,
      disabledColor: colors.onSurface.withValues(alpha: 0.38),
      activeLabelColor:
          colors.onSurface, // spec: baseline active label on-surface
      inactiveLabelColor: colors.onSurfaceVariant,
      activeLabelWeight:
          FontWeight.w700, // spec: baseline active label weight 700
      // spec: baseline label tracking 0.1pt (Material's labelMedium is 0.5).
      verticalLabelStyle: text.labelMedium!.copyWith(letterSpacing: 0.1),
      // The baseline spec defines no expanded config; inherit expressive's large.
      horizontalLabelStyle: text.labelLarge!,
      iconLabelSpacing: 8,
      verticalIconLabelSpacing: 4,
      horizontalLeadingSpace: 16,
      horizontalTrailingSpace: 16,
      expandedPillHorizontalMargin: 12,
      topSpace: 44,
      itemVerticalSpace: 6,
      trailingSpace: 20,
      stateLayerColor: colors.onSecondaryContainer,
      hoverOpacity: 0.08,
      focusPressOpacity: 0.1,
    );
  }

  /// Collapsed container width (expressive 96dp / baseline 80dp).
  final double minWidth;

  /// Expanded container width (Material 3 220–360dp range; default 280dp).
  final double expandedWidth;

  /// Inline container color (surface).
  final Color containerColor;

  /// Inline container elevation (0).
  final double elevation;

  /// Modal (overlay) container color (surface-container).
  final Color modalColor;

  /// Modal container elevation (3dp).
  final double modalElevation;

  /// Modal container corner radius (16dp large rounding, on the trailing edge).
  final double modalCornerRadius;

  /// Active-indicator color (secondary-container).
  final Color indicatorColor;

  /// Icon size (24dp).
  final double iconSize;

  /// Collapsed/vertical active indicator width (56dp).
  final double collapsedIndicatorWidth;

  /// Vertical active indicator height (32dp).
  final double verticalIndicatorHeight;

  /// Expanded/horizontal active indicator height (56dp).
  final double horizontalIndicatorHeight;

  /// Selected icon color.
  final Color activeIconColor;

  /// Unselected icon color.
  final Color inactiveIconColor;

  /// Disabled color.
  final Color disabledColor;

  /// Selected label color (expressive secondary / baseline on-surface).
  final Color activeLabelColor;

  /// Unselected label color.
  final Color inactiveLabelColor;

  /// Selected label weight (baseline 700 / expressive 500).
  final FontWeight activeLabelWeight;

  /// Vertical (collapsed) label style (label-medium).
  final TextStyle verticalLabelStyle;

  /// Horizontal (expanded) label style (label-large).
  final TextStyle horizontalLabelStyle;

  /// Horizontal-config icon→label spacing (8dp).
  final double iconLabelSpacing;

  /// Vertical-config gap between the active indicator and the below-label (4dp).
  final double verticalIconLabelSpacing;

  /// Expanded active-indicator leading space (16dp).
  final double horizontalLeadingSpace;

  /// Expanded active-indicator trailing space (16dp).
  final double horizontalTrailingSpace;

  /// Side breathing room for the expanded active indicator within its slot
  /// (12dp). Not a strict Material 3 token, but an internal layout value.
  final double expandedPillHorizontalMargin;

  /// Space above the first destination (collapsed item top space 44dp).
  final double topSpace;

  /// Per-item container vertical space (6dp), collapsing to 0 when expanded.
  final double itemVerticalSpace;

  /// Expanded vertical trailing space below the destinations (20dp).
  final double trailingSpace;

  /// State-layer color (on-secondary-container).
  final Color stateLayerColor;

  /// Hover state-layer opacity (0.08).
  final double hoverOpacity;

  /// Focus/pressed state-layer opacity (0.1).
  final double focusPressOpacity;

  /// The horizontal offset at which the label begins in the expanded config:
  /// the leading space plus the icon plus the icon-to-label gap.
  ///
  /// Assumes the icon is centered in the indicator box, that is,
  /// `horizontalLeadingSpace == (collapsedIndicatorWidth - iconSize) / 2`.
  double get besideLabelStart =>
      horizontalLeadingSpace + iconSize + iconLabelSpacing;

  /// The per-destination style derived from these tokens, handed to each
  /// [NavigationDestination].
  NavigationDestinationStyle get destinationStyle => NavigationDestinationStyle(
        activeIconColor: activeIconColor,
        inactiveIconColor: inactiveIconColor,
        disabledColor: disabledColor,
        activeLabelColor: activeLabelColor,
        inactiveLabelColor: inactiveLabelColor,
        activeLabelWeight: activeLabelWeight,
        verticalLabelStyle: verticalLabelStyle,
        horizontalLabelStyle: horizontalLabelStyle,
        overlayColor: NavigationDestinationStyle.overlayFor(
            stateLayerColor, hoverOpacity, focusPressOpacity),
      );

  /// Creates a copy of this style with the given fields replaced by the
  /// non-null arguments.
  NavigationRailStyle copyWith({
    double? minWidth,
    double? expandedWidth,
    Color? containerColor,
    double? elevation,
    Color? modalColor,
    double? modalElevation,
    double? modalCornerRadius,
    Color? indicatorColor,
    double? iconSize,
    double? collapsedIndicatorWidth,
    double? verticalIndicatorHeight,
    double? horizontalIndicatorHeight,
    Color? activeIconColor,
    Color? inactiveIconColor,
    Color? disabledColor,
    Color? activeLabelColor,
    Color? inactiveLabelColor,
    FontWeight? activeLabelWeight,
    TextStyle? verticalLabelStyle,
    TextStyle? horizontalLabelStyle,
    double? iconLabelSpacing,
    double? verticalIconLabelSpacing,
    double? horizontalLeadingSpace,
    double? horizontalTrailingSpace,
    double? expandedPillHorizontalMargin,
    double? topSpace,
    double? itemVerticalSpace,
    double? trailingSpace,
    Color? stateLayerColor,
    double? hoverOpacity,
    double? focusPressOpacity,
  }) {
    return NavigationRailStyle(
      minWidth: minWidth ?? this.minWidth,
      expandedWidth: expandedWidth ?? this.expandedWidth,
      containerColor: containerColor ?? this.containerColor,
      elevation: elevation ?? this.elevation,
      modalColor: modalColor ?? this.modalColor,
      modalElevation: modalElevation ?? this.modalElevation,
      modalCornerRadius: modalCornerRadius ?? this.modalCornerRadius,
      indicatorColor: indicatorColor ?? this.indicatorColor,
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
      activeLabelWeight: activeLabelWeight ?? this.activeLabelWeight,
      verticalLabelStyle: verticalLabelStyle ?? this.verticalLabelStyle,
      horizontalLabelStyle: horizontalLabelStyle ?? this.horizontalLabelStyle,
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
      itemVerticalSpace: itemVerticalSpace ?? this.itemVerticalSpace,
      trailingSpace: trailingSpace ?? this.trailingSpace,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      hoverOpacity: hoverOpacity ?? this.hoverOpacity,
      focusPressOpacity: focusPressOpacity ?? this.focusPressOpacity,
    );
  }
}

// A 0..1 view of an unbounded controller: the expand spring may overshoot, but
// destinations and the public handle must only ever see values within range.
class _ClampedAnimation extends Animation<double> {
  _ClampedAnimation(this._parent);

  final Animation<double> _parent;

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

  @override
  AnimationStatus get status => _parent.status;

  @override
  double get value => _parent.value.clamp(0.0, 1.0);
}
