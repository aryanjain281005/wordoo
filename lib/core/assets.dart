import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Readle's asset manifest: every image / music track has a logical id (e.g. `char.milo.body`, `bg.forest`).
/// If an id has no file yet, callers get `null` and use their built-in placeholder.
/// This lets us build now and drop final art/audio in later without code changes.
class ReadleAssets {
  static final ReadleAssets instance = ReadleAssets._();
  ReadleAssets._();

  Map<String, String> _art = {};
  Map<String, String> _music = {};
  Set<String> _bundled = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = jsonDecode(await rootBundle.loadString('assets/manifest.json')) as Map<String, dynamic>;
      _art = Map<String, String>.from(raw['art'] as Map? ?? const {});
      _music = Map<String, String>.from(raw['music'] as Map? ?? const {});
    } catch (e) {
      debugPrint('manifest: $e');
    }
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle); // Flutter's list of bundled files
      _bundled = m.listAssets().toSet();
    } catch (e) {
      debugPrint('asset list: $e');
    }
    _loaded = true;
  }

  /// Manifest entry first; otherwise a file simply named after the id, e.g. `assets/art/char.milo.png`.
  String? art(String id) => _art[id] ?? _find('assets/art/$id', const ['webp', 'png', 'jpg']);

  /// Manifest entry first; otherwise e.g. `assets/music/music.forest.mp3`.
  String? music(String id) => _music[id] ?? _find('assets/music/$id', const ['ogg', 'mp3', 'm4a']);

  String? _find(String base, List<String> exts) {
    for (final e in exts) {
      if (_bundled.contains('$base.$e')) return '$base.$e';
    }
    return null;
  }

  /// True when a file is really bundled in the app (used to auto-discover sfx and voice files).
  bool bundled(String path) => _bundled.contains(path);
}

/// Image with a placeholder: shows the real art when the manifest has it, otherwise the fallback widget.
class ArtImage extends StatelessWidget {
  final String id;
  final Widget fallback;
  final BoxFit fit;
  const ArtImage(this.id, {super.key, required this.fallback, this.fit = BoxFit.contain});
  @override
  Widget build(BuildContext context) {
    final p = ReadleAssets.instance.art(id);
    if (p == null) return fallback;
    return Image.asset(p, fit: fit, errorBuilder: (_, _, _) => fallback);
  }
}
