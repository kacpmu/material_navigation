# material_navigation

Material 3 Expressive navigation for Flutter: a navigation bar with vertical or horizontal items, and a navigation rail that is collapsed or expanded, in place or as a modal.

The widgets take the parameters of Flutter's own `NavigationBar` and `NavigationRail` where the two share a concept, and follow the Material 3 Expressive specification and design tokens.

## Table of Contents

- [Getting started](#getting-started)
- [Navigation bar](#navigation-bar)
- [Navigation rail](#navigation-rail)
  - [The modal](#the-modal)
  - [Layout and slots](#layout-and-slots)
- [Destinations](#destinations)
- [Styling](#styling)
- [Motion](#motion)
- [Migrating from Flutter's widgets](#migrating-from-flutters-widgets)
- [License](#license)

## Getting started

```sh
flutter pub add material_navigation material_ui
```

The widgets are built on [`material_ui`](https://pub.dev/packages/material_ui), the standalone Material library, and read their theme from its `Theme`. The package declares three names that the Material library also declares, so hide those at the import:

```dart
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;
import 'package:material_navigation/material_navigation.dart';
```

## Navigation bar

Three to five destinations at the bottom of a compact or medium window.

```dart
NavigationBar(
  selectedIndex: _index,
  onDestinationSelected: (index) => setState(() => _index = index),
  destinations: [
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: const Icon(Icons.chat_bubble_outline),
      selectedIcon: const Icon(Icons.chat_bubble),
      label: 'Chats',
      badge: Badge.count(count: _unread),
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'You',
    ),
  ],
)
```

`itemLayout` places each label below its icon (`vertical`, the default) or beside it, inside the active indicator (`horizontal`). Horizontal items are centered as a group. A change of `itemLayout` animates.

No widget in this package adapts itself to the window: the app decides. Material 3 uses horizontal items from 600dp:

```dart
NavigationBar(
  itemLayout: MediaQuery.sizeOf(context).width >= 600
      ? NavigationBarItemLayout.horizontal
      : NavigationBarItemLayout.vertical,
  // ...
)
```

## Navigation rail

Three to seven destinations along the leading edge of a medium or larger window. Collapsed, the rail is 96dp wide with the labels below the icons. Expanded, it is as wide as its widest destination, between 220dp and 360dp, with the labels beside the icons.

`expanded` expands the rail in place, pushing the content aside. The parent owns it; the rail never changes it. Material 3 uses a collapsed rail in medium windows and an expanded rail in large ones:

```dart
NavigationRail(
  expanded: MediaQuery.sizeOf(context).width >= 1200,
  selectedIndex: _index,
  onDestinationSelected: (index) => setState(() => _index = index),
  destinations: const [
    NavigationDestination(
      icon: Icon(Icons.inbox_outlined),
      selectedIcon: Icon(Icons.inbox),
      label: 'Inbox',
    ),
    NavigationDestination(
      icon: Icon(Icons.send_outlined),
      selectedIcon: Icon(Icons.send),
      label: 'Sent',
    ),
    NavigationDestination(
      icon: Icon(Icons.drafts_outlined),
      selectedIcon: Icon(Icons.drafts),
      label: 'Drafts',
    ),
  ],
)
```

### The modal

The expanded rail can also open as a modal over the content, behind a scrim. The modal is transient, like a drawer: it opens through a `NavigationRailController` and closes itself when the user taps the scrim, presses back or Escape, or selects a destination. Android's predictive back gesture shrinks it as the gesture progresses.

`NavigationMenuButton` opens the modal of the rail around it, or closes it when it is open. Its icon turns from menu to menu-open as the rail expands, in place or as the modal:

```dart
NavigationRail(
  leading: const NavigationMenuButton(),
  // ...
)
```

A rail expanded in place is the parent's to collapse, so its button takes an `onPressed` that changes `expanded`:

```dart
leading: NavigationMenuButton(
  onPressed: () => setState(() => _expanded = !_expanded),
),
```

Any other widget inside the rail reaches the rail's controller with `NavigationRail.of(context)`.

A controller passed to the rail works from anywhere. Its background slides in from the leading edge; the collapsed rail's destinations expand in place as it arrives. With a collapsed width of 0, the rail takes no room until it opens, and its destinations slide in with the background, which can also be dragged away. That is Material 3's navigation for compact windows with more destinations than a bar holds:

```dart
final _rail = NavigationRailController(); // disposed with the State

Scaffold(
  appBar: AppBar(
    leading: IconButton(
      icon: const Icon(Icons.menu),
      onPressed: _rail.openModal,
    ),
  ),
  body: Row(
    children: [
      NavigationRail(controller: _rail, minWidth: 0, /* ... */),
      Expanded(child: page),
    ],
  ),
)
```

`openModal` returns a future that completes when the modal closes. While the rail is expanded in place, it does nothing. Setting `expanded` to true while the modal is open turns the modal into the in-place rail, so a window that grows past a breakpoint needs no special handling.

### Layout and slots

The rail places its content in three regions: a header pinned to the top, a group placed by `groupAlignment` that scrolls when it does not fit, and a footer pinned to the bottom. `layout` arranges the rail's parts in them and mixes in other widgets; `modalLayout` does the same for the modal, which often wants a header of its own:

```dart
NavigationRail(
  destinations: _mailboxes,
  secondaryDestinations: _labels, // shown only while expanded
  expandedBody: const StorageMeter(),
  trailing: const AccountButton(),
  layout: const NavigationRailLayout(
    group: [
      NavigationRailSlot.destinations,
      NavigationRailSlot.widget(
        Text('Labels'),
        visibility: NavigationRailSlotVisibility.expanded,
      ),
      NavigationRailSlot.secondaryDestinations,
      NavigationRailSlot.expandedBody,
      NavigationRailSlot.trailing, // straight after the group
    ],
    footer: [],
  ),
  modalLayout: NavigationRailLayout(
    header: [NavigationRailSlot.widget(MailHeader(onClose: _rail.closeModal))],
  ),
  // ...
)
```

While the modal shows, the rail keeps only its footprint. Without a `modalLayout`, the rail's content moves into the modal and its widgets keep their state; with one, they are built again when the modal closes.

A widget slot is as wide as the rail at each moment, so one that always shows passes through the collapsed width while the rail or its modal expands. A header with a title should let the title give way, for example with `TextOverflow.fade`.

The indices of `secondaryDestinations` follow those of `destinations`: with three destinations, the first secondary destination is index 3 for `selectedIndex` and `onDestinationSelected`.

`NavigationRail.expandedAnimation(context)` gives widgets in the rail its expansion, from 0 to 1. Material 3 asks the rail's floating action button to become an extended one as the rail expands; one that widens with the animation keeps its start still, as the rail places it. For example, a `FloatingActionButton.extended` whose label is uncovered as the rail expands:

```dart
floatingActionButton: Builder(builder: (context) {
  final expansion = NavigationRail.expandedAnimation(context);
  return FloatingActionButton.extended(
    heroTag: null,
    elevation: 0,
    // 56dp wide with the label hidden; its spacing is in the label.
    extendedPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
    extendedIconLabelSpacing: 0,
    onPressed: _compose,
    icon: const Icon(Icons.edit_outlined),
    label: AnimatedBuilder(
      animation: expansion,
      builder: (context, label) => ClipRect(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: expansion.value,
          child: label,
        ),
      ),
      child: const Padding(
        padding: EdgeInsetsDirectional.only(start: 8),
        child: Text('Compose'),
      ),
    ),
  );
}),
```

## Destinations

`NavigationDestination` takes an `icon`, an optional `selectedIcon`, a `label` and an optional `tooltip`, as Flutter's does, and `enabled`. It adds:

- `badge`, typically a `Badge` without a child, placed at the icon's top end, and beside the label in an expanded rail;
- `semanticLabel`, an accessible name for a label that is ambiguous on its own;
- `onTap`, called when the destination is tapped, before `onDestinationSelected`.

A destination is announced as a tab, with its position ("Tab 2 of 4"). A label that is hidden, by `labelBehavior`, `labelType` or a collapsed rail with no labels, shows as a tooltip.

A destination also works anywhere else in a rail, such as its `trailing` widget or a widget of its layout. It takes the rail's layout and style, so it lines up with the rail's destinations and expands with them; it is never selected, and a tap calls its `onTap` (and closes the modal):

```dart
NavigationRail(
  trailing: NavigationDestination(
    icon: const Icon(Icons.settings_outlined),
    label: 'Settings',
    onTap: _openSettings,
  ),
  // ...
)
```

## Styling

`NavigationBarStyle` and `NavigationRailStyle` hold every token of their component, from colors and text styles to the indicator's size and the rail's spacing. Every token is optional; unset tokens fall back to the Material 3 Expressive defaults for the current `ColorScheme` and `TextTheme`. Both are `ThemeExtension`s:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [
      NavigationBarStyle(indicatorColor: Colors.amber),
      NavigationRailStyle(
        expandedIndicatorSize: NavigationIndicatorSize.fill,
        divider: BorderSide(),
      ),
    ],
  ),
);
```

A style passed to a widget applies over the theme's, and a widget's own arguments, such as `backgroundColor`, apply over both. `NavigationBarStyle.of(context)` and `NavigationRailStyle.of(context)` return the resolved style.

`iconTheme`, `labelTextStyle` and `overlayColor` are `WidgetStateProperty`s, resolved against `selected`, `disabled`, `hovered`, `focused` and `pressed`.

## Motion

Both widgets animate with springs, the Material 3 Expressive motion scheme by default. `motion` selects another:

```dart
NavigationRail(motion: const NavigationMotion.standard(), /* ... */);

NavigationBar(
  motion: NavigationMotion(
    defaultSpatial: SpringDescription.withDampingRatio(
        mass: 1, stiffness: 300, ratio: 0.7),
    fastSpatial: NavigationMotion.expressiveFastSpatial,
    defaultEffects: NavigationMotion.expressiveDefaultEffects,
  ),
  // ...
);
```

`NavigationMotion.easing` replaces the springs with a duration and a curve. The bar's `animationDuration` selects it for the selection.

## Migrating from Flutter's widgets

| Flutter | material_navigation |
| --- | --- |
| `NavigationBar(...)` | The same arguments, plus `itemLayout`, `style` and `motion`. |
| `NavigationRail(extended: ...)` | `expanded: ...` |
| `NavigationRail(minExtendedWidth: ...)` | `minExpandedWidth: ...` |
| `NavigationRail(labelType: ...)` | The same; it applies while the rail is collapsed, as an expanded rail always shows its labels. |
| `NavigationRail(leadingAtTop:, trailingAtBottom:)` | `layout`, which places `leading` and `trailing` anywhere. |
| `NavigationRailDestination(label: Text('Inbox'), disabled: true)` | `NavigationDestination(label: 'Inbox', enabled: false)` |
| `NavigationRail.extendedAnimation(context)` | `NavigationRail.expandedAnimation(context)` |
| `NavigationBarThemeData`, `NavigationRailThemeData` | `NavigationBarStyle`, `NavigationRailStyle` |

## License

MIT — see [LICENSE](LICENSE).
