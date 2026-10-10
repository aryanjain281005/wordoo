import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/core/cloud.dart';
import 'package:wordoo/screening/adaptive.dart';
import 'package:wordoo/screening/bank.dart';
import 'package:wordoo/screening/bank_en.dart';
import 'package:wordoo/screening/battery.dart';
import 'package:wordoo/screening/history_doc.dart';
import 'package:wordoo/screening/models.dart';
import 'package:wordoo/screening/question_store.dart';
import 'package:wordoo/screening/scorer.dart';

ItemResponse resp(double score, {int ms = 3000, int replays = 0, SpeechMetrics? speech, String id = 'r1'}) => ItemResponse(itemId: id, subtest: 'rhyme', score: score, ms: ms, replays: replays, speech: speech);
final rhyme = subtestById('rhyme');
final wordReading = subtestById('wordReading');

void main() {
  group('three pools: how the next question is chosen', () {
    test('wrong answer → easy pool', () {
      final r = [resp(0)];
      expect(Adaptive.next(r, Adaptive.assess(r, rhyme, GradeBand.junior)), Tier.easy);
    });
    test('right, quick and clean → hard pool', () {
      final r = [resp(1, ms: 2500)];
      expect(Adaptive.next(r, Adaptive.assess(r, rhyme, GradeBand.junior)), Tier.hard);
    });
    test('right but slow → medium pool', () {
      final r = [resp(1, ms: 20000)];
      final q = Adaptive.assess(r, rhyme, GradeBand.junior);
      expect(q.slow, true);
      expect(Adaptive.next(r, q), Tier.medium);
    });
    test('right but asked for the instruction again → medium pool', () {
      final r = [resp(1, replays: 2)];
      expect(Adaptive.next(r, Adaptive.assess(r, rhyme, GradeBand.junior)), Tier.medium);
    });
    test('right but with a long pause before speaking → medium pool', () {
      final r = [resp(1, speech: const SpeechMetrics(transcript: 'cat', confidence: .9, latencyMs: 5000))];
      final q = Adaptive.assess(r, wordReading, GradeBand.junior);
      expect(q.longPause, true);
      expect(Adaptive.next(r, q), Tier.medium);
    });
    test('right but several pauses / silence inside the answer → medium pool', () {
      expect(Adaptive.assess([resp(1, speech: const SpeechMetrics(transcript: 'cat', confidence: .9, pauses: 2))], wordReading, GradeBand.junior).longPause, true);
      expect(Adaptive.assess([resp(1, speech: const SpeechMetrics(transcript: 'cat', confidence: .9, pauseMs: 1500))], wordReading, GradeBand.junior).longPause, true);
    });
    test('right but unclear speech → medium pool', () {
      final q = Adaptive.assess([resp(1, speech: const SpeechMetrics(transcript: 'cat', confidence: .3))], wordReading, GradeBand.junior);
      expect(q.lowConfidence, true);
      expect(q.clean, false);
    });
    test('right, quick speech with no pauses → hard pool', () {
      final r = [resp(1, speech: const SpeechMetrics(transcript: 'cat', confidence: .9, latencyMs: 900, pauses: 0, pauseMs: 100))];
      expect(Adaptive.next(r, Adaptive.assess(r, wordReading, GradeBand.junior)), Tier.hard);
    });
    test('partly right → medium pool', () {
      final r = [resp(.6)];
      expect(Adaptive.next(r, Adaptive.assess(r, rhyme, GradeBand.junior)), Tier.medium);
    });
    test('a story question (3 answers): any slow answer keeps it at medium', () {
      final r = [resp(1, ms: 4000), resp(1, ms: 4000), resp(1, ms: 30000)];
      expect(Adaptive.next(r, Adaptive.assess(r, subtestById('listening'), GradeBand.junior)), Tier.medium);
    });
    test('younger children get 30 % more time', () {
      expect(Adaptive.slowAfterMs(TaskType.picture, GradeBand.junior), greaterThan(Adaptive.slowAfterMs(TaskType.picture, GradeBand.middle)));
    });
  });

  group('picking a question from a pool', () {
    final bank = EnglishScreenBank();
    final cands = [...bank.forSubtest('rhyme', 'A', GradeBand.junior), ...bank.forSubtest('rhyme', 'B', GradeBand.junior)];

    test('the bank has all three pools for the main stations', () {
      for (final id in ['rhyme', 'phonemeManip', 'letterSound', 'wordReading', 'nonwordReading', 'spelling']) {
        final c = [...bank.forSubtest(id, 'A', GradeBand.junior), ...bank.forSubtest(id, 'B', GradeBand.junior)];
        for (final t in Tier.values) {
          expect(c.where((i) => i.tier == t), isNotEmpty, reason: '$id has no ${t.name} questions');
        }
      }
    });
    test('takes from the wanted pool', () {
      for (final t in Tier.values) {
        expect(Adaptive.pick(cands, t, used: {}, form: 'A')!.tier, t);
      }
    });
    test('never repeats a question and falls back to the nearest pool when one is used up', () {
      final used = <String>{};
      for (var k = 0; k < cands.length; k++) {
        final n = Adaptive.pick(cands, Tier.hard, used: used, form: 'A');
        expect(n, isNotNull);
        expect(used.add(n!.id), true);
      }
      expect(Adaptive.pick(cands, Tier.hard, used: used, form: 'A'), isNull);
    });
    test('prefers questions the child has not met, then this cycle’s form', () {
      final medium = cands.where((i) => i.tier == Tier.medium).toList();
      final seen = {for (final i in medium.skip(1)) i.id: 1};
      expect(Adaptive.pick(cands, Tier.medium, used: {}, form: 'A', seen: seen)!.id, medium.first.id);
    });
    test('questions written by the agent are tried before shipped ones the child has met', () {
      final gen = SItem(id: 'g_rhyme_m_x', subtest: 'rhyme', pool: 'A', difficulty: 2, target: 'zzz', source: 'gemini');
      final all = [...cands, gen];
      expect(Adaptive.pick(all, Tier.medium, used: {}, form: 'A')!.id, 'g_rhyme_m_x');
    });
    test('a full station follows the rule: wrong → easy, clean right → hard', () {
      final used = <String>{};
      var item = Adaptive.pick(cands, Adaptive.startTier, used: used, form: 'A')!;
      expect(item.tier, Tier.medium);
      final path = <Tier>[item.tier];
      for (final answer in [0.0, 1.0, 1.0, 0.0]) {
        used.add(item.id);
        final r = [resp(answer, id: item.id)];
        item = Adaptive.pick(cands, Adaptive.next(r, Adaptive.assess(r, rhyme, GradeBand.junior)), used: used, form: 'A')!;
        path.add(item.tier);
      }
      expect(path, [Tier.medium, Tier.easy, Tier.hard, Tier.hard, Tier.easy]);
    });
  });

  group('scoring with pools', () {
    test('all-medium answers score exactly as before (plain average)', () {
      final r = [for (var i = 0; i < 4; i++) resp(i < 3 ? 1 : 0)];
      expect(Scorer.scoreSubtest(rhyme, r, GradeBand.junior).accuracy, closeTo(.75, 1e-9));
    });
    test('a right answer in the hard pool counts more than one in the easy pool', () {
      final hardRight = [resp(1).withTier(3), resp(0).withTier(1)];
      final easyRight = [resp(1).withTier(1), resp(0).withTier(3)];
      expect(Scorer.scoreSubtest(rhyme, hardRight, GradeBand.junior).accuracy, greaterThan(Scorer.scoreSubtest(rhyme, easyRight, GradeBand.junior).accuracy));
    });
    test('a child who is right at every hard question still scores 100 %', () {
      expect(Scorer.scoreSubtest(rhyme, [for (var i = 0; i < 5; i++) resp(1).withTier(3)], GradeBand.junior).accuracy, closeTo(1, 1e-9));
    });
  });

  group('questions as database documents', () {
    test('every question in the app’s bank survives JSON and keeps its pool', () {
      for (final i in EnglishScreenBank().items) {
        final back = SItem.fromJson(jsonDecode(jsonEncode(i.toJson())) as Map<String, dynamic>);
        expect(back.id, i.id);
        expect(back.subtest, i.subtest);
        expect(back.tier, i.tier);
        expect(back.options.length, i.options.length);
        expect(back.questions.length, i.questions.length);
        expect(back.answer, i.answer);
        expect(back.only, i.only);
      }
    });
    test('the screening history document has the agreed shape', () {
      final report = Scorer.build(
        responses: {'rhyme': [resp(1), resp(0)]},
        band: GradeBand.junior,
        lang: 'en',
        pool: 'A',
        bg: Background(),
        speechAvailable: false,
        minutes: 9,
      );
      final doc = screeningDoc(studentId: 'child_8829', childName: 'Aryan', report: report, baseline: true);
      expect(doc['student_id'], 'child_8829');
      expect(doc['child_name'], 'Aryan');
      expect(doc['grade_band'], 'Junior');
      expect(DateTime.parse(doc['test_date'] as String).isUtc, true);
      expect(doc['indicator'], matches(RegExp(r'^(low|some|elevated)_indicators$')));
      final cs = doc['construct_scores'] as Map;
      expect((cs['phonological'] as Map).keys, containsAll(['percentile', 'band']));
      expect(doc['observations'], isA<List>());
      expect(doc['kind'], 'baseline');
    });
  });

  group('cloud link', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      QuestionStore.instance.clear();
      Cloud.instance.baseUrl = 'http://test';
    });

    SItem made(String id) => SItem(id: id, subtest: 'rhyme', pool: 'A', difficulty: 3, target: 'cat', say: 'Which one rhymes with cat?', options: const [ChoiceOpt('hat', emoji: '🎩')], source: 'gemini');

    test('an answer is sent, the agent’s 10 new questions are shown and added to the local bank', () async {
      late Map<String, dynamic> sent;
      Cloud.instance.client = MockClient((req) async {
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response.bytes(
            utf8.encode(jsonEncode({'ok': true, 'agent': {'ran': true, 'added': 10, 'bankBefore': 124, 'bankAfter': 134, 'subtest': 'rhyme', 'tier': 'hard', 'ms': 5000, 'questions': [for (var i = 0; i < 10; i++) made('g$i').toJson()]}})),
            200);
      });
      final e = await Cloud.instance.sendResponse({'studentId': 'child_1', 'subtest': 'rhyme', 'itemId': 'r1', 'lang': 'en', 'nextTier': 'hard'});
      expect(sent['studentId'], 'child_1');
      expect(e.status, 'done');
      expect(e.added, 10);
      expect(e.bankAfter - e.bankBefore, 10);
      expect(Cloud.instance.last.value!.status, 'done');
      expect(QuestionStore.instance.generated('en'), 10);
      // and the screening now draws from them
      expect(EnglishScreenBank().forSubtest('rhyme', 'A', GradeBand.junior).every((i) => i.id.startsWith('g')), true);
    });

    test('with no server the screening just runs offline from the bundled questions', () async {
      Cloud.instance.client = MockClient((_) async => throw Exception('no network'));
      final e = await Cloud.instance.sendResponse({'studentId': 'c', 'subtest': 'rhyme', 'itemId': 'r1', 'lang': 'en'});
      expect(e.status, 'offline');
      expect(EnglishScreenBank().forSubtest('rhyme', 'A', GradeBand.junior), isNotEmpty);
    });

    test('a screening that cannot be sent is kept and sent next time', () async {
      var online = false;
      final posted = <Map>[];
      Cloud.instance.client = MockClient((req) async {
        if (!online) throw Exception('offline');
        posted.add(jsonDecode(req.body) as Map);
        return http.Response('{"ok":true}', 200);
      });
      await Cloud.instance.sendScreening({'student_id': 'c1', 'child_name': 'A'});
      expect(posted, isEmpty);
      online = true;
      await Cloud.instance.flushPending();
      expect(posted.single['student_id'], 'c1');
      posted.clear();
      await Cloud.instance.flushPending();
      expect(posted, isEmpty); // not sent twice
    });

    test('a fresh download replaces the phone’s copy: questions removed from the database disappear', () async {
      Cloud.instance.client = MockClient((_) async => http.Response.bytes(utf8.encode(jsonEncode({'questions': [made('g_new').toJson()]})), 200));
      QuestionStore.instance.merge('en', [made('g_old')]);
      await Cloud.instance.syncQuestions('en');
      expect(QuestionStore.instance.forSubtest('en', 'rhyme').map((i) => i.id), ['g_new']);
    });

    test('questions downloaded from the database are kept on the phone', () async {
      Cloud.instance.client = MockClient((_) async => http.Response.bytes(utf8.encode(jsonEncode({'questions': [made('g_a').toJson(), made('g_b').toJson()]})), 200));
      expect(await Cloud.instance.syncQuestions('en'), true);
      QuestionStore.instance.clear();
      await QuestionStore.instance.load('en');
      expect(QuestionStore.instance.size('en'), 2);
    });
  });
}
