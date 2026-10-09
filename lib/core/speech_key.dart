/// Plain-Dart key for the recorded speech bank (shared by the app and tool/export_speech.dart):
/// the same text always maps to the same clip, whatever its case or spacing.
String speechKey(String text) => text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').replaceAll('’', "'");

/// File id for a key: readable slug + short checksum (unique, safe as a file name).
String speechId(String key) {
  var h = 0x811c9dc5;
  for (final c in key.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  var slug = key.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  if (slug.length > 32) slug = slug.substring(0, 32);
  return 'say/${slug.isEmpty ? 'x' : slug}_${h.toRadixString(16).padLeft(8, '0')}';
}
