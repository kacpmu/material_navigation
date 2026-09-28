// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

// The measured size of a destination label.
//
// A rail measures every label in the expanded style to fit its width, and each
// of its destinations measures its own while collapsed, so the same string is
// measured several times per build. Results are memoized on everything that
// can change them, and painters are disposed as soon as they are read.
typedef _LabelKey = (
  String text,
  TextStyle? style,
  TextDirection textDirection,
  TextScaler textScaler,
  Locale? locale,
  int? maxLines,
  double maxWidth,
  bool boldText,
);

// Bounded so labels that change every frame cannot grow it without limit;
// entries are evicted oldest-first.
const int _maxEntries = 256;
final Map<_LabelKey, Size> _cache = <_LabelKey, Size>{};

// A font loaded after a measurement — a web font arriving, or the platform's
// fonts changing — invalidates every size taken before it.
bool _watchingFonts = false;
void _watchFonts() {
  if (_watchingFonts) return;
  _watchingFonts = true;
  PaintingBinding.instance.systemFonts.addListener(_cache.clear);
}

Size _measure(_LabelKey key) {
  _watchFonts();
  final hit = _cache[key];
  if (hit != null) return hit;
  final (
    text,
    style,
    textDirection,
    textScaler,
    locale,
    maxLines,
    maxWidth,
    boldText,
  ) = key;
  // [Text] applies the bold-text accessibility setting itself, so a
  // measurement that ignored it would come out narrow.
  final effective = boldText
      ? (style ?? const TextStyle()).merge(
          const TextStyle(fontWeight: FontWeight.bold),
        )
      : style;
  final painter = TextPainter(
    text: TextSpan(text: text, style: effective),
    maxLines: maxLines,
    textDirection: textDirection,
    textScaler: textScaler,
    locale: locale,
  )..layout(maxWidth: maxWidth);
  final size = painter.size;
  painter.dispose();
  if (_cache.length >= _maxEntries) _cache.remove(_cache.keys.first);
  _cache[key] = size;
  return size;
}

/// The size [text] occupies under [style], wrapped to [maxWidth] (unbounded
/// unless given) in at most [maxLines] lines, or any number when null.
///
/// A label that fits [maxWidth] on one line is measured once, unbounded, so a
/// width that changes costs nothing for labels that fit.
Size measureLabel(
  String text, {
  required TextStyle? style,
  required TextDirection textDirection,
  required TextScaler textScaler,
  Locale? locale,
  int? maxLines,
  double maxWidth = double.infinity,
  bool boldText = false,
}) {
  final line = _measure((
    text,
    style,
    textDirection,
    textScaler,
    locale,
    maxLines,
    double.infinity,
    boldText,
  ));
  if (line.width <= maxWidth + precisionErrorTolerance) return line;
  return _measure((
    text,
    style,
    textDirection,
    textScaler,
    locale,
    maxLines,
    maxWidth,
    boldText,
  ));
}
