import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Width below which the app uses its phone layout.
const double compactBreakpoint = 600;

bool isCompact(BuildContext context) {
  return MediaQuery.sizeOf(context).width < compactBreakpoint;
}

/// Padding that keeps page content in a centred column no wider than
/// [maxContentWidth]. On narrow screens it is just the side gutter.
///
/// Applying this as scroll-view padding (instead of wrapping the scroll view
/// in a narrow box) keeps the scrollbar at the edge of the window.
///
/// The width comes from MediaQuery rather than a LayoutBuilder on purpose:
/// widgets inside a LayoutBuilder are only rebuilt when it is laid out, so a
/// screen hidden under another route would miss theme changes.
EdgeInsets pagePadding(
  BuildContext context, {
  double maxContentWidth = 680,
  double top = 16,
  double bottom = 24,
}) {
  final availableWidth = MediaQuery.sizeOf(context).width;
  final gutter = availableWidth < compactBreakpoint ? 16.0 : 24.0;
  final side = math.max(gutter, (availableWidth - maxContentWidth) / 2);
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}
