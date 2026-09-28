// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

import 'bar.dart';
import 'motion.dart';

/// The tokens of a [NavigationBar].
///
/// Every token is optional. A bar resolves its style with [of]: the style
/// passed to it, over the [NavigationBarStyle] in the ambient
/// [ThemeData.extensions], over the Material 3 Expressive defaults computed
/// from the theme's [ColorScheme] and [TextTheme]. The defaults therefore
/// follow light and dark themes, and an app can set a few tokens once for every
/// bar:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [NavigationBarStyle(indicatorColor: Colors.amber)],
///   ),
/// )
/// ```
///
/// A bar's own arguments, such as [NavigationBar.backgroundColor], apply over
/// its resolved style.
@immutable
class NavigationBarStyle extends ThemeExtension<NavigationBarStyle>
    with Diagnosticable {
  /// Creates a bar style.
  ///
  /// Tokens left null fall back, when the style is resolved by [of], to the
  /// ambient theme's extension and then to the defaults.
  const NavigationBarStyle({
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.height,
    this.labelBehavior,
    this.indicatorColor,
    this.indicatorShape,
    this.useIndicator,
    this.iconSize,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.selectedLabelColor,
    this.horizontalSelectedLabelColor,
    this.unselectedLabelColor,
    this.disabledColor,
    this.labelStyle,
    this.horizontalLabelStyle,
    this.labelPadding,
    this.labelMaxLines,
    this.labelOverflow,
    this.maxLabelScale,
    this.stateLayerColor,
    this.hoverOpacity,
    this.focusOpacity,
    this.pressedOpacity,
    this.overlayColor,
    this.iconTheme,
    this.labelTextStyle,
    this.motion,
    this.verticalIndicatorWidth,
    this.verticalIndicatorHeight,
    this.verticalItemPadding,
    this.horizontalIndicatorHeight,
    this.horizontalLeadingSpace,
    this.horizontalTrailingSpace,
    this.horizontalIconLabelSpacing,
  });

  // The Material 3 Expressive defaults for [colors] and [text].
  factory NavigationBarStyle._defaults(ColorScheme colors, TextTheme text) =>
      NavigationBarStyle(
        backgroundColor: colors.surfaceContainer,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colors.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        useIndicator: true,
        iconSize: 24,
        selectedIconColor: colors.onSecondaryContainer,
        unselectedIconColor: colors.onSurfaceVariant,
        selectedLabelColor: colors.secondary,
        horizontalSelectedLabelColor: colors.onSecondaryContainer,
        unselectedLabelColor: colors.onSurfaceVariant,
        disabledColor: colors.onSurfaceVariant.withValues(alpha: 0.38),
        labelStyle: text.labelMedium!,
        horizontalLabelStyle: text.labelMedium!,
        labelPadding: const EdgeInsets.only(top: 4),
        labelOverflow: TextOverflow.clip,
        stateLayerColor: colors.onSecondaryContainer,
        hoverOpacity: 0.08,
        focusOpacity: 0.1,
        pressedOpacity: 0.1,
        motion: const NavigationMotion.expressive(),
        verticalIndicatorWidth: 56,
        verticalIndicatorHeight: 32,
        verticalItemPadding: 6,
        horizontalIndicatorHeight: 40,
        horizontalLeadingSpace: 16,
        horizontalTrailingSpace: 16,
        horizontalIconLabelSpacing: 4,
      );

  /// The style a component below [context] renders with.
  ///
  /// Applies [style] over the [NavigationBarStyle] in the ambient
  /// [ThemeData.extensions], over the Material 3 Expressive defaults for the
  /// theme's [ColorScheme] and [TextTheme]. Every token of the result is non-
  /// null except those whose documentation gives null a meaning.
  static NavigationBarStyle of(
    BuildContext context, [
    NavigationBarStyle? style,
  ]) {
    final theme = Theme.of(context);
    return NavigationBarStyle._defaults(
      theme.colorScheme,
      theme.textTheme,
    ).merge(theme.extension<NavigationBarStyle>()).merge(style);
  }

  /// The container color (`ColorScheme.surfaceContainer`).
  final Color? backgroundColor;

  /// The container elevation (none).
  final double? elevation;

  /// The color of the shadow the container casts at [elevation] (transparent).
  final Color? shadowColor;

  /// The tint the container takes at [elevation] (transparent).
  final Color? surfaceTintColor;

  /// The height of the container, excluding system insets (64dp).
  ///
  /// A minimum: the bar grows when its labels need more room.
  final double? height;

  /// Which labels are shown (all of them).
  final NavigationDestinationLabelBehavior? labelBehavior;

  /// The fill of the active indicator (`ColorScheme.secondaryContainer`).
  final Color? indicatorColor;

  /// The shape of the active indicator, which also clips the state layer
  /// (full rounding, a [StadiumBorder]).
  final ShapeBorder? indicatorShape;

  /// Whether the active indicator is drawn behind the selected destination
  /// (true).
  final bool? useIndicator;

  /// The size of the destination icons (24dp).
  final double? iconSize;

  /// The selected destination's icon color
  /// (`ColorScheme.onSecondaryContainer`).
  final Color? selectedIconColor;

  /// The unselected destinations' icon color (`ColorScheme.onSurfaceVariant`).
  final Color? unselectedIconColor;

  /// The selected destination's label color when the label is below the icon
  /// (`ColorScheme.secondary`).
  final Color? selectedLabelColor;

  /// The selected destination's label color when the label is beside the icon,
  /// inside the active indicator (`ColorScheme.onSecondaryContainer`).
  final Color? horizontalSelectedLabelColor;

  /// The unselected destinations' label color (`ColorScheme.onSurfaceVariant`).
  final Color? unselectedLabelColor;

  /// A disabled destination's icon and label color
  /// (`ColorScheme.onSurfaceVariant` at 38% opacity).
  final Color? disabledColor;

  /// The label style below the icon (`TextTheme.labelMedium`).
  final TextStyle? labelStyle;

  /// The label style beside the icon (`TextTheme.labelMedium`).
  final TextStyle? horizontalLabelStyle;

  /// The padding around a label below the icon. Its top is the gap between the
  /// active indicator and the label (4dp above).
  final EdgeInsetsGeometry? labelPadding;

  /// The most lines a label may take, or null for no limit (the default).
  ///
  /// Material 3 keeps the full label visible at up to twice the text size,
  /// wrapping it rather than cutting it.
  final int? labelMaxLines;

  /// How a label that exceeds [labelMaxLines] is cut (clipped, never
  /// an ellipsis).
  final TextOverflow? labelOverflow;

  /// The largest text scale factor applied to the labels, or null to follow the
  /// platform without limit (the default). Tooltips keep the full scale.
  final double? maxLabelScale;

  /// The color of the hover, focus and pressed state layers
  /// (`ColorScheme.onSecondaryContainer`). Ignored where [overlayColor]
  /// resolves a color.
  final Color? stateLayerColor;

  /// The opacity of the hover state layer (8%).
  final double? hoverOpacity;

  /// The opacity of the focus state layer (10%).
  final double? focusOpacity;

  /// The opacity of the pressed state layer (10%).
  final double? pressedOpacity;

  /// The state layer color per [WidgetState], over the one built from
  /// [stateLayerColor] and the opacities. Null by default.
  final WidgetStateProperty<Color?>? overlayColor;

  /// Per-state icon theme, merged over the resolved icon size and color.
  /// Resolved against [WidgetState.selected], [WidgetState.disabled],
  /// [WidgetState.hovered], [WidgetState.focused] and [WidgetState.pressed].
  /// Null by default.
  final WidgetStateProperty<IconThemeData?>? iconTheme;

  /// Per-state label style, merged over both resolved label styles. Resolved
  /// against the same states as [iconTheme]. Null by default.
  final WidgetStateProperty<TextStyle?>? labelTextStyle;

  /// How the bar animates ([NavigationMotion.expressive]).
  final NavigationMotion? motion;

  /// The width of the active indicator of a vertical item (56dp). A
  /// narrower item narrows it.
  final double? verticalIndicatorWidth;

  /// The height of the active indicator of a vertical item (32dp).
  final double? verticalIndicatorHeight;

  /// The space above the active indicator and below the label of a vertical
  /// item (6dp).
  final double? verticalItemPadding;

  /// The height of the active indicator of a horizontal item (40dp).
  final double? horizontalIndicatorHeight;

  /// The space before the icon inside the active indicator of a horizontal item
  /// (16dp).
  final double? horizontalLeadingSpace;

  /// The space after the label inside the active indicator of a horizontal item
  /// (16dp).
  final double? horizontalTrailingSpace;

  /// The space between the icon and the label of a horizontal item (4dp).
  final double? horizontalIconLabelSpacing;

  /// A copy of this style with every non-null token of [other] applied over it.
  ///
  /// Returns this style when [other] is null.
  NavigationBarStyle merge(NavigationBarStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      elevation: other.elevation,
      shadowColor: other.shadowColor,
      surfaceTintColor: other.surfaceTintColor,
      height: other.height,
      labelBehavior: other.labelBehavior,
      indicatorColor: other.indicatorColor,
      indicatorShape: other.indicatorShape,
      useIndicator: other.useIndicator,
      iconSize: other.iconSize,
      selectedIconColor: other.selectedIconColor,
      unselectedIconColor: other.unselectedIconColor,
      selectedLabelColor: other.selectedLabelColor,
      horizontalSelectedLabelColor: other.horizontalSelectedLabelColor,
      unselectedLabelColor: other.unselectedLabelColor,
      disabledColor: other.disabledColor,
      labelStyle: other.labelStyle,
      horizontalLabelStyle: other.horizontalLabelStyle,
      labelPadding: other.labelPadding,
      labelMaxLines: other.labelMaxLines,
      labelOverflow: other.labelOverflow,
      maxLabelScale: other.maxLabelScale,
      stateLayerColor: other.stateLayerColor,
      hoverOpacity: other.hoverOpacity,
      focusOpacity: other.focusOpacity,
      pressedOpacity: other.pressedOpacity,
      overlayColor: other.overlayColor,
      iconTheme: other.iconTheme,
      labelTextStyle: other.labelTextStyle,
      motion: other.motion,
      verticalIndicatorWidth: other.verticalIndicatorWidth,
      verticalIndicatorHeight: other.verticalIndicatorHeight,
      verticalItemPadding: other.verticalItemPadding,
      horizontalIndicatorHeight: other.horizontalIndicatorHeight,
      horizontalLeadingSpace: other.horizontalLeadingSpace,
      horizontalTrailingSpace: other.horizontalTrailingSpace,
      horizontalIconLabelSpacing: other.horizontalIconLabelSpacing,
    );
  }

  /// A copy of this style with the given tokens replaced.
  @override
  NavigationBarStyle copyWith({
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? height,
    NavigationDestinationLabelBehavior? labelBehavior,
    Color? indicatorColor,
    ShapeBorder? indicatorShape,
    bool? useIndicator,
    double? iconSize,
    Color? selectedIconColor,
    Color? unselectedIconColor,
    Color? selectedLabelColor,
    Color? horizontalSelectedLabelColor,
    Color? unselectedLabelColor,
    Color? disabledColor,
    TextStyle? labelStyle,
    TextStyle? horizontalLabelStyle,
    EdgeInsetsGeometry? labelPadding,
    int? labelMaxLines,
    TextOverflow? labelOverflow,
    double? maxLabelScale,
    Color? stateLayerColor,
    double? hoverOpacity,
    double? focusOpacity,
    double? pressedOpacity,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateProperty<IconThemeData?>? iconTheme,
    WidgetStateProperty<TextStyle?>? labelTextStyle,
    NavigationMotion? motion,
    double? verticalIndicatorWidth,
    double? verticalIndicatorHeight,
    double? verticalItemPadding,
    double? horizontalIndicatorHeight,
    double? horizontalLeadingSpace,
    double? horizontalTrailingSpace,
    double? horizontalIconLabelSpacing,
  }) {
    return NavigationBarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      height: height ?? this.height,
      labelBehavior: labelBehavior ?? this.labelBehavior,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorShape: indicatorShape ?? this.indicatorShape,
      useIndicator: useIndicator ?? this.useIndicator,
      iconSize: iconSize ?? this.iconSize,
      selectedIconColor: selectedIconColor ?? this.selectedIconColor,
      unselectedIconColor: unselectedIconColor ?? this.unselectedIconColor,
      selectedLabelColor: selectedLabelColor ?? this.selectedLabelColor,
      horizontalSelectedLabelColor:
          horizontalSelectedLabelColor ?? this.horizontalSelectedLabelColor,
      unselectedLabelColor: unselectedLabelColor ?? this.unselectedLabelColor,
      disabledColor: disabledColor ?? this.disabledColor,
      labelStyle: labelStyle ?? this.labelStyle,
      horizontalLabelStyle: horizontalLabelStyle ?? this.horizontalLabelStyle,
      labelPadding: labelPadding ?? this.labelPadding,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      maxLabelScale: maxLabelScale ?? this.maxLabelScale,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      hoverOpacity: hoverOpacity ?? this.hoverOpacity,
      focusOpacity: focusOpacity ?? this.focusOpacity,
      pressedOpacity: pressedOpacity ?? this.pressedOpacity,
      overlayColor: overlayColor ?? this.overlayColor,
      iconTheme: iconTheme ?? this.iconTheme,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      motion: motion ?? this.motion,
      verticalIndicatorWidth:
          verticalIndicatorWidth ?? this.verticalIndicatorWidth,
      verticalIndicatorHeight:
          verticalIndicatorHeight ?? this.verticalIndicatorHeight,
      verticalItemPadding: verticalItemPadding ?? this.verticalItemPadding,
      horizontalIndicatorHeight:
          horizontalIndicatorHeight ?? this.horizontalIndicatorHeight,
      horizontalLeadingSpace:
          horizontalLeadingSpace ?? this.horizontalLeadingSpace,
      horizontalTrailingSpace:
          horizontalTrailingSpace ?? this.horizontalTrailingSpace,
      horizontalIconLabelSpacing:
          horizontalIconLabelSpacing ?? this.horizontalIconLabelSpacing,
    );
  }

  @override
  NavigationBarStyle lerp(
    covariant ThemeExtension<NavigationBarStyle>? other,
    double t,
  ) {
    if (other is! NavigationBarStyle) return this;
    return NavigationBarStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      elevation: lerpDouble(elevation, other.elevation, t),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      surfaceTintColor: Color.lerp(surfaceTintColor, other.surfaceTintColor, t),
      height: lerpDouble(height, other.height, t),
      labelBehavior: t < 0.5 ? labelBehavior : other.labelBehavior,
      indicatorColor: Color.lerp(indicatorColor, other.indicatorColor, t),
      indicatorShape: ShapeBorder.lerp(indicatorShape, other.indicatorShape, t),
      useIndicator: t < 0.5 ? useIndicator : other.useIndicator,
      iconSize: lerpDouble(iconSize, other.iconSize, t),
      selectedIconColor: Color.lerp(
        selectedIconColor,
        other.selectedIconColor,
        t,
      ),
      unselectedIconColor: Color.lerp(
        unselectedIconColor,
        other.unselectedIconColor,
        t,
      ),
      selectedLabelColor: Color.lerp(
        selectedLabelColor,
        other.selectedLabelColor,
        t,
      ),
      horizontalSelectedLabelColor: Color.lerp(
        horizontalSelectedLabelColor,
        other.horizontalSelectedLabelColor,
        t,
      ),
      unselectedLabelColor: Color.lerp(
        unselectedLabelColor,
        other.unselectedLabelColor,
        t,
      ),
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t),
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      horizontalLabelStyle: TextStyle.lerp(
        horizontalLabelStyle,
        other.horizontalLabelStyle,
        t,
      ),
      labelPadding: EdgeInsetsGeometry.lerp(
        labelPadding,
        other.labelPadding,
        t,
      ),
      labelMaxLines: t < 0.5 ? labelMaxLines : other.labelMaxLines,
      labelOverflow: t < 0.5 ? labelOverflow : other.labelOverflow,
      maxLabelScale: maxLabelScale == null || other.maxLabelScale == null
          ? (t < 0.5 ? maxLabelScale : other.maxLabelScale)
          : lerpDouble(maxLabelScale, other.maxLabelScale, t),
      stateLayerColor: Color.lerp(stateLayerColor, other.stateLayerColor, t),
      hoverOpacity: lerpDouble(hoverOpacity, other.hoverOpacity, t),
      focusOpacity: lerpDouble(focusOpacity, other.focusOpacity, t),
      pressedOpacity: lerpDouble(pressedOpacity, other.pressedOpacity, t),
      overlayColor: WidgetStateProperty.lerp<Color?>(
        overlayColor,
        other.overlayColor,
        t,
        Color.lerp,
      ),
      iconTheme: WidgetStateProperty.lerp<IconThemeData?>(
        iconTheme,
        other.iconTheme,
        t,
        IconThemeData.lerp,
      ),
      labelTextStyle: WidgetStateProperty.lerp<TextStyle?>(
        labelTextStyle,
        other.labelTextStyle,
        t,
        TextStyle.lerp,
      ),
      motion: t < 0.5 ? motion : other.motion,
      verticalIndicatorWidth: lerpDouble(
        verticalIndicatorWidth,
        other.verticalIndicatorWidth,
        t,
      ),
      verticalIndicatorHeight: lerpDouble(
        verticalIndicatorHeight,
        other.verticalIndicatorHeight,
        t,
      ),
      verticalItemPadding: lerpDouble(
        verticalItemPadding,
        other.verticalItemPadding,
        t,
      ),
      horizontalIndicatorHeight: lerpDouble(
        horizontalIndicatorHeight,
        other.horizontalIndicatorHeight,
        t,
      ),
      horizontalLeadingSpace: lerpDouble(
        horizontalLeadingSpace,
        other.horizontalLeadingSpace,
        t,
      ),
      horizontalTrailingSpace: lerpDouble(
        horizontalTrailingSpace,
        other.horizontalTrailingSpace,
        t,
      ),
      horizontalIconLabelSpacing: lerpDouble(
        horizontalIconLabelSpacing,
        other.horizontalIconLabelSpacing,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationBarStyle &&
        other.backgroundColor == backgroundColor &&
        other.elevation == elevation &&
        other.shadowColor == shadowColor &&
        other.surfaceTintColor == surfaceTintColor &&
        other.height == height &&
        other.labelBehavior == labelBehavior &&
        other.indicatorColor == indicatorColor &&
        other.indicatorShape == indicatorShape &&
        other.useIndicator == useIndicator &&
        other.iconSize == iconSize &&
        other.selectedIconColor == selectedIconColor &&
        other.unselectedIconColor == unselectedIconColor &&
        other.selectedLabelColor == selectedLabelColor &&
        other.horizontalSelectedLabelColor == horizontalSelectedLabelColor &&
        other.unselectedLabelColor == unselectedLabelColor &&
        other.disabledColor == disabledColor &&
        other.labelStyle == labelStyle &&
        other.horizontalLabelStyle == horizontalLabelStyle &&
        other.labelPadding == labelPadding &&
        other.labelMaxLines == labelMaxLines &&
        other.labelOverflow == labelOverflow &&
        other.maxLabelScale == maxLabelScale &&
        other.stateLayerColor == stateLayerColor &&
        other.hoverOpacity == hoverOpacity &&
        other.focusOpacity == focusOpacity &&
        other.pressedOpacity == pressedOpacity &&
        other.overlayColor == overlayColor &&
        other.iconTheme == iconTheme &&
        other.labelTextStyle == labelTextStyle &&
        other.motion == motion &&
        other.verticalIndicatorWidth == verticalIndicatorWidth &&
        other.verticalIndicatorHeight == verticalIndicatorHeight &&
        other.verticalItemPadding == verticalItemPadding &&
        other.horizontalIndicatorHeight == horizontalIndicatorHeight &&
        other.horizontalLeadingSpace == horizontalLeadingSpace &&
        other.horizontalTrailingSpace == horizontalTrailingSpace &&
        other.horizontalIconLabelSpacing == horizontalIconLabelSpacing;
  }

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    elevation,
    shadowColor,
    surfaceTintColor,
    height,
    labelBehavior,
    indicatorColor,
    indicatorShape,
    useIndicator,
    iconSize,
    selectedIconColor,
    unselectedIconColor,
    selectedLabelColor,
    horizontalSelectedLabelColor,
    unselectedLabelColor,
    disabledColor,
    labelStyle,
    horizontalLabelStyle,
    labelPadding,
    labelMaxLines,
    labelOverflow,
    maxLabelScale,
    stateLayerColor,
    hoverOpacity,
    focusOpacity,
    pressedOpacity,
    overlayColor,
    iconTheme,
    labelTextStyle,
    motion,
    verticalIndicatorWidth,
    verticalIndicatorHeight,
    verticalItemPadding,
    horizontalIndicatorHeight,
    horizontalLeadingSpace,
    horizontalTrailingSpace,
    horizontalIconLabelSpacing,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ColorProperty('backgroundColor', backgroundColor, defaultValue: null),
      )
      ..add(DoubleProperty('elevation', elevation, defaultValue: null))
      ..add(ColorProperty('shadowColor', shadowColor, defaultValue: null))
      ..add(
        ColorProperty('surfaceTintColor', surfaceTintColor, defaultValue: null),
      )
      ..add(DoubleProperty('height', height, defaultValue: null))
      ..add(
        EnumProperty<NavigationDestinationLabelBehavior>(
          'labelBehavior',
          labelBehavior,
          defaultValue: null,
        ),
      )
      ..add(ColorProperty('indicatorColor', indicatorColor, defaultValue: null))
      ..add(
        DiagnosticsProperty<ShapeBorder>(
          'indicatorShape',
          indicatorShape,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'useIndicator',
          useIndicator,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('iconSize', iconSize, defaultValue: null))
      ..add(
        ColorProperty(
          'selectedIconColor',
          selectedIconColor,
          defaultValue: null,
        ),
      )
      ..add(
        ColorProperty(
          'unselectedIconColor',
          unselectedIconColor,
          defaultValue: null,
        ),
      )
      ..add(
        ColorProperty(
          'selectedLabelColor',
          selectedLabelColor,
          defaultValue: null,
        ),
      )
      ..add(
        ColorProperty(
          'horizontalSelectedLabelColor',
          horizontalSelectedLabelColor,
          defaultValue: null,
        ),
      )
      ..add(
        ColorProperty(
          'unselectedLabelColor',
          unselectedLabelColor,
          defaultValue: null,
        ),
      )
      ..add(ColorProperty('disabledColor', disabledColor, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextStyle>(
          'labelStyle',
          labelStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TextStyle>(
          'horizontalLabelStyle',
          horizontalLabelStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'labelPadding',
          labelPadding,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('labelMaxLines', labelMaxLines, defaultValue: null))
      ..add(
        EnumProperty<TextOverflow>(
          'labelOverflow',
          labelOverflow,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('maxLabelScale', maxLabelScale, defaultValue: null))
      ..add(
        ColorProperty('stateLayerColor', stateLayerColor, defaultValue: null),
      )
      ..add(DoubleProperty('hoverOpacity', hoverOpacity, defaultValue: null))
      ..add(DoubleProperty('focusOpacity', focusOpacity, defaultValue: null))
      ..add(
        DoubleProperty('pressedOpacity', pressedOpacity, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<WidgetStateProperty<Color?>>(
          'overlayColor',
          overlayColor,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<WidgetStateProperty<IconThemeData?>>(
          'iconTheme',
          iconTheme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<WidgetStateProperty<TextStyle?>>(
          'labelTextStyle',
          labelTextStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<NavigationMotion>(
          'motion',
          motion,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'verticalIndicatorWidth',
          verticalIndicatorWidth,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'verticalIndicatorHeight',
          verticalIndicatorHeight,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'verticalItemPadding',
          verticalItemPadding,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'horizontalIndicatorHeight',
          horizontalIndicatorHeight,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'horizontalLeadingSpace',
          horizontalLeadingSpace,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'horizontalTrailingSpace',
          horizontalTrailingSpace,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'horizontalIconLabelSpacing',
          horizontalIconLabelSpacing,
          defaultValue: null,
        ),
      );
  }
}
