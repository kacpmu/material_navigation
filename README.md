# material_navigation

Material 3 Expressive navigation for Flutter: a flexible navigation bar, and a navigation rail that expands in place or as a modal overlay.

## Getting started

```sh
flutter pub add material_navigation material_ui
```

These widgets are built on [`material_ui`](https://pub.dev/packages/material_ui), the standalone Material library, and read their theme from its `Theme`. An application using them should therefore use `material_ui`'s `MaterialApp` or `Theme`: a theme from `package:flutter/material.dart` is not visible to them. See the [`material_ui` migration guide](https://pub.dev/packages/material_ui#migrating-existing-code-to-this-package) for moving an existing application over.

The package declares three names that the Material library also declares, so hide the Material versions at the import:

```dart
import 'package:material_ui/material_ui.dart' hide NavigationBar, NavigationRail, NavigationDestination;
import 'package:material_navigation/material_navigation.dart';
```

All widgets and styles are exported from that one library.

## Examples

### Navigation rail

The rail keeps its own expanded state. A button in the `leading` slot controls it through `NavigationRail.of(context)`; wrap the button in a `Builder` so that its context is below the rail.

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

### Rail with secondary destinations

`expandedBody` is shown only while the rail is expanded. Material 3 uses that area for secondary destinations, which a collapsed rail has no room for. It is placed below the destinations and scrolls into view; the destinations themselves stay where `groupAlignment` puts them.

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

### Navigation bar

The bar takes the same `selectedIndex`, `onDestinationSelected` and `destinations` arguments as Flutter's own `NavigationBar`, and the same `NavigationDestination(icon:, selectedIcon:, label:)` description of a destination.

With `layoutDirection: Axis.horizontal`, each destination places its icon beside its label, and the destinations are centred as a group with outer margins. Changing `layoutDirection` animates between the two layouts using `motion`.

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

Both the bar and the rail accept a `motion`, which drives the transition between their two layouts. The default is the Material 3 Expressive spatial spring, `NavigationMotion.defaultSpatial`; a rail opening as a modal overlay uses the faster `NavigationMotion.fastSpatial`, which its `modalMotion` argument controls. `NavigationMotion.standard()` replaces the spring with a fixed duration and curve.

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

Every token of `NavigationBarStyle` and `NavigationRailStyle` is optional; an unset token falls back to the Material 3 default for the current `ColorScheme` and `TextTheme`. Both classes are `ThemeExtension`s, so a style can be set for an entire application in the theme and overridden for a single widget with `style:`:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [
      NavigationBarStyle(indicatorColor: Colors.amber),
      NavigationRailStyle(expandedWidth: 320, groupAlignment: 0),
    ],
  ),
  // ...
);

NavigationBar( // this bar only: a squarer indicator
  style: const NavigationBarStyle(
    indicatorShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
  // ...
);
```

`variant` selects the defaults used for the remaining tokens: `StyleVariant.material3Expressive`, the default, or `StyleVariant.material3` for the pre-Expressive baseline, as in `NavigationBarStyle(variant: StyleVariant.material3)`.

Colours and text can also depend on interaction state. `iconTheme`, `labelTextStyle` and `overlayColor` are `WidgetStateProperty`s, resolved against `selected`, `disabled`, `hovered`, `focused` and `pressed`:

```dart
NavigationRailStyle(
  labelTextStyle: WidgetStateProperty.resolveWith((states) =>
      states.contains(WidgetState.hovered)
          ? const TextStyle(decoration: TextDecoration.underline)
          : null),
)
```

`NavigationBarStyle.of(context)` and `NavigationRailStyle.of(context)` return the fully resolved style. `NavigationBarStyle.flexible(...)`, `NavigationBarStyle.baseline(...)`, `NavigationRailStyle.expressive(...)` and `NavigationRailStyle.baseline(...)` build a complete style from a `ColorScheme` and `TextTheme`.

## Components

| Type | Description |
| --- | --- |
| `NavigationBar` | A bottom navigation bar of three to five destinations: Material 3 Expressive flexible, 64dp, or baseline, 80dp. |
| `NavigationBarStyle` | The tokens of a bar, usable as a theme extension, with `.flexible` and `.baseline` factories, `of`, `merge` and `copyWith`. |
| `NavigationRail` | A rail that collapses and expands, in place or as a modal overlay, with `leading`, `floatingActionButton`, `trailing` and `expandedBody` slots. |
| `NavigationRailHandle` | The handle returned by `NavigationRail.of(context)`: `open`, `openModal`, `close`, `toggle`, `toggleModal`, `isOpen`, `isModal` and `expandAnimation`. |
| `NavigationRailStyle` | The tokens of a rail, usable as a theme extension, with `.expressive` and `.baseline` factories, `of`, `merge` and `copyWith`. |
| `NavigationDestination` | A destination shared by the bar and the rail, which animates between the vertical and horizontal layouts. |
| `NavigationDestinationStyle` | The resolved styling of a single destination: colours, label styles, indicator shape, and the per-state icon, label and state layer. |
| `NavigationLabelBehavior` | When the label below the icon is shown: `all`, `selected` or `none`. |
| `NavigationIndicatorSize` | How the expanded active indicator is sized: `fill`, the full width, or `label`, sized to the icon and label. |
| `NavigationMotion` | The motion of both components: `.expressive()`, a spring simulation, or `.standard()`, a duration and curve. |
