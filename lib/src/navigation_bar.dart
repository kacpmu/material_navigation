import 'package:flutter/material.dart'
    hide NavigationBar, NavigationDestination;

import 'navigation_destination.dart';
import 'navigation_motion.dart';

/// A Material 3 Expressive bottom navigation bar.
///
/// Displays a short row of 3 to 5 [destinations], each an icon in a pill-shaped
/// active indicator with a label. Exactly one destination is selected at a time,
/// given by [selectedIndex]; tapping another calls [onDestinationSelected].
///
/// [layoutDirection] selects the item layout. With [Axis.vertical] the icon sits
/// above the label and the items fill the bar; with [Axis.horizontal] the icon
/// and label sit side by side inside the pill and the items are centered with
/// outer margins. Changing [layoutDirection] animates between the two layouts
/// under [motion].
///
/// Colors and sizes are resolved from [style]; when omitted, the bar builds a
/// [NavigationBarStyle.flexible] from the ambient [Theme]'s [ColorScheme] and
/// [TextTheme], matching the Material 3 Expressive bar. Individual aspects can
/// be overridden with [backgroundColor], [indicatorColor], [elevation], and
/// [height].
///
/// Typically placed in [Scaffold.bottomNavigationBar].
///
/// ```dart
/// NavigationBar(
///   selectedIndex: _index,
///   onDestinationSelected: (i) => setState(() => _index = i),
///   destinations: const [
///     NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
///     NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
///     NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
///   ],
/// )
/// ```
///
/// See also:
///
///  * [NavigationRail], the wide-window counterpart that shares the same morph.
///  * [NavigationBarStyle], the token bundle that drives the bar's appearance.
class NavigationBar extends StatefulWidget {
  /// Creates a Material 3 Expressive bottom navigation bar.
  ///
  /// The [destinations] and [selectedIndex] arguments are required.
  const NavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.layoutDirection = Axis.vertical,
    this.labelBehavior = NavigationLabelBehavior.all,
    this.style,
    this.motion = const NavigationMotion.expressive(),
    this.height,
    this.backgroundColor,
    this.indicatorColor,
    this.elevation,
  });

  /// The destinations laid out across the bar, three to five recommended.
  ///
  /// Their order matches [selectedIndex] and the index passed to
  /// [onDestinationSelected].
  final List<NavigationDestination> destinations;

  /// The index into [destinations] of the currently selected destination.
  final int selectedIndex;

  /// Called with the destination index when a destination is tapped.
  ///
  /// If null, the bar is non-interactive. Disabled destinations never call back.
  final ValueChanged<int>? onDestinationSelected;

  /// The orientation of each item's icon and label.
  ///
  /// With [Axis.vertical] the icon sits above the label, the Material 3 bottom
  /// bar layout; with [Axis.horizontal] they sit side by side inside the active
  /// indicator. Changing this animates the bar between the two layouts under
  /// [motion].
  final Axis layoutDirection;

  /// Whether below-labels are shown for all destinations, only the selected one,
  /// or never.
  ///
  /// Shows every destination's below-label ([NavigationLabelBehavior.all])
  /// unless set otherwise. In the horizontal layout every destination shows its
  /// label beside the icon regardless of this value.
  final NavigationLabelBehavior labelBehavior;

  /// The token bundle that drives the bar's geometry, colors, and text styles.
  ///
  /// When null, the bar builds a [NavigationBarStyle.flexible] from the ambient
  /// [Theme] (the Material 3 Expressive 64dp bar). Use
  /// [NavigationBarStyle.baseline] for the baseline 80dp bar, or
  /// [NavigationBarStyle.copyWith] to adjust individual tokens.
  final NavigationBarStyle? style;

  /// The motion that animates the bar between its vertical and horizontal item
  /// layouts.
  ///
  /// Material 3 Expressive spring physics drive the morph
  /// ([NavigationMotion.expressive]); pass [NavigationMotion.standard] for a
  /// fixed emphasized-easing duration and curve instead.
  final NavigationMotion motion;

  /// The height of the bar's container.
  ///
  /// Falls back to [NavigationBarStyle.height] (Material 3: flexible 64dp,
  /// baseline 80dp).
  final double? height;

  /// The color of the bar's container.
  ///
  /// Falls back to [NavigationBarStyle.containerColor], the Material 3
  /// [ColorScheme.surfaceContainer] role.
  final Color? backgroundColor;

  /// The color of the active indicator behind the selected destination.
  ///
  /// Falls back to [NavigationBarStyle.indicatorColor], the Material 3
  /// [ColorScheme.secondaryContainer] role.
  final Color? indicatorColor;

  /// The elevation of the bar's container.
  ///
  /// Falls back to [NavigationBarStyle.elevation] (Material 3: 3dp).
  final double? elevation;

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

// Drives the active indicator per destination and the shared
// vertical/horizontal morph.
class _NavigationBarState extends State<NavigationBar>
    with TickerProviderStateMixin {
  // One controller per destination drives its active indicator's scale/fade.
  late List<AnimationController> _destControllers;
  late List<Animation<double>> _destAnimations;
  // 0 = vertical layout, 1 = horizontal layout.
  late AnimationController _morphController;

  double get _morphTarget =>
      widget.layoutDirection == Axis.horizontal ? 1.0 : 0.0;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(NavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.motion != oldWidget.motion) {
      // Re-create the morph controller under the new motion, keeping progress.
      final value = _morphController.value;
      _morphController.dispose();
      _morphController = widget.motion.createController(this, value)
        ..addListener(_rebuild);
    }
    if (widget.layoutDirection != oldWidget.layoutDirection) {
      widget.motion.animateTo(_morphController, _morphTarget);
    }
    if (widget.destinations.length != oldWidget.destinations.length) {
      _disposeControllers();
      _initControllers();
      return;
    }
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      if (oldWidget.selectedIndex >= 0 &&
          oldWidget.selectedIndex < _destControllers.length) {
        _destControllers[oldWidget.selectedIndex].reverse();
      }
      _destControllers[widget.selectedIndex].forward();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initControllers() {
    _destControllers = List<AnimationController>.generate(
      widget.destinations.length,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      )..addListener(_rebuild),
    );
    _destAnimations = _destControllers.map((c) => c.view).toList();
    if (widget.selectedIndex >= 0 &&
        widget.selectedIndex < _destControllers.length) {
      _destControllers[widget.selectedIndex].value = 1.0;
    }
    _morphController = widget.motion.createController(this, _morphTarget)
      ..addListener(_rebuild);
  }

  void _disposeControllers() {
    for (final c in _destControllers) {
      c.dispose();
    }
    _morphController.dispose();
  }

  void _rebuild() => setState(() {});

  double _maxHorizontalItemWidth(
      BuildContext context, NavigationBarStyle style) {
    final labelStyle = style.horizontalLabelStyle
        .copyWith(fontWeight: style.activeLabelWeight);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    var widest = style.verticalIndicatorWidth;
    for (final destination in widget.destinations) {
      final painter = TextPainter(
        text: TextSpan(text: destination.label, style: labelStyle),
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      final hug = style.besideLabelStart +
          painter.width +
          style.horizontalTrailingSpace;
      if (hug > widest) widest = hug;
    }
    return widest + 2 * style.expandedPillHorizontalMargin;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style ??
        NavigationBarStyle.flexible(theme.colorScheme, theme.textTheme);
    final indicatorColor = widget.indicatorColor ?? style.indicatorColor;
    final itemStyle = style.destinationStyle;
    return Material(
      color: widget.backgroundColor ?? style.containerColor,
      elevation: widget.elevation ?? style.elevation,
      shadowColor: style.shadowColor,
      // surfaceContainer already encodes the elevation tint; don't double-tint.
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: widget.height ?? style.height,
          child: LayoutBuilder(
            builder: (context, barConstraints) {
              final extend = _morphController.value.clamp(0.0, 1.0);
              var margin = 0.0;
              if (extend > 0) {
                final n = widget.destinations.length;
                final itemWidth = _maxHorizontalItemWidth(context, style);
                final room = ((barConstraints.maxWidth - n * itemWidth) / 2)
                    .clamp(0.0, double.infinity);
                margin = room * extend;
              }
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: margin),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.destinations.length; i++)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              NavigationDestination.custom(
                            icon: widget.destinations[i].icon,
                            selectedIcon: widget.destinations[i].selectedIcon,
                            label: widget.destinations[i].label,
                            tooltip: widget.destinations[i].tooltip,
                            disabled: widget.destinations[i].disabled,
                            selected: i == widget.selectedIndex,
                            labelBehavior: widget.labelBehavior,
                            indicatorColor: indicatorColor,
                            iconSize: style.iconSize,
                            minWidth: constraints.maxWidth,
                            expandedWidth: constraints.maxWidth,
                            collapsedIndicatorWidth:
                                style.verticalIndicatorWidth,
                            collapsedIndicatorHeight:
                                style.verticalIndicatorHeight,
                            expandedIndicatorHeight:
                                style.horizontalIndicatorHeight,
                            besideLabelStart: style.besideLabelStart,
                            labelTrailingSpace: style.horizontalTrailingSpace,
                            belowLabelSpacing: style.verticalIconLabelSpacing,
                            horizontalMargin:
                                style.expandedPillHorizontalMargin,
                            indicatorSize: NavigationIndicatorSize.label,
                            centered: true,
                            style: itemStyle,
                            destinationAnimation: _destAnimations[i],
                            expandAnimation: _morphController.view,
                            onTap: (!widget.destinations[i].disabled &&
                                    widget.onDestinationSelected != null)
                                ? () => widget.onDestinationSelected!(i)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The visual tokens that drive a [NavigationBar].
///
/// Bundles every value the bar renders: container geometry and color, active
/// indicator dimensions, icon and label colors, label text styles, state-layer
/// opacities, and inter-element spacing.
///
/// Build one with [NavigationBarStyle.flexible] (the recommended bar) or
/// [NavigationBarStyle.baseline] (the older variant) from a [ColorScheme] and
/// [TextTheme], then adjust individual tokens with [copyWith].
///
/// ```dart
/// final style = NavigationBarStyle.flexible(
///   theme.colorScheme,
///   theme.textTheme,
/// ).copyWith(indicatorColor: Colors.amber);
/// ```
@immutable
class NavigationBarStyle {
  /// Creates a token bundle with every value specified.
  ///
  /// Prefer [NavigationBarStyle.flexible] or [NavigationBarStyle.baseline],
  /// which fill these in from a [ColorScheme] and [TextTheme].
  const NavigationBarStyle({
    required this.height,
    required this.containerColor,
    required this.elevation,
    required this.shadowColor,
    required this.indicatorColor,
    required this.iconSize,
    required this.verticalIndicatorWidth,
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
    required this.stateLayerColor,
    required this.hoverOpacity,
    required this.focusPressOpacity,
  });

  /// Creates the tokens for the Material 3 Expressive (flexible) bar.
  ///
  /// Per Material 3 Expressive: a 64dp [ColorScheme.surfaceContainer] container
  /// at 3dp elevation, a 56dp x 32dp vertical active indicator, a 40dp-tall
  /// beside-icon indicator, and a [ColorScheme.secondary] active label. Colors
  /// derive from [colors] and label styles from [text].
  factory NavigationBarStyle.flexible(ColorScheme colors, TextTheme text) {
    return NavigationBarStyle(
      height: 64, // spec: nav bar height 64dp
      containerColor: colors.surfaceContainer,
      elevation: 3, // spec: container elevation 3dp
      shadowColor: colors.shadow, // spec: shadow color #000
      indicatorColor: colors.secondaryContainer,
      iconSize: 24, // spec: nav bar item icon size 24dp
      verticalIndicatorWidth: 56, // spec: vertical active indicator width 56dp
      verticalIndicatorHeight:
          32, // spec: vertical active indicator height 32dp
      horizontalIndicatorHeight:
          40, // spec: horizontal active indicator height 40dp
      activeIconColor: colors.onSecondaryContainer,
      inactiveIconColor: colors.onSurfaceVariant,
      disabledColor: colors.onSurface.withValues(alpha: 0.38),
      activeLabelColor:
          colors.secondary, // spec: active label text color secondary
      inactiveLabelColor: colors.onSurfaceVariant,
      activeLabelWeight: FontWeight.w500,
      verticalLabelStyle: text.labelMedium!, // spec: label medium
      horizontalLabelStyle:
          text.labelMedium!, // spec: horizontal also label medium
      iconLabelSpacing:
          4, // spec: horizontal active indicator icon label space 4dp
      verticalIconLabelSpacing:
          4, // spec: vertical active indicator icon label space 4dp
      horizontalLeadingSpace:
          16, // spec: horizontal indicator leading space 16dp
      horizontalTrailingSpace:
          16, // spec: horizontal indicator trailing space 16dp
      expandedPillHorizontalMargin:
          12, // internal: side breathing room for the morphed pill
      stateLayerColor: colors.onSecondaryContainer,
      hoverOpacity: 0.08,
      focusPressOpacity: 0.1,
    );
  }

  /// Creates the tokens for the Material 3 baseline (pre-Expressive) bar.
  ///
  /// Per the Material 3 baseline: an 80dp [ColorScheme.surfaceContainer]
  /// container, a 64dp-wide vertical active indicator, and a bolder
  /// [ColorScheme.onSurface] active label at weight 700. Colors derive from
  /// [colors] and label styles from [text]. Prefer
  /// [NavigationBarStyle.flexible] for the Expressive bar.
  factory NavigationBarStyle.baseline(ColorScheme colors, TextTheme text) {
    return NavigationBarStyle(
      height: 80, // spec: baseline height 80dp
      containerColor: colors.surfaceContainer,
      elevation: 3,
      shadowColor: colors.shadow,
      indicatorColor: colors.secondaryContainer,
      iconSize: 24, // spec: baseline icon size 24dp
      verticalIndicatorWidth: 64, // spec: baseline active indicator width 64dp
      verticalIndicatorHeight: 32,
      horizontalIndicatorHeight:
          40, // baseline has no horizontal config; unused
      activeIconColor: colors.onSecondaryContainer,
      inactiveIconColor: colors.onSurfaceVariant,
      disabledColor: colors.onSurface.withValues(alpha: 0.38),
      activeLabelColor:
          colors.onSurface, // spec: baseline active label on-surface
      inactiveLabelColor: colors.onSurfaceVariant,
      activeLabelWeight:
          FontWeight.w700, // spec: baseline active label weight 700
      verticalLabelStyle: text.labelMedium!,
      horizontalLabelStyle: text.labelMedium!,
      iconLabelSpacing: 4,
      verticalIconLabelSpacing: 4,
      horizontalLeadingSpace: 16,
      horizontalTrailingSpace: 16,
      expandedPillHorizontalMargin: 12,
      stateLayerColor: colors.onSecondaryContainer,
      hoverOpacity: 0.08,
      focusPressOpacity: 0.1,
    );
  }

  /// The height of the container (Material 3: flexible 64dp, baseline 80dp).
  final double height;

  /// The fill color of the container, the Material 3
  /// [ColorScheme.surfaceContainer] role.
  final Color containerColor;

  /// The elevation of the container (Material 3: 3dp).
  final double elevation;

  /// The color of the shadow cast by the container.
  final Color shadowColor;

  /// The fill color of the active indicator, the Material 3
  /// [ColorScheme.secondaryContainer] role.
  final Color indicatorColor;

  /// The edge length of each destination icon. Material 3 specifies 24dp for
  /// navigation icons.
  final double iconSize;

  /// The width of the active indicator in the vertical layout (Material 3:
  /// flexible 56dp, baseline 64dp).
  final double verticalIndicatorWidth;

  /// The height of the active indicator in the vertical layout (Material 3:
  /// 32dp).
  final double verticalIndicatorHeight;

  /// The height of the active indicator in the horizontal (beside-icon) layout
  /// (Material 3: 40dp).
  final double horizontalIndicatorHeight;

  /// The color of the selected destination's icon, the Material 3
  /// [ColorScheme.onSecondaryContainer] role.
  final Color activeIconColor;

  /// The color of unselected destinations' icons, the Material 3
  /// [ColorScheme.onSurfaceVariant] role.
  final Color inactiveIconColor;

  /// The color of a disabled destination's icon and label, the Material 3
  /// [ColorScheme.onSurface] role at 38% opacity.
  final Color disabledColor;

  /// The color of the selected destination's label (Material 3:
  /// [ColorScheme.secondary] in Expressive, [ColorScheme.onSurface] in
  /// baseline).
  final Color activeLabelColor;

  /// The color of unselected destinations' labels, the Material 3
  /// [ColorScheme.onSurfaceVariant] role.
  final Color inactiveLabelColor;

  /// The font weight applied to the selected destination's label (Material 3:
  /// flexible 500, baseline 700).
  final FontWeight activeLabelWeight;

  /// The base label text style in the vertical (icon-above) layout, the
  /// Material 3 labelMedium type role.
  final TextStyle verticalLabelStyle;

  /// The base label text style in the horizontal (icon-beside) layout, the
  /// Material 3 labelMedium type role.
  final TextStyle horizontalLabelStyle;

  /// The gap between icon and label in the horizontal layout (Material 3: 4dp).
  final double iconLabelSpacing;

  /// The gap between the active indicator and the label below it in the
  /// vertical layout (Material 3: 4dp).
  final double verticalIconLabelSpacing;

  /// The space before the icon in the horizontal layout (Material 3: 16dp).
  final double horizontalLeadingSpace;

  /// The space after the label in the horizontal layout (Material 3: 16dp).
  final double horizontalTrailingSpace;

  /// The side inset that keeps the expanded active indicator clear of its slot
  /// edges (12dp).
  ///
  /// Not a Material 3 spec token, but an internal layout value.
  final double expandedPillHorizontalMargin;

  /// The color of the hover, focus, and pressed state layers, the Material 3
  /// [ColorScheme.onSecondaryContainer] role.
  final Color stateLayerColor;

  /// The opacity of the hover state layer (Material 3: 0.08).
  final double hoverOpacity;

  /// The opacity of the focus and pressed state layers (Material 3: 0.10).
  final double focusPressOpacity;

  /// The x offset, from the pill's leading edge, at which the label begins in
  /// the horizontal layout.
  ///
  /// The sum of [horizontalLeadingSpace], [iconSize], and [iconLabelSpacing].
  /// In the flexible bar the icon is centered in the indicator box, that is
  /// `horizontalLeadingSpace == (verticalIndicatorWidth - iconSize) / 2`.
  double get besideLabelStart =>
      horizontalLeadingSpace + iconSize + iconLabelSpacing;

  /// The per-destination style derived from these tokens and handed to each
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

  /// Creates a copy of this style with the given fields replaced.
  ///
  /// Fields left null retain their current value.
  NavigationBarStyle copyWith({
    double? height,
    Color? containerColor,
    double? elevation,
    Color? shadowColor,
    Color? indicatorColor,
    double? iconSize,
    double? verticalIndicatorWidth,
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
    Color? stateLayerColor,
    double? hoverOpacity,
    double? focusPressOpacity,
  }) {
    return NavigationBarStyle(
      height: height ?? this.height,
      containerColor: containerColor ?? this.containerColor,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      iconSize: iconSize ?? this.iconSize,
      verticalIndicatorWidth:
          verticalIndicatorWidth ?? this.verticalIndicatorWidth,
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
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      hoverOpacity: hoverOpacity ?? this.hoverOpacity,
      focusPressOpacity: focusPressOpacity ?? this.focusPressOpacity,
    );
  }
}
