import 'package:flutter/foundation.dart';
import 'dart:ui' show FramePhase;
import 'package:flutter/scheduler.dart';

/// Developer-only frame timing. `begin()` before a screen, `end()` after: logs (tag FRAMESTATS) and returns a summary.
/// A frame is "slow" when build or raster took longer than 16.7 ms (60 fps budget).
class FrameStats {
  static final List<FrameTiming> _t = [];
  static bool _on = false;

  static void _cb(List<FrameTiming> l) => _t.addAll(l);

  static void begin() {
    _t.clear();
    if (!_on) {
      SchedulerBinding.instance.addTimingsCallback(_cb);
      _on = true;
    }
  }

  static String end(String label) {
    if (_on) {
      SchedulerBinding.instance.removeTimingsCallback(_cb);
      _on = false;
    }
    if (_t.isEmpty) return '$label: no frames';
    double ms(Duration d) => d.inMicroseconds / 1000;
    final b = _t.map((f) => ms(f.buildDuration)).toList()..sort();
    final r = _t.map((f) => ms(f.rasterDuration)).toList()..sort();
    final slow = _t.where((f) => ms(f.buildDuration) > 16.7 || ms(f.rasterDuration) > 16.7).length;
    final worst = _t.map((f) => ms(f.totalSpan)).reduce((a, c) => a > c ? a : c);
    String p(List<double> x, double q) => x[(x.length * q).floor().clamp(0, x.length - 1)].toStringAsFixed(1);
    // the worst moments, with seconds since the screen opened, so a hitch can be matched to what the child just did
    final t0 = _t.first.timestampInMicroseconds(FramePhase.buildStart);
    final bad = _t.where((f) => ms(f.totalSpan) > 40).take(14).map((f) => '${((f.timestampInMicroseconds(FramePhase.buildStart) - t0) / 1e6).toStringAsFixed(1)}s:${ms(f.totalSpan).toStringAsFixed(0)}ms(b${ms(f.buildDuration).toStringAsFixed(0)}/r${ms(f.rasterDuration).toStringAsFixed(0)})').join(' ');
    if (bad.isNotEmpty) debugPrint('FRAMESTATS hitches $label: $bad');
    final s = '$label: ${_t.length} frames, slow ${(100 * slow / _t.length).toStringAsFixed(1)}%, build p50 ${p(b, .5)} p95 ${p(b, .95)} ms, raster p50 ${p(r, .5)} p95 ${p(r, .95)} ms, worst ${worst.toStringAsFixed(0)} ms';
    debugPrint('FRAMESTATS $s');
    return s;
  }
}
