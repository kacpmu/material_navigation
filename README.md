# material_navigation

Material 3 **Expressive** navigation for Flutter — the flexible navigation bar, the collapsing/expanding navigation rail.

## Getting started

```sh
flutter pub add material_navigation
```

These widgets share names with Flutter's Material library, so hide the SDK's versions at the import:

```dart
import 'package:flutter/material.dart' hide NavigationBar, NavigationRail, NavigationDestination;
import 'package:material_navigation/material_navigation.dart';
```

Everything is exported from that single barrel.

## Examples

### A navigation rail

The rail owns its expand state; a menu button in the `leading` slot toggles it through `NavigationRail.of(context)`. Use a `Builder` so the button's context sits below the rail.

```dart
NavigationRail(
  selectedIndex: _index,
  onDestinationSelected: (i) => setState(() => _index = i),
  leading: Builder(
    builder: (context) => IconButton(
      icon: const Icon(Icons.menu),
      onPressed: NavigationRail.of(context).toggle, // .toggleModal() for an overlay
    ),
  ),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Inbox'),
    NavigationDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send), label: 'Sent'),
    NavigationDestination(icon: Icon(Icons.archive_outlined), selectedIcon: Icon(Icons.archive), label: 'Archive'),
  ],
)
```

### A rail with secondary destinations

`expandedBody` is revealed only while the rail is expanded — per Material 3, the place for the secondary destinations a collapsed rail can't show.

```dart
NavigationRail(
  selectedIndex: _index,
  onDestinationSelected: (i) => setState(() => _index = i),
  leading: Builder(
    builder: (context) => IconButton(
      icon: const Icon(Icons.menu),
      onPressed: NavigationRail.of(context).toggle,
    ),
  ),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Inbox'),
    NavigationDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send), label: 'Sent'),
  ],
  expandedBody: Column(
    children: const [
      ListTile(leading: Icon(Icons.label_outline), title: Text('Promotions')),
      ListTile(leading: Icon(Icons.label_outline), title: Text('Social')),
      ListTile(leading: Icon(Icons.label_outline), title: Text('Updates')),
    ],
  ),
)
```

### A flexible navigation bar

Same shape as Flutter's own `NavigationBar` — the familiar `selectedIndex` / `onDestinationSelected` / `destinations` triad and `NavigationDestination(icon:, selectedIcon:, label:)`.

Set `layoutDirection: Axis.horizontal` and the items lay their icon beside the label and center as a group with outer margins. Toggling `layoutDirection` animates the morph under `motion`.

```dart
NavigationBar(
  layoutDirection: Axis.horizontal, // or Axis.vertical 
  selectedIndex: _index,
  onDestinationSelected: (i) => setState(() => _index = i),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
  ],
)
```

## Motion

Both the bar and the rail take a `motion`. Material 3 Expressive spring physics drive the transition unless you pass `NavigationMotion.standard()` for a fixed duration and curve.

```dart
NavigationRail( // spring (Expressive)
  motion: const NavigationMotion.expressive(),
  // ...
);

NavigationRail( // a softer, custom spring
  motion: const NavigationMotion.expressive(
    spring: SpringDescription(mass: 1, stiffness: 300, damping: 30),
  ),
  // ...
);

NavigationBar( // a fixed duration eased by a curve
  motion: const NavigationMotion.standard(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOutCubicEmphasized,
  ),
  // ...
);
```

## Styling

Each component resolves a token bundle from the ambient `Theme`. Build one explicitly from a `ColorScheme` and `TextTheme`, then adjust individual tokens with `copyWith`. `NavigationBarStyle.baseline(...)` and `NavigationRailStyle.baseline(...)` build the pre-Expressive Material 3 variants.

```dart
final theme = Theme.of(context);

NavigationRail( // the expressive rail, widened to 320dp
  style: NavigationRailStyle.expressive(theme.colorScheme, theme.textTheme)
      .copyWith(expandedWidth: 320),
  // ...
);

NavigationBar( // the flexible (64dp) bar with a custom indicator color
  style: NavigationBarStyle.flexible(theme.colorScheme, theme.textTheme)
      .copyWith(indicatorColor: Colors.amber),
  // ...
);
```

## Components

| Type | What it is |
| --- | --- |
| `NavigationBar` | A bottom navigation bar of three to five destinations; Material 3 Expressive flexible 64dp or baseline 80dp. |
| `NavigationBarStyle` | The token bundle driving a bar; `.flexible` (Expressive) / `.baseline` factories plus `copyWith`. |
| `NavigationRail` | A rail that collapses and expands, in place or as a modal overlay, with `leading`, `floatingActionButton`, `trailing`, and `expandedBody` slots. |
| `NavigationRailHandle` | The handle from `NavigationRail.of(context)`: `open`, `openModal`, `close`, `toggle`, `toggleModal`, `isOpen`, `isModal`, `expandAnimation`. |
| `NavigationRailStyle` | The token bundle driving a rail; `.expressive` / `.baseline` factories plus `copyWith`. |
| `NavigationDestination` | A destination shared by the bar and the rail that morphs between the vertical and horizontal layouts. |
| `NavigationDestinationStyle` | The resolved per-item styling — colors, label styles, and state layer. |
| `NavigationLabelBehavior` | When the below-label is shown: `all`, `selected`, or `none`. |
| `NavigationIndicatorSize` | How the expanded active indicator is sized: `fill` (full width) or `label` (hugs content). |
| `NavigationMotion` | The shared motion: `.expressive()` (spring physics) or `.standard()` (duration + curve). |
