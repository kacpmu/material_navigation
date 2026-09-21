import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
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
    final labelStyle = style.horizontalLabelStyle!
        .copyWith(fontWeight: style.activeLabelWeight);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    var widest = style.verticalIndicatorWidth!;
    for (final destination in widget.destinations) {
      final painter = TextPainter(
        text: TextSpan(text: destination.label, style: labelStyle),
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      final hug = _besideLabelStart(style) +
          painter.width +
          style.horizontalTrailingSpace!;
      painter.dispose();
      if (hug > widest) widest = hug;
    }
    return widest + 2 * style.expandedPillHorizontalMargin!;
  }

  @override
  Widget build(BuildContext context) {
    final style = NavigationBarStyle.of(context, widget.style);
    final indicatorColor = widget.indicatorColor ?? style.indicatorColor;
    final itemStyle = _destinationStyle(style);
    for (final controller in _destControllers) {
      controller.duration = style.selectionDuration;
    }
    // A slot too narrow for a destination squashes it rather than overflowing:
    // the pill's side margins give way first, then the indicator narrows.
    double indicatorWidthFor(double slot) =>
        math.min(style.verticalIndicatorWidth!, slot);
    double pillMarginFor(double slot) => math.min(
        style.expandedPillHorizontalMargin!,
        (slot - indicatorWidthFor(slot)) / 2);
    return Material(
      color: widget.backgroundColor ?? style.containerColor,
      elevation: widget.elevation ?? style.elevation!,
      shadowColor: style.shadowColor,
      // surfaceContainer already encodes the elevation tint; don't double-tint.
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: widget.height ?? style.height!,
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
                            iconSize: style.iconSize!,
                            minWidth: constraints.maxWidth,
                            expandedWidth: constraints.maxWidth,
                            collapsedIndicatorWidth:
                                indicatorWidthFor(constraints.maxWidth),
                            collapsedIndicatorHeight:
                                style.verticalIndicatorHeight!,
                            expandedIndicatorHeight:
                                style.horizontalIndicatorHeight!,
                            besideLabelStart: _besideLabelStart(style),
                            labelTrailingSpace: style.horizontalTrailingSpace!,
                            belowLabelSpacing: style.verticalIconLabelSpacing!,
                            horizontalMargin:
                                pillMarginFor(constraints.maxWidth),
                            indicatorSize: style.horizontalIndicatorSize!,
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
/// indicator dimensions and shape, icon and label colors, label text styles,
/// state layers, and inter-element spacing.
///
/// Every token is optional. A bar resolves its style with [of]: the style
/// passed to [NavigationBar.style], over the [NavigationBarStyle] registered in
/// the ambient [ThemeData.extensions], over the Material 3 defaults for the
/// chosen [variant] computed from the theme's [ColorScheme] and [TextTheme]. So
/// the defaults follow light and dark themes, and an app can set a few tokens
/// once for every bar:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [NavigationBarStyle(indicatorColor: Colors.amber)],
///   ),
/// )
/// ```
///
/// [NavigationBarStyle.flexible] and [NavigationBarStyle.baseline] build a
/// complete style for a given [ColorScheme] and [TextTheme].
@immutable
class NavigationBarStyle extends ThemeExtension<NavigationBarStyle>
    with Diagnosticable {
  /// Creates a bar style.
  ///
  /// Every token is optional. Tokens left null fall back, when the style is
  /// resolved by [of], to the ambient theme's extension and then to the
  /// defaults of the chosen [variant].
  const NavigationBarStyle({
    this.variant,
    this.height,
    this.containerColor,
    this.elevation,
    this.shadowColor,
    this.indicatorColor,
    this.indicatorShape,
    this.useIndicator,
    this.iconSize,
    this.verticalIndicatorWidth,
    this.verticalIndicatorHeight,
    this.horizontalIndicatorHeight,
    this.horizontalIndicatorSize,
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
    this.stateLayerColor,
    this.hoverOpacity,
    this.focusPressOpacity,
    this.overlayColor,
    this.iconTheme,
    this.labelTextStyle,
    this.selectionDuration,
  });

  /// The complete Material 3 Expressive (flexible) bar.
  ///
  /// A 64dp [ColorScheme.surfaceContainer] container, a 56dp x 32dp vertical
  /// active indicator, a 40dp-tall horizontal indicator, and a
  /// [ColorScheme.secondary] active label. Colors derive from [colors] and label
  /// styles from [text].
  factory NavigationBarStyle.flexible(ColorScheme colors, TextTheme text) {
    return NavigationBarStyle(
      variant: StyleVariant.material3Expressive,
      height: 64, // spec: nav bar height 64dp
      containerColor: colors.surfaceContainer,
      elevation: 3, // spec: container elevation 3dp
      shadowColor: Colors.transparent, // spec: tonal elevation, no shadow
      indicatorColor: colors.secondaryContainer,
      indicatorShape: const StadiumBorder(), // spec: full rounding
      useIndicator: true,
      iconSize: 24, // spec: nav bar item icon size 24dp
      verticalIndicatorWidth: 56, // spec: vertical active indicator width 56dp
      verticalIndicatorHeight:
          32, // spec: vertical active indicator height 32dp
      horizontalIndicatorHeight: 40, // spec: horizontal active indicator 40dp
      horizontalIndicatorSize: NavigationIndicatorSize.label,
      activeIconColor: colors.onSecondaryContainer,
      inactiveIconColor: colors.onSurfaceVariant,
      disabledColor: colors.onSurfaceVariant.withValues(alpha: 0.38),
      activeLabelColor: colors.secondary, // spec: active label secondary
      inactiveLabelColor: colors.onSurfaceVariant,
      horizontalActiveLabelColor: colors.onSecondaryContainer,
      verticalLabelStyle: text.labelMedium!, // spec: label medium
      horizontalLabelStyle: text.labelMedium!, // spec: horizontal label medium
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      iconLabelSpacing: 4, // spec: horizontal icon label space 4dp
      verticalIconLabelSpacing: 4, // spec: vertical icon label space 4dp
      horizontalLeadingSpace: 16, // spec: horizontal indicator leading 16dp
      horizontalTrailingSpace: 16, // spec: horizontal indicator trailing 16dp
      expandedPillHorizontalMargin: 12,
      stateLayerColor: colors.onSecondaryContainer,
      hoverOpacity: 0.08,
      focusPressOpacity: 0.1,
      selectionDuration: const Duration(milliseconds: 200),
    );
  }

  /// The complete Material 3 baseline (pre-Expressive) bar.
  ///
  /// An 80dp [ColorScheme.surfaceContainer] container, a 64dp-wide vertical
  /// active indicator, an [ColorScheme.onSurface] active label, and inactive
  /// icons and labels that turn [ColorScheme.onSurface] while hovered, focused
  /// or pressed. Colors derive from [colors] and label styles from [text].
  factory NavigationBarStyle.baseline(ColorScheme colors, TextTheme text) {
    return NavigationBarStyle.flexible(colors, text).copyWith(
      variant: StyleVariant.material3,
      height: 80, // spec: baseline height 80dp
      verticalIndicatorWidth: 64, // spec: baseline active indicator width 64dp
      activeLabelColor: colors.onSurface, // spec: baseline active label
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

  /// The style a [NavigationBar] below [context] renders with.
  ///
  /// Applies [style] (typically [NavigationBar.style]) over the
  /// [NavigationBarStyle] in the ambient [ThemeData.extensions], over the
  /// complete defaults for the resulting [variant] built from the theme's
  /// [ColorScheme] and [TextTheme]. Every token of the result is non-null except
  /// [activeLabelWeight], [overlayColor], [iconTheme] and [labelTextStyle].
  static NavigationBarStyle of(BuildContext context,
      [NavigationBarStyle? style]) {
    final theme = Theme.of(context);
    final themed = theme.extension<NavigationBarStyle>();
    final variant =
        style?.variant ?? themed?.variant ?? StyleVariant.material3Expressive;
    final defaults = switch (variant) {
      StyleVariant.material3 =>
        NavigationBarStyle.baseline(theme.colorScheme, theme.textTheme),
      StyleVariant.material3Expressive =>
        NavigationBarStyle.flexible(theme.colorScheme, theme.textTheme),
    };
    return defaults.merge(themed).merge(style);
  }

  /// Which Material 3 variant supplies the defaults for tokens left null:
  /// [StyleVariant.material3Expressive] (the default) or
  /// [StyleVariant.material3] (baseline).
  ///
  /// Only read by [of], from the style passed in or the theme's extension.
  final StyleVariant? variant;

  /// The height of the container (Material 3 Expressive: 64dp; baseline: 80dp).
  final double? height;

  /// The fill color of the container (Material 3:
  /// [ColorScheme.surfaceContainer]).
  final Color? containerColor;

  /// The elevation of the container (Material 3: 3dp).
  final double? elevation;

  /// The color of the shadow cast by the container.
  ///
  /// Transparent by default: Material 3 expresses the bar's elevation through
  /// its [containerColor] rather than a shadow.
  final Color? shadowColor;

  /// The fill color of the active indicator (Material 3:
  /// [ColorScheme.secondaryContainer]).
  final Color? indicatorColor;

  /// The shape of the active indicator, also used to clip the ink drawn over it
  /// (Material 3: full rounding, a [StadiumBorder]).
  final ShapeBorder? indicatorShape;

  /// Whether the active indicator is drawn behind the selected destination
  /// (Material 3: true).
  final bool? useIndicator;

  /// The size of each destination icon (Material 3: 24dp).
  final double? iconSize;

  /// The width of the active indicator in the vertical layout (Material 3
  /// Expressive: 56dp; baseline: 64dp).
  ///
  /// A destination narrower than this squashes the indicator to fit.
  final double? verticalIndicatorWidth;

  /// The height of the active indicator in the vertical layout (Material 3:
  /// 32dp).
  final double? verticalIndicatorHeight;

  /// The height of the active indicator in the horizontal layout (Material 3
  /// Expressive: 40dp).
  final double? horizontalIndicatorHeight;

  /// How the active indicator is sized in the horizontal layout: hugging the
  /// icon and label ([NavigationIndicatorSize.label], Material 3 Expressive) or
  /// filling the destination ([NavigationIndicatorSize.fill]).
  final NavigationIndicatorSize? horizontalIndicatorSize;

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
  /// (Material 3: [TextTheme.labelMedium]).
  final TextStyle? horizontalLabelStyle;

  /// The padding around the below-label, added to [verticalIconLabelSpacing]
  /// above it (4dp on each side).
  final EdgeInsetsGeometry? labelPadding;

  /// The gap between the icon and the label in the horizontal layout (Material
  /// 3: 4dp).
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

  /// The space kept clear on each side of the horizontal active indicator
  /// within its destination (12dp).
  ///
  /// Not a Material 3 token, but an internal layout value. It shrinks first
  /// when a destination is too narrow.
  final double? expandedPillHorizontalMargin;

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
  NavigationBarStyle merge(NavigationBarStyle? other) {
    if (other == null) return this;
    return copyWith(
      variant: other.variant,
      height: other.height,
      containerColor: other.containerColor,
      elevation: other.elevation,
      shadowColor: other.shadowColor,
      indicatorColor: other.indicatorColor,
      indicatorShape: other.indicatorShape,
      useIndicator: other.useIndicator,
      iconSize: other.iconSize,
      verticalIndicatorWidth: other.verticalIndicatorWidth,
      verticalIndicatorHeight: other.verticalIndicatorHeight,
      horizontalIndicatorHeight: other.horizontalIndicatorHeight,
      horizontalIndicatorSize: other.horizontalIndicatorSize,
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
  NavigationBarStyle copyWith({
    StyleVariant? variant,
    double? height,
    Color? containerColor,
    double? elevation,
    Color? shadowColor,
    Color? indicatorColor,
    ShapeBorder? indicatorShape,
    bool? useIndicator,
    double? iconSize,
    double? verticalIndicatorWidth,
    double? verticalIndicatorHeight,
    double? horizontalIndicatorHeight,
    NavigationIndicatorSize? horizontalIndicatorSize,
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
    Color? stateLayerColor,
    double? hoverOpacity,
    double? focusPressOpacity,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateProperty<IconThemeData?>? iconTheme,
    WidgetStateProperty<TextStyle?>? labelTextStyle,
    Duration? selectionDuration,
  }) {
    return NavigationBarStyle(
      variant: variant ?? this.variant,
      height: height ?? this.height,
      containerColor: containerColor ?? this.containerColor,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorShape: indicatorShape ?? this.indicatorShape,
      useIndicator: useIndicator ?? this.useIndicator,
      iconSize: iconSize ?? this.iconSize,
      verticalIndicatorWidth:
          verticalIndicatorWidth ?? this.verticalIndicatorWidth,
      verticalIndicatorHeight:
          verticalIndicatorHeight ?? this.verticalIndicatorHeight,
      horizontalIndicatorHeight:
          horizontalIndicatorHeight ?? this.horizontalIndicatorHeight,
      horizontalIndicatorSize:
          horizontalIndicatorSize ?? this.horizontalIndicatorSize,
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
  NavigationBarStyle lerp(
      covariant ThemeExtension<NavigationBarStyle>? other, double t) {
    if (other is! NavigationBarStyle) return this;
    return NavigationBarStyle(
      variant: t < 0.5 ? variant : other.variant,
      height: lerpDouble(height, other.height, t),
      containerColor: Color.lerp(containerColor, other.containerColor, t),
      elevation: lerpDouble(elevation, other.elevation, t),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      indicatorColor: Color.lerp(indicatorColor, other.indicatorColor, t),
      indicatorShape: ShapeBorder.lerp(indicatorShape, other.indicatorShape, t),
      useIndicator: t < 0.5 ? useIndicator : other.useIndicator,
      iconSize: lerpDouble(iconSize, other.iconSize, t),
      verticalIndicatorWidth:
          lerpDouble(verticalIndicatorWidth, other.verticalIndicatorWidth, t),
      verticalIndicatorHeight:
          lerpDouble(verticalIndicatorHeight, other.verticalIndicatorHeight, t),
      horizontalIndicatorHeight: lerpDouble(
          horizontalIndicatorHeight, other.horizontalIndicatorHeight, t),
      horizontalIndicatorSize:
          t < 0.5 ? horizontalIndicatorSize : other.horizontalIndicatorSize,
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
    return other is NavigationBarStyle &&
        other.variant == variant &&
        other.height == height &&
        other.containerColor == containerColor &&
        other.elevation == elevation &&
        other.shadowColor == shadowColor &&
        other.indicatorColor == indicatorColor &&
        other.indicatorShape == indicatorShape &&
        other.useIndicator == useIndicator &&
        other.iconSize == iconSize &&
        other.verticalIndicatorWidth == verticalIndicatorWidth &&
        other.verticalIndicatorHeight == verticalIndicatorHeight &&
        other.horizontalIndicatorHeight == horizontalIndicatorHeight &&
        other.horizontalIndicatorSize == horizontalIndicatorSize &&
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
        height,
        containerColor,
        elevation,
        shadowColor,
        indicatorColor,
        indicatorShape,
        useIndicator,
        iconSize,
        verticalIndicatorWidth,
        verticalIndicatorHeight,
        horizontalIndicatorHeight,
        horizontalIndicatorSize,
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
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(
        ColorProperty('containerColor', containerColor, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties
        .add(ColorProperty('shadowColor', shadowColor, defaultValue: null));
    properties.add(
        ColorProperty('indicatorColor', indicatorColor, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>(
        'indicatorShape', indicatorShape,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('useIndicator', useIndicator,
        defaultValue: null));
    properties.add(DoubleProperty('iconSize', iconSize, defaultValue: null));
    properties.add(DoubleProperty(
        'verticalIndicatorWidth', verticalIndicatorWidth,
        defaultValue: null));
    properties.add(DoubleProperty(
        'verticalIndicatorHeight', verticalIndicatorHeight,
        defaultValue: null));
    properties.add(DoubleProperty(
        'horizontalIndicatorHeight', horizontalIndicatorHeight,
        defaultValue: null));
    properties.add(EnumProperty<NavigationIndicatorSize>(
        'horizontalIndicatorSize', horizontalIndicatorSize,
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
double _besideLabelStart(NavigationBarStyle style) =>
    style.horizontalLeadingSpace! + style.iconSize! + style.iconLabelSpacing!;

// The per-destination style handed to each destination of a resolved style.
NavigationDestinationStyle _destinationStyle(NavigationBarStyle style) =>
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
