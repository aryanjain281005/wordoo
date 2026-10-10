import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/cloud.dart';
import '../../core/theme.dart';
import '../../core/tts.dart';
import '../../state/app_state.dart';
import '../../widgets/art.dart';
import '../../widgets/common.dart';
import '../adaptive.dart';
import '../bank.dart';
import '../battery.dart';
import '../models.dart';
import '../scorer.dart';
import '../speech_engine.dart';
import 'agent_banner.dart';
import 'tasks.dart';

Scene _sceneFor(Construct c) => switch (c) {
      Construct.phonological => Scene.forest,
      Construct.gpc => Scene.day,
      Construct.decoding => Scene.night,
      Construct.wordRecognition => Scene.ocean,
      Construct.spelling => Scene.treasure,
      Construct.comprehension => Scene.castle,
      Construct.oralLanguage => Scene.forest,
      Construct.rapidNaming => Scene.night,
    };

/// One station of the battery: all questions it can draw from (the three difficulty pools), and the ones asked so far.
class _Station {
  final SubtestDef def;
  final List<SItem> pool; // every question for this grade band, from the easy, medium and hard pools
  final int want; // how many questions the station asks
  final List<SItem> asked = [];
  _Station(this.def, this.pool, this.want);
}

/// The child's "First Adventure": a DALI-aligned screening battery presented as bridge stations.
class ScreeningScreen extends StatefulWidget {
  final bool isDev;
  const ScreeningScreen({super.key, this.isDev = false});
  @override
  State<ScreeningScreen> createState() => _ScreeningScreenState();
}

class _ScreeningScreenState extends State<ScreeningScreen> {
  late final AppState st = context.read<AppState>();
  late final ScreenBank bank = bankFor(st.langCode);
  late final GradeBand band = bandForGrade(st.grade);
  late final String pool = st.screenings.length.isEven ? 'A' : 'B';
  late final DateTime started = DateTime.now();
  final plan = <_Station>[];
  final trace = <TraceStep>[]; // the path through the easy / medium / hard pools
  final responses = <String, List<ItemResponse>>{};
  bool? speechOk;
  int si = 0, ii = 0, missRun = 0;
  bool intro = true;
  bool finished = false;
  String? msg;

  @override
  void initState() {
    super.initState();
    for (final def in battery) {
      final n = def.count(band);
      if (n == 0) continue;
      // every question of the station (both forms), in the three difficulty pools; the child's answers decide which pool the next one comes from
      final byId = <String, SItem>{for (final i in [...bank.forSubtest(def.id, 'A', band), ...bank.forSubtest(def.id, 'B', band)]) i.id: i};
      if (byId.isEmpty) continue;
      final station = _Station(def, byId.values.toList(), min(n, byId.length));
      final first = Adaptive.pick(station.pool, Adaptive.startTier, used: const {}, form: pool, seen: st.screeningSeen);
      if (first == null) continue;
      station.asked.add(first); // the first question of every station comes from the medium pool
      plan.add(station);
    }
    Cloud.instance.last.value = null; // the Question Agent banner starts empty for each screening
    _checkSpeech();
  }

  Future<void> _checkSpeech() async {
    final ok = st.background.voiceConsent && await SpeechEngine.instance.init();
    if (mounted) setState(() => speechOk = ok);
  }

  SubtestDef get def => plan[si].def;
  List<SItem> get items => plan[si].asked;

  void _startStation() {
    Speaker.instance.stop();
    if (def.speech && speechOk != true) {
      // the device can't hear the child: mark the station as not measured, never guess a score
      responses[def.id] = [for (final it in items) ItemResponse(itemId: it.id, subtest: def.id, score: 0, ms: 0, measured: false)];
      _nextStation();
      return;
    }
    setState(() => intro = false);
  }

  void _onDone(List<ItemResponse> raw) {
    final station = plan[si];
    final asked = station.asked[ii];
    // each answer is stamped with the pool its question came from (harder pools weigh more in the score)
    final r = [for (final x in raw) x.withTier(asked.tier.level)];
    responses.putIfAbsent(def.id, () => []).addAll(r);
    // HOW the child answered decides the next pool: wrong → easy; right but slow / paused / unclear → medium; right and quick → hard
    final quality = Adaptive.assess(r, def, band);
    final nextTier = Adaptive.next(r, quality);
    final step = TraceStep(subtest: def.id, itemId: asked.id, tier: asked.tier, score: Adaptive.score(r), ms: r.map((x) => x.ms).fold(0, (a, b) => a + b), quality: quality, nextTier: nextTier);
    trace.add(step);
    _sendToCloud(asked, r, step);
    final miss = r.every((x) => x.score < .5);
    missRun = miss ? missRun + 1 : 0;
    if (missRun >= def.discontinue) {
      // stop rule: the child is not kept on items that are too hard
      for (var k = station.asked.length; k < station.want; k++) {
        responses[def.id]!.add(ItemResponse(itemId: '${def.id}-skipped$k', subtest: def.id, score: 0, ms: 0, tag: 'discontinued'));
      }
      _nextStation();
      return;
    }
    final next = station.asked.length < station.want
        ? Adaptive.pick(station.pool, nextTier, used: {for (final i in station.asked) i.id}, form: pool, seen: st.screeningSeen)
        : null;
    if (next != null) {
      station.asked.add(next);
      setState(() {
        ii++;
        msg = null;
      });
    } else {
      _nextStation();
    }
  }

  /// Sends the answer to the database; the Question Agent answers with 10 new questions (shown in the banner).
  void _sendToCloud(SItem asked, List<ItemResponse> r, TraceStep step) {
    final sp = r.map((x) => x.speech).whereType<SpeechMetrics>().firstOrNull;
    Cloud.instance.sendResponse({
      'studentId': st.cloudStudentId,
      'childName': st.childName,
      'gradeBand': band.name,
      'lang': bank.code,
      'subtest': def.id,
      'itemId': asked.id,
      'itemSource': asked.source,
      'tier': step.tier.name,
      'nextTier': step.nextTier.name,
      'score': step.score,
      'ms': step.ms,
      'replays': r.fold<int>(0, (a, x) => a + x.replays),
      'tag': r.map((x) => x.tag).whereType<String>().firstOrNull,
      'quality': step.quality.toJson(),
      if (sp != null) 'speech': sp.toJson(),
      'station': si,
      'index': ii,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Developer demo ("DEV SKIP"): jumps to the next station, filling this one with full-marks answers so the report builds.
  void _devSkipStation() {
    if (!widget.isDev || finished) return;
    final station = plan[si];
    if (!responses.containsKey(def.id) || responses[def.id]!.isEmpty) {
      responses[def.id] = [
        for (var k = 0; k < station.want; k++)
          ItemResponse(itemId: k < station.asked.length ? station.asked[k].id : '${def.id}-dev$k', subtest: def.id, score: 1.0, ms: 1200, tier: k < station.asked.length ? station.asked[k].tier.level : 2),
      ];
    }
    _nextStation();
  }

  void _nextStation() {
    if (si + 1 >= plan.length) {
      _finish();
      return;
    }
    setState(() {
      si++;
      ii = 0;
      missRun = 0;
      intro = true;
      msg = null;
    });
  }

  void _finish() {
    setState(() => finished = true);
    final report = Scorer.build(
      responses: responses,
      band: band,
      lang: bank.code,
      pool: pool,
      bg: st.background,
      speechAvailable: speechOk == true,
      minutes: DateTime.now().difference(started).inMinutes,
    );
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) st.completeScreening(report, responses, trace: trace);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = bank.code;
    if (finished) {
      return AdventureBackground(
        scene: Scene.day,
        child: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🌉✨', style: TextStyle(fontSize: 90)),
              const SizedBox(height: 10),
              Companion(type: st.avatar.companion, size: 130, message: lang == 'hi' ? 'हमने मिलकर पुल ठीक कर दिया!' : 'We fixed the bridge together!', speakLocale: bank.tts),
            ]),
          ),
        ),
      );
    }
    return AdventureBackground(
      scene: _sceneFor(def.construct),
      calm: true,
      child: SafeArea(
        child: Stack(
          children: [
            Column(children: [
              _bridge(),
              if (Cloud.showBanner) const AgentBanner(),
              Expanded(
                child: Stack(children: [
                  Positioned.fill(child: intro ? _stationCard() : _task()),
                  if (!intro)
                    Positioned(left: 8, bottom: 4, right: 8, child: Align(alignment: Alignment.bottomLeft, child: Companion(type: st.avatar.companion, size: 74, message: msg ?? def.t(lang)))),
                ]),
              ),
            ]),
            if (widget.isDev)
              Positioned(
                right: 14,
                bottom: 110, // low on the screen, so it never covers the Question Agent banner at the top
                child: FloatingActionButton.extended(
                  heroTag: 'dev_skip_btn',
                  backgroundColor: const Color(0xFFFF3D00),
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                  label: Text('DEV SKIP: ${def.t(lang)} (${si + 1}/${plan.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: _devSkipStation,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bridge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B3F8F), Color(0xFF262A66)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8C46A), width: 2.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(bank.code == 'hi' ? (st.hasBaseline ? 'बादलों का पुल बनाओ' : 'मीलो का पुल ठीक करो') : (st.hasBaseline ? 'Rebuild the Cloud Bridge' : 'Help Milo fix the bridge!'), style: ts(15, color: const Color(0xFFFFE17A))),
          const SizedBox(height: 6),
          Row(children: [
            for (var k = 0; k < plan.length; k++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: k < si ? const Color(0xFFC88A48) : (k == si ? C.gold : Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: k <= si ? const Color(0xFF7A4E22) : Colors.white24, width: 1.5),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _stationCard() {
    final lang = bank.code;
    final skip = def.speech && speechOk == false;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Pop(
          key: ValueKey('st$si'),
          child: Panel(
            color: const Color(0xFFFFF9E8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.purple, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                child: Text('${si + 1}', style: ts(24, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              Text(def.t(lang), textAlign: TextAlign.center, style: ts(30)),
              const SizedBox(height: 4),
              Text(def.emoji, style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 6),
              Companion(type: st.avatar.companion, size: 90, message: skip ? bank.ui['noMic'] : def.l(lang), speakLocale: skip ? null : bank.tts),
              const SizedBox(height: 14),
              if (speechOk == null && def.speech)
                const CircularProgressIndicator()
              else
                BigButton(label: skip ? bank.ui['next']! : bank.ui['go']!, icon: Icons.play_arrow_rounded, style: BtnStyle.go, width: 220, onTap: _startStation),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _task() {
    final it = items[ii];
    void say(String m) => setState(() => msg = m);
    final key = ValueKey('${def.id}-${it.id}');
    switch (def.task) {
      case TaskType.picture:
      case TaskType.audioChoice:
      case TaskType.letterChoice:
      case TaskType.sentencePicture:
        return ChoiceTask(key: key, item: it, def: def, bank: bank, onDone: _onDone, onSay: say);
      case TaskType.passage:
        return it.questions.isEmpty
            ? ChoiceTask(key: key, item: it, def: def, bank: bank, onDone: _onDone, onSay: say)
            : QuestionsTask(key: key, item: it, def: def, bank: bank, onDone: _onDone, listening: false, onSay: say);
      case TaskType.listening:
        return QuestionsTask(key: key, item: it, def: def, bank: bank, onDone: _onDone, listening: true, onSay: say);
      case TaskType.tiles:
        return TilesTask(key: key, item: it, def: def, bank: bank, onDone: _onDone, onSay: say);
      case TaskType.readAloud:
        return ReadAloudTask(key: key, item: it, def: def, bank: bank, onDone: _onDone, onSay: say);
      case TaskType.ran:
        return RanTask(key: key, item: it, def: def, bank: bank, onDone: _onDone, onSay: say);
      case TaskType.oralReading:
        return OralReadingTask(key: key, item: it, def: def, bank: bank, onDone: _onDone, band: band, onSay: say);
      case TaskType.fluency:
        return FluencyTask(key: key, item: it, def: def, bank: bank, onDone: _onDone, onSay: say);
    }
  }
}
