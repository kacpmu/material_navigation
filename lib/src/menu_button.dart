// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

import 'rail.dart';

/// A menu button for the header of a [NavigationRail], which turns from
/// [icon] to [openIcon] as the rail expands.
///
/// The icons turn half a turn and cross-fade with [animation], by default the
/// rail's expansion, and so with the modal's inside the modal. The tooltip
/// follows, from Material's "open navigation menu" to "close".
///
/// When [onPressed] is null, the button opens the rail's modal, or closes it
/// when it is open. A rail expanded in place is the app's to collapse, so
/// such a rail's button takes an [onPressed] that changes the rail's
/// `expanded`:
///
/// ```dart
/// NavigationRail(
///   expanded: _expanded,
///   leading: NavigationMenuButton(
///     onPressed: () => setState(() => _expanded = !_expanded),
///   ),
///   // ...
/// )
/// ```
final class NavigationMenuButton extends StatefulWidget {
  /// Creates a menu button.
  const NavigationMenuButton({
    super.key,
    this.onPressed,
    this.animation,
    this.icon = const Icon(Icons.menu),
    this.openIcon = const Icon(Icons.menu_open),
  });

  /// Called when the button is pressed.
  ///
  /// When null, the button opens or closes the modal of the rail around it.
  final VoidCallback? onPressed;

  /// The progress from [icon] (0) to [openIcon] (1).
  ///
  /// When null, [NavigationRail.expandedAnimation] of the rail around the
  /// button. A button outside a rail must be given one.
  final Animation<double>? animation;

  /// The icon while the rail is collapsed.
  final Widget icon;

  /// The icon while the rail is expanded.
  final Widget openIcon;

  @override
  State<NavigationMenuButton> createState() => _NavigationMenuButtonState();
}

class _NavigationMenuButtonState extends State<NavigationMenuButton> {
  Animation<double>? _animation;
  // Whether the open icon shows: the one threshold the button rebuilds on,
  // for its tooltip.
  bool _open = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listen();
  }

  @override
  void didUpdateWidget(NavigationMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) _listen();
  }

  @override
  void dispose() {
    _animation?.removeListener(_onTick);
    super.dispose();
  }

  void _listen() {
    final animation =
        widget.animation ??
        (NavigationRail.maybeOf(context) == null
            ? null
            : NavigationRail.expandedAnimation(context));
    assert(
      animation != null,
      'A NavigationMenuButton outside a NavigationRail needs an animation.',
    );
    if (animation == _animation) return;
    _animation?.removeListener(_onTick);
    _animation = animation?..addListener(_onTick);
    _open = _isOpen;
  }

  bool get _isOpen => (_animation?.value ?? 0) >= 0.5;

  void _onTick() {
    if (_isOpen != _open) setState(() => _open = _isOpen);
  }

  void _toggleModal() {
    final rail = NavigationRail.of(context);
    if (rail.isModalOpen) {
      rail.closeModal();
    } else {
      rail.openModal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animation = _animation ?? kAlwaysDismissedAnimation;
    final localizations = MaterialLocalizations.of(context);
    // Both icons turn the same way, mirrored in right-to-left layouts: the
    // closing icon from rest, the opening one into rest.
    final turn = Directionality.of(context) == TextDirection.ltr ? 0.5 : -0.5;
    const crossing = Interval(0.3, 0.7);
    return IconButton(
      tooltip: _open
          ? localizations.closeButtonTooltip
          : localizations.openAppDrawerTooltip,
      onPressed:
          widget.onPressed ??
          (NavigationRail.maybeOf(context) == null ? null : _toggleModal),
      icon: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: animation.drive(
              Tween<double>(
                begin: 1,
                end: 0,
              ).chain(CurveTween(curve: crossing)),
            ),
            child: RotationTransition(
              turns: animation.drive(Tween<double>(begin: 0, end: turn)),
              child: widget.icon,
            ),
          ),
          FadeTransition(
            opacity: animation.drive(CurveTween(curve: crossing)),
            child: RotationTransition(
              turns: animation.drive(Tween<double>(begin: -turn, end: 0)),
              child: widget.openIcon,
            ),
          ),
        ],
      ),
    );
  }
}
