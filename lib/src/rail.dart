// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kMinFlingVelocity;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

import 'animation.dart';
import 'destination.dart';
import 'item.dart';
import 'label_metrics.dart';
import 'motion.dart';
import 'rail_layout.dart';
import 'rail_style.dart';

/// How the active indicator of an expanded rail destination is sized.
enum NavigationIndicatorSize {
  /// Around the icon and the label, the Material 3 Expressive default.
  hug,

  /// Across the rail, less its item padding, for a navigation drawer's look.
  fill,
}

/// Opens and closes the modal of a [NavigationRail].
///
/// The modal is the expanded rail drawn over the content behind a scrim. Unlike
/// the rail's in-place expansion, which the rail's `expanded` argument sets,
/// the modal is transient: it is opened by [openModal] and closes itself when
/// the user taps the scrim, presses back or Escape, drags it away, or selects a
/// destination.
///
/// A rail without a controller creates its own, which widgets inside the rail
/// reach with [NavigationRail.of]. A controller passed to the rail can be used
/// from anywhere, such as an app bar's menu button:
///
/// ```dart
/// final controller = NavigationRailController();
///
/// AppBar(
///   leading: IconButton(
///     icon: const Icon(Icons.menu),
///     onPressed: controller.openModal,
///   ),
/// );
/// NavigationRail(controller: controller, /* ... */);
/// ```
///
/// A controller serves one rail at a time. It notifies its listeners when
/// the modal opens and closes.
final class NavigationRailController extends ChangeNotifier {
  _NavigationRailState? _rail;

  /// Whether the modal is open.
  bool get isModalOpen => _rail?._modalOpen ?? false;

  /// Opens the modal: its background slides in from the leading edge over
  /// the content, while the collapsed rail's destinations expand in place, or
  /// slide in with it when the rail has no collapsed width.
  ///
  /// Returns a future that completes when the modal closes, however it
  /// closes. Does nothing, and completes at once, while the rail is expanded
  /// in place.
  Future<void> openModal() {
    assert(_rail != null, 'No NavigationRail uses this controller.');
    return _rail?._openModal() ?? Future<void>.value();
  }

  /// Closes the modal, if it is open.
  void closeModal() => _rail?._closeModal();

  bool _disposed = false;

  // The newest rail to use the controller is the one it serves: a rail that
  // replaces another attaches before the other detaches.
  void _attach(_NavigationRailState rail) => _rail = rail;

  void _detach(_NavigationRailState rail) {
    if (_rail == rail) _rail = null;
  }

  // Notifies the listeners, after the frame when the change happens while
  // the framework builds, where a listener may not mark widgets dirty.
  void _notify() {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// A Material 3 Expressive navigation rail: three to seven destinations along
/// the leading edge of a medium or larger window.
///
/// The rail is collapsed, 96dp wide with its labels below the icons, or
/// expanded, with its labels beside the icons and room for secondary
/// destinations. [expanded] switches it in place, pushing the content aside;
/// the parent owns that state and the rail never changes it. The rail's
/// [NavigationRailController] opens the expanded rail as a modal over the
/// content instead.
///
/// The rail never adapts itself to the window. Material 3 uses a collapsed
/// rail in medium windows and an expanded one in large windows:
///
/// ```dart
/// NavigationRail(
///   expanded: MediaQuery.sizeOf(context).width >= 1200,
///   selectedIndex: _index,
///   onDestinationSelected: (index) => setState(() => _index = index),
///   // Opens the collapsed rail as a modal.
///   leading: const NavigationMenuButton(),
///   destinations: const [
///     NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
///     NavigationDestination(icon: Icon(Icons.send), label: 'Sent'),
///     NavigationDestination(icon: Icon(Icons.drafts), label: 'Drafts'),
///   ],
/// )
/// ```
///
/// The rail's content is arranged by [layout], and the modal's by
/// [modalLayout].
final class NavigationRail extends StatefulWidget {
  /// Creates a navigation rail.
  const NavigationRail({
    super.key,
    required this.destinations,
    this.secondaryDestinations = const [],
    required this.selectedIndex,
    this.onDestinationSelected,
    this.expanded = false,
    this.controller,
    this.leading,
    this.floatingActionButton,
    this.expandedBody,
    this.trailing,
    this.layout = const NavigationRailLayout(),
    this.modalLayout,
    this.groupAlignment,
    this.labelType,
    this.backgroundColor,
    this.elevation,
    this.indicatorColor,
    this.indicatorShape,
    this.useIndicator,
    this.selectedLabelTextStyle,
    this.unselectedLabelTextStyle,
    this.selectedIconTheme,
    this.unselectedIconTheme,
    this.minWidth,
    this.minExpandedWidth,
    this.scrollable,
    this.style,
    this.motion,
  });

  /// The destinations, three to seven.
  final List<NavigationDestination> destinations;

  /// Destinations shown only while the rail is expanded.
  ///
  /// Their indices follow those of [destinations]: with three destinations,
  /// the first secondary destination is index 3 for [selectedIndex] and
  /// [onDestinationSelected].
  final List<NavigationDestination> secondaryDestinations;

  /// The index of the selected destination, or null for none.
  final int? selectedIndex;

  /// Called with a destination's index when it is tapped. A modal closes
  /// after it.
  ///
  /// When null, the destinations cannot be selected.
  final ValueChanged<int>? onDestinationSelected;

  /// Whether the rail is expanded in place, pushing the content aside.
  ///
  /// A change animates. Becoming true while the modal is open turns the
  /// modal into the expanded rail.
  final bool expanded;

  /// Opens and closes the modal. When null, the rail creates its own, which
  /// [NavigationRail.of] returns.
  final NavigationRailController? controller;

  /// A widget at the top, typically a menu button.
  ///
  /// Centered in the collapsed rail, where it stays as the rail expands.
  final Widget? leading;

  /// A floating action button below [leading], which should have no
  /// elevation.
  ///
  /// Centered in the collapsed rail, and moving to the destinations' start
  /// as the rail expands. One that extends with the rail, following
  /// [expandedAnimation], keeps its start still as it widens.
  final Widget? floatingActionButton;

  /// Content shown only while the rail is expanded, such as an account row.
  final Widget? expandedBody;

  /// A widget at the bottom of the rail.
  final Widget? trailing;

  /// Where the rail places its content.
  final NavigationRailLayout layout;

  /// Where the modal places its content, such as a header of its own. When
  /// null, [layout].
  ///
  /// While the modal shows, the rail keeps only its footprint. With no modal
  /// layout, the rail's content moves into the modal, its widgets keeping
  /// their state; with one, the rail's widgets are built again when the modal
  /// closes.
  final NavigationRailLayout? modalLayout;

  /// Overrides [NavigationRailStyle.groupAlignment].
  final double? groupAlignment;

  /// Overrides [NavigationRailStyle.labelType].
  final NavigationRailLabelType? labelType;

  /// Overrides [NavigationRailStyle.backgroundColor].
  final Color? backgroundColor;

  /// Overrides [NavigationRailStyle.elevation].
  final double? elevation;

  /// Overrides [NavigationRailStyle.indicatorColor].
  final Color? indicatorColor;

  /// Overrides [NavigationRailStyle.indicatorShape].
  final ShapeBorder? indicatorShape;

  /// Overrides [NavigationRailStyle.useIndicator].
  final bool? useIndicator;

  /// The label style of the selected destination, over the resolved one.
  final TextStyle? selectedLabelTextStyle;

  /// The label style of the unselected destinations, over the resolved one.
  final TextStyle? unselectedLabelTextStyle;

  /// The icon theme of the selected destination, over the resolved one.
  final IconThemeData? selectedIconTheme;

  /// The icon theme of the unselected destinations, over the resolved one.
  final IconThemeData? unselectedIconTheme;

  /// Overrides [NavigationRailStyle.minWidth].
  final double? minWidth;

  /// Overrides [NavigationRailStyle.minExpandedWidth].
  final double? minExpandedWidth;

  /// Overrides [NavigationRailStyle.scrollable].
  final bool? scrollable;

  /// The rail's tokens, over the theme's [NavigationRailStyle] and the
  /// defaults.
  final NavigationRailStyle? style;

  /// Overrides [NavigationRailStyle.motion].
  final NavigationMotion? motion;

  /// The controller of the nearest [NavigationRail] around [context].
  static NavigationRailController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No NavigationRail around this context.');
    return controller!;
  }

  /// The controller of the nearest [NavigationRail] around [context], or
  /// null.
  static NavigationRailController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RailScope>()?.controller;

  /// The expansion progress of the nearest [NavigationRail] around
  /// [context], from 0 (collapsed) to 1 (expanded), for widgets that change
  /// with it, such as a floating action button that extends.
  ///
  /// Inside the modal, the modal's progress; 1 throughout a modal that slides
  /// in whole, as a rail without a collapsed width's does.
  static Animation<double> expandedAnimation(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RailScope>();
    assert(scope != null, 'No NavigationRail around this context.');
    return scope!.expandedAnimation;
  }

  @override
  State<NavigationRail> createState() => _NavigationRailState();
}

class _RailScope extends InheritedWidget {
  const _RailScope({
    required this.controller,
    required this.expandedAnimation,
    required super.child,
  });

  final NavigationRailController controller;
  final Animation<double> expandedAnimation;

  @override
  bool updateShouldNotify(_RailScope oldWidget) =>
      controller != oldWidget.controller ||
      expandedAnimation != oldWidget.expandedAnimation;
}

// A 0 to 1 view of a spring that only moves toward its target. It follows the
// spring until the spring first reaches the target, then holds there while an
// underdamped spring swings past and back, so what it drives does not shake
// as the spring settles. A new target, or null for none (a drag), releases it.
class _Settled extends Animation<double> with AnimationWithParentMixin<double> {
  _Settled(this.parent, this._target);

  @override
  final Animation<double> parent;

  final double? Function() _target;
  double? _heldTarget;
  double _held = 0;
  bool _rising = true;

  @override
  double get value {
    final current = parent.value.clamp(0.0, 1.0);
    final target = _target();
    if (target == null || target != _heldTarget) {
      _heldTarget = target;
      _rising = target == null || target >= current;
      return _held = current;
    }
    return _held = _rising
        ? math.max(_held, current)
        : math.min(_held, current);
  }
}

class _NavigationRailState extends State<NavigationRail>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _expand = createMotionController(
    this,
    widget.expanded ? 1 : 0,
  )..addListener(_onThresholds);
  late final AnimationController _modal = createMotionController(this, 0)
    ..addListener(_onModalTick);
  // Predictive back progress.
  late final AnimationController _back = AnimationController(vsync: this);
  late final Animation<double> _expandView = _Settled(
    _expand,
    () => widget.expanded ? 1 : 0,
  );
  late final Animation<double> _modalView = _Settled(
    _modal,
    () => _dragging ? null : (_modalOpen ? 1 : 0),
  );
  // Whether the user drags the modal, which it then follows as it is.
  bool _dragging = false;

  final List<AnimationController> _selection = [];
  final List<AnimationController> _labels = [];
  final List<double> _selectionTargets = [];
  final List<double> _labelTargets = [];

  final OverlayPortalController _portal = OverlayPortalController();
  final FocusScopeNode _modalScope = FocusScopeNode(
    debugLabel: 'NavigationRail modal',
  );
  final RailMetrics _inlineMetrics = RailMetrics();
  final RailMetrics _modalMetrics = RailMetrics();

  NavigationRailController? _ownController;
  NavigationRailController get _controller =>
      widget.controller ?? (_ownController ??= NavigationRailController());

  // The style of the last build, for callbacks that run between builds.
  late NavigationRailStyle _style;

  bool _modalOpen = false;
  bool _modalShown = false;
  // Whether the open modal's content slides in with its background, rather
  // than expanding in place from the collapsed rail: fixed when it opens.
  bool _slide = false;
  Completer<void>? _modalClosed;
  FocusNode? _focusBeforeModal;
  AxisDirection _backEdge = AxisDirection.left;

  // Whether the slots shown only while expanded are showing, inline and in
  // the modal; the rebuild thresholds of the expansion.
  bool _inlineExpandedContent = false;
  bool _modalExpandedContent = false;

  @override
  void initState() {
    super.initState();
    _controller._attach(this);
    _inlineExpandedContent = widget.expanded;
  }

  @override
  void didUpdateWidget(NavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      final previous = oldWidget.controller ?? _ownController;
      previous?._detach(this);
      _controller._attach(this);
      if (_modalOpen) {
        previous?._notify();
        _controller._notify();
      }
    }
    if (widget.expanded != oldWidget.expanded) {
      final motion = _resolveStyle(context).motion!;
      if (widget.expanded && _modalOpen) {
        // The modal becomes the in-place rail from where it is.
        _expand.value = _modal.value;
        _closeModal(animate: false);
      }
      animateWithMotion(
        _expand,
        motion,
        MotionRole.defaultSpatial,
        widget.expanded ? 1 : 0,
      );
    }
  }

  @override
  void dispose() {
    _controller._detach(this);
    if (_modalOpen) {
      WidgetsBinding.instance.removeObserver(this);
      _modalClosed?.complete();
      _controller._notify();
    }
    _ownController?.dispose();
    _expand.dispose();
    _modal.dispose();
    _back.dispose();
    for (final controller in [..._selection, ..._labels]) {
      controller.dispose();
    }
    _modalScope.dispose();
    super.dispose();
  }

  void _onThresholds() {
    final inline = _expand.value > 0.5;
    if (inline != _inlineExpandedContent) {
      setState(() => _inlineExpandedContent = inline);
    }
  }

  void _onModalTick() {
    final modal = _slide || _modal.value > 0.5;
    if (modal != _modalExpandedContent && _modalShown) {
      setState(() => _modalExpandedContent = modal);
    }
  }

  // Shows or hides the overlay; deferred to after the frame when asked while
  // building.
  void _syncOverlay() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncOverlay();
      });
      return;
    }
    if (_modalShown == _portal.isShowing) return;
    if (_modalShown) {
      _portal.show();
    } else {
      _portal.hide();
    }
  }

  Future<void> _openModal() {
    if (widget.expanded) return Future<void>.value();
    if (_modalOpen) return _modalClosed!.future;
    final closed = _modalClosed = Completer<void>();
    // Reopened while it closes, the modal still has the focus to return to.
    _focusBeforeModal ??= FocusManager.instance.primaryFocus;
    setState(() {
      _modalOpen = true;
      _modalShown = true;
      _slide = _style.minWidth! == 0;
      _modalExpandedContent = _slide;
    });
    _back.value = 0;
    _syncOverlay();
    WidgetsBinding.instance.addObserver(this);
    animateWithMotion(_modal, _style.motion!, MotionRole.fastSpatial, 1);
    // Focus moves to the modal's first interactive element.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_modalOpen) return;
      _modalScope.requestFocus();
      if (_modalScope.focusedChild == null) _modalScope.nextFocus();
    });
    _controller._notify();
    return closed.future;
  }

  void _closeModal({bool animate = true}) {
    if (!_modalOpen) return;
    _modalOpen = false;
    // A drag in progress lets go: the modal closes on its own spring.
    _dragging = false;
    WidgetsBinding.instance.removeObserver(this);
    final closed = _modalClosed;
    _modalClosed = null;
    if (animate) {
      animateWithMotion(
        _modal,
        _style.motion!,
        MotionRole.fastSpatial,
        0,
      ).whenCompleteOrCancel(() {
        if (mounted && !_modalOpen) _hideModal();
      });
      if (mounted) setState(() {});
    } else {
      _modal.value = 0;
      _hideModal();
    }
    closed?.complete();
    _controller._notify();
  }

  void _hideModal() {
    if (!_modalShown) return;
    _modalShown = false;
    _modalExpandedContent = false;
    _back.value = 0;
    // Focus returns once the content is back in the rail, where it can take
    // focus again.
    final restore = _focusBeforeModal;
    _focusBeforeModal = null;
    if (restore != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (restore.context != null) restore.requestFocus();
      });
    }
    _syncOverlay();
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      setState(() {});
    }
  }

  // Predictive back.

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (!_modalOpen) return false;
    _backEdge = backEvent.isButtonEvent
        ? AxisDirection.left
        : backEvent.swipeEdge == SwipeEdge.left
        ? AxisDirection.left
        : AxisDirection.right;
    _back.value = 0;
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    _back.value = const Cubic(0.1, 0.1, 0, 1).transform(backEvent.progress);
  }

  @override
  void handleCommitBackGesture() {
    _closeModal();
    // The modal closes from where the gesture left it, easing back to its
    // full size on the close's spring, so its content returns to the rail
    // at its own size.
    animateWithMotion(_back, _style.motion!, MotionRole.fastSpatial, 0);
  }

  @override
  void handleCancelBackGesture() =>
      animateWithMotion(_back, _style.motion!, MotionRole.fastSpatial, 0);

  @override
  Future<bool> didPopRoute() async {
    if (!_modalOpen) return false;
    _closeModal();
    return true;
  }

  NavigationRailStyle _resolveStyle(BuildContext context) {
    final w = widget;
    final style = NavigationRailStyle.of(context, w.style);
    // The selected or unselected override, over the style's own value for
    // the same states.
    WidgetStateProperty<T?>? bySelection<T>(
      WidgetStateProperty<T?>? base,
      T? selected,
      T? unselected,
      T Function(T base, T override) merge,
    ) => selected == null && unselected == null
        ? base
        : WidgetStateProperty.resolveWith((states) {
            final under = base?.resolve(states);
            final over = states.contains(WidgetState.selected)
                ? selected
                : unselected;
            return under == null || over == null
                ? over ?? under
                : merge(under, over);
          });
    return style.merge(
      NavigationRailStyle(
        backgroundColor: w.backgroundColor,
        elevation: w.elevation,
        indicatorColor: w.indicatorColor,
        indicatorShape: w.indicatorShape,
        useIndicator: w.useIndicator,
        minWidth: w.minWidth,
        minExpandedWidth: w.minExpandedWidth,
        groupAlignment: w.groupAlignment,
        labelType: w.labelType,
        scrollable: w.scrollable,
        motion: w.motion,
        iconTheme: bySelection(
          style.iconTheme,
          w.selectedIconTheme,
          w.unselectedIconTheme,
          (base, override) => base.merge(override),
        ),
        labelTextStyle: bySelection(
          style.labelTextStyle,
          w.selectedLabelTextStyle,
          w.unselectedLabelTextStyle,
          (base, override) => base.merge(override),
        ),
      ),
    );
  }

  static double _labelTarget(NavigationRailLabelType type, bool selected) =>
      switch (type) {
        NavigationRailLabelType.all => 1,
        NavigationRailLabelType.selected => selected ? 1 : 0,
        NavigationRailLabelType.none => 0,
      };

  // Moves the selection and label animations toward what the widget and its
  // style now ask for.
  void _sync(NavigationRailStyle style) {
    final count =
        widget.destinations.length + widget.secondaryDestinations.length;
    final type = style.labelType!;
    if (_selection.length > count) {
      final removed = [..._selection.sublist(count), ..._labels.sublist(count)];
      _selection.removeRange(count, _selection.length);
      _labels.removeRange(count, _labels.length);
      _selectionTargets.removeRange(count, _selectionTargets.length);
      _labelTargets.removeRange(count, _labelTargets.length);
      // Their destinations still listen until this build replaces them.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        for (final controller in removed) {
          controller.dispose();
        }
      });
    }
    for (var i = _selection.length; i < count; i++) {
      final selected = i == widget.selectedIndex;
      final label = _labelTarget(type, selected);
      _selection.add(createMotionController(this, selected ? 1 : 0));
      _labels.add(createMotionController(this, label));
      _selectionTargets.add(selected ? 1 : 0);
      _labelTargets.add(label);
    }
    for (var i = 0; i < count; i++) {
      final selected = i == widget.selectedIndex;
      final selection = selected ? 1.0 : 0.0;
      if (selection != _selectionTargets[i]) {
        _selectionTargets[i] = selection;
        animateWithMotion(
          _selection[i],
          style.motion!,
          MotionRole.defaultSpatial,
          selection,
        );
      }
      final label = _labelTarget(type, selected);
      if (label != _labelTargets[i]) {
        _labelTargets[i] = label;
        animateWithMotion(
          _labels[i],
          style.motion!,
          MotionRole.defaultEffects,
          label,
        );
      }
    }
  }

  // The expanded width the widest destination needs, its label in
  // the selected and the unselected style. A badge beside a label is not
  // measured: the label wraps to make room for it.
  double _fitWidth(BuildContext context, NavigationRailStyle style) {
    final scaler = MediaQuery.textScalerOf(context);
    final max = style.maxLabelScale;
    final textScaler = max == null ? scaler : scaler.clamp(maxScaleFactor: max);
    final labelStyles = {
      for (final states in [
        const {WidgetState.selected},
        const <WidgetState>{},
      ])
        style.horizontalLabelStyle!.merge(
          style.labelTextStyle?.resolve(states),
        ),
    };
    var widest = 0.0;
    for (final destination in [
      ...widget.destinations,
      ...widget.secondaryDestinations,
    ]) {
      for (final labelStyle in labelStyles) {
        widest = math.max(
          widest,
          measureLabel(
            destination.label,
            style: labelStyle,
            textDirection: Directionality.of(context),
            textScaler: textScaler,
            locale: Localizations.maybeLocaleOf(context),
            boldText: MediaQuery.boldTextOf(context),
          ).width,
        );
      }
    }
    return 2 * style.itemHorizontalPadding! +
        style.horizontalLeadingSpace! +
        style.iconSize! +
        style.horizontalIconLabelSpacing! +
        widest +
        style.horizontalTrailingSpace!;
  }

  ItemStyle _itemStyle(NavigationRailStyle style) => ItemStyle(
    iconSize: style.iconSize!,
    selectedIconColor: style.selectedIconColor!,
    unselectedIconColor: style.unselectedIconColor!,
    selectedLabelColor: style.selectedLabelColor!,
    horizontalSelectedLabelColor: style.horizontalSelectedLabelColor!,
    unselectedLabelColor: style.unselectedLabelColor!,
    disabledColor: style.disabledColor!,
    labelStyle: style.labelStyle!,
    horizontalLabelStyle: style.horizontalLabelStyle!,
    labelMaxLines: style.labelMaxLines,
    labelOverflow: style.labelOverflow!,
    maxLabelScale: style.maxLabelScale,
    indicatorColor: style.indicatorColor!,
    indicatorShape: style.indicatorShape!,
    useIndicator: style.useIndicator!,
    overlayColor: ItemStyle.stateLayer(
      color: style.stateLayerColor!,
      hoverOpacity: style.hoverOpacity!,
      focusOpacity: style.focusOpacity!,
      pressedOpacity: style.pressedOpacity!,
      custom: style.overlayColor,
    ),
    iconTheme: style.iconTheme,
    labelTextStyle: style.labelTextStyle,
    motion: style.motion!,
  );

  @override
  Widget build(BuildContext context) {
    final style = _style = _resolveStyle(context);
    _sync(style);
    final textDirection = Directionality.of(context);
    // A rail without a collapsed width shows nothing until it is halfway
    // expanded: until then, its content takes neither focus nor a screen
    // reader's attention.
    final hidden = style.minWidth! == 0 && !_inlineExpandedContent;
    final fitWidth = _fitWidth(context, style);
    final measures = _Measures(
      style: style,
      itemStyle: _itemStyle(style),
      fitWidth: fitWidth,
      targetWidth: style.expandedWidth ?? _clampWidth(fitWidth, style),
      textDirection: textDirection,
    );
    final inline = _RailScope(
      controller: _controller,
      expandedAnimation: _expandView,
      child: _surface(
        style: style,
        textDirection: textDirection,
        // A collapsed width of 0 leaves the content nowhere to be but out
        // of bounds.
        child: ClipRect(
          // While the modal shows, the rail keeps only its footprint: its
          // content is in the modal, moved there with its state when both use
          // the same layout, so no widget is built twice.
          child: _modalShown
              ? _footprint(measures, _expandView)
              : ExcludeSemantics(
                  excluding: hidden,
                  child: ExcludeFocus(
                    excluding: hidden,
                    child: _frame(
                      measures,
                      key: _sharedContentKey,
                      morph: _expandView,
                      layout: widget.layout,
                      modal: false,
                    ),
                  ),
                ),
        ),
      ),
    );
    return Semantics(
      // The overlay's semantics are read in place of the rail's; they need
      // a node of their own under a parent keeping its children explicit.
      container: true,
      explicitChildNodes: true,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => _buildModal(context, measures),
        child: inline,
      ),
    );
  }

  // The rail's container: its color, its elevation, and its divider.
  Widget _surface({
    required NavigationRailStyle style,
    required TextDirection textDirection,
    required Widget child,
  }) {
    final divider = style.divider;
    final ltr = textDirection == TextDirection.ltr;
    Widget content = SafeArea(
      left: ltr,
      right: !ltr,
      bottom: style.applyBottomInset!,
      child: child,
    );
    if (divider != null) {
      content = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: BorderDirectional(end: divider)),
        child: content,
      );
    }
    return Material(
      color: style.backgroundColor,
      elevation: style.elevation!,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: content,
    );
  }

  // Moves the content between the rail and the modal when they share a
  // layout.
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'NavigationRail content');

  GlobalKey? get _sharedContentKey =>
      widget.modalLayout == null ? _contentKey : null;

  // A frame as wide as the rail, with nothing in it.
  Widget _footprint(_Measures measures, Animation<double> morph) {
    final style = measures.style;
    return RailFrame(
      morph: morph,
      collapsedWidth: style.minWidth!,
      expandedWidth: style.expandedWidth,
      fitWidth: measures.fitWidth,
      minExpandedWidth: style.minExpandedWidth!,
      maxExpandedWidth: style.maxExpandedWidth!,
      topSpace: 0,
      metrics: _inlineMetrics,
      header: const SizedBox.shrink(),
      group: const SizedBox.shrink(),
      footer: const SizedBox.shrink(),
    );
  }

  Widget _frame(
    _Measures measures, {
    Key? key,
    required Animation<double> morph,
    required NavigationRailLayout layout,
    required bool modal,
  }) {
    final style = measures.style;
    final expandedContent = modal
        ? _modalExpandedContent
        : _inlineExpandedContent;
    final collapsedWidth = style.minWidth!;
    final pinWidth = collapsedWidth > 0
        ? collapsedWidth
        : style.verticalIndicatorWidth! + 2 * style.itemHorizontalPadding!;
    final fitWidth = measures.fitWidth;
    final targetWidth = measures.targetWidth;
    final geometry = ItemGeometry(
      topIndicatorSize: style.labelType == NavigationRailLabelType.none
          ? Size.square(style.noLabelIndicatorSize!)
          : Size(style.verticalIndicatorWidth!, style.verticalIndicatorHeight!),
      labelPadding: style.labelPadding!.resolve(measures.textDirection),
      topPadding: 0,
      topMinHeight: style.collapsedItemMinHeight!,
      topBoxWidth: pinWidth,
      topAnchored: false,
      startIndicatorHeight: style.horizontalIndicatorHeight!,
      startLeadingSpace: style.horizontalLeadingSpace!,
      startTrailingSpace: style.horizontalTrailingSpace!,
      startIconLabelSpacing: style.horizontalIconLabelSpacing!,
      startBadgeSpacing: style.badgeLabelSpacing!,
      startInset: style.itemHorizontalPadding!,
      startAnchored: true,
      startFill: style.expandedIndicatorSize == NavigationIndicatorSize.fill,
      startMinHeight: style.expandedItemMinHeight!,
      expandedWidth: targetWidth,
      labelShownInStartForm: true,
    );
    final select = widget.onDestinationSelected;

    Widget destinations(List<NavigationDestination> list, int first) =>
        RailDestinationList(
          morph: morph,
          itemSpace: style.itemSpace!,
          isTabBar: select != null,
          children: [
            for (var i = 0; i < list.length; i++)
              DestinationScope(
                data: DestinationData(
                  index: i,
                  count: list.length,
                  selected: first + i == widget.selectedIndex,
                  onTap: select == null
                      ? null
                      : () {
                          select(first + i);
                          if (modal) _closeModal();
                        },
                  morph: morph,
                  selection: _selection[first + i],
                  labelVisibility: _labels[first + i],
                  geometry: geometry,
                  style: measures.itemStyle,
                ),
                child: list[i],
              ),
          ],
        );

    (Widget, NavigationRailSlotVisibility)? resolve(NavigationRailSlot slot) =>
        switch (slot) {
          WidgetRailSlot(:final child, :final visibility) => (
            child,
            visibility,
          ),
          NamedRailSlot.leading =>
            widget.leading == null
                ? null
                : (
                    RailHeaderAlign(
                      morph: morph,
                      pinWidth: pinWidth,
                      child: widget.leading,
                    ),
                    NavigationRailSlotVisibility.always,
                  ),
          NamedRailSlot.floatingActionButton =>
            widget.floatingActionButton == null
                ? null
                : (
                    RailHeaderAlign(
                      morph: morph,
                      pinWidth: pinWidth,
                      expandedInset: style.itemHorizontalPadding,
                      child: widget.floatingActionButton,
                    ),
                    NavigationRailSlotVisibility.always,
                  ),
          NamedRailSlot.destinations =>
            widget.destinations.isEmpty
                ? null
                : (
                    destinations(widget.destinations, 0),
                    NavigationRailSlotVisibility.always,
                  ),
          NamedRailSlot.secondaryDestinations =>
            widget.secondaryDestinations.isEmpty
                ? null
                : (
                    destinations(
                      widget.secondaryDestinations,
                      widget.destinations.length,
                    ),
                    NavigationRailSlotVisibility.expanded,
                  ),
          NamedRailSlot.expandedBody =>
            widget.expandedBody == null
                ? null
                : (widget.expandedBody!, NavigationRailSlotVisibility.expanded),
          NamedRailSlot.trailing =>
            widget.trailing == null
                ? null
                : (widget.trailing!, NavigationRailSlotVisibility.always),
        };

    Widget column(
      List<NavigationRailSlot> slots, {
      double spacing = 0,
      double trailingSpace = 0,
      double? alignment,
      RailMetrics? metrics,
      bool clip = false,
    }) => RailColumn(
      morph: morph,
      spacing: spacing,
      trailingSpace: trailingSpace,
      revealWidth: targetWidth,
      alignment: alignment,
      metrics: metrics,
      clip: clip,
      children: [
        for (final (index, slot) in slots.indexed)
          if (resolve(slot) case (final child, final visibility))
            RailColumnChild(
              key: ValueKey<Object>(slot is NamedRailSlot ? slot : index),
              visibility: visibility,
              child: ExcludeFocus(
                excluding: switch (visibility) {
                  NavigationRailSlotVisibility.always => false,
                  NavigationRailSlotVisibility.expanded => !expandedContent,
                  NavigationRailSlotVisibility.collapsed => expandedContent,
                },
                child: child,
              ),
            ),
      ],
    );

    final scrollable = style.scrollable!;
    final group = column(
      layout.group,
      alignment: style.groupAlignment,
      metrics: modal ? _modalMetrics : _inlineMetrics,
      clip: !scrollable,
    );
    // A destination anywhere else in the rail, such as its trailing widget,
    // is laid out as the rail's destinations are, and never selected.
    return DestinationScope(
      key: key,
      data: DestinationData(
        index: null,
        count: 0,
        selected: false,
        onTap: modal ? _closeModal : null,
        morph: morph,
        selection: kAlwaysDismissedAnimation,
        labelVisibility: style.labelType == NavigationRailLabelType.all
            ? kAlwaysCompleteAnimation
            : kAlwaysDismissedAnimation,
        geometry: geometry,
        style: measures.itemStyle,
      ),
      child: RailFrame(
        morph: morph,
        collapsedWidth: collapsedWidth,
        expandedWidth: style.expandedWidth,
        fitWidth: fitWidth,
        minExpandedWidth: style.minExpandedWidth!,
        maxExpandedWidth: style.maxExpandedWidth!,
        topSpace: style.topSpace!,
        metrics: modal ? _modalMetrics : _inlineMetrics,
        header: column(
          layout.header,
          spacing: style.headerItemSpacing!,
          trailingSpace: style.headerSpace!,
        ),
        group: scrollable ? SingleChildScrollView(child: group) : group,
        footer: column(layout.footer),
      ),
    );
  }

  Widget _buildModal(BuildContext context, _Measures measures) {
    final style = measures.style;
    final textDirection = measures.textDirection;
    final ltr = textDirection == TextDirection.ltr;
    final slide = _slide;
    final targetWidth = measures.targetWidth;
    final morph = slide ? kAlwaysCompleteAnimation : _modalView;
    final localizations = MaterialLocalizations.of(context);

    // Closing while building, the overlay is rebuilt once more before it
    // hides; the content is back in the rail by then.
    if (!_modalShown) return const SizedBox.shrink();
    final frame = _frame(
      measures,
      key: _sharedContentKey,
      morph: morph,
      layout: widget.modalLayout ?? widget.layout,
      modal: true,
    );
    Widget content = Material(
      type: MaterialType.transparency,
      child: SafeArea(
        left: ltr,
        right: !ltr,
        bottom: style.applyBottomInset!,
        child: frame,
      ),
    );
    if (slide) {
      // Dragged toward its edge, the modal follows, and closes past half
      // way or on a fling. Once it closes, by the drag or by
      // anything else, the drag no longer moves it.
      content = GestureDetector(
        onHorizontalDragStart: (_) => _dragging = _modalOpen,
        onHorizontalDragUpdate: (details) {
          if (!_dragging) return;
          final delta = details.primaryDelta! / targetWidth;
          _modal.value = (_modal.value + (ltr ? delta : -delta)).clamp(
            0.0,
            1.0,
          );
        },
        onHorizontalDragEnd: (details) {
          if (!_dragging) return;
          _dragging = false;
          final velocity = details.primaryVelocity! * (ltr ? 1 : -1);
          if (velocity < -kMinFlingVelocity || _modal.value < 0.5) {
            _closeModal();
          } else {
            animateWithMotion(
              _modal,
              style.motion!,
              MotionRole.defaultSpatial,
              1,
            );
          }
        },
        onHorizontalDragCancel: () => _dragging = false,
        child: content,
      );
    }
    final background = Material(
      color: style.modalBackgroundColor,
      elevation: style.modalElevation!,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: style.modalShape,
    );
    final layers = AnimatedBuilder(
      animation: Listenable.merge([_modal, _back]),
      child: content,
      builder: (context, content) {
        final t = _modalView.value;
        // The background slides in from off-screen. As the spring overshoots,
        // only its trailing edge moves on, stretching it, and settles back.
        final overshoot = math.max(0.0, _modal.value - 1);
        final start = (t - 1) * targetWidth;
        // As a back gesture progresses, the background scales around its
        // leading edge, 24dp wider when the swipe comes from the rail's side
        // and 24dp narrower from the other, and 48dp shorter; the content
        // scales with its height, keeping its aspect.
        final progress = _back.value;
        final height = MediaQuery.sizeOf(context).height;
        final fromRailSide = (_backEdge == AxisDirection.left) == ltr;
        final scaleX =
            1 +
            (fromRailSide ? 1 : -1) *
                math.min(24.0, targetWidth) *
                progress /
                targetWidth;
        final scaleY = 1 - math.min(48.0, height) * progress / height;
        final leading = ltr ? Alignment.centerLeft : Alignment.centerRight;
        return Stack(
          children: [
            PositionedDirectional(
              top: 0,
              bottom: 0,
              start: start,
              width: targetWidth * (1 + overshoot),
              child: Transform(
                alignment: leading,
                transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
                child: background,
              ),
            ),
            // With a collapsed rail, the destinations morph where they are
            // while the background arrives; without one, they arrive with it.
            PositionedDirectional(
              top: 0,
              bottom: 0,
              start: slide ? start : 0,
              child: Transform(
                alignment: leading,
                transform: Matrix4.diagonal3Values(scaleY, scaleY, 1),
                child: content,
              ),
            ),
          ],
        );
      },
    );

    return _RailScope(
      controller: _controller,
      expandedAnimation: morph,
      child: PopScope(
        canPop: !_modalOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeModal();
        },
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  _closeModal();
                  return null;
                },
              ),
            },
            child: FocusScope(
              node: _modalScope,
              child: Semantics(
                // A container, so the barrier's blocking stops at the modal.
                container: true,
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: localizations.drawerLabel,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedModalBarrier(
                        color: _modalView.drive(
                          ColorTween(
                            begin: style.scrimColor!.withValues(alpha: 0),
                            end: style.scrimColor,
                          ),
                        ),
                        dismissible: true,
                        onDismiss: _closeModal,
                        semanticsLabel: localizations.modalBarrierDismissLabel,
                      ),
                    ),
                    Positioned.fill(child: layers),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The fitted expanded width within the style's bounds, where a minimum above
// the maximum wins.
double _clampWidth(double fit, NavigationRailStyle style) => fit.clamp(
  style.minExpandedWidth!,
  math.max(style.minExpandedWidth!, style.maxExpandedWidth!),
);

// What one build of the rail resolves once for both of its surfaces.
class _Measures {
  _Measures({
    required this.style,
    required this.itemStyle,
    required this.fitWidth,
    required this.targetWidth,
    required this.textDirection,
  });

  final NavigationRailStyle style;
  final ItemStyle itemStyle;
  final double fitWidth;
  // The expanded width.
  final double targetWidth;
  final TextDirection textDirection;
}
