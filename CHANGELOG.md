## 0.2.0

A rewrite against the Material 3 Expressive specification and design tokens,
with Flutter's parameter names where the two share a concept.

**Breaking**

* Material 3 Expressive only: the baseline variant, `StyleVariant` and the
  `NavigationBarStyle.flexible` / `.baseline` and `NavigationRailStyle`
  `.expressive` / `.baseline` factories are removed.
* `NavigationRail` no longer keeps its own expanded state. `expanded` is owned
  by the parent and the rail never changes it; `onExpandedChanged`,
  `NavigationRailHandle` and the handle's `open`, `openModal`, `close`,
  `toggle` and `toggleModal` are removed. The modal opens through the new
  `NavigationRailController`, which `NavigationRail.of` now returns.
* `NavigationDestination` takes `enabled` in place of `disabled`, and renders
  only inside a bar or a rail. `NavigationDestination.custom`, its layout
  arguments and `NavigationDestinationStyle` are removed, and so is
  `expandAnimation`: a destination anywhere in a rail outside its
  destinations, such as `trailing`, still takes the rail's layout and style,
  and now follows the rail's expansion by itself. It is never selected, and a
  tap calls its `onTap`, which it keeps.
* `NavigationBar.layoutDirection` is replaced by `itemLayout`
  (`NavigationBarItemLayout.vertical` or `.horizontal`). `selectedIndex`
  defaults to 0, as Flutter's does.
* `NavigationLabelBehavior` is replaced by `material_ui`'s own enums:
  `NavigationBar.labelBehavior` takes a `NavigationDestinationLabelBehavior`,
  and `NavigationRail.labelType` a `NavigationRailLabelType`.
* `NavigationIndicatorSize.label` is renamed `hug`.
* `NavigationMotion.standard` is now Material 3's standard spring scheme; the
  former duration-and-curve motion is `NavigationMotion.easing`.
  `NavigationRail.modalMotion` is removed: the modal uses the motion's fast
  spatial spring. `NavigationMotion.defaultSpatial` and `.fastSpatial` are
  renamed `expressiveDefaultSpatial` and `expressiveFastSpatial`.
* Style tokens are renamed after their rule in the specification, for example
  `containerColor` to `backgroundColor`, `activeIconColor` to
  `selectedIconColor`, `verticalLabelStyle` to `labelStyle` and
  `focusPressOpacity` to `focusOpacity` and `pressedOpacity`. `variant`,
  `selectionDuration`, `modalOvershoot`, `modalCornerRadius` (now
  `modalShape`), `fabSpace` (now `headerItemSpacing`), `trailingSpace` and the
  bar's `horizontalIndicatorSize` are removed, and so is `activeLabelWeight`:
  a `labelTextStyle` resolving `WidgetState.selected` sets the selected
  label's weight.

**Specification**

* The active indicator springs in, growing from its center, or from the start
  edge in an expanded rail, and the label color follows on the effects
  spring.
* Horizontal bar items are centered with percentage side padding, and widen
  to fit their labels, as Material 3 specifies.
* A collapsed rail destination without a label has a 56dp circular
  indicator.
* The expanded rail's label switches to `labelLarge` at the midpoint of the
  expansion, where it is invisible, and the icons never move sideways.
* State layers are `onSecondaryContainer` in every state.
* The bar's selected label below the icon is `secondary`, and beside the icon
  `onSecondaryContainer`.
* Labels are no longer limited to two lines by default: the full label stays
  visible at large text sizes.

**New**

* `NavigationRailController`: `openModal`, which returns a future completing
  when the modal closes, `closeModal` and `isModalOpen`.
* The modal responds to Android's predictive back gesture.
* The modal's background slides in from the leading edge, the destinations
  expanding in place, and settles without swinging back.
* A rail with `minWidth: 0` takes no room while collapsed, and keeps its
  content from focus and screen readers; its modal's destinations slide in
  with the background, which can be dragged closed.
* `NavigationRail.secondaryDestinations`, shown only while expanded, their
  indices following those of `destinations`.
* `NavigationRail.layout` and `modalLayout`: the rail's content in a header,
  a group and a footer, with `NavigationRailSlot`s for its own parts and for
  any widget, shown always, only expanded or only collapsed. Slots shown
  only collapsed next to slots shown only expanded take turns in one room.
* `NavigationDestination.badge`, on the icon and beside the label of an
  expanded rail, and `NavigationDestination.semanticLabel`.
* `NavigationRail.expandedAnimation(context)`.
* `NavigationMenuButton`, whose icon turns from menu to menu-open as the rail
  expands, and which opens and closes the rail's modal unless given
  `onPressed`.
* A floating action button that widens with the rail's expansion keeps its
  start still.
* An example, and rail layouts to start from in the demo, among them an
  extending floating action button.
* The rail's `groupAlignment` places the group at the bottom as well.
* `NavigationRailStyle.divider`, on the edge next to the content.
* Destinations announce their position among their tabs ("Tab 2 of 4").

**Changed**

* The bar and the rail take Flutter's own parameters: `animationDuration`,
  `shadowColor`, `surfaceTintColor`, `indicatorShape`, `overlayColor`,
  `labelTextStyle`, `labelPadding` and `maintainBottomViewPadding` on the bar;
  `elevation`, `useIndicator`, `indicatorShape`, the selected and unselected
  label styles and icon themes, `minExpandedWidth` and `scrollable` on the
  rail.
* Destinations are laid out by a single render object each, and animation
  frames relayout and repaint them without rebuilding.

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
