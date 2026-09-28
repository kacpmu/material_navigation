// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

/// Material 3 Expressive navigation: a navigation bar and a navigation rail.
///
///  * `NavigationBar`, three to five destinations at the bottom of a compact
///    or medium window, with vertical or horizontal items.
///  * `NavigationRail`, three to seven destinations along the leading edge of
///    a medium or larger window, collapsed or expanded, in place or as a
///    modal.
///  * `NavigationDestination`, a destination of either.
///  * `NavigationMenuButton`, a rail's menu button, which turns to the
///    menu-open icon as the rail expands.
///
/// Both are styled by tokens, `NavigationBarStyle` and `NavigationRailStyle`,
/// which default to Material 3 Expressive, and animate with a
/// `NavigationMotion`.
library;

export 'src/bar.dart';
export 'src/bar_style.dart';
export 'src/destination.dart' show NavigationDestination;
export 'src/menu_button.dart';
export 'src/motion.dart';
export 'src/rail.dart';
export 'src/rail_layout.dart'
    show NavigationRailLayout, NavigationRailSlot, NavigationRailSlotVisibility;
export 'src/rail_style.dart';
