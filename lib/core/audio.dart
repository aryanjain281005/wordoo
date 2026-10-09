import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'assets.dart';
import 'speech_key.dart';
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
  AudioPlayer? _voicePlayer;
  String? _musicId;
  Map<String, String> _sayIndex = {}; // speech key → recorded clip id (assets/story/say_en.json)
  Map<String, List<int>> _envelopes = {}; // per voice line: loudness 0..9 every 50 ms
  Timer? _lip;
  Completer<void>? _voiceDone;
  bool _ready = false;

  Future<void> init() async {
    if (_ready || !enabled) return;
    try {
      // Our paths are full asset paths ("assets/sfx/x.ogg"). audioplayers adds "assets/" by default, which made
      // every sound load "assets/assets/…" on real devices — so clear the prefix for every cache we use.
      FlameAudio.updatePrefix('');
      AudioCache.instance.prefix = '';
      await ReadleAssets.instance.load();
      try {
        final raw = jsonDecode(await rootBundle.loadString('assets/vo/en/envelopes.json')) as Map<String, dynamic>;
        _envelopes = raw.map((k, v) => MapEntry(k, List<int>.from(v as List)));
      } catch (_) {}
      try {
        final raw = jsonDecode(await rootBundle.loadString('assets/story/say_en.json')) as Map<String, dynamic>;
        _sayIndex = {for (final e in raw.entries) speechKey((e.value as Map)['text'] as String): e.key};
      } catch (_) {}
      // every sound effect is loaded up-front, so the first tap on anything sounds instantly
      final all = ReadleAssets.instance.bundledUnder('assets/sfx/').where((p) => p.endsWith('.ogg'));
      await Future.wait([for (final p in all) _pool(p.substring('assets/sfx/'.length, p.length - 4))]);
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

  String? get currentMusic => _musicId;

  Future<void> music(String id) async {
    if (!enabled || _musicId == id) return;
    _musicId = id;
    await stopMusic();
    if (!musicOn) return;
    final path = ReadleAssets.instance.music(id);
    if (path == null) return; // placeholder: silence until the Pixabay track is added to the manifest
    try {
      _music = await FlameAudio.loopLongAudio(path, volume: musicVolume * _level);
    } catch (e) {
      debugPrint('music $id: $e');
    }
  }

  /// Settings switch: stops the music, or restarts the track that should be playing now.
  Future<void> setMusicOn(bool on) async {
    musicOn = on;
    final id = _musicId;
    _musicId = null;
    if (on && id != null) return music(id);
    if (!on) {
      _musicId = id;
      await stopMusic();
    }
  }

  Future<void> stopMusic() async {
    try {
      await _music?.stop();
      await _music?.dispose();
    } catch (_) {}
    _music = null;
  }

  double _level = 1; // 0..1 set by games (Sound Orchestra wakes the band up layer by layer)
  bool _ducked = false;

  void _duck(bool down) {
    _ducked = down;
    _applyVolume();
  }

  /// Sound Orchestra: the track grows from quiet to full as the band wakes up.
  void setMusicLevel(double level) {
    _level = level.clamp(0.0, 1.0);
    _applyVolume();
  }

  void _applyVolume() {
    try {
      _music?.setVolume(musicVolume * _level * (_ducked ? .35 : 1));
    } catch (_) {}
  }

  bool hasVoice(String id) => ReadleAssets.instance.bundled('assets/vo/en/$id.ogg');

  /// Length of a generated voice line (from its lip-sync envelope); null when only TTS is available.
  Duration? voiceLength(String id) => hasVoice(id) && _envelopes[id] != null ? Duration(milliseconds: _envelopes[id]!.length * 50) : null;

  /// Recorded clip for a phrase (word, sound, instruction, story sentence), if one was generated.
  String? sayId(String text) {
    final id = _sayIndex[speechKey(text)];
    return id != null && hasVoice(id) ? id : null;
  }

  /// Say a word / sound / instruction in the narrator's recorded voice (falls back to device TTS).
  /// "c,  a,  t" plays each sound's clip in turn.
  Future<void> say(String text, {String ttsLocale = 'en-IN'}) async {
    if (text.contains(',  ')) {
      final gen = ++_sayGen;
      for (final part in text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty)) {
        if (gen != _sayGen) return;
        await voice(sayId(part) ?? '', part, character: 'say', ttsLocale: ttsLocale);
        await Future.delayed(const Duration(milliseconds: 120));
      }
      return;
    }
    ++_sayGen;
    await voice(sayId(text) ?? '', text, character: 'say', ttsLocale: ttsLocale);
  }

  int _sayGen = 0;

  /// Speak a character line. Completes when the line has finished (approximately, for TTS).
  Future<void> voice(String id, String text, {String character = 'milo', String ttsLocale = 'en-IN'}) async {
    await stopVoice();
    speaking.value = character;
    _duck(true);
    final done = Completer<void>();
    _voiceDone = done;
    var played = false;
    if (kDebugMode || const bool.fromEnvironment('VOICE_LOG')) debugPrint('VOICE ${DateTime.now().millisecondsSinceEpoch % 100000} $id');
    if (enabled && hasVoice(id)) {
      try {
        // one reused player for every line (creating a player per line caused small stutters)
        final p = _voicePlayer ??= (AudioPlayer()..onPlayerComplete.listen((_) {
              final d = _voiceDone;
              if (d != null && !d.isCompleted) d.complete();
            }));
        _voice = p;
        await p.play(AssetSource('assets/vo/en/$id.ogg'));
        played = true;
        final env = _envelopes[id];
        final sw = Stopwatch()..start();
        _lip = Timer.periodic(const Duration(milliseconds: 50), (_) {
          final i = sw.elapsedMilliseconds ~/ 50;
          mouth.value = env == null ? (sin(i * 1.3).abs()) : (i < env.length ? env[i] / 9 : 0);
        });
        final len = voiceLength(id);
        await done.future.timeout(len == null ? const Duration(seconds: 30) : len + const Duration(seconds: 2), onTimeout: () {});
      } catch (e) {
        debugPrint('voice $id: $e');
      }
    }
    if (!played && !done.isCompleted) {
      // placeholder voice (or the file failed): device TTS + simulated mouth movement for an estimated duration
      Speaker.instance.speak(text, ttsLocale);
      final ms = 400 + text.length * 62;
      final sw = Stopwatch()..start();
      _lip = Timer.periodic(const Duration(milliseconds: 60), (_) {
        mouth.value = sw.elapsedMilliseconds < ms ? (sin(sw.elapsedMilliseconds / 70).abs() * .9) : 0;
      });
      await Future.any([Future.delayed(Duration(milliseconds: ms)), done.future]);
    }
    if (_voiceDone != done) return; // a newer line took over; it owns the mouth and ducking now
    _lip?.cancel();
    mouth.value = 0;
    speaking.value = null;
    _duck(false);
  }

  Future<void> stopVoice() async {
    final d = _voiceDone;
    if (d != null && !d.isCompleted) d.complete(); // release whoever is waiting for the line to end
    _lip?.cancel();
    mouth.value = 0;
    // Order matters: take the player out first and send the TTS "stop" immediately. A slow, older stop must
    // never land after a NEW line has started (that silenced the first sentence of every round).
    final p = _voice;
    _voice = null;
    Speaker.instance.stop();
    try {
      await p?.stop(); // the shared player is kept for the next line
    } catch (_) {}
  }

}
