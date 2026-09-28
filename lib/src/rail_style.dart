// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

import 'motion.dart';
import 'rail.dart';

/// The tokens of a [NavigationRail].
///
/// Every token is optional. A rail resolves its style with [of]: the style
/// passed to it, over the [NavigationRailStyle] in the ambient
/// [ThemeData.extensions], over the Material 3 Expressive defaults computed
/// from the theme's [ColorScheme] and [TextTheme]:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [NavigationRailStyle(expandedWidth: 320)],
///   ),
/// )
/// ```
///
/// A rail's own arguments, such as [NavigationRail.minWidth], apply over its
/// resolved style.
@immutable
class NavigationRailStyle extends ThemeExtension<NavigationRailStyle>
    with Diagnosticable {
  /// Creates a rail style.
  ///
  /// Tokens left null fall back, when the style is resolved by [of], to the
  /// ambient theme's extension and then to the defaults.
  const NavigationRailStyle({
    this.backgroundColor,
    this.elevation,
    this.divider,
    this.modalBackgroundColor,
    this.modalElevation,
    this.modalShape,
    this.scrimColor,
    this.labelType,
    this.expandedIndicatorSize,
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
    this.minWidth,
    this.expandedWidth,
    this.minExpandedWidth,
    this.maxExpandedWidth,
    this.topSpace,
    this.headerSpace,
    this.headerItemSpacing,
    this.itemSpace,
    this.collapsedItemMinHeight,
    this.expandedItemMinHeight,
    this.itemHorizontalPadding,
    this.verticalIndicatorWidth,
    this.verticalIndicatorHeight,
    this.noLabelIndicatorSize,
    this.horizontalIndicatorHeight,
    this.horizontalLeadingSpace,
    this.horizontalTrailingSpace,
    this.horizontalIconLabelSpacing,
    this.badgeLabelSpacing,
    this.groupAlignment,
    this.scrollable,
    this.applyBottomInset,
  });

  // The Material 3 Expressive defaults for [colors] and [text].
  factory NavigationRailStyle._defaults(ColorScheme colors, TextTheme text) =>
      NavigationRailStyle(
        backgroundColor: colors.surface,
        elevation: 0,
        modalBackgroundColor: colors.surfaceContainer,
        modalElevation: 3,
        modalShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        scrimColor: colors.scrim.withValues(alpha: 0.32),
        labelType: NavigationRailLabelType.all,
        expandedIndicatorSize: NavigationIndicatorSize.hug,
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
        horizontalLabelStyle: text.labelLarge!,
        labelPadding: const EdgeInsets.only(top: 4),
        labelOverflow: TextOverflow.clip,
        stateLayerColor: colors.onSecondaryContainer,
        hoverOpacity: 0.08,
        focusOpacity: 0.1,
        pressedOpacity: 0.1,
        motion: const NavigationMotion.expressive(),
        minWidth: 96,
        minExpandedWidth: 220,
        maxExpandedWidth: 360,
        topSpace: 44,
        headerSpace: 40,
        headerItemSpacing: 8,
        itemSpace: 4,
        collapsedItemMinHeight: 64,
        expandedItemMinHeight: 48,
        itemHorizontalPadding: 20,
        verticalIndicatorWidth: 56,
        verticalIndicatorHeight: 32,
        noLabelIndicatorSize: 56,
        horizontalIndicatorHeight: 56,
        horizontalLeadingSpace: 16,
        horizontalTrailingSpace: 16,
        horizontalIconLabelSpacing: 8,
        badgeLabelSpacing: 12,
        groupAlignment: -1,
        scrollable: true,
        applyBottomInset: true,
      );

  /// The style a component below [context] renders with.
  ///
  /// Applies [style] over the [NavigationRailStyle] in the ambient
  /// [ThemeData.extensions], over the Material 3 Expressive defaults for the
  /// theme's [ColorScheme] and [TextTheme]. Every token of the result is non-
  /// null except those whose documentation gives null a meaning.
  static NavigationRailStyle of(
    BuildContext context, [
    NavigationRailStyle? style,
  ]) {
    final theme = Theme.of(context);
    return NavigationRailStyle._defaults(
      theme.colorScheme,
      theme.textTheme,
    ).merge(theme.extension<NavigationRailStyle>()).merge(style);
  }

  /// The container color, collapsed and expanded (`ColorScheme.surface`).
  final Color? backgroundColor;

  /// The container elevation (none).
  final double? elevation;

  /// A divider on the edge next to the content, or null for none (the
  /// default).
  final BorderSide? divider;

  /// The color of the modal surface (`ColorScheme.surfaceContainer`).
  final Color? modalBackgroundColor;

  /// The elevation of the modal surface (3dp, without a shadow).
  final double? modalElevation;

  /// The shape of the modal surface (16dp corners).
  final ShapeBorder? modalShape;

  /// The scrim behind the modal surface at full opacity (`ColorScheme.scrim` at
  /// 32%).
  final Color? scrimColor;

  /// Which labels a collapsed rail shows (all of them). An expanded
  /// rail always shows its labels.
  final NavigationRailLabelType? labelType;

  /// Whether the active indicator of an expanded destination hugs its content
  /// or fills the rail (hugs).
  final NavigationIndicatorSize? expandedIndicatorSize;

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

  /// The label style beside the icon (`TextTheme.labelLarge`).
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

  /// How the rail animates ([NavigationMotion.expressive]).
  final NavigationMotion? motion;

  /// The width of the collapsed rail (96dp).
  ///
  /// Zero leaves no collapsed rail: the rail takes no room until it expands,
  /// and its modal slides in from the leading edge.
  final double? minWidth;

  /// A fixed width for the expanded rail, or null to fit the widest destination
  /// between [minExpandedWidth] and [maxExpandedWidth] (the default).
  final double? expandedWidth;

  /// The narrowest the expanded rail fits itself to (220dp).
  final double? minExpandedWidth;

  /// The widest the expanded rail fits itself to (360dp).
  final double? maxExpandedWidth;

  /// The space above the header (44dp).
  final double? topSpace;

  /// The space between the header and the group, when there is a header
  /// (40dp).
  final double? headerSpace;

  /// The space between the widgets of the header, such as the menu button and
  /// the floating action button (8dp; not a Material 3 token).
  final double? headerItemSpacing;

  /// The space between adjacent destinations while collapsed, closing to none
  /// as the rail expands (4dp).
  final double? itemSpace;

  /// The minimum height of a collapsed destination (64dp).
  final double? collapsedItemMinHeight;

  /// The minimum height of an expanded destination (48dp).
  final double? expandedItemMinHeight;

  /// The space between the rail's edges and an expanded destination's active
  /// indicator (20dp).
  final double? itemHorizontalPadding;

  /// The width of the active indicator of a collapsed destination (56dp).
  final double? verticalIndicatorWidth;

  /// The height of the active indicator of a collapsed destination (32dp).
  final double? verticalIndicatorHeight;

  /// The width and height of the active indicator of a collapsed destination
  /// without a visible label, with [labelType] none (56dp).
  final double? noLabelIndicatorSize;

  /// The height of the active indicator of an expanded destination (56dp).
  final double? horizontalIndicatorHeight;

  /// The space before the icon inside the active indicator of an expanded
  /// destination (16dp).
  final double? horizontalLeadingSpace;

  /// The space after the label inside the active indicator of an expanded
  /// destination (16dp).
  final double? horizontalTrailingSpace;

  /// The space between the icon and the label of an expanded destination
  /// (8dp).
  final double? horizontalIconLabelSpacing;

  /// The space between the label and the badge of an expanded destination
  /// (12dp).
  final double? badgeLabelSpacing;

  /// Where the group sits along the rail's height, from -1 (top) through 0
  /// (center) to 1 (bottom) (top).
  final double? groupAlignment;

  /// Whether the group scrolls when it does not fit (true). When false, what
  /// does not fit is clipped.
  final bool? scrollable;

  /// Whether the rail keeps its content above the bottom system inset (true).
  final bool? applyBottomInset;

  /// A copy of this style with every non-null token of [other] applied over it.
  ///
  /// Returns this style when [other] is null.
  NavigationRailStyle merge(NavigationRailStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      elevation: other.elevation,
      divider: other.divider,
      modalBackgroundColor: other.modalBackgroundColor,
      modalElevation: other.modalElevation,
      modalShape: other.modalShape,
      scrimColor: other.scrimColor,
      labelType: other.labelType,
      expandedIndicatorSize: other.expandedIndicatorSize,
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
      minWidth: other.minWidth,
      expandedWidth: other.expandedWidth,
      minExpandedWidth: other.minExpandedWidth,
      maxExpandedWidth: other.maxExpandedWidth,
      topSpace: other.topSpace,
      headerSpace: other.headerSpace,
      headerItemSpacing: other.headerItemSpacing,
      itemSpace: other.itemSpace,
      collapsedItemMinHeight: other.collapsedItemMinHeight,
      expandedItemMinHeight: other.expandedItemMinHeight,
      itemHorizontalPadding: other.itemHorizontalPadding,
      verticalIndicatorWidth: other.verticalIndicatorWidth,
      verticalIndicatorHeight: other.verticalIndicatorHeight,
      noLabelIndicatorSize: other.noLabelIndicatorSize,
      horizontalIndicatorHeight: other.horizontalIndicatorHeight,
      horizontalLeadingSpace: other.horizontalLeadingSpace,
      horizontalTrailingSpace: other.horizontalTrailingSpace,
      horizontalIconLabelSpacing: other.horizontalIconLabelSpacing,
      badgeLabelSpacing: other.badgeLabelSpacing,
      groupAlignment: other.groupAlignment,
      scrollable: other.scrollable,
      applyBottomInset: other.applyBottomInset,
    );
  }

  /// A copy of this style with the given tokens replaced.
  @override
  NavigationRailStyle copyWith({
    Color? backgroundColor,
    double? elevation,
    BorderSide? divider,
    Color? modalBackgroundColor,
    double? modalElevation,
    ShapeBorder? modalShape,
    Color? scrimColor,
    NavigationRailLabelType? labelType,
    NavigationIndicatorSize? expandedIndicatorSize,
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
    double? minWidth,
    double? expandedWidth,
    double? minExpandedWidth,
    double? maxExpandedWidth,
    double? topSpace,
    double? headerSpace,
    double? headerItemSpacing,
    double? itemSpace,
    double? collapsedItemMinHeight,
    double? expandedItemMinHeight,
    double? itemHorizontalPadding,
    double? verticalIndicatorWidth,
    double? verticalIndicatorHeight,
    double? noLabelIndicatorSize,
    double? horizontalIndicatorHeight,
    double? horizontalLeadingSpace,
    double? horizontalTrailingSpace,
    double? horizontalIconLabelSpacing,
    double? badgeLabelSpacing,
    double? groupAlignment,
    bool? scrollable,
    bool? applyBottomInset,
  }) {
    return NavigationRailStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      divider: divider ?? this.divider,
      modalBackgroundColor: modalBackgroundColor ?? this.modalBackgroundColor,
      modalElevation: modalElevation ?? this.modalElevation,
      modalShape: modalShape ?? this.modalShape,
      scrimColor: scrimColor ?? this.scrimColor,
      labelType: labelType ?? this.labelType,
      expandedIndicatorSize:
          expandedIndicatorSize ?? this.expandedIndicatorSize,
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
      minWidth: minWidth ?? this.minWidth,
      expandedWidth: expandedWidth ?? this.expandedWidth,
      minExpandedWidth: minExpandedWidth ?? this.minExpandedWidth,
      maxExpandedWidth: maxExpandedWidth ?? this.maxExpandedWidth,
      topSpace: topSpace ?? this.topSpace,
      headerSpace: headerSpace ?? this.headerSpace,
      headerItemSpacing: headerItemSpacing ?? this.headerItemSpacing,
      itemSpace: itemSpace ?? this.itemSpace,
      collapsedItemMinHeight:
          collapsedItemMinHeight ?? this.collapsedItemMinHeight,
      expandedItemMinHeight:
          expandedItemMinHeight ?? this.expandedItemMinHeight,
      itemHorizontalPadding:
          itemHorizontalPadding ?? this.itemHorizontalPadding,
      verticalIndicatorWidth:
          verticalIndicatorWidth ?? this.verticalIndicatorWidth,
      verticalIndicatorHeight:
          verticalIndicatorHeight ?? this.verticalIndicatorHeight,
      noLabelIndicatorSize: noLabelIndicatorSize ?? this.noLabelIndicatorSize,
      horizontalIndicatorHeight:
          horizontalIndicatorHeight ?? this.horizontalIndicatorHeight,
      horizontalLeadingSpace:
          horizontalLeadingSpace ?? this.horizontalLeadingSpace,
      horizontalTrailingSpace:
          horizontalTrailingSpace ?? this.horizontalTrailingSpace,
      horizontalIconLabelSpacing:
          horizontalIconLabelSpacing ?? this.horizontalIconLabelSpacing,
      badgeLabelSpacing: badgeLabelSpacing ?? this.badgeLabelSpacing,
      groupAlignment: groupAlignment ?? this.groupAlignment,
      scrollable: scrollable ?? this.scrollable,
      applyBottomInset: applyBottomInset ?? this.applyBottomInset,
    );
  }

  @override
  NavigationRailStyle lerp(
    covariant ThemeExtension<NavigationRailStyle>? other,
    double t,
  ) {
    if (other is! NavigationRailStyle) return this;
    return NavigationRailStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      elevation: lerpDouble(elevation, other.elevation, t),
      divider: divider == null || other.divider == null
          ? (t < 0.5 ? divider : other.divider)
          : BorderSide.lerp(divider!, other.divider!, t),
      modalBackgroundColor: Color.lerp(
        modalBackgroundColor,
        other.modalBackgroundColor,
        t,
      ),
      modalElevation: lerpDouble(modalElevation, other.modalElevation, t),
      modalShape: ShapeBorder.lerp(modalShape, other.modalShape, t),
      scrimColor: Color.lerp(scrimColor, other.scrimColor, t),
      labelType: t < 0.5 ? labelType : other.labelType,
      expandedIndicatorSize: t < 0.5
          ? expandedIndicatorSize
          : other.expandedIndicatorSize,
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
      minWidth: lerpDouble(minWidth, other.minWidth, t),
      expandedWidth: expandedWidth == null || other.expandedWidth == null
          ? (t < 0.5 ? expandedWidth : other.expandedWidth)
          : lerpDouble(expandedWidth, other.expandedWidth, t),
      minExpandedWidth: lerpDouble(minExpandedWidth, other.minExpandedWidth, t),
      maxExpandedWidth: lerpDouble(maxExpandedWidth, other.maxExpandedWidth, t),
      topSpace: lerpDouble(topSpace, other.topSpace, t),
      headerSpace: lerpDouble(headerSpace, other.headerSpace, t),
      headerItemSpacing: lerpDouble(
        headerItemSpacing,
        other.headerItemSpacing,
        t,
      ),
      itemSpace: lerpDouble(itemSpace, other.itemSpace, t),
      collapsedItemMinHeight: lerpDouble(
        collapsedItemMinHeight,
        other.collapsedItemMinHeight,
        t,
      ),
      expandedItemMinHeight: lerpDouble(
        expandedItemMinHeight,
        other.expandedItemMinHeight,
        t,
      ),
      itemHorizontalPadding: lerpDouble(
        itemHorizontalPadding,
        other.itemHorizontalPadding,
        t,
      ),
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
      noLabelIndicatorSize: lerpDouble(
        noLabelIndicatorSize,
        other.noLabelIndicatorSize,
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
      badgeLabelSpacing: lerpDouble(
        badgeLabelSpacing,
        other.badgeLabelSpacing,
        t,
      ),
      groupAlignment: lerpDouble(groupAlignment, other.groupAlignment, t),
      scrollable: t < 0.5 ? scrollable : other.scrollable,
      applyBottomInset: t < 0.5 ? applyBottomInset : other.applyBottomInset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationRailStyle &&
        other.backgroundColor == backgroundColor &&
        other.elevation == elevation &&
        other.divider == divider &&
        other.modalBackgroundColor == modalBackgroundColor &&
        other.modalElevation == modalElevation &&
        other.modalShape == modalShape &&
        other.scrimColor == scrimColor &&
        other.labelType == labelType &&
        other.expandedIndicatorSize == expandedIndicatorSize &&
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
        other.minWidth == minWidth &&
        other.expandedWidth == expandedWidth &&
        other.minExpandedWidth == minExpandedWidth &&
        other.maxExpandedWidth == maxExpandedWidth &&
        other.topSpace == topSpace &&
        other.headerSpace == headerSpace &&
        other.headerItemSpacing == headerItemSpacing &&
        other.itemSpace == itemSpace &&
        other.collapsedItemMinHeight == collapsedItemMinHeight &&
        other.expandedItemMinHeight == expandedItemMinHeight &&
        other.itemHorizontalPadding == itemHorizontalPadding &&
        other.verticalIndicatorWidth == verticalIndicatorWidth &&
        other.verticalIndicatorHeight == verticalIndicatorHeight &&
        other.noLabelIndicatorSize == noLabelIndicatorSize &&
        other.horizontalIndicatorHeight == horizontalIndicatorHeight &&
        other.horizontalLeadingSpace == horizontalLeadingSpace &&
        other.horizontalTrailingSpace == horizontalTrailingSpace &&
        other.horizontalIconLabelSpacing == horizontalIconLabelSpacing &&
        other.badgeLabelSpacing == badgeLabelSpacing &&
        other.groupAlignment == groupAlignment &&
        other.scrollable == scrollable &&
        other.applyBottomInset == applyBottomInset;
  }

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    elevation,
    divider,
    modalBackgroundColor,
    modalElevation,
    modalShape,
    scrimColor,
    labelType,
    expandedIndicatorSize,
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
    minWidth,
    expandedWidth,
    minExpandedWidth,
    maxExpandedWidth,
    topSpace,
    headerSpace,
    headerItemSpacing,
    itemSpace,
    collapsedItemMinHeight,
    expandedItemMinHeight,
    itemHorizontalPadding,
    verticalIndicatorWidth,
    verticalIndicatorHeight,
    noLabelIndicatorSize,
    horizontalIndicatorHeight,
    horizontalLeadingSpace,
    horizontalTrailingSpace,
    horizontalIconLabelSpacing,
    badgeLabelSpacing,
    groupAlignment,
    scrollable,
    applyBottomInset,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ColorProperty('backgroundColor', backgroundColor, defaultValue: null),
      )
      ..add(DoubleProperty('elevation', elevation, defaultValue: null))
      ..add(
        DiagnosticsProperty<BorderSide>('divider', divider, defaultValue: null),
      )
      ..add(
        ColorProperty(
          'modalBackgroundColor',
          modalBackgroundColor,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty('modalElevation', modalElevation, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<ShapeBorder>(
          'modalShape',
          modalShape,
          defaultValue: null,
        ),
      )
      ..add(ColorProperty('scrimColor', scrimColor, defaultValue: null))
      ..add(
        EnumProperty<NavigationRailLabelType>(
          'labelType',
          labelType,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<NavigationIndicatorSize>(
          'expandedIndicatorSize',
          expandedIndicatorSize,
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
      ..add(DoubleProperty('minWidth', minWidth, defaultValue: null))
      ..add(DoubleProperty('expandedWidth', expandedWidth, defaultValue: null))
      ..add(
        DoubleProperty(
          'minExpandedWidth',
          minExpandedWidth,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'maxExpandedWidth',
          maxExpandedWidth,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('topSpace', topSpace, defaultValue: null))
      ..add(DoubleProperty('headerSpace', headerSpace, defaultValue: null))
      ..add(
        DoubleProperty(
          'headerItemSpacing',
          headerItemSpacing,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('itemSpace', itemSpace, defaultValue: null))
      ..add(
        DoubleProperty(
          'collapsedItemMinHeight',
          collapsedItemMinHeight,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'expandedItemMinHeight',
          expandedItemMinHeight,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'itemHorizontalPadding',
          itemHorizontalPadding,
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
          'noLabelIndicatorSize',
          noLabelIndicatorSize,
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
      )
      ..add(
        DoubleProperty(
          'badgeLabelSpacing',
          badgeLabelSpacing,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty('groupAlignment', groupAlignment, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<bool>('scrollable', scrollable, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'applyBottomInset',
          applyBottomInset,
          defaultValue: null,
        ),
      );
  }
}
