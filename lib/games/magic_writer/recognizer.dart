import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

/// On-device handwriting check for single letters (like the $P point-cloud recogniser), with no network or
/// model: each letter's template is a cloud of points sampled from the app's own font glyph. The child's
/// strokes become a cloud too; both are normalised (centred, scaled by their larger side) and compared with
/// a symmetric average nearest-point distance. Gentle: the expected letter only has to be among the closest
/// few and under a loose distance limit.
class LetterRecognizer {
  final Map<String, List<Offset>> templates;
  LetterRecognizer(this.templates);

  static const letters = 'abcdefghijklmnopqrstuvwxyz';

  /// Renders every letter with [fontFamily] and samples its ink into a normalised point cloud.
  static Future<LetterRecognizer> build({String fontFamily = 'Fredoka', double size = 72}) async {
    final t = <String, List<Offset>>{};
    for (final ch in letters.split('')) {
      t[ch] = await _glyphCloud(ch, fontFamily, size);
    }
    return LetterRecognizer(t);
  }

  static Future<List<Offset>> _glyphCloud(String ch, String font, double size) async {
    final tp = TextPainter(
      text: TextSpan(text: ch, style: TextStyle(fontFamily: font, fontSize: size, fontWeight: FontWeight.w500, color: const Color(0xFF000000))),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width.ceil() + 4, h = tp.height.ceil() + 4;
    final rec = ui.PictureRecorder();
    tp.paint(Canvas(rec), const Offset(2, 2));
    final img = await rec.endRecording().toImage(w, h);
    final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final pts = <Offset>[];
    const step = 2;
    for (var y = 0; y < h; y += step) {
      for (var x = 0; x < w; x += step) {
        if (data.getUint8((y * w + x) * 4 + 3) > 128) pts.add(Offset(x.toDouble(), y.toDouble()));
      }
    }
    return normalise(pts);
  }

  /// Centre on the bounding box and scale so the larger side is 1.
  static List<Offset> normalise(List<Offset> pts) {
    if (pts.isEmpty) return pts;
    var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
    for (final p in pts) {
      minX = min(minX, p.dx);
      minY = min(minY, p.dy);
      maxX = max(maxX, p.dx);
      maxY = max(maxY, p.dy);
    }
    final s = max(max(maxX - minX, maxY - minY), 1e-6);
    final c = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    return [for (final p in pts) (p - c) / s];
  }

  /// Even resampling of strokes into ~[n] points (stroke speed must not matter).
  static List<Offset> resample(List<List<Offset>> strokes, {int n = 64}) {
    var length = 0.0;
    for (final s in strokes) {
      for (var i = 1; i < s.length; i++) {
        length += (s[i] - s[i - 1]).distance;
      }
    }
    final out = <Offset>[];
    if (length == 0) {
      for (final s in strokes) {
        out.addAll(s);
      }
      return out;
    }
    final gap = length / n;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      out.add(s.first);
      var acc = 0.0;
      for (var i = 1; i < s.length; i++) {
        var a = s[i - 1];
        final b = s[i];
        var d = (b - a).distance;
        while (acc + d >= gap && d > 0) {
          final t = (gap - acc) / d;
          final q = Offset.lerp(a, b, t)!;
          out.add(q);
          a = q;
          d = (b - a).distance;
          acc = 0;
        }
        acc += d;
      }
    }
    return out;
  }

  static double _avgNearest(List<Offset> from, List<Offset> to) {
    var sum = 0.0;
    for (final p in from) {
      var best = double.infinity;
      for (final q in to) {
        final d = (p - q).distanceSquared;
        if (d < best) best = d;
      }
      sum += sqrt(best);
    }
    return sum / from.length;
  }

  /// Symmetric distance between two normalised clouds (0 = identical).
  static double distance(List<Offset> a, List<Offset> b) {
    if (a.isEmpty || b.isEmpty) return double.infinity;
    final sa = _thin(a, 140), sb = _thin(b, 140);
    return (_avgNearest(sa, sb) + _avgNearest(sb, sa)) / 2;
  }

  static List<Offset> _thin(List<Offset> l, int n) {
    if (l.length <= n) return l;
    final step = l.length / n;
    return [for (var i = 0; i < n; i++) l[(i * step).floor()]];
  }

  /// Ranked letters for some strokes, closest first.
  List<(String, double)> rank(List<List<Offset>> strokes) {
    final cloud = normalise(resample(strokes.where((s) => s.isNotEmpty).toList()));
    final r = [for (final e in templates.entries) (e.key, distance(cloud, e.value))]..sort((a, b) => a.$2.compareTo(b.$2));
    return r;
  }

  /// Gentle check: [expected] is within the [topK] closest letters and close enough in shape.
  bool accepts(List<List<Offset>> strokes, String expected, {int topK = 3, double limit = .16}) {
    final ink = strokes.fold<int>(0, (a, s) => a + s.length);
    if (ink < 4 || !templates.containsKey(expected)) return false;
    final r = rank(strokes);
    final i = r.indexWhere((e) => e.$1 == expected);
    return i >= 0 && i < topK && r[i].$2 <= limit;
  }

  /// Turns a template back into a stroke-like list (used by the demo and tests).
  List<List<Offset>> sample(String letter, {double scale = 80, Offset at = Offset.zero}) {
    final t = templates[letter] ?? const [];
    return [for (final p in t) [at + p * scale]];
  }
}
