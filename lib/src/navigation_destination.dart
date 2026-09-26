import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/semantics.dart' show SemanticsRole;

import 'label_metrics.dart';
import 'package:material_ui/material_ui.dart' hide NavigationDestination;

/// Defines when a destination's label is shown in a [NavigationBar] or
/// [NavigationRail].
///
/// In a [NavigationBar] this applies to both item layouts: to the label below
/// the icon, and to the label beside it, where a hidden label leaves the active
/// indicator around the icon alone. In a [NavigationRail] it applies to the
/// collapsed rail's label below the icon; an expanded rail always shows its
/// labels.
///
/// A hidden label stays the destination's accessible name, and its tooltip.
enum NavigationLabelBehavior {
  /// The label is never shown; destinations show their icon only.
  none,

  /// The label is shown for the selected destination only.
  selected,

  /// Every destination's label is always shown.
  all,
}

/// How long a change of [NavigationLabelBehavior] takes: the below-labels ease
/// in or out, and a [NavigationBar] resizes with them. The selection
/// animation's default duration.
///
/// Internal to the package: not exported.
const Duration navigationLabelBehaviorDuration = Duration(milliseconds: 200);

/// The easing of a change of [NavigationLabelBehavior].
///
/// Internal to the package: not exported.
const Curve navigationLabelBehaviorCurve = Curves.easeInOut;

// The lines a label may take when no style says otherwise. Two, because
// Material 3 lets scaled text wrap so the full label stays visible at up to
// twice the text size; a label that fits one line is unaffected.
const int _kLabelMaxLines = 2;

/// Defines how a destination's active indicator is sized in its expanded,
/// horizontal form.
///
/// Used by [NavigationBar] and [NavigationRail] for the pill shown around a
/// selected destination once it has morphed to the icon-beside-label layout.
enum NavigationIndicatorSize {
  /// The indicator spans the full destination width, like a drawer item.
  fill,

  /// The indicator hugs the icon and label content, as in Material 3
  /// Expressive.
  ///
  /// The pill is left-anchored so that icons stay aligned across destinations.
  label,
}

/// A single navigation destination that morphs between a vertical and a
/// horizontal arrangement as it expands.
///
/// [NavigationDestination] is both the data carrier describing one destination
/// (its [icon], [label] and selection state) and the widget that renders it.
/// The same widget is used by [NavigationBar] and [NavigationRail], which feed
/// it the animations and geometry that suit each.
///
/// The layout is driven by [expandAnimation] (0 → 1):
///
///  * At 0, the icon sits in a collapsed pill with the label below it.
///  * At 1, the icon and label sit side by side inside an expanded pill — either
///    full-width or content-hugging per [indicatorSize] — and the below-label
///    collapses away.
///
/// [destinationAnimation] drives the active indicator (0 → 1 when selected),
/// independently of the morph.
///
/// In a [NavigationBar] the pill is centered in its slot ([centered] is true); in
/// a [NavigationRail] it is pinned to the rail's leading edge ([centered] is
/// false).
///
/// {@tool snippet}
/// ```dart
/// NavigationDestination(
///   icon: Icon(Icons.inbox_outlined),
///   selectedIcon: Icon(Icons.inbox),
///   label: 'Inbox',
///   selected: true,
///   onTap: () => print('Inbox tapped'),
/// )
/// ```
/// {@end-tool}
class NavigationDestination extends StatefulWidget {
  /// Creates a navigation destination.
  ///
  /// The [icon] and [label] are required. This describes a destination; the
  /// [NavigationBar] and [NavigationRail] supply the layout and animation
  /// themselves. For full control, use [NavigationDestination.custom].
  ///
  /// Placed in one of a [NavigationRail]'s slots, such as
  /// [NavigationRail.trailing] or [NavigationRail.expandedBody], it takes the
  /// rail's layout and style, so it lines up with the rail's own destinations.
  /// Pass the rail's [NavigationRailHandle.expandAnimation] as
  /// [expandAnimation] so it morphs along with them.
  const NavigationDestination({
    super.key,
    this.onTap,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.disabled = false,
    this.expandAnimation = kAlwaysDismissedAnimation,
  })  : centered = false,
        selected = false,
        labelBehavior = NavigationLabelBehavior.all,
        indicatorSize = NavigationIndicatorSize.fill,
        indicatorColor = null,
        iconSize = 24,
        minWidth = 80,
        expandedWidth = 280,
        collapsedIndicatorHeight = 32,
        collapsedIndicatorWidth = 56,
        expandedIndicatorHeight = 56,
        belowLabelSpacing = 4,
        besideLabelStart = 56,
        horizontalMargin = 20,
        itemSpace = 4,
        collapsedMinHeight = 64,
        expandedMinHeight = 48,
        labelTrailingSpace = 16,
        style = null,
        destinationAnimation = kAlwaysDismissedAnimation,
        _adoptsLayout = true;

  /// Creates a navigation destination with explicit control over its layout,
  /// indicator, spacing, and the animations that drive its morph and selection.
  ///
  /// Used by [NavigationBar] and [NavigationRail] to render each destination;
  /// most callers want the default [NavigationDestination] constructor instead.
  const NavigationDestination.custom({
    super.key,
    this.onTap,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.centered = false,
    this.disabled = false,
    this.selected = false,
    this.labelBehavior = NavigationLabelBehavior.all,
    this.indicatorSize = NavigationIndicatorSize.fill,
    this.indicatorColor,
    this.iconSize = 24,
    this.minWidth = 80,
    this.expandedWidth = 280,
    this.collapsedIndicatorHeight = 32,
    this.collapsedIndicatorWidth = 56,
    this.expandedIndicatorHeight = 56,
    this.belowLabelSpacing = 4,
    this.besideLabelStart = 56,
    this.horizontalMargin = 20,
    this.itemSpace = 4,
    this.collapsedMinHeight = 64,
    this.expandedMinHeight = 48,
    this.labelTrailingSpace = 16,
    this.style,
    this.destinationAnimation = kAlwaysDismissedAnimation,
    this.expandAnimation = kAlwaysDismissedAnimation,
  }) : _adoptsLayout = false;

  /// Called when the destination is tapped.
  final VoidCallback? onTap;

  /// The icon shown for the destination, typically an outlined [Icon].
  ///
  /// If [selectedIcon] is also provided, this icon is shown only when the
  /// destination is unselected.
  final Widget icon;

  /// The icon shown when the destination is selected, typically a filled [Icon].
  ///
  /// When null, [icon] is shown in both states.
  final Widget? selectedIcon;

  /// The destination's text label.
  final String label;

  /// The message shown when the destination is long-pressed or hovered.
  ///
  /// A tooltip is shown only when the label cannot be read in full: while it
  /// is hidden by [labelBehavior] or by the collapsed, icon-only state, or when
  /// it does not fit the space available. Falls back to [label] when null.
  final String? tooltip;

  /// Whether the pill and label are centered within the available width.
  ///
  /// True for a [NavigationBar], where the destination is centered in its slot.
  /// False for a [NavigationRail], where the icon is pinned to [minWidth] and a
  /// content-hugging pill is left-anchored.
  final bool centered;

  /// Whether the destination is disabled.
  ///
  /// A disabled destination is not tappable and is shown dimmed. Per Material 3,
  /// disabled content renders at [ColorScheme.onSurfaceVariant] at 38% opacity.
  final bool disabled;

  /// Whether this destination is selected.
  final bool selected;

  /// Whether the label is shown always, only when selected, or never.
  ///
  /// Shows the label ([NavigationLabelBehavior.all]) unless set otherwise.
  /// Applies to the label below the icon and, when [centered] (in a
  /// [NavigationBar]), to the label beside it.
  final NavigationLabelBehavior labelBehavior;

  /// How the expanded pill is sized — full width or hugging the content.
  ///
  /// Spans the full destination width ([NavigationIndicatorSize.fill]) unless
  /// set otherwise; [NavigationIndicatorSize.label] hugs the content as in
  /// Material 3 Expressive.
  final NavigationIndicatorSize indicatorSize;

  /// The color of the active indicator pill.
  ///
  /// When null, the Material 3 [ColorScheme.secondaryContainer] role is used.
  final Color? indicatorColor;

  /// The icon size. Material 3 specifies 24dp for navigation icons.
  final double iconSize;

  /// The collapsed, icon-only width of the destination.
  ///
  /// Material 3 Expressive rails collapse to 96dp; baseline rails to 80dp, and
  /// bar destinations track the bar's slot width.
  final double minWidth;

  /// The width of the destination when fully expanded.
  ///
  /// Material 3 Expressive expands the rail to 280dp (baseline 256dp), within
  /// the spec's 220-360dp range.
  final double expandedWidth;

  /// The height of the active indicator while collapsed.
  ///
  /// Material 3 sizes the collapsed vertical active indicator at 56dp x 32dp, so
  /// this height is 32dp.
  final double collapsedIndicatorHeight;

  /// The width of the active indicator while collapsed, which is also the width
  /// of the icon box.
  ///
  /// Material 3 uses 56dp for the collapsed vertical active indicator; the
  /// baseline bar variant uses 64dp.
  final double collapsedIndicatorWidth;

  /// The height of the active indicator pill when extended.
  ///
  /// The collapsed height is always [collapsedIndicatorHeight]. Material 3 sizes
  /// the expanded (horizontal) active indicator at 56dp in a rail; the bar's
  /// beside indicator is 40dp tall.
  final double expandedIndicatorHeight;

  /// The vertical gap between the active indicator and the below-label.
  ///
  /// Material 3 places 4dp between the icon and its below-label.
  final double belowLabelSpacing;

  /// The leading offset at which the beside-label begins, reserving room for the
  /// icon.
  ///
  /// Smaller values reduce the gap between the icon and the label. This is 56dp
  /// to match the Material 3 collapsed indicator width; the icon box itself
  /// stays [collapsedIndicatorWidth] wide so the collapsed pill centers the
  /// icon.
  final double besideLabelStart;

  /// The horizontal breathing room reserved on each side of the extended pill
  /// within its slot.
  ///
  /// Reserves 20dp on each side, which keeps a rail's icons in place as it
  /// expands.
  final double horizontalMargin;

  /// The vertical gap between adjacent destinations while collapsed.
  ///
  /// Shrinks to 0 as the destination expands. Ignored when [centered]. Material
  /// 3 Expressive uses 4dp between rail items.
  final double itemSpace;

  /// The minimum height of the destination while collapsed.
  ///
  /// Eases to [expandedMinHeight] as the destination expands; the content is
  /// centered vertically within it. Ignored when [centered]. Material 3
  /// Expressive uses 64dp for a collapsed rail item.
  final double collapsedMinHeight;

  /// The minimum height of the destination when fully expanded.
  ///
  /// Ignored when [centered]. Material 3 Expressive uses 48dp for an expanded
  /// rail item.
  final double expandedMinHeight;

  /// The trailing padding after the beside-label, inside the pill.
  ///
  /// Reserves 16dp after the label.
  final double labelTrailingSpace;

  /// The resolved per-item visual styling — colors, label styles, active weight
  /// and state layer.
  ///
  /// Supplied by a [NavigationBar] or [NavigationRail] from its style. When
  /// null, the destination falls back to [ColorScheme]-derived defaults, so a
  /// standalone destination renders correctly on its own.
  final NavigationDestinationStyle? style;

  /// The animation driving the active indicator, 0 (unselected) to 1
  /// (selected).
  ///
  /// When omitted this is [kAlwaysDismissedAnimation] (the destination stays
  /// unselected); a [NavigationBar] or [NavigationRail] supplies a live
  /// animation.
  final Animation<double> destinationAnimation;

  /// The animation driving the morph, 0 (vertical, collapsed) to 1 (horizontal,
  /// expanded).
  ///
  /// When omitted this is [kAlwaysDismissedAnimation] (the destination stays
  /// collapsed); a [NavigationBar] or [NavigationRail] supplies a live
  /// animation.
  final Animation<double> expandAnimation;

  // Whether this destination takes its layout and style from an enclosing
  // [NavigationDestinationLayout] (the default constructor) rather than its own
  // fields ([NavigationDestination.custom]).
  final bool _adoptsLayout;

  @override
  State<NavigationDestination> createState() => _NavigationDestinationState();
}

// Builds and animates the morphing item; self-listens to both drivers so it
// repaints even when its parent doesn't rebuild it each frame.
class _NavigationDestinationState extends State<NavigationDestination>
    with SingleTickerProviderStateMixin {
  // The below-label shrinks away as it extends.
  late CurvedAnimation _belowLabelSize;
  // The selected below-label "grows in" from its top.
  late CurvedAnimation _appearAnimation;
  // The label behavior shown, and the one a change of behavior eases away
  // from while [_labelBehaviorChange] runs.
  NavigationLabelBehavior? _labelBehavior;
  NavigationLabelBehavior? _fromLabelBehavior;
  late final AnimationController _labelBehaviorChange = AnimationController(
    vsync: this,
    duration: navigationLabelBehaviorDuration,
    value: 1,
  )..addListener(_rebuild);
  final GlobalKey _indicatorKey = GlobalKey();
  // The ink response moves under a tooltip, or out from one, as its label is
  // hidden or shown, which with a selected-only label is every selection.
  // Keyed, it moves rather than being rebuilt, keeping its splash and focus.
  final GlobalKey _inkKey = GlobalKey();
  // Reported by the ink response. Only its hovered / focused / pressed states
  // are used, to resolve the style's per-state icon theme and label style;
  // selected and disabled come from the widget.
  final WidgetStatesController _states = WidgetStatesController();
  Set<WidgetState> _interaction = const {};

  @override
  void initState() {
    super.initState();
    _belowLabelSize = CurvedAnimation(
      parent: ReverseAnimation(widget.expandAnimation),
      curve: Curves.linear,
    );
    _setAppearAnimation();
    // Self-animate: rebuild on every tick of either driver, so the destination
    // morphs even when its parent doesn't reconstruct it each frame — e.g. used
    // standalone or in a rail slot, not just in the rail/bar's own item loop.
    widget.expandAnimation.addListener(_rebuild);
    widget.destinationAnimation.addListener(_rebuild);
    _states.addListener(_onStatesChanged);
  }

  // Rebuilds only when an interaction state changes: the ink response also
  // reports disabled while it initializes, mid-build.
  void _onStatesChanged() {
    final interaction = _states.value
        .where((state) =>
            state == WidgetState.hovered ||
            state == WidgetState.focused ||
            state == WidgetState.pressed)
        .toSet();
    if (interaction.length == _interaction.length &&
        interaction.containsAll(_interaction)) {
      return;
    }
    setState(() => _interaction = interaction);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  // This destination with the enclosing rail's layout and style in place of its
  // own, when it takes them (the plain constructor in a rail slot).
  NavigationDestination _resolved() => widget._adoptsLayout
      ? NavigationDestinationLayout.maybeOf(context)?.applyTo(widget) ?? widget
      : widget;

  // Starts easing the below-label toward [behavior] when it changes.
  void _syncLabelBehavior(NavigationLabelBehavior behavior) {
    final shown = _labelBehavior;
    _labelBehavior = behavior;
    if (shown == null || shown == behavior) return;
    _fromLabelBehavior = shown;
    _labelBehaviorChange.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A slot destination's behavior arrives through the rail's layout.
    _syncLabelBehavior(_resolved().labelBehavior);
  }

  @override
  void didUpdateWidget(NavigationDestination oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLabelBehavior(_resolved().labelBehavior);
    if (widget.expandAnimation != oldWidget.expandAnimation) {
      oldWidget.expandAnimation.removeListener(_rebuild);
      widget.expandAnimation.addListener(_rebuild);
      _belowLabelSize.dispose();
      _belowLabelSize = CurvedAnimation(
        parent: ReverseAnimation(widget.expandAnimation),
        curve: Curves.linear,
      );
    }
    if (widget.destinationAnimation != oldWidget.destinationAnimation) {
      oldWidget.destinationAnimation.removeListener(_rebuild);
      widget.destinationAnimation.addListener(_rebuild);
      _appearAnimation.dispose();
      _setAppearAnimation();
    }
  }

  void _setAppearAnimation() {
    _appearAnimation = CurvedAnimation(
      parent: ReverseAnimation(widget.destinationAnimation),
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut.flipped,
    );
  }

  @override
  void dispose() {
    widget.expandAnimation.removeListener(_rebuild);
    widget.destinationAnimation.removeListener(_rebuild);
    _belowLabelSize.dispose();
    _appearAnimation.dispose();
    _labelBehaviorChange.dispose();
    _states.dispose();
    super.dispose();
  }

  // The scale the labels are drawn and measured at: the ambient one, capped by
  // the style's [NavigationDestinationStyle.maxLabelScale]. Only the labels:
  // the tooltip keeps the ambient scale.
  TextScaler _labelScaler(BuildContext context, NavigationDestination w) {
    final scaler = MediaQuery.textScalerOf(context);
    final max = w.style?.maxLabelScale;
    return max == null ? scaler : scaler.clamp(maxScaleFactor: max);
  }

  // The expanded pill's width: the full content slot (fill), or a hug sized to
  // the icon plus as much of its label as shows ([labelShown], 0 to 1). A slot
  // narrower than the icon box caps the hug at the slot instead of inverting
  // the clamp.
  double _expandedPillWidth(BuildContext context, NavigationDestination w,
      TextStyle labelStyle, double labelShown) {
    final fill = w.indicatorSize == NavigationIndicatorSize.fill;
    final maxWidth = math.max(0.0, w.expandedWidth - 2 * w.horizontalMargin);
    final iconBox = math.min(w.collapsedIndicatorWidth, maxWidth);
    if (fill) return maxWidth;
    final labelWidth = measureLabel(w.label,
            style: labelStyle,
            textDirection: Directionality.of(context),
            textScaler: _labelScaler(context, w),
            locale: Localizations.maybeLocaleOf(context),
            // Unbounded, any line count gives the one line; the label's own
            // shares its measurement with the pill's height.
            maxLines: w.style?.labelMaxLines ?? _kLabelMaxLines,
            boldText: MediaQuery.boldTextOf(context))
        .width;
    final hug = (w.besideLabelStart + labelWidth + w.labelTrailingSpace)
        .clamp(iconBox, maxWidth);
    return lerpDouble(iconBox, hug, labelShown)!;
  }

  // The widest the beside-label can be before its slot cuts it: from where it
  // starts, past the icon, to the slot's edge, less the space after it. Taken
  // at the expanded width rather than the width mid-morph, so the label does
  // not re-wrap as a rail expands.
  double _besideLabelMaxWidth(NavigationDestination w) => math.max(
      0.0,
      w.expandedWidth -
          w.horizontalMargin -
          w.besideLabelStart -
          w.labelTrailingSpace);

  // The expanded pill's height. Material 3 sizes it around its content, so a
  // label taller than the icon (large text scales, more than one line) grows
  // the pill instead of being clipped by it, as far as the label shows
  // ([labelShown], 0 to 1); [expandedIndicatorHeight] is the height at the
  // icon's own size, and so the minimum.
  double _expandedPillHeight(BuildContext context, NavigationDestination w,
      TextStyle labelStyle, double labelShown) {
    final labelHeight = measureLabel(w.label,
            style: labelStyle,
            textDirection: Directionality.of(context),
            textScaler: _labelScaler(context, w),
            locale: Localizations.maybeLocaleOf(context),
            maxLines: w.style?.labelMaxLines ?? _kLabelMaxLines,
            maxWidth: _besideLabelMaxWidth(w),
            boldText: MediaQuery.boldTextOf(context))
        .height;
    final padding = w.expandedIndicatorHeight - w.iconSize;
    return lerpDouble(
        w.expandedIndicatorHeight,
        math.max(w.expandedIndicatorHeight, labelHeight + padding),
        labelShown)!;
  }

  @override
  Widget build(BuildContext context) {
    // In a rail slot, the plain constructor takes the rail's layout and style.
    final w = _resolved();
    final fill = w.indicatorSize == NavigationIndicatorSize.fill;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = w.style;
    final indicatorColor = style?.useIndicator == false
        ? Colors.transparent
        : (w.indicatorColor ?? colors.secondaryContainer);
    final indicatorShape = style?.indicatorShape ?? const StadiumBorder();
    final disabled = w.disabled;
    final extend = w.expandAnimation.value;
    final centered = w.centered;
    final states = <WidgetState>{
      ..._interaction,
      if (w.selected) WidgetState.selected,
      if (disabled) WidgetState.disabled,
    };

    final disabledColor =
        style?.disabledColor ?? colors.onSurfaceVariant.withValues(alpha: 0.38);
    final iconColor = disabled
        ? disabledColor
        : (w.selected
            ? (style?.activeIconColor ?? colors.onSecondaryContainer)
            : (style?.inactiveIconColor ?? colors.onSurfaceVariant));
    final labelColor = disabled
        ? disabledColor
        : (w.selected
            ? (style?.activeLabelColor ?? colors.onSurface)
            : (style?.inactiveLabelColor ?? colors.onSurfaceVariant));
    // The horizontal (beside) label sits inside the pill, so when selected it
    // takes the icon's color unless the style gives it its own.
    final besideLabelColor = w.selected && !disabled
        ? (style?.horizontalActiveLabelColor ?? iconColor)
        : labelColor;
    final activeWeight = w.selected ? style?.activeLabelWeight : null;
    // Per-state overrides from the style (hovered, focused, pressed, selected,
    // disabled) are merged over the resolved defaults.
    final stateLabelStyle = style?.labelTextStyle?.resolve(states);
    final besideLabelStyle =
        (style?.horizontalLabelStyle ?? theme.textTheme.labelLarge!)
            .copyWith(color: besideLabelColor, fontWeight: activeWeight)
            .merge(stateLabelStyle);
    final belowLabelStyle =
        (style?.verticalLabelStyle ?? theme.textTheme.labelMedium!)
            .copyWith(color: labelColor, fontWeight: activeWeight)
            .merge(stateLabelStyle);

    final icon = IconTheme.merge(
      data: IconThemeData(size: w.iconSize, color: iconColor)
          .merge(style?.iconTheme?.resolve(states)),
      child: w.selected ? (w.selectedIcon ?? w.icon) : w.icon,
    );
    final labelMaxLines = style?.labelMaxLines ?? _kLabelMaxLines;
    final labelOverflow = style?.labelOverflow ?? TextOverflow.clip;
    final labelScaler = _labelScaler(context, w);
    // Both labels are excluded from the semantics tree: the item's own node
    // carries the name, so hiding or fading a label never costs the
    // destination its accessible name.
    final label = ExcludeSemantics(
      child: Text(
        w.label,
        maxLines: labelMaxLines,
        overflow: labelOverflow,
        textScaler: labelScaler,
        style: besideLabelStyle,
      ),
    );
    final belowLabelText = ExcludeSemantics(
      child: Text(
        w.label,
        maxLines: labelMaxLines,
        overflow: labelOverflow,
        textScaler: labelScaler,
        textAlign: TextAlign.center,
        style: belowLabelStyle,
      ),
    );

    // Centered (bar) keeps the pill centered; a non-fill (hug) rail pill is
    // left-anchored so icons stay aligned across destinations. A collapsed
    // indicator wider than the collapsed width has no room to centre in: it
    // starts at the edge and is fitted to the width, rather than taking a
    // negative inset.
    final collapsedLeadingInset =
        math.max(0.0, (w.minWidth - w.collapsedIndicatorWidth) / 2);
    final alignX = centered ? 0.0 : (fill ? 0.0 : -1.0);
    final startInset = centered
        ? 0.0
        : (fill
            ? 0.0
            : lerpDouble(collapsedLeadingInset, w.horizontalMargin, extend)!);
    final contentWidth = lerpDouble(w.minWidth, w.expandedWidth, extend)!;
    // The below-label box: a fixed collapsed-width box pinned at the rail's
    // start (no drift as the rail morphs), or full-width + centered for the bar
    // (whose slot width is fixed, so centring can't drift).
    final belowLabelWidth = centered ? double.infinity : w.minWidth;

    final belowLabelFade =
        _belowLabelSize.drive(CurveTween(curve: const Interval(0.75, 1.0)));
    final selectionInterval =
        w.selected ? const Interval(0.25, 0.75) : const Interval(0.75, 1.0);
    final selectedBelowFade =
        w.destinationAnimation.drive(CurveTween(curve: selectionInterval));

    final labelPadding =
        style?.labelPadding ?? const EdgeInsets.symmetric(horizontal: 4);
    final belowLabelPadding =
        labelPadding.add(EdgeInsets.only(top: w.belowLabelSpacing));
    // How much of the label each behavior shows. Below the icon: fractions of
    // the gap above the label, of the padded label's height, and of its
    // opacity. Beside it: one fraction, which the pill hugs; in a bar
    // (centered) the behavior applies there too, while an expanded rail
    // always shows its labels. [NavigationLabelBehavior.selected] follows the
    // selection.
    final selection = 1 - _appearAnimation.value;
    ({double gap, double height, double opacity, double beside}) shown(
            NavigationLabelBehavior behavior) =>
        switch (behavior) {
          NavigationLabelBehavior.all =>
            (gap: 1, height: 1, opacity: 1, beside: 1),
          NavigationLabelBehavior.selected => (
              gap: selection,
              height: selection,
              opacity: selectedBelowFade.value,
              beside: centered ? selection : 1,
            ),
          NavigationLabelBehavior.none =>
            (gap: 1, height: 0, opacity: 0, beside: centered ? 0 : 1),
        };
    // A change of behavior eases from what the old one showed to the new.
    final to = shown(w.labelBehavior);
    final from = shown(_fromLabelBehavior ?? w.labelBehavior);
    final change =
        navigationLabelBehaviorCurve.transform(_labelBehaviorChange.value);
    final labelHeight = lerpDouble(from.height, to.height, change)!;
    final besideShown = lerpDouble(from.beside, to.beside, change)!;

    // The pill grows from 56×32 (around the icon) to its expanded form, which
    // hugs as much of the beside-label as shows.
    final indicatorWidth = lerpDouble(w.collapsedIndicatorWidth,
        _expandedPillWidth(context, w, besideLabelStyle, besideShown), extend)!;
    final expandedPillHeight =
        _expandedPillHeight(context, w, besideLabelStyle, besideShown);
    final indicatorHeight =
        lerpDouble(w.collapsedIndicatorHeight, expandedPillHeight, extend)!;

    // The beside (extended) label fades in with the morph, and with its
    // behavior once the pill has grown half way around it. It sits on TOP of
    // the pill (Stack) and is never clipped to it, so collapsing fades the
    // whole label rather than shearing its letters.
    final besideLabelOpacity =
        const Interval(0.3, 0.7).transform(extend.clamp(0.0, 1.0)) *
            const Interval(0.5, 1.0).transform(besideShown.clamp(0.0, 1.0));
    final Widget belowLabel = SizedBox(
      width: belowLabelWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              height: w.belowLabelSpacing *
                  lerpDouble(from.gap, to.gap, change)!),
          if (labelHeight > 0)
            Align(
              alignment: Alignment.topCenter,
              heightFactor: labelHeight,
              child: Padding(
                padding: labelPadding,
                child: Opacity(
                  opacity: lerpDouble(from.opacity, to.opacity, change)!
                      .clamp(0.0, 1.0),
                  child: FadeTransition(
                      opacity: belowLabelFade, child: belowLabelText),
                ),
              ),
            ),
        ],
      ),
    );

    final content = ClipRect(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional(alignX, 0),
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: startInset),
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                // Don't clip the beside label to the pill — it sits on top and is
                // bounded only by the item's outer ClipRect, so collapsing fades
                // the whole label instead of shearing off its last letters.
                clipBehavior: Clip.none,
                children: [
                  NavigationIndicator(
                    key: _indicatorKey,
                    animation: w.destinationAnimation,
                    color: indicatorColor,
                    shape: indicatorShape,
                    width: indicatorWidth,
                    height: indicatorHeight,
                  ),
                  SizedBox(
                      width: w.collapsedIndicatorWidth,
                      child: Center(child: icon)),
                  // The beside (expanded) label, on TOP of the pill at a fixed
                  // start — faded by [besideLabelOpacity], never clipped to the
                  // pill, so collapsing never shears off its last letters.
                  if (besideLabelOpacity > 0)
                    PositionedDirectional(
                      start: w.besideLabelStart,
                      child: Opacity(
                        opacity: besideLabelOpacity.clamp(0.0, 1.0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                              end: w.labelTrailingSpace),
                          // Wraps where the slot would otherwise cut it.
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: _besideLabelMaxWidth(w)),
                            child: label,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // The below (collapsed) label, collapsing as it extends.
          SizeTransition(
            sizeFactor: _belowLabelSize,
            alignment: AlignmentDirectional.topStart,
            child: belowLabel,
          ),
        ],
      ),
    );

    final tooltip = w.tooltip ?? w.label;
    // A label the user cannot read in full gets a tooltip: either it is hidden
    // outright, or it does not fit the box it is laid out in.
    final bool labelUnreadable;
    if (extend < 0.5) {
      labelUnreadable = labelHeight < 0.5 ||
          labelOverflows(w.label,
              available:
                  math.max(0.0, w.minWidth - belowLabelPadding.horizontal),
              style: belowLabelStyle,
              textDirection: Directionality.of(context),
              textScaler: _labelScaler(context, w),
              locale: Localizations.maybeLocaleOf(context),
              maxLines: labelMaxLines,
              boldText: MediaQuery.boldTextOf(context));
    } else {
      labelUnreadable = besideShown < 0.5 ||
          labelOverflows(w.label,
          available: _besideLabelMaxWidth(w),
          style: besideLabelStyle,
          textDirection: Directionality.of(context),
          textScaler: _labelScaler(context, w),
          locale: Localizations.maybeLocaleOf(context),
          maxLines: labelMaxLines,
          boldText: MediaQuery.boldTextOf(context));
    }
    final showTooltip = labelUnreadable;

    // Cap the content at its own [contentWidth] rather than letting it stretch
    // to fill a wider slot. Otherwise — in a slot wider than the destination
    // (e.g. a rail `trailing` item whose collapsed width is narrower than the
    // rail) — the icon would center in the full slot while the below-label
    // centers in [minWidth], and the two would drift apart.
    final item = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: contentWidth),
      child: content,
    );

    return MergeSemantics(
      child: Semantics(
        // An enabled tab must be tappable, so an inert destination is just a
        // labelled button. A disabled one stays a tab, as every child of the
        // container's tab bar must be.
        role: w.onTap != null || disabled ? SemanticsRole.tab : null,
        button: true,
        selected: w.selected,
        enabled: !disabled,
        label: w.label,
        child: Padding(
          // A gap between destinations when collapsed; flush when expanded (rail).
          padding: EdgeInsets.symmetric(
              vertical:
                  centered ? 0.0 : lerpDouble(w.itemSpace, 0, extend)! / 2),
          child: Material(
            type: MaterialType.transparency,
            child: _maybeTooltip(
              tooltip: showTooltip ? tooltip : null,
              label: w.label,
              child: _IndicatorInkWell(
                key: _inkKey,
                onTap: disabled ? null : w.onTap,
                customBorder: indicatorShape,
                overlayColor: style?.overlayColor,
                statesController: _states,
                indicatorKey: _indicatorKey,
                child: centered
                    ? Center(child: item)
                    // A rail item keeps its minimum height, content centered.
                    // The minimum eases toward the expanded item's real height
                    // (at least the expanded pill's), not just the expanded
                    // minimum: otherwise it drops below the growing pill
                    // mid-morph and the item shrinks, then grows back.
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight: lerpDouble(
                                w.collapsedMinHeight,
                                math.max(
                                    w.expandedMinHeight, expandedPillHeight),
                                extend)!),
                        child: Center(widthFactor: 1, child: item),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // The item's own semantics node already carries [label], so a tooltip that
  // only repeats it is left out of the tree rather than announced twice.
  Widget _maybeTooltip(
          {String? tooltip, required String label, required Widget child}) =>
      tooltip == null
          ? child
          : Tooltip(
              message: tooltip,
              excludeFromSemantics: tooltip == label,
              child: child,
            );
}

/// The layout and style a [NavigationRail] gives the destinations built with
/// the plain [NavigationDestination] constructor in its slots, so they line up
/// with the rail's own.
///
/// Internal to the package: not exported.
class NavigationDestinationLayout extends InheritedWidget {
  /// Provides [NavigationDestination.custom]'s layout arguments to plain
  /// destinations below.
  const NavigationDestinationLayout({
    super.key,
    required this.labelBehavior,
    required this.indicatorSize,
    required this.indicatorColor,
    required this.iconSize,
    required this.minWidth,
    required this.expandedWidth,
    required this.collapsedIndicatorHeight,
    required this.collapsedIndicatorWidth,
    required this.expandedIndicatorHeight,
    required this.belowLabelSpacing,
    required this.besideLabelStart,
    required this.horizontalMargin,
    required this.itemSpace,
    required this.collapsedMinHeight,
    required this.expandedMinHeight,
    required this.labelTrailingSpace,
    required this.style,
    required super.child,
  });

  /// See [NavigationDestination.labelBehavior].
  final NavigationLabelBehavior labelBehavior;

  /// See [NavigationDestination.indicatorSize].
  final NavigationIndicatorSize indicatorSize;

  /// See [NavigationDestination.indicatorColor].
  final Color? indicatorColor;

  /// See [NavigationDestination.iconSize].
  final double iconSize;

  /// See [NavigationDestination.minWidth].
  final double minWidth;

  /// See [NavigationDestination.expandedWidth].
  final double expandedWidth;

  /// See [NavigationDestination.collapsedIndicatorHeight].
  final double collapsedIndicatorHeight;

  /// See [NavigationDestination.collapsedIndicatorWidth].
  final double collapsedIndicatorWidth;

  /// See [NavigationDestination.expandedIndicatorHeight].
  final double expandedIndicatorHeight;

  /// See [NavigationDestination.belowLabelSpacing].
  final double belowLabelSpacing;

  /// See [NavigationDestination.besideLabelStart].
  final double besideLabelStart;

  /// See [NavigationDestination.horizontalMargin].
  final double horizontalMargin;

  /// See [NavigationDestination.itemSpace].
  final double itemSpace;

  /// See [NavigationDestination.collapsedMinHeight].
  final double collapsedMinHeight;

  /// See [NavigationDestination.expandedMinHeight].
  final double expandedMinHeight;

  /// See [NavigationDestination.labelTrailingSpace].
  final double labelTrailingSpace;

  /// See [NavigationDestination.style].
  final NavigationDestinationStyle? style;

  /// The nearest layout above [context], if any.
  static NavigationDestinationLayout? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationDestinationLayout>();

  /// [destination] with this layout and style in place of its own.
  NavigationDestination applyTo(NavigationDestination destination) =>
      NavigationDestination.custom(
        onTap: destination.onTap,
        icon: destination.icon,
        selectedIcon: destination.selectedIcon,
        label: destination.label,
        tooltip: destination.tooltip,
        disabled: destination.disabled,
        selected: destination.selected,
        labelBehavior: labelBehavior,
        indicatorSize: indicatorSize,
        indicatorColor: indicatorColor,
        iconSize: iconSize,
        minWidth: minWidth,
        expandedWidth: expandedWidth,
        collapsedIndicatorHeight: collapsedIndicatorHeight,
        collapsedIndicatorWidth: collapsedIndicatorWidth,
        expandedIndicatorHeight: expandedIndicatorHeight,
        belowLabelSpacing: belowLabelSpacing,
        besideLabelStart: besideLabelStart,
        horizontalMargin: horizontalMargin,
        itemSpace: itemSpace,
        collapsedMinHeight: collapsedMinHeight,
        expandedMinHeight: expandedMinHeight,
        labelTrailingSpace: labelTrailingSpace,
        style: style,
        destinationAnimation: destination.destinationAnimation,
        expandAnimation: destination.expandAnimation,
      );

  // The rail rebuilds this with fresh values as it animates; its destinations
  // rebuild on the same ticks anyway.
  @override
  bool updateShouldNotify(NavigationDestinationLayout oldWidget) => true;
}

/// An [InkResponse] whose splash matches the active indicator's rect, located
/// from [indicatorKey] so it tracks the pill wherever the content sits — e.g.
/// vertically centered within a taller bar slot.
class _IndicatorInkWell extends InkResponse {
  const _IndicatorInkWell({
    super.key,
    super.child,
    super.onTap,
    super.customBorder,
    super.overlayColor,
    super.statesController,
    required this.indicatorKey,
  }) : super(
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
        );

  final GlobalKey indicatorKey;

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) {
    return () {
      final indicator =
          indicatorKey.currentContext?.findRenderObject() as RenderBox?;
      if (indicator == null || !indicator.attached) {
        return Offset.zero & referenceBox.size;
      }
      final topLeft =
          referenceBox.globalToLocal(indicator.localToGlobal(Offset.zero));
      return topLeft & indicator.size;
    };
  }
}

/// The visual styling applied to a single [NavigationDestination].
///
/// A [NavigationBar] or [NavigationRail] resolves one of these from its own
/// style and hands it to each destination. Every field is nullable; a null
/// field leaves the destination on its [ColorScheme]-derived default, so a
/// standalone destination renders correctly without a style.
///
/// {@tool snippet}
/// ```dart
/// final style = NavigationDestinationStyle(
///   activeIconColor: colorScheme.onSecondaryContainer,
///   inactiveIconColor: colorScheme.onSurfaceVariant,
///   activeLabelWeight: FontWeight.w700,
///   overlayColor: NavigationDestinationStyle.overlayFor(
///     colorScheme.onSecondaryContainer, 0.08, 0.12),
/// );
/// ```
/// {@end-tool}
@immutable
class NavigationDestinationStyle {
  /// Creates per-item navigation styling.
  ///
  /// Every field is optional; omitted fields fall back to the destination's
  /// [ColorScheme]-derived defaults.
  const NavigationDestinationStyle({
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
    this.labelMaxLines,
    this.labelOverflow,
    this.maxLabelScale,
    this.indicatorShape,
    this.useIndicator,
    this.overlayColor,
    this.iconTheme,
    this.labelTextStyle,
  });

  /// The icon color when the destination is selected.
  ///
  /// When null, the Material 3 active-icon role [ColorScheme.onSecondaryContainer]
  /// is used.
  final Color? activeIconColor;

  /// The icon color when the destination is unselected.
  ///
  /// When null, the Material 3 inactive-icon role [ColorScheme.onSurfaceVariant]
  /// is used.
  final Color? inactiveIconColor;

  /// The icon and label color when the destination is disabled.
  ///
  /// When null, Material 3 disabled content uses
  /// [ColorScheme.onSurfaceVariant] at 38% opacity.
  final Color? disabledColor;

  /// The below-label color when the destination is selected.
  ///
  /// When null, [ColorScheme.onSurface] is used.
  final Color? activeLabelColor;

  /// The label color when the destination is unselected.
  ///
  /// When null, the Material 3 inactive-label role [ColorScheme.onSurfaceVariant]
  /// is used.
  final Color? inactiveLabelColor;

  /// The beside-label color when the destination is selected.
  ///
  /// The beside label sits inside the active indicator, so when null it takes
  /// the selected icon's color, as Material 3 Expressive does.
  final Color? horizontalActiveLabelColor;

  /// The label font weight applied when the destination is selected.
  ///
  /// When null, the selected label keeps its text style's weight.
  final FontWeight? activeLabelWeight;

  /// The text style of the below-label (icon above text).
  ///
  /// When null, the Material 3 navigation label role [TextTheme.labelMedium] is
  /// used.
  final TextStyle? verticalLabelStyle;

  /// The text style of the beside-label (icon next to text).
  ///
  /// When null, [TextTheme.labelLarge] is used.
  final TextStyle? horizontalLabelStyle;

  /// The padding around the below-label, added to the gap between it and the
  /// active indicator.
  ///
  /// When null, 4dp on each side.
  final EdgeInsetsGeometry? labelPadding;

  /// The maximum number of lines a label may occupy.
  ///
  /// When null, two: a label that does not fit one line wraps once rather
  /// than being cut.
  final int? labelMaxLines;

  /// How a label that does not fit its box is handled.
  final TextOverflow? labelOverflow;

  /// The largest text scale factor applied to the labels.
  ///
  /// When null, the labels follow the ambient [MediaQueryData.textScaler]
  /// without limit. The tooltip is never capped.
  final double? maxLabelScale;

  /// The shape of the active indicator and of the ink drawn over it.
  ///
  /// When null, a [StadiumBorder] (the Material 3 full-rounding pill).
  final ShapeBorder? indicatorShape;

  /// Whether the active indicator is drawn behind the selected destination.
  ///
  /// When null, it is.
  final bool? useIndicator;

  /// The ink state-layer color for hover, focus and pressed states.
  ///
  /// Resolved per [WidgetState]; see [overlayFor] for a spec-conformant builder.
  final WidgetStateProperty<Color?>? overlayColor;

  /// Per-state icon theme, merged over the icon's resolved size and color.
  ///
  /// Resolved against the destination's [WidgetState]s: [WidgetState.selected],
  /// [WidgetState.disabled], [WidgetState.hovered], [WidgetState.focused] and
  /// [WidgetState.pressed].
  final WidgetStateProperty<IconThemeData?>? iconTheme;

  /// Per-state label text style, merged over both labels' resolved styles.
  ///
  /// Resolved against the same [WidgetState]s as [iconTheme].
  final WidgetStateProperty<TextStyle?>? labelTextStyle;

  /// Builds a Material 3 state-layer [overlayColor] tinted with [color].
  ///
  /// The overlay uses [hover] opacity for the hovered state and [focusPress]
  /// opacity for the focused and pressed states. [color] is typically
  /// [ColorScheme.onSecondaryContainer], per the spec.
  static WidgetStateProperty<Color?> overlayFor(
      Color color, double hover, double focusPress) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return color.withValues(alpha: focusPress);
      }
      if (states.contains(WidgetState.focused)) {
        return color.withValues(alpha: focusPress);
      }
      if (states.contains(WidgetState.hovered)) {
        return color.withValues(alpha: hover);
      }
      return null;
    });
  }
}
