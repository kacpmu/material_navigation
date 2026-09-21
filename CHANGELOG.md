## 0.1.0

**Breaking.**

* Migrates to `material_ui`.
* `NavigationBarStyle` and `NavigationRailStyle` are now `ThemeExtension`s with
  optional tokens, falling back to the Material 3 defaults for the current
  `ColorScheme` and `TextTheme`. Adds `variant`, `of`, `merge` and `lerp`.
* New tokens, including indicator shape, per-state icon and label styles, the
  rail's header and item spacing, item heights, `groupAlignment` and
  `scrollable`.
* Defaults follow the Material 3 tokens: the Expressive springs, an expanded
  rail sized to its destinations instead of a fixed 280dp, the rail's header
  and item spacing, `onSurfaceVariant` for disabled destinations, no shadow on
  the bar, and no bold active label in the baseline variant.
* Adds `NavigationRail.groupAlignment`, `NavigationRail.modalMotion`,
  `NavigationMotion.defaultSpatial` and `NavigationMotion.fastSpatial`.
* Destinations in a rail's `trailing` and `expandedBody` slots take the rail's
  layout and style instead of their own defaults.
* Removes `itemVerticalSpace`, and the style classes' `besideLabelStart` and
  `destinationStyle` getters.

## 0.0.2

* Fixes `setState() or markNeedsBuild() called during build` when a destination
  is selected, or the destinations change, while `NavigationRail` is open as a
  modal overlay. The overlay is now built with an `OverlayPortal`, so it also
  inherits what the rail inherits (such as a local `Theme`), and dialogs or
  routes opened while it is showing now appear above it instead of beneath it.
* Fixes `NavigationBar` throwing an `ArgumentError` and rendering no
  destinations when a destination is narrower than 80dp, for example five
  destinations on a screen under 400dp wide. Destinations now squash to fit.

## 0.0.1

* Initial release.
