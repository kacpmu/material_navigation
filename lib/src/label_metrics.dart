import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:material_ui/material_ui.dart';

// The measured size of a destination label.
//
// The containers measure every label to size themselves and each destination
// measures its own to size its pill, so the same string is laid out more than
// once per frame. Laying out text is not cheap during a morph, when it happens
// on every tick, so results are memoized on everything that can change them.
// Painters are disposed as soon as they are read: only the resulting size, and
// whether the text ran past its line limit, is kept.
typedef _LabelKey = (
  String text,
  TextStyle? style,
  TextDirection textDirection,
  TextScaler textScaler,
  Locale? locale,
  int maxLines,
  double maxWidth,
  bool boldText,
);

typedef _LabelMetrics = ({Size size, bool didExceedMaxLines});

// Bounded so a rail whose labels change every frame cannot grow it without
// limit; entries are evicted oldest-first.
const int _maxEntries = 256;
final Map<_LabelKey, _LabelMetrics> _cache = <_LabelKey, _LabelMetrics>{};

// A font loaded after a measurement — a web font arriving, or the platform's
// fonts changing — invalidates every size taken before it.
bool _watchingFonts = false;
void _watchFonts() {
  if (_watchingFonts) return;
  _watchingFonts = true;
  PaintingBinding.instance.systemFonts.addListener(_cache.clear);
}

_LabelMetrics _measure(
  String text, {
  required TextStyle? style,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required Locale? locale,
  required int maxLines,
  required double maxWidth,
  required bool boldText,
}) {
  _watchFonts();
  final key = (
    text,
    style,
    textDirection,
    textScaler,
    locale,
    maxLines,
    maxWidth,
    boldText
  );
  final hit = _cache[key];
  if (hit != null) return hit;
  // [Text] applies the bold-text accessibility setting itself, so a
  // measurement that ignored it would come out narrow.
  final effective = boldText
      ? (style ?? const TextStyle())
          .merge(const TextStyle(fontWeight: FontWeight.bold))
      : style;
  final painter = TextPainter(
    text: TextSpan(text: text, style: effective),
    maxLines: maxLines,
    textDirection: textDirection,
    textScaler: textScaler,
    locale: locale,
  )..layout(maxWidth: maxWidth);
  final metrics =
      (size: painter.size, didExceedMaxLines: painter.didExceedMaxLines);
  painter.dispose();
  if (_cache.length >= _maxEntries) {
    _cache.remove(_cache.keys.first);
  }
  _cache[key] = metrics;
  return metrics;
}

/// The size [text] occupies under [style], wrapped to [maxWidth] (unbounded
/// unless given) in at most [maxLines] lines.
///
/// A label that fits [maxWidth] on one line is measured once, unbounded, so a
/// width that changes every frame costs nothing for labels that fit.
Size measureLabel(
  String text, {
  required TextStyle? style,
  required TextDirection textDirection,
  required TextScaler textScaler,
  Locale? locale,
  int maxLines = 1,
  double maxWidth = double.infinity,
  bool boldText = false,
}) {
  final line = _measure(text,
          style: style,
          textDirection: textDirection,
          textScaler: textScaler,
          locale: locale,
          maxLines: maxLines,
          maxWidth: double.infinity,
          boldText: boldText)
      .size;
  if (line.width <= maxWidth + precisionErrorTolerance) return line;
  return _measure(text,
          style: style,
          textDirection: textDirection,
          textScaler: textScaler,
          locale: locale,
          maxLines: maxLines,
          maxWidth: maxWidth,
          boldText: boldText)
      .size;
}

/// Whether [text] cannot be shown in full in a box [available] logical pixels
/// wide: wrapped to that width, it needs more than [maxLines] lines.
bool labelOverflows(
  String text, {
  required double available,
  required TextStyle? style,
  required TextDirection textDirection,
  required TextScaler textScaler,
  Locale? locale,
  int maxLines = 1,
  bool boldText = false,
}) {
  // Most labels fit on one line, and that measurement is shared with the
  // containers' own sizing, so it is the one taken first.
  final line = measureLabel(text,
      style: style,
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      maxLines: maxLines,
      boldText: boldText);
  if (line.width <= available + precisionErrorTolerance) return false;
  if (maxLines == 1) return true;
  return _measure(text,
          style: style,
          textDirection: textDirection,
          textScaler: textScaler,
          locale: locale,
          maxLines: maxLines,
          maxWidth: available,
          boldText: boldText)
      .didExceedMaxLines;
}

/// Empties the memo. Exposed for tests that change fonts between cases.
void debugClearLabelMetrics() => _cache.clear();
