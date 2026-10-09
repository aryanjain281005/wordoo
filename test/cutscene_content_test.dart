import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Every shipped cutscene must only refer to things that exist: lines (with a voice file), sounds, pictures, effects, characters.
void main() {
  const knownFx = {
    'none', 'grey', 'greying', 'storm', 'light', 'colour', 'rain', 'sparkle', 'keys', 'lightning', 'fireflies', 'leaves', 'notes', 'mist', 'rays', 'letters', 'lanterns', 'dust', 'embers', 'petals', 'confetti',
  };
  final lines = jsonDecode(File('assets/story/lines_en.json').readAsStringSync()) as Map<String, dynamic>;
  final cast = RegExp(r"'(\w+)': StoryCharacter\(").allMatches(File('lib/story/puppets.dart').readAsStringSync()).map((m) => m.group(1)!).toSet();
  final scenes = Directory('assets/cutscenes').listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();

  test('there are cutscenes', () => expect(scenes.length, greaterThanOrEqualTo(18)));

  for (final f in scenes) {
    final name = f.uri.pathSegments.last;
    test('$name only uses what exists', () {
      final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      expect(File('assets/music/${j['music'] ?? 'music.story'}.ogg').existsSync(), true, reason: 'music');
      for (final s in j['shots'] as List) {
        final shot = s as Map<String, dynamic>;
        for (final fx in (shot['fx'] as String? ?? 'none').split('+')) {
          expect(knownFx, contains(fx), reason: 'fx $fx');
        }
        final ln = shot['line'] as String?;
        if (ln != null) {
          expect(lines, contains(ln), reason: 'line $ln');
          expect(File('assets/vo/en/$ln.ogg').existsSync(), true, reason: 'voice file for $ln');
        }
        final sfx = shot['sfx'];
        for (final c in [if (sfx is String) sfx, if (sfx is List) ...sfx.map((e) => e is String ? e : (e as Map)['id'])]) {
          expect(File('assets/sfx/$c.ogg').existsSync(), true, reason: 'sfx $c');
        }
        final bg = shot['bg'] as String? ?? 'tree';
        if (bg.startsWith('art:')) {
          final id = bg.substring(4).replaceAll('~storm', '');
          expect(File('assets/art/$id.webp').existsSync() || File('assets/art/$id.png').existsSync(), true, reason: 'art $id');
        }
        for (final c in (shot['cast'] as List? ?? const [])) {
          expect(cast, contains((c as Map)['id']), reason: 'character ${c['id']}');
        }
      }
    });
  }

  test('no API key is bundled in the app or committed in lib/', () {
    final key = RegExp(r'sk_[0-9a-f]{40,}');
    for (final root in ['lib', 'assets/story', 'assets/cutscenes', 'tool']) {
      for (final f in Directory(root).listSync(recursive: true).whereType<File>()) {
        if (f.path.endsWith('.ogg') || f.path.endsWith('.webp') || f.path.endsWith('.png') || f.path.endsWith('.onnx')) continue;
        expect(key.hasMatch(f.readAsStringSync()), false, reason: 'secret-looking key in ${f.path}');
      }
    }
  });
}
