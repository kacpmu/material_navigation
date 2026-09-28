// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// How a navigation component animates: with springs, or with a duration and
/// a curve.
///
/// Material 3 Expressive animates with springs. Each component uses
/// three of them: [defaultSpatial] for movement across the component, such as
/// the rail expanding and the active indicator growing; [fastSpatial] for
/// quick movement, such as the modal rail opening; and [defaultEffects] for
/// color and opacity, which never overshoot.
///
/// ```dart
/// NavigationRail(
///   motion: const NavigationMotion.standard(),
///   // ...
/// )
/// ```
@immutable
final class NavigationMotion with Diagnosticable {
  /// Creates a motion from three springs.
  const NavigationMotion({
    required SpringDescription this.defaultSpatial,
    required SpringDescription this.fastSpatial,
    required SpringDescription this.defaultEffects,
  }) : duration = null,
       curve = null;

  /// The Material 3 Expressive motion scheme, the default.
  ///
  /// Its spatial springs are underdamped and overshoot a little before they
  /// settle.
  const NavigationMotion.expressive()
    : this(
        defaultSpatial: expressiveDefaultSpatial,
        fastSpatial: expressiveFastSpatial,
        defaultEffects: expressiveDefaultEffects,
      );

  /// The Material 3 standard motion scheme.
  ///
  /// Stiffer and more damped than [NavigationMotion.expressive], so movement
  /// settles sooner and barely overshoots.
  const NavigationMotion.standard()
    : this(
        defaultSpatial: standardDefaultSpatial,
        fastSpatial: standardFastSpatial,
        defaultEffects: standardDefaultEffects,
      );

  /// A fixed [duration] eased by [curve], for every transition.
  ///
  /// Unlike a spring, an interrupted transition restarts the full duration
  /// from where it was. The navigation bar's `animationDuration` selects this
  /// motion for its selection.
  const NavigationMotion.easing({
    Duration this.duration = const Duration(milliseconds: 500),
    Curve this.curve = Curves.easeInOutCubicEmphasized,
  }) : defaultSpatial = null,
       fastSpatial = null,
       defaultEffects = null;

  const NavigationMotion._({
    required this.defaultSpatial,
    required this.fastSpatial,
    required this.defaultEffects,
    required this.duration,
    required this.curve,
  }) : assert(
         (defaultSpatial != null &&
                 fastSpatial != null &&
                 defaultEffects != null &&
                 duration == null &&
                 curve == null) ||
             (defaultSpatial == null &&
                 fastSpatial == null &&
                 defaultEffects == null &&
                 duration != null &&
                 curve != null),
         'A NavigationMotion has either three springs or a duration and a '
         'curve.',
       );

  /// The Material 3 Expressive default spatial spring: stiffness 380, damping
  /// ratio 0.8.
  static const SpringDescription expressiveDefaultSpatial = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 31.189742,
  );

  /// The Material 3 Expressive fast spatial spring: stiffness 800, damping
  /// ratio 0.6.
  static const SpringDescription expressiveFastSpatial = SpringDescription(
    mass: 1,
    stiffness: 800,
    damping: 33.941125,
  );

  /// The Material 3 Expressive default effects spring: stiffness 1600,
  /// critically damped.
  static const SpringDescription expressiveDefaultEffects = SpringDescription(
    mass: 1,
    stiffness: 1600,
    damping: 80,
  );

  /// The Material 3 standard default spatial spring: stiffness 700, damping
  /// ratio 0.9.
  static const SpringDescription standardDefaultSpatial = SpringDescription(
    mass: 1,
    stiffness: 700,
    damping: 47.623524,
  );

  /// The Material 3 standard fast spatial spring: stiffness 1400, damping
  /// ratio 0.9.
  static const SpringDescription standardFastSpatial = SpringDescription(
    mass: 1,
    stiffness: 1400,
    damping: 67.349833,
  );

  /// The Material 3 standard default effects spring, the same as
  /// [expressiveDefaultEffects].
  static const SpringDescription standardDefaultEffects =
      expressiveDefaultEffects;

  /// The spring for movement across the component, or null for an easing
  /// motion.
  final SpringDescription? defaultSpatial;

  /// The spring for quick movement, or null for an easing motion.
  final SpringDescription? fastSpatial;

  /// The spring for color and opacity, or null for an easing motion.
  final SpringDescription? defaultEffects;

  /// The duration of every transition, or null for a spring motion.
  final Duration? duration;

  /// The easing of every transition, or null for a spring motion.
  final Curve? curve;

  /// A copy of this motion with the given fields replaced.
  ///
  /// The result must still be a spring motion or an easing motion.
  NavigationMotion copyWith({
    SpringDescription? defaultSpatial,
    SpringDescription? fastSpatial,
    SpringDescription? defaultEffects,
    Duration? duration,
    Curve? curve,
  }) => NavigationMotion._(
    defaultSpatial: defaultSpatial ?? this.defaultSpatial,
    fastSpatial: fastSpatial ?? this.fastSpatial,
    defaultEffects: defaultEffects ?? this.defaultEffects,
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
  );

  @override
  bool operator ==(Object other) =>
      other is NavigationMotion &&
      _springEquals(other.defaultSpatial, defaultSpatial) &&
      _springEquals(other.fastSpatial, fastSpatial) &&
      _springEquals(other.defaultEffects, defaultEffects) &&
      other.duration == duration &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(
    _springHash(defaultSpatial),
    _springHash(fastSpatial),
    _springHash(defaultEffects),
    duration,
    curve,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<SpringDescription>(
          'defaultSpatial',
          defaultSpatial,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<SpringDescription>(
          'fastSpatial',
          fastSpatial,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<SpringDescription>(
          'defaultEffects',
          defaultEffects,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>('duration', duration, defaultValue: null),
      )
      ..add(DiagnosticsProperty<Curve>('curve', curve, defaultValue: null));
  }
}

// SpringDescription has no value equality.
bool _springEquals(SpringDescription? a, SpringDescription? b) =>
    identical(a, b) ||
    (a != null &&
        b != null &&
        a.mass == b.mass &&
        a.stiffness == b.stiffness &&
        a.damping == b.damping);

int _springHash(SpringDescription? spring) => spring == null
    ? 0
    : Object.hash(spring.mass, spring.stiffness, spring.damping);
