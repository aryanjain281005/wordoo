import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/core/config.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/engine/skill_model.dart';
import 'package:wordoo/models/models.dart';

void main() {
  final c = GameContent.of('en');

  group('feature-tagged English word database', () {
    test('size, coverage of all 10 steps, units rebuild the word', () {
      expect(c.words.length, greaterThan(700));
      for (var s = 1; s <= 10; s++) {
        expect(c.words.where((w) => w.step == s).length, greaterThanOrEqualTo(10), reason: 'step $s');
      }
      for (final w in c.words) {
        expect(w.units.join(), w.text, reason: w.text);
      }
    });

    test('difficulty is automatic and sensible', () {
      double d(String t) => c.words.firstWhere((w) => w.text == t).difficulty;
      expect(d('cat'), lessThan(d('ship')));
      expect(d('ship'), lessThan(d('train')));
      expect(d('train'), lessThan(d('elephant')));
      expect(d('elephant'), lessThan(d('strawberry')));
      expect(c.words.firstWhere((w) => w.text == 'said').irregular, isTrue);
      expect(c.words.firstWhere((w) => w.text == 'ship').units, ['sh', 'i', 'p']);
    });

    test('each picture stands for one word only', () {
      final emojis = c.words.where((w) => w.emoji != null).map((w) => w.emoji).toList();
      expect(emojis.toSet().length, emojis.length);
    });

    test('made-up words are never real words', () {
      final real = c.words.map((w) => w.text).toSet();
      for (var s = 7; s <= 10; s++) {
        for (final n in c.nonwords(s, 20, s)) {
          expect(real.contains(n.text), isFalse);
          expect(n.nonword, isTrue);
        }
      }
    });
  });

  group('item generator', () {
    test('every skill × every step produces valid items', () {
      final g = ItemGen(c, rng: Random(1));
      for (final s in Skill.values) {
        for (var step = 1; step <= 10; step++) {
          for (var k = 0; k < 12; k++) {
            final it = g.make(s, step);
            if (it.kind == ItemKind.choice) {
              expect(it.options.length, 3, reason: '${it.id}');
              expect(it.options.map((o) => o.label).toSet().length, 3, reason: 'duplicate options ${it.id} ${it.options.map((o) => o.label)}');
              expect(it.correct, inInclusiveRange(0, 2));
              if (it.audioOptions) expect(it.options.every((o) => o.say != null), isTrue);
            } else {
              for (final a in it.answer) {
                expect(it.tiles.contains(a), isTrue);
              }
            }
            expect(it.diff, inInclusiveRange(1, 11));
          }
        }
      }
    });

    test('harder steps really are harder', () {
      final g = ItemGen(c, rng: Random(2));
      double avg(Skill s, int step) => List.generate(20, (_) => g.make(s, step).diff).reduce((a, b) => a + b) / 20;
      for (final s in [Skill.decoding, Skill.spelling, Skill.wordRecognition]) {
        expect(avg(s, 2), lessThan(avg(s, 8)), reason: '$s');
      }
    });

    test('exposure tracking avoids repeating the same items', () {
      final g = ItemGen(c, rng: Random(3));
      final ids = List.generate(30, (_) => g.make(Skill.wordRecognition, 3).id);
      expect(ids.toSet().length, greaterThanOrEqualTo(22));
    });

    test('repeated error types change what is practised', () {
      final g = ItemGen(c, rng: Random(4));
      final it = g.make(Skill.gpc, 9, focus: ['Similar-letter confusion']);
      expect(it.diff, lessThanOrEqualTo(6)); // look-alike letters, not rare patterns
      final ph = g.make(Skill.phonological, 9, focus: ['Wrong first sound']);
      expect(ph.id.startsWith('ps:'), isTrue);
    });
  });

  group('per-skill learner model', () {
    test('screening percentile decides the starting step', () {
      expect(SkillModel.fromScreening(3).step, 1);
      expect(SkillModel.fromScreening(25).step, 3);
      expect(SkillModel.fromScreening(60).step, 5);
      expect(SkillModel.fromScreening(95).step, 7);
    });

    test('success raises, mistakes lower, errors are remembered then fade', () {
      final m = SkillModel.fromScreening(40);
      final start = m.step;
      for (var i = 0; i < 12; i++) {
        m.update(1, m.step.toDouble());
      }
      expect(m.step, greaterThan(start));
      final high = m.step;
      for (var i = 0; i < 14; i++) {
        m.update(0, m.step.toDouble(), tag: 'Wrong vowel');
      }
      expect(m.step, lessThan(high));
      expect(m.focusErrors, contains('Wrong vowel'));
      expect(m.needsScaffold, isTrue);
      for (var i = 0; i < 40; i++) {
        m.update(1, m.step.toDouble());
      }
      expect(m.focusErrors, isNot(contains('Wrong vowel')));
    });

    test('status: ready for challenge vs struggling', () {
      final a = SkillModel.fromScreening(50)..calibrationLeft = 0;
      for (var i = 0; i < 10; i++) {
        a.update(1, a.step - 2);
      }
      a.endRound();
      expect(a.status, SkillStatus.ready);
      final b = SkillModel.fromScreening(50)..calibrationLeft = 0;
      for (var i = 0; i < 6; i++) {
        b.update(0, b.step.toDouble());
      }
      expect(b.status, SkillStatus.struggling);
    });
  });

  group('campaign', () {
    Map<Skill, SkillModel> models(Map<Skill, double> pct) => {for (final s in Skill.values) s: SkillModel.fromScreening(pct[s] ?? 50)};

    test('quest board is always full and puts the weakest skill first', () {
      final m = models({Skill.spelling: 4, Skill.wordRecognition: 90});
      final camp = Campaign()..startTiers(m);
      final b = camp.board(m);
      expect(b.length, Cfg.boardSize);
      expect(b.first.island, IslandId.treasure);
      expect(b.any((q) => q.island == IslandId.village), isTrue); // a strong skill still gets a stretch quest
    });

    test('retest needs all seven islands, not time', () {
      final m = models({});
      final camp = Campaign()..startTiers(m);
      expect(camp.retest(m).ready, isFalse);
      for (final i in islandSkill.keys) {
        camp.islands[i]!.nodes = Cfg.chapterNodes;
      }
      expect(camp.observatoryUnlocked, isTrue);
      for (final mm in m.values) {
        mm.cycleItems = Cfg.retestMinItemsPerSkill;
        mm.history.addAll([5, 5.1, 5.2]);
      }
      expect(camp.retest(m).ready, isFalse, reason: 'observatory not done');
      camp.islands[IslandId.observatory]!.nodes = Cfg.observatoryNodes;
      expect(camp.retest(m).ready, isTrue);
    });

    test('after the chapters the board keeps offering meaningful quests', () {
      final m = models({});
      final camp = Campaign()..startTiers(m);
      for (final i in IslandId.values) {
        camp.islands[i]!.nodes = 99;
      }
      final b = camp.board(m);
      expect(b.length, Cfg.boardSize);
      expect(b.every((q) => q.kind == QuestKind.bonus || q.kind == QuestKind.echo), isTrue);
    });

    test('a new season grows every island a tier', () {
      final m = models({});
      final camp = Campaign()..startTiers(m);
      camp.islands[IslandId.forest]!.nodes = 10;
      camp.nextSeason(m);
      expect(camp.season, 2);
      expect(camp.islands.values.every((i) => i.tier == 2 && i.nodes == 0), isTrue);
    });
  });
}
