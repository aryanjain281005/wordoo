import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screening/models.dart';
import '../screening/question_store.dart';

/// What the Question Agent did after one answer (shown to the grown-up as the "Question Agent" banner during the screening).
class AgentEvent {
  final String status; // sending | done | none | offline
  final int added, bankBefore, bankAfter;
  final String subtest, tier, message;
  final List<SItem> questions;
  final int ms;
  const AgentEvent({required this.status, this.added = 0, this.bankBefore = 0, this.bankAfter = 0, this.subtest = '', this.tier = '', this.message = '', this.questions = const [], this.ms = 0});
}

/// The app's link to the Wordoo server (MongoDB + Question Agent). Everything here is optional: with no server the screening runs
/// exactly as before, from the questions bundled in the app.
///
///   --dart-define=READLE_API=https://your-server      (default http://127.0.0.1:8787, reachable on a phone via `adb reverse tcp:8787 tcp:8787`)
///   --dart-define=READLE_API=off                      turns the cloud link off
class Cloud {
  static final Cloud instance = Cloud._();
  Cloud._();

  static const _api = String.fromEnvironment('READLE_API', defaultValue: 'http://127.0.0.1:8787');
  static const showBanner = bool.fromEnvironment('READLE_AGENT_BANNER', defaultValue: false);

  String baseUrl = _api;
  bool get enabled => baseUrl.isNotEmpty && baseUrl != 'off';

  /// The latest Question Agent event, for the banner.
  final ValueNotifier<AgentEvent?> last = ValueNotifier(null);

  http.Client _client = http.Client();
  @visibleForTesting
  set client(http.Client c) => _client = c;

  Uri _u(String path, [Map<String, String>? q]) => Uri.parse('$baseUrl$path').replace(queryParameters: q);

  /// Loads the copy of the bank saved on the phone, then refreshes it from the server in the background.
  Future<void> init(String lang) async {
    await QuestionStore.instance.load(lang);
    unawaited(syncQuestions(lang));
    unawaited(flushPending());
  }

  Future<bool> syncQuestions(String lang) async {
    if (!enabled) return false;
    try {
      final r = await _client.get(_u('/questions', {'lang': lang})).timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return false;
      final qs = (jsonDecode(utf8.decode(r.bodyBytes)) as Map)['questions'] as List;
      QuestionStore.instance.replace(lang, [for (final j in qs) SItem.fromJson(Map<String, dynamic>.from(j as Map))]);
      await QuestionStore.instance.save(lang);
      return true;
    } catch (e) {
      debugPrint('cloud sync: $e');
      return false;
    }
  }

  /// One answer → the server stores it and the Question Agent writes 10 new questions. The new questions are added to the
  /// local bank at once, so the same screening can already use them. Never throws.
  Future<AgentEvent> sendResponse(Map<String, dynamic> telemetry) async {
    final lang = telemetry['lang'] as String? ?? 'en';
    if (!enabled) return _publish(const AgentEvent(status: 'offline', message: 'Cloud link is off — using the questions in the app'));
    last.value = AgentEvent(status: 'sending', subtest: telemetry['subtest'] as String? ?? '', tier: telemetry['nextTier'] as String? ?? '');
    try {
      final r = await _client.post(_u('/telemetry'), headers: {'content-type': 'application/json'}, body: jsonEncode(telemetry)).timeout(const Duration(seconds: 90));
      if (r.statusCode != 200) return _publish(AgentEvent(status: 'offline', message: 'Server answered ${r.statusCode}'));
      final a = Map<String, dynamic>.from((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['agent'] as Map);
      if (a['ran'] != true) return _publish(AgentEvent(status: 'none', message: 'Question Agent did not write questions (${a['reason'] ?? a['error'] ?? 'unknown'})'));
      final qs = [for (final j in (a['questions'] as List)) SItem.fromJson(Map<String, dynamic>.from(j as Map))];
      QuestionStore.instance.merge(lang, qs);
      unawaited(QuestionStore.instance.save(lang));
      return _publish(AgentEvent(
        status: 'done',
        added: (a['added'] as num).toInt(),
        bankBefore: (a['bankBefore'] as num).toInt(),
        bankAfter: (a['bankAfter'] as num).toInt(),
        subtest: a['subtest'] as String,
        tier: a['tier'] as String,
        questions: qs,
        ms: (a['ms'] as num?)?.toInt() ?? 0,
      ));
    } catch (e) {
      return _publish(AgentEvent(status: 'offline', message: 'No connection to the server — the answer was not sent'));
    }
  }

  AgentEvent _publish(AgentEvent e) {
    last.value = e;
    return e;
  }

  // ---- speech recognition (OpenAI Whisper, through the Wordoo server: the key never leaves the server) ----
  DateTime _whisperChecked = DateTime.fromMillisecondsSinceEpoch(0);
  bool _whisperOk = false;
  DateTime _whisperPausedUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// True when the server can transcribe with Whisper (asked at most every 90 s; after a failure the app uses the phone's own
  /// recogniser for 2 minutes).
  Future<bool> whisperAvailable() async {
    if (!enabled || DateTime.now().isBefore(_whisperPausedUntil)) return false;
    if (DateTime.now().difference(_whisperChecked).inSeconds < 90) return _whisperOk;
    _whisperChecked = DateTime.now();
    try {
      final r = await _client.get(_u('/health')).timeout(const Duration(seconds: 3));
      _whisperOk = r.statusCode == 200 && ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['whisper'] == true);
    } catch (_) {
      _whisperOk = false;
    }
    return _whisperOk;
  }

  /// Sends one recording; returns the server's transcript (text, words with times, confidence) or null on any failure.
  Future<Map<String, dynamic>?> transcribe(Uint8List audio, {String lang = 'en', String prompt = ''}) async {
    try {
      final r = await _client.post(_u('/transcribe', {'lang': lang, if (prompt.isNotEmpty) 'prompt': prompt}), headers: {'content-type': 'audio/wav'}, body: audio).timeout(const Duration(seconds: 25));
      if (r.statusCode != 200) throw Exception('server ${r.statusCode}');
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(r.bodyBytes)) as Map);
    } catch (e) {
      debugPrint('whisper: $e');
      _whisperPausedUntil = DateTime.now().add(const Duration(minutes: 2));
      return null;
    }
  }

  // ---- screening history (screenings collection) ----
  static const _pendingKey = 'cloud_pending_screenings';

  /// Saves one finished screening to the database; when the server cannot be reached it is kept and sent next time.
  Future<void> sendScreening(Map<String, dynamic> doc) async {
    if (!enabled) return;
    if (!await _post(doc)) await _queue(doc);
  }

  Future<bool> _post(Map<String, dynamic> doc) async {
    try {
      final r = await _client.post(_u('/screenings'), headers: {'content-type': 'application/json'}, body: jsonEncode(doc)).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _queue(Map<String, dynamic> doc) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList(_pendingKey) ?? [];
      await p.setStringList(_pendingKey, [...list, jsonEncode(doc)]);
    } catch (_) {}
  }

  Future<void> flushPending() async {
    if (!enabled) return;
    try {
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList(_pendingKey) ?? [];
      final left = <String>[];
      for (final s in list) {
        if (!await _post(Map<String, dynamic>.from(jsonDecode(s) as Map))) left.add(s);
      }
      await p.setStringList(_pendingKey, left);
    } catch (_) {}
  }
}
