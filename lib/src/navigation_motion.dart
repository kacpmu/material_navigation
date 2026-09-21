import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// The motion that drives a navigation component between its two layouts.
///
/// Controls how a [NavigationBar] morphs between vertical and horizontal and
/// how a [NavigationRail] morphs between collapsed and expanded.
///
/// Choose between two feels with the component's `motion` parameter:
///
///  * [NavigationMotion.expressive] follows the Material 3 Expressive motion
///    system: a spatial spring that feels lively and reacts to interruption with
///    real velocity. Components use this unless a motion is supplied.
///  * [NavigationMotion.standard] is the non-expressive feel: a fixed duration
///    eased by Material 3's emphasized curve.
///
/// ```dart
/// // Material 3 Expressive spatial spring:
/// NavigationRail(motion: const NavigationMotion.expressive(), ...);
/// // The non-expressive feel:
/// NavigationRail(motion: const NavigationMotion.standard(), ...);
/// ```
@immutable
sealed class NavigationMotion {
  /// Abstract const constructor for subclasses.
  const NavigationMotion();

  /// Material 3 Expressive motion, driven by a spring simulation.
  ///
  /// When [spring] is omitted, the Material 3 Expressive default spatial spring
  /// ([defaultSpatial]) drives the transition: an underdamped spring that
  /// overshoots a little before settling, carrying gesture velocity through
  /// interruptions. Pass [fastSpatial], or a custom [SpringDescription], for a
  /// quicker, softer or bouncier feel.
  const factory NavigationMotion.expressive({SpringDescription spring}) =
      _SpringMotion;

  /// The Material 3 Expressive default spatial spring: stiffness 380, damping
  /// ratio 0.8.
  ///
  /// Used for movement across a component, such as the inline rail expanding
  /// and the bar's item morph.
  static const SpringDescription defaultSpatial =
      SpringDescription(mass: 1, stiffness: 380, damping: 31.19);

  /// The Material 3 Expressive fast spatial spring: stiffness 800, damping ratio
  /// 0.6.
  ///
  /// Used for small or quick movements, such as the modal rail sliding in.
  static const SpringDescription fastSpatial =
      SpringDescription(mass: 1, stiffness: 800, damping: 33.94);

  /// The non-expressive motion: a fixed [duration] eased by an emphasized
  /// [curve].
  ///
  /// When omitted, [duration] is 300ms and [curve] is the Material 3 emphasized
  /// easing ([Curves.easeInOutCubicEmphasized]), within the M3 emphasized range
  /// of ~300-500ms.
  const factory NavigationMotion.standard({Duration duration, Curve curve}) =
      _CurveMotion;

  /// The [AnimationController] for this motion, starting at [value]
  /// (0 for collapsed/vertical, 1 for expanded/horizontal).
  ///
  /// When [bounded] is false the value may travel outside 0..1, letting the
  /// Material 3 Expressive spatial spring overshoot before settling.
  AnimationController createController(TickerProvider vsync, double value,
      {bool bounded = true});

  /// Animates [controller] toward [target] (0 or 1) using this motion.
  ///
  /// Returns the [TickerFuture] that completes when the animation settles or is
  /// interrupted.
  TickerFuture animateTo(AnimationController controller, double target);
}

// Non-expressive motion: a fixed [duration] eased by a [curve].
class _CurveMotion extends NavigationMotion {
  const _CurveMotion({
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubicEmphasized,
  });

  final Duration duration;
  final Curve curve;

  @override
  AnimationController createController(TickerProvider vsync, double value,
          {bool bounded = true}) =>
      bounded
          ? AnimationController(vsync: vsync, value: value, duration: duration)
          : AnimationController.unbounded(
              vsync: vsync, value: value, duration: duration);

  @override
  TickerFuture animateTo(AnimationController controller, double target) =>
      controller.animateTo(target, duration: duration, curve: curve);

  @override
  bool operator ==(Object other) =>
      other is _CurveMotion &&
      other.duration == duration &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);
}

// Material 3 Expressive physics motion: a [spring] simulation.
class _SpringMotion extends NavigationMotion {
  const _SpringMotion({this.spring = NavigationMotion.defaultSpatial});

  final SpringDescription spring;

  @override
  AnimationController createController(TickerProvider vsync, double value,
          {bool bounded = true}) =>
      bounded
          ? AnimationController(vsync: vsync, value: value)
          : AnimationController.unbounded(vsync: vsync, value: value);

  @override
  TickerFuture animateTo(AnimationController controller, double target) =>
      controller.animateWith(
        SpringSimulation(spring, controller.value, target, controller.velocity),
      );

  @override
  bool operator ==(Object other) =>
      other is _SpringMotion && other.spring == spring;

  @override
  int get hashCode => spring.hashCode;
}
