// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Which of a [NavigationMotion]'s springs a transition uses.
enum MotionRole {
  /// Movement across the component.
  defaultSpatial,

  /// Quick movement.
  fastSpatial,

  /// Color and opacity.
  defaultEffects,
}

/// A controller for a transition driven by a [NavigationMotion].
///
/// Unbounded, so that an underdamped spring can overshoot its target before
/// it settles.
AnimationController createMotionController(
  TickerProvider vsync,
  double value,
) => AnimationController.unbounded(vsync: vsync, value: value);

/// Animates [controller] to [target] with the spring [motion] gives [role], or
/// with its duration and curve.
///
/// A spring starts from the controller's current value and velocity, so an
/// interrupted transition carries its momentum into the new one.
TickerFuture animateWithMotion(
  AnimationController controller,
  NavigationMotion motion,
  MotionRole role,
  double target,
) {
  final spring = switch (role) {
    MotionRole.defaultSpatial => motion.defaultSpatial,
    MotionRole.fastSpatial => motion.fastSpatial,
    MotionRole.defaultEffects => motion.defaultEffects,
  };
  if (spring == null) {
    return controller.animateTo(
      target,
      duration: motion.duration,
      curve: motion.curve!,
    );
  }
  return controller.animateWith(
    SpringSimulation(
      spring,
      controller.value,
      target,
      controller.velocity,
      snapToEnd: true,
    ),
  );
}
