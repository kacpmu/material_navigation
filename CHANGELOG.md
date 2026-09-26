## 0.1.1

**Accessibility**

* Destinations carry the tab role and the button flag, in one merged semantics
  node each, and the bar and rail carry the tab-bar role. Previously they had
  no role.
* A destination keeps its accessible name under every `labelBehavior`.
  Previously `NavigationLabelBehavior.none` exposed only a tooltip and
  `NavigationLabelBehavior.selected` left unselected destinations unnamed.
* A destination whose label is hidden or does not fit gets a tooltip.
  Previously only `NavigationLabelBehavior.none` gave one.
* The modal rail behaves like a modal: the scrim is a `ModalBarrier` with the
  platform's dismiss action and label, the pane is named for screen readers,
  and focus moves into the overlay and is restored on close.
* The modal rail closes on `Escape` and on the system back gesture. Previously
  `Escape` did nothing and back left the page.
* A rail not stretched to its parent's height no longer collapses to nothing
  behind its modal, which also left the modal unreadable to screen readers.

**Changed**

* `NavigationBar.labelBehavior` applies to horizontal items too. With
  `selected`, only the selected destination shows its label beside the icon,
  its indicator growing around the label as it is selected; with `none`, items
  show their icons only.
* Changing `labelBehavior` animates: labels ease in or out, and the bar resizes
  with them.

**Fixes**

* `NavigationBar` no longer throws a `RangeError` when `selectedIndex` is out
  of range; it shows no destination as selected.
* `NavigationBar` no longer overflows at large text scales: its `height` is now
  a minimum, and the bar grows with its content.
  `NavigationBarStyle.maxLabelScale` caps the labels' text scale, and with it
  the growth; tooltips keep the full scale.
* The expanded pill grows around a label taller than the icon instead of
  clipping it, matching the Material 3 tokens.
* A label that does not fit wraps to a second line instead of being cut, both
  below the icon and beside it, so it stays visible in full at up to twice the
  text size, as Material 3's accessibility guidance asks. A label that fits one
  line is unaffected; `labelMaxLines`, 2 by default, sets the limit.
* A `NavigationRail` whose destinations do not fit and whose style sets
  `scrollable: false` now clips them and reports an overflow instead of
  painting over the content beside it.
* A collapsed `NavigationRail` narrower than its indicator no longer throws: the
  indicator fits the rail.
* Setting `NavigationRail.expanded` to `true` expands the rail in place, as
  documented, even when it was last opened as a modal.
* `NavigationRail.onExpandedChanged` is no longer called during a build, so a
  `setState` in the callback is safe.
* `NavigationRail` honours the bottom view padding, keeping `trailing` clear of
  a system gesture bar. `NavigationRailStyle.applyBottomInset` opts out.
* `NavigationRailHandle.isOpen` and `isModal` always report the rail's current
  state, including from a handle captured earlier.
* Widgets in the rail's `leading`, `floatingActionButton`, `trailing` and
  `expandedBody` slots keep their state when the rail opens or closes as a
  modal.
* `NavigationBar` finishes its layout morph when `motion` changes part-way
  through it; previously the morph stopped where it was. A change in the number
  of destinations part-way no longer jumps the morph to its end.

**Performance**

* Labels are measured once and cached rather than laid out twice per
  destination per frame. Expanding a seven-destination rail took 476 label
  layouts; it now takes none after the first frame.
* Selecting a destination no longer rebuilds the whole bar or rail on every
  animation tick. One tap on a seven-destination rail went from 14 rail
  rebuilds, 98 destination rebuilds and 196 label layouts to 1, 33 and 4.
* The `TextPainter` each destination created on every build, and never
  disposed, is gone.

**New**

* `NavigationBarStyle.maxLabelScale`, `NavigationRailStyle.applyBottomInset`,
  and `labelMaxLines` and `labelOverflow` on both styles.
* `labelMaxLines`, `labelOverflow` and `maxLabelScale` on
  `NavigationDestinationStyle`.
* `NavigationRailHandle.openListenable` and `modalListenable`, for rebuilding
  when the rail opens or closes.

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
