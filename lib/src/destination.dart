// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

import 'animation.dart';
import 'bar.dart';
import 'bar_style.dart';
import 'item.dart';
import 'label_metrics.dart';
import 'motion.dart';
import 'rail.dart';

/// A destination of a [NavigationBar] or a [NavigationRail]: an icon, a label
/// and an optional badge.
///
/// A destination renders itself inside a bar's or a rail's destinations,
/// which give it its layout, its selection and its style:
///
/// ```dart
/// NavigationDestination(
///   icon: const Icon(Icons.inbox_outlined),
///   selectedIcon: const Icon(Icons.inbox),
///   label: 'Inbox',
///   badge: Badge.count(count: 3),
/// )
/// ```
///
/// Anywhere else in a rail, such as its `trailing` widget or a widget of its
/// layout, a destination takes the rail's layout and style, so it lines up
/// with the rail's destinations and expands with them. It is never selected;
/// a tap calls [onTap]:
///
/// ```dart
/// NavigationRail(
///   trailing: NavigationDestination(
///     icon: const Icon(Icons.settings_outlined),
///     label: 'Settings',
///     onTap: _openSettings,
///   ),
///   // ...
/// )
/// ```
final class NavigationDestination extends StatefulWidget {
  /// Creates a destination.
  const NavigationDestination({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.enabled = true,
    this.badge,
    this.semanticLabel,
    this.onTap,
  });

  /// The icon, typically an outlined [Icon].
  ///
  /// Shown only while unselected when [selectedIcon] is given.
  final Widget icon;

  /// The icon while selected, typically a filled [Icon].
  ///
  /// When null, [icon] is shown in both states.
  final Widget? selectedIcon;

  /// The label, one or two words (m3 guidelines).
  final String label;

  /// The tooltip shown while the label is not visible.
  ///
  /// When null, the tooltip shows [label]. An empty string turns the tooltip
  /// off.
  final String? tooltip;

  /// Whether the destination can be selected.
  ///
  /// A disabled destination is dimmed and ignores taps.
  final bool enabled;

  /// A badge, typically a [Badge] without a child.
  ///
  /// Placed at the icon's top end, and beside the label in an
  /// expanded rail.
  final Widget? badge;

  /// The destination's accessible name, when [label] alone is ambiguous.
  ///
  /// When null, [label] is the accessible name.
  final String? semanticLabel;

  /// Called when the destination is tapped, before the bar's or the rail's
  /// `onDestinationSelected`.
  final VoidCallback? onTap;

  @override
  State<NavigationDestination> createState() => _NavigationDestinationState();
}

/// The resolved style of the destinations of a bar or a rail.
@immutable
class ItemStyle {
  /// Creates a resolved destination style.
  const ItemStyle({
    required this.iconSize,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.selectedLabelColor,
    required this.horizontalSelectedLabelColor,
    required this.unselectedLabelColor,
    required this.disabledColor,
    required this.labelStyle,
    required this.horizontalLabelStyle,
    required this.labelMaxLines,
    required this.labelOverflow,
    required this.maxLabelScale,
    required this.indicatorColor,
    required this.indicatorShape,
    required this.useIndicator,
    required this.overlayColor,
    required this.iconTheme,
    required this.labelTextStyle,
    required this.motion,
  });

  /// See [NavigationBarStyle.iconSize].
  final double iconSize;

  /// See [NavigationBarStyle.selectedIconColor].
  final Color selectedIconColor;

  /// See [NavigationBarStyle.unselectedIconColor].
  final Color unselectedIconColor;

  /// See [NavigationBarStyle.selectedLabelColor].
  final Color selectedLabelColor;

  /// See [NavigationBarStyle.horizontalSelectedLabelColor].
  final Color horizontalSelectedLabelColor;

  /// See [NavigationBarStyle.unselectedLabelColor].
  final Color unselectedLabelColor;

  /// See [NavigationBarStyle.disabledColor].
  final Color disabledColor;

  /// See [NavigationBarStyle.labelStyle].
  final TextStyle labelStyle;

  /// See [NavigationBarStyle.horizontalLabelStyle].
  final TextStyle horizontalLabelStyle;

  /// See [NavigationBarStyle.labelMaxLines].
  final int? labelMaxLines;

  /// See [NavigationBarStyle.labelOverflow].
  final TextOverflow labelOverflow;

  /// See [NavigationBarStyle.maxLabelScale].
  final double? maxLabelScale;

  /// See [NavigationBarStyle.indicatorColor].
  final Color indicatorColor;

  /// See [NavigationBarStyle.indicatorShape].
  final ShapeBorder indicatorShape;

  /// See [NavigationBarStyle.useIndicator].
  final bool useIndicator;

  /// The state layer color, the style's [NavigationBarStyle.overlayColor]
  /// over its [NavigationBarStyle.stateLayerColor] and opacities.
  final WidgetStateProperty<Color?> overlayColor;

  /// See [NavigationBarStyle.iconTheme].
  final WidgetStateProperty<IconThemeData?>? iconTheme;

  /// See [NavigationBarStyle.labelTextStyle].
  final WidgetStateProperty<TextStyle?>? labelTextStyle;

  /// See [NavigationBarStyle.motion].
  final NavigationMotion motion;

  /// The state layer: [color] at the given opacities,
  /// under [custom] where it resolves a color.
  static WidgetStateProperty<Color?> stateLayer({
    required Color color,
    required double hoverOpacity,
    required double focusOpacity,
    required double pressedOpacity,
    WidgetStateProperty<Color?>? custom,
  }) => WidgetStateProperty.resolveWith((states) {
    final override = custom?.resolve(states);
    if (override != null) return override;
    if (states.contains(WidgetState.pressed)) {
      return color.withValues(alpha: pressedOpacity);
    }
    if (states.contains(WidgetState.focused)) {
      return color.withValues(alpha: focusOpacity);
    }
    if (states.contains(WidgetState.hovered)) {
      return color.withValues(alpha: hoverOpacity);
    }
    return null;
  });
}

/// What a bar or a rail tells one of its destinations, anew on each of its
/// builds.
@immutable
class DestinationData {
  /// Creates the data of one destination.
  const DestinationData({
    required this.index,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.morph,
    required this.selection,
    required this.labelVisibility,
    required this.geometry,
    required this.style,
  });

  /// The destination's position among its container's destinations, or null
  /// for a destination elsewhere in a rail.
  final int? index;

  /// How many destinations the container has.
  final int count;

  /// Whether the destination is selected.
  final bool selected;

  /// Called when the destination is tapped, after its own `onTap`; null when
  /// the container does nothing.
  final VoidCallback? onTap;

  /// The progress from the top form (0) to the start form (1).
  final Animation<double> morph;

  /// The selection progress.
  final Animation<double> selection;

  /// How far the label shows in the top form.
  final Animation<double> labelVisibility;

  /// The measurements.
  final ItemGeometry geometry;

  /// The style.
  final ItemStyle style;
}

/// Provides a [DestinationData] to one [NavigationDestination].
class DestinationScope extends InheritedWidget {
  /// Creates the scope of one destination.
  const DestinationScope({super.key, required this.data, required super.child});

  /// The destination's data.
  final DestinationData data;

  /// The data of the destination at [context].
  static DestinationData of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DestinationScope>();
    assert(
      scope != null,
      'A NavigationDestination renders only in a NavigationBar or a '
      'NavigationRail.',
    );
    return scope!.data;
  }

  // The data is new on each build of the bar or the rail, which rebuilds its
  // destinations with it.
  @override
  bool updateShouldNotify(DestinationScope oldWidget) => true;
}

class _NavigationDestinationState extends State<NavigationDestination> {
  final WidgetStatesController _states = WidgetStatesController();
  final ItemInkGeometry _inkGeometry = ItemInkGeometry();
  Set<WidgetState> _interaction = const {};

  Animation<double>? _morph;
  Animation<double>? _labelVisibility;
  // Whether the start form shows the label whatever its visibility, as a
  // rail's does.
  bool _labelShownInStartForm = false;
  // Whether the start form's label style applies, and whether the
  // label is hidden, so a tooltip is due: the only animation
  // thresholds this widget rebuilds on.
  bool _startForm = false;
  bool _labelHidden = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_onStatesChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = DestinationScope.of(context);
    if (data.morph != _morph) {
      _morph?.removeListener(_onThresholds);
      _morph = data.morph..addListener(_onThresholds);
    }
    if (data.labelVisibility != _labelVisibility) {
      _labelVisibility?.removeListener(_onThresholds);
      _labelVisibility = data.labelVisibility..addListener(_onThresholds);
    }
    _labelShownInStartForm = data.geometry.labelShownInStartForm;
    _startForm = _isStartForm;
    _labelHidden = _isLabelHidden;
  }

  @override
  void dispose() {
    _morph?.removeListener(_onThresholds);
    _labelVisibility?.removeListener(_onThresholds);
    _states.dispose();
    super.dispose();
  }

  bool get _isStartForm => _morph!.value >= 0.5;

  bool get _isLabelHidden =>
      !(_isStartForm && _labelShownInStartForm) &&
      _labelVisibility!.value < 0.5;

  void _onThresholds() {
    if (_isStartForm != _startForm || _isLabelHidden != _labelHidden) {
      setState(() {
        _startForm = _isStartForm;
        _labelHidden = _isLabelHidden;
      });
    }
  }

  // Rebuilds only when an interaction state changes: the ink response also
  // reports disabled while it initializes.
  void _onStatesChanged() {
    final interaction = _states.value
        .where(
          (state) =>
              state == WidgetState.hovered ||
              state == WidgetState.focused ||
              state == WidgetState.pressed,
        )
        .toSet();
    if (setEquals(interaction, _interaction)) return;
    setState(() => _interaction = interaction);
  }

  TextScaler _labelScaler(ItemStyle style) {
    final scaler = MediaQuery.textScalerOf(context);
    final max = style.maxLabelScale;
    return max == null ? scaler : scaler.clamp(maxScaleFactor: max);
  }

  // Measures the label in the style of the form it is not laid out in, at
  // the width the item gives it there.
  Size Function(double maxWidth) _otherFormLabel(
    ItemStyle style,
    TextStyle? stateLabelStyle,
  ) {
    final textStyle =
        (_startForm ? style.labelStyle : style.horizontalLabelStyle).merge(
          stateLabelStyle,
        );
    final textDirection = Directionality.of(context);
    final textScaler = _labelScaler(style);
    final locale = Localizations.maybeLocaleOf(context);
    final boldText = MediaQuery.boldTextOf(context);
    return (maxWidth) => measureLabel(
      widget.label,
      style: textStyle,
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      maxLines: style.labelMaxLines,
      maxWidth: maxWidth,
      boldText: boldText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = DestinationScope.of(context);
    final style = data.style;
    final enabled = widget.enabled;
    final states = <WidgetState>{
      ..._interaction,
      if (data.selected) WidgetState.selected,
      if (!enabled) WidgetState.disabled,
    };

    final iconColor = !enabled
        ? style.disabledColor
        : data.selected
        ? style.selectedIconColor
        : style.unselectedIconColor;
    final icon = IconTheme.merge(
      data: IconThemeData(
        size: style.iconSize,
        color: iconColor,
      ).merge(style.iconTheme?.resolve(states)),
      child: ExcludeSemantics(
        child: data.selected
            ? (widget.selectedIcon ?? widget.icon)
            : widget.icon,
      ),
    );

    final labelColor = !enabled
        ? style.disabledColor
        : data.selected
        ? (_startForm
              ? style.horizontalSelectedLabelColor
              : style.selectedLabelColor)
        : style.unselectedLabelColor;
    final stateLabelStyle = style.labelTextStyle?.resolve(states);
    final labelStyle =
        (_startForm ? style.horizontalLabelStyle : style.labelStyle)
            .copyWith(color: labelColor)
            .merge(stateLabelStyle);
    final label = ExcludeSemantics(
      child: _AnimatedLabel(
        text: widget.label,
        style: labelStyle,
        motion: style.motion,
        maxLines: style.labelMaxLines,
        overflow: style.labelOverflow,
        textScaler: _labelScaler(style),
        textAlign: _startForm ? TextAlign.start : TextAlign.center,
      ),
    );

    final own = widget.onTap;
    final container = data.onTap;
    final onTap = !enabled || (own == null && container == null)
        ? null
        : () {
            own?.call();
            container?.call();
          };

    // The tooltip is always built, and only shown while the label is hidden,
    // so the ink response keeps its place, and its hover and focus, as the
    // label hides and shows.
    final tooltip = widget.tooltip ?? widget.label;
    // Its own transparent Material puts the state layer and the ripple over
    // the indicator the item paints, within the item's clips and fades.
    final ink = Material(
      type: MaterialType.transparency,
      child: TooltipVisibility(
        visible: _labelHidden && tooltip.isNotEmpty,
        child: Tooltip(
          message: tooltip.isEmpty ? widget.label : tooltip,
          excludeFromSemantics: true,
          child: _IndicatorInkResponse(
            onTap: onTap,
            statesController: _states,
            overlayColor: style.overlayColor,
            customBorder: style.indicatorShape,
            inkGeometry: _inkGeometry,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    // A destination of a list is a tab, its position announced after its
    // name, as Flutter's own navigation widgets do.
    final index = data.index;
    final name = widget.semanticLabel ?? widget.label;
    final position = index == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).tabLabel(tabIndex: index + 1, tabCount: data.count);
    return NavigationItem(
      geometry: data.geometry,
      morph: data.morph,
      selection: data.selection,
      labelVisibility: data.labelVisibility,
      measureOtherFormLabel: _otherFormLabel(style, stateLabelStyle),
      indicatorColor: style.indicatorColor,
      indicatorShape: style.indicatorShape,
      showIndicator: style.useIndicator,
      inkGeometry: _inkGeometry,
      semanticsLabel: position == null ? name : '$name\n$position',
      selected: data.selected,
      enabled: enabled,
      isTab: index != null && data.onTap != null,
      ink: ink,
      icon: icon,
      label: label,
      badge: widget.badge,
    );
  }
}

// An ink response whose state layer and ripple fill the full-size active
// indicator, clipped to its shape, while the whole item takes the taps.
class _IndicatorInkResponse extends InkResponse {
  const _IndicatorInkResponse({
    super.onTap,
    super.statesController,
    super.overlayColor,
    super.customBorder,
    required this.inkGeometry,
    super.child,
  }) : super(containedInkWell: true, highlightShape: BoxShape.rectangle);

  final ItemInkGeometry inkGeometry;

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) =>
      () => inkGeometry.indicator;
}

// A label whose color follows its target on the motion's effects spring.
class _AnimatedLabel extends StatefulWidget {
  const _AnimatedLabel({
    required this.text,
    required this.style,
    required this.motion,
    required this.maxLines,
    required this.overflow,
    required this.textScaler,
    required this.textAlign,
  });

  final String text;
  final TextStyle style;
  final NavigationMotion motion;
  final int? maxLines;
  final TextOverflow overflow;
  final TextScaler textScaler;
  final TextAlign textAlign;

  @override
  State<_AnimatedLabel> createState() => _AnimatedLabelState();
}

class _AnimatedLabelState extends State<_AnimatedLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    value: 1,
  )..addListener(() => setState(() {}));
  Color? _from;
  late Color? _to = widget.style.color;

  Color? get _color => Color.lerp(_from ?? _to, _to, _progress.value);

  @override
  void didUpdateWidget(_AnimatedLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.style.color;
    if (target == _to) return;
    _from = _color;
    _to = target;
    _progress.value = 0;
    animateWithMotion(_progress, widget.motion, MotionRole.defaultEffects, 1);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    widget.text,
    style: widget.style.copyWith(color: _color),
    maxLines: widget.maxLines,
    overflow: widget.overflow,
    textScaler: widget.textScaler,
    textAlign: widget.textAlign,
  );
}
