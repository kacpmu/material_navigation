import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/semantics.dart' show SemanticsRole;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination;

import 'label_metrics.dart';
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

  /// Whether labels are shown for all destinations, only the selected one, or
  /// never.
  ///
  /// Shows every destination's label ([NavigationLabelBehavior.all]) unless
  /// set otherwise. Applies in both layouts: below the icon in the vertical
  /// one, and beside it in the horizontal one, where a hidden label leaves the
  /// active indicator around the icon alone.
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
  /// baseline 80dp). A minimum rather than a fixed value: the bar grows when
  /// its destinations need more room, as at large text scales. Cap that growth
  /// with [NavigationBarStyle.maxLabelScale].
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
  // The label behavior a change eases the bar's height away from, in step
  // with the destinations easing their below-labels.
  NavigationLabelBehavior? _fromLabelBehavior;
  late final AnimationController _labelBehaviorChange = AnimationController(
    vsync: this,
    duration: navigationLabelBehaviorDuration,
    value: 1,
  )..addListener(_rebuild);

  double get _morphTarget =>
      widget.layoutDirection == Axis.horizontal ? 1.0 : 0.0;

  @override
  void initState() {
    super.initState();
    _initDestinationControllers();
    _morphController = widget.motion.createController(this, _morphTarget)
      ..addListener(_rebuild);
  }

  @override
  void didUpdateWidget(NavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.layoutDirection != oldWidget.layoutDirection) {
      widget.motion.animateTo(_morphController, _morphTarget);
    }
    if (widget.labelBehavior != oldWidget.labelBehavior) {
      _fromLabelBehavior = oldWidget.labelBehavior;
      _labelBehaviorChange.forward(from: 0);
    }
    if (widget.destinations.length != oldWidget.destinations.length) {
      // The morph controller is independent of the destination list, so the
      // bar keeps its layout progress across a change in destinations.
      _disposeDestinationControllers();
      _initDestinationControllers();
      return;
    }
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectionControllerAt(oldWidget.selectedIndex)?.reverse();
      _selectionControllerAt(widget.selectedIndex)?.forward();
    }
  }

  @override
  void dispose() {
    _disposeDestinationControllers();
    _morphController.dispose();
    _labelBehaviorChange.dispose();
    super.dispose();
  }

  // Null rather than a range error when [index] is out of bounds, so an
  // out-of-range selectedIndex shows nothing selected instead of crashing. The
  // constructor cannot check the range while it stays const.
  AnimationController? _selectionControllerAt(int index) =>
      index >= 0 && index < _destControllers.length
          ? _destControllers[index]
          : null;

  void _initDestinationControllers() {
    _destControllers = List<AnimationController>.generate(
      widget.destinations.length,
      // The destinations listen to these themselves; the bar reads no value
      // from them, so it deliberately does not rebuild on their ticks.
      (_) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _destAnimations = _destControllers.map((c) => c.view).toList();
    _selectionControllerAt(widget.selectedIndex)?.value = 1.0;
  }

  void _disposeDestinationControllers() {
    for (final c in _destControllers) {
      c.dispose();
    }
  }

  void _rebuild() => setState(() {});

  // The tab-bar role needs at least one tab under it, and a tab needs a tap
  // action, so a bar with nothing to select is left unroled.
  Widget _asTabBar(Widget child) =>
      widget.destinations.isEmpty || widget.onDestinationSelected == null
          ? child
          : Semantics(
              role: SemanticsRole.tabBar,
              explicitChildNodes: true,
              container: true,
              child: child,
            );

  // The scale labels are laid out at, honouring [NavigationBarStyle.maxLabelScale].
  TextScaler _labelScaler(BuildContext context, NavigationBarStyle style) {
    final scaler = MediaQuery.textScalerOf(context);
    final max = style.maxLabelScale;
    return max == null ? scaler : scaler.clamp(maxScaleFactor: max);
  }

  // The height the destinations need at morph progress [extend], in slots
  // [slotWidth] wide whose beside-labels wrap at [besideWidth], at the current
  // text scale. Material 3 grows the bar rather than clipping its labels, so
  // this is a floor under the bar's own height rather than a value it
  // overrides.
  double _contentHeight(BuildContext context, NavigationBarStyle style,
      double slotWidth, double besideWidth, double extend) {
    final textDirection = Directionality.of(context);
    final textScaler = _labelScaler(context, style);
    final locale = Localizations.maybeLocaleOf(context);
    final boldText = MediaQuery.boldTextOf(context);
    final belowStyle =
        style.verticalLabelStyle!.copyWith(fontWeight: style.activeLabelWeight);
    final besideStyle = style.horizontalLabelStyle!
        .copyWith(fontWeight: style.activeLabelWeight);
    final maxLines = style.labelMaxLines!;
    // The destination's own fallback when the style sets none.
    final labelPadding =
        style.labelPadding ?? const EdgeInsets.symmetric(horizontal: 4);
    // Each label measured at the width it wraps to in its destination.
    final belowWidth = math.max(0.0, slotWidth - labelPadding.horizontal);
    var below = 0.0;
    var beside = 0.0;
    for (final destination in widget.destinations) {
      below = math.max(
          below,
          measureLabel(destination.label,
                  style: belowStyle,
                  textDirection: textDirection,
                  textScaler: textScaler,
                  locale: locale,
                  maxLines: maxLines,
                  maxWidth: belowWidth,
                  boldText: boldText)
              .height);
      beside = math.max(
          beside,
          measureLabel(destination.label,
                  style: besideStyle,
                  textDirection: textDirection,
                  textScaler: textScaler,
                  locale: locale,
                  maxLines: maxLines,
                  maxWidth: besideWidth,
                  boldText: boldText)
              .height);
    }
    // As a destination lays itself out: the pill, growing from its vertical
    // to its horizontal height around a tall label, or the icon where that is
    // taller still, above the below-label, which collapses as the bar morphs.
    // A hidden label still reserves the gap below the pill, and the pill
    // hugs only the icon.
    final labelShown = _labelsShown;
    final belowLabel = style.verticalIconLabelSpacing! +
        labelShown * (below + labelPadding.vertical);
    final horizontalPill = lerpDouble(
        style.horizontalIndicatorHeight!,
        math.max(style.horizontalIndicatorHeight!,
            beside + style.horizontalIndicatorHeight! - style.iconSize!),
        labelShown)!;
    final pill =
        lerpDouble(style.verticalIndicatorHeight!, horizontalPill, extend)!;
    return math.max(pill, style.iconSize!) + (1 - extend) * belowLabel;
  }

  // How far the labels show, from 0 under [NavigationLabelBehavior.none] to 1
  // otherwise, easing through a change of behavior as the destinations do.
  // [NavigationLabelBehavior.selected] counts as shown: any destination's label
  // shows once it is selected.
  double get _labelsShown {
    double shown(NavigationLabelBehavior behavior) =>
        behavior == NavigationLabelBehavior.none ? 0 : 1;
    return lerpDouble(
        shown(_fromLabelBehavior ?? widget.labelBehavior),
        shown(widget.labelBehavior),
        navigationLabelBehaviorCurve.transform(_labelBehaviorChange.value))!;
  }

  // The width every horizontal destination takes: the widest pill, around its
  // label when labels show and around the icon alone when they do not, plus
  // the pill's margins. Uniform, so destinations keep their positions as the
  // selection moves.
  double _maxHorizontalItemWidth(
      BuildContext context, NavigationBarStyle style) {
    final labelStyle = style.horizontalLabelStyle!
        .copyWith(fontWeight: style.activeLabelWeight);
    final textDirection = Directionality.of(context);
    final textScaler = _labelScaler(context, style);
    final locale = Localizations.maybeLocaleOf(context);
    final boldText = MediaQuery.boldTextOf(context);
    var widest = style.verticalIndicatorWidth!;
    for (final destination in widget.destinations) {
      final hug = _besideLabelStart(style) +
          measureLabel(destination.label,
                  style: labelStyle,
                  textDirection: textDirection,
                  textScaler: textScaler,
                  locale: locale,
                  boldText: boldText)
              .width +
          style.horizontalTrailingSpace!;
      if (hug > widest) widest = hug;
    }
    return lerpDouble(style.verticalIndicatorWidth!, widest, _labelsShown)! +
        2 * style.expandedPillHorizontalMargin!;
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
        child: LayoutBuilder(
          builder: (context, barConstraints) {
            final n = widget.destinations.length;
            final extend = _morphController.value.clamp(0.0, 1.0);
            var margin = 0.0;
            if (extend > 0) {
              final itemWidth = _maxHorizontalItemWidth(context, style);
              final room = ((barConstraints.maxWidth - n * itemWidth) / 2)
                  .clamp(0.0, double.infinity);
              margin = room * extend;
            }
            final slotWidth =
                (barConstraints.maxWidth - 2 * margin) / math.max(n, 1);
            // The width a destination wraps its beside-label at: the slot,
            // less the pill's margin, the icon and the space after the label.
            final besideWidth = math.max(
                0.0,
                slotWidth -
                    pillMarginFor(slotWidth) -
                    _besideLabelStart(style) -
                    style.horizontalTrailingSpace!);
            return SizedBox(
              // Never shorter than its contents: labels grow with the text
              // scale instead of overflowing a fixed box.
              height: math.max(
                  widget.height ?? style.height!,
                  _contentHeight(
                      context, style, slotWidth, besideWidth, extend)),
              child: _asTabBar(Padding(
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
              )),
            );
          },
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
    this.maxLabelScale,
    this.labelMaxLines,
    this.labelOverflow,
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
      labelMaxLines: 2, // a label that does not fit wraps once
      labelOverflow: TextOverflow.clip,
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

  /// The largest text scale factor applied to destination labels, or null to
  /// follow the platform without limit (the default).
  ///
  /// The bar grows taller rather than clipping when labels scale up, as Jetpack
  /// Compose's navigation bars do. Set this for a bar that must keep its
  /// height; 1.3 matches Flutter's own navigation components.
  ///
  /// Only the labels are capped. A destination's tooltip keeps the platform's
  /// scale, so a label that is hidden or cut off can still be read in full.
  final double? maxLabelScale;

  /// The maximum number of lines a destination label may occupy (two).
  ///
  /// Labels short enough not to wrap are the guidance. A label that does not
  /// fit wraps rather than being cut, so it stays visible in full at up to
  /// twice the text size, as Material 3's accessibility guidance asks; beyond
  /// that it is cut. A label that fits one line is unaffected.
  final int? labelMaxLines;

  /// How a destination label that still does not fit is handled (Material 3:
  /// clipped, never an ellipsis).
  final TextOverflow? labelOverflow;

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
      maxLabelScale: other.maxLabelScale,
      labelMaxLines: other.labelMaxLines,
      labelOverflow: other.labelOverflow,
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
    double? maxLabelScale,
    int? labelMaxLines,
    TextOverflow? labelOverflow,
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
      maxLabelScale: maxLabelScale ?? this.maxLabelScale,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
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
      // Null means no cap rather than zero, so interpolating from it would
      // shrink the labels mid-animation; switch over instead.
      maxLabelScale: maxLabelScale == null || other.maxLabelScale == null
          ? (t < 0.5 ? maxLabelScale : other.maxLabelScale)
          : lerpDouble(maxLabelScale, other.maxLabelScale, t),
      labelMaxLines: t < 0.5 ? labelMaxLines : other.labelMaxLines,
      labelOverflow: t < 0.5 ? labelOverflow : other.labelOverflow,
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
        other.maxLabelScale == maxLabelScale &&
        other.labelMaxLines == labelMaxLines &&
        other.labelOverflow == labelOverflow &&
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
        maxLabelScale,
        labelMaxLines,
        labelOverflow,
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
    properties.add(
        DoubleProperty('maxLabelScale', maxLabelScale, defaultValue: null));
    properties
        .add(IntProperty('labelMaxLines', labelMaxLines, defaultValue: null));
    properties.add(EnumProperty<TextOverflow>('labelOverflow', labelOverflow,
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
      labelMaxLines: style.labelMaxLines,
      maxLabelScale: style.maxLabelScale,
      labelOverflow: style.labelOverflow,
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
