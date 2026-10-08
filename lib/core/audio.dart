import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'assets.dart';
import 'tts.dart';

/// One place for every sound in the game.
///  • sfx(id)    short effects (assets/sfx/<id>.ogg) — silently skipped if a file is missing
///  • music(id)  looping background track from the asset manifest, ducked (lowered) while someone speaks
///  • voice(...) a character line: plays assets/vo/en/<id>.ogg if it exists, otherwise device text-to-speech.
///               [mouth] (0..1) follows the loudness of the line so characters can lip-sync.
class AudioManager {
  static final AudioManager instance = AudioManager._();
  AudioManager._();

  bool enabled = !kIsWeb || true; // tests switch this off
  bool sfxOn = true;
  bool musicOn = true;
  double musicVolume = .35;
  final ValueNotifier<double> mouth = ValueNotifier(0);
  final ValueNotifier<String?> speaking = ValueNotifier(null); // character id currently talking

  final Map<String, AudioPool> _pools = {};
  AudioPlayer? _music;
  AudioPlayer? _voice;
  String? _musicId;
  Map<String, List<int>> _envelopes = {}; // per voice line: loudness 0..9 every 50 ms
  Timer? _lip;
  bool _ready = false;

  Future<void> init() async {
    if (_ready || !enabled) return;
    try {
      FlameAudio.updatePrefix('');
      await ReadleAssets.instance.load();
      try {
        final raw = jsonDecode(await rootBundle.loadString('assets/vo/en/envelopes.json')) as Map<String, dynamic>;
        _envelopes = raw.map((k, v) => MapEntry(k, List<int>.from(v as List)));
      } catch (_) {}
      for (final id in const ['ui_tap', 'correct_1', 'correct_2', 'correct_3', 'miss_soft', 'tile_pick', 'tile_snap', 'star_1', 'pop']) {
        await _pool(id);
      }
      _ready = true;
    } catch (e) {
      debugPrint('audio init: $e');
    }
  }

  Future<AudioPool?> _pool(String id) async {
    final path = 'assets/sfx/$id.ogg';
    if (!ReadleAssets.instance.bundled(path)) return null;
    final p = _pools[id] ??= await AudioPool.createFromAsset(path: path, maxPlayers: 3, playerMode: PlayerMode.lowLatency);
    return p;
  }

  /// Play a short sound effect.
  Future<void> sfx(String id, {double volume = .8}) async {
    if (!enabled || !sfxOn) return;
    try {
      final p = await _pool(id);
      await p?.start(volume: volume);
    } catch (e) {
      debugPrint('sfx $id: $e');
    }
  }

  /// A random variation (e.g. correct_1/2/3) so repeated feedback doesn't sound mechanical.
  Future<void> sfxOneOf(List<String> ids, {double volume = .8}) => sfx(ids[Random().nextInt(ids.length)], volume: volume);

  Future<void> music(String id) async {
    if (!enabled || _musicId == id) return;
    _musicId = id;
    await stopMusic();
    if (!musicOn) return;
    final path = ReadleAssets.instance.music(id);
    if (path == null) return; // placeholder: silence until the Pixabay track is added to the manifest
    try {
      _music = await FlameAudio.loopLongAudio(path, volume: musicVolume);
    } catch (e) {
      debugPrint('music $id: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _music?.stop();
      await _music?.dispose();
    } catch (_) {}
    _music = null;
  }

  void _duck(bool down) {
    try {
      _music?.setVolume(down ? musicVolume * .35 : musicVolume);
    } catch (_) {}
  }

  bool hasVoice(String id) => ReadleAssets.instance.bundled('assets/vo/en/$id.ogg');

  /// Speak a character line. Completes when the line has finished (approximately, for TTS).
  Future<void> voice(String id, String text, {String character = 'milo', String ttsLocale = 'en-IN'}) async {
    await stopVoice();
    speaking.value = character;
    _duck(true);
    final done = Completer<void>();
    if (enabled && hasVoice(id)) {
      try {
        final p = AudioPlayer();
        _voice = p;
        await p.play(AssetSource('assets/vo/en/$id.ogg'));
        final env = _envelopes[id];
        final sw = Stopwatch()..start();
        _lip = Timer.periodic(const Duration(milliseconds: 50), (_) {
          final i = sw.elapsedMilliseconds ~/ 50;
          mouth.value = env == null ? (sin(i * 1.3).abs()) : (i < env.length ? env[i] / 9 : 0);
        });
        p.onPlayerComplete.first.then((_) {
          if (!done.isCompleted) done.complete();
        });
        await done.future.timeout(const Duration(seconds: 30), onTimeout: () {});
      } catch (e) {
        debugPrint('voice $id: $e');
      }
    } else {
      // placeholder voice: device TTS + simulated mouth movement for an estimated duration
      Speaker.instance.speak(text, ttsLocale);
      final ms = 400 + text.length * 62;
      final sw = Stopwatch()..start();
      _lip = Timer.periodic(const Duration(milliseconds: 60), (_) {
        mouth.value = sw.elapsedMilliseconds < ms ? (sin(sw.elapsedMilliseconds / 70).abs() * .9) : 0;
      });
      await Future.delayed(Duration(milliseconds: ms));
    }
    _lip?.cancel();
    mouth.value = 0;
    speaking.value = null;
    _duck(false);
  }

  Future<void> stopVoice() async {
    _lip?.cancel();
    mouth.value = 0;
    try {
      await _voice?.stop();
      await _voice?.dispose();
    } catch (_) {}
    _voice = null;
    await Speaker.instance.stop();
  }
}
