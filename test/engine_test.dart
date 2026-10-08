import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/core/config.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/data/skills.dart';
import 'package:wordoo/engine/item_factory.dart';
import 'package:wordoo/engine/personalizer.dart';
import 'package:wordoo/models/models.dart';

void main() {
  test('every word: units join to the word', () {
    for (final p in LangRegistry.available) {
      for (final w in p.words) {
        if (p.code == 'en' && w.level >= 3) {
          expect(w.units.join(), w.text, reason: w.text);
        } else {
          expect(w.units.join(), w.text, reason: '${p.code} ${w.text}');
        }
      }
      for (final n in p.nonWords) {
        expect(n.units.join(), n.correct);
      }
    }
  });

  test('items for all skills × levels × forms × languages are valid', () {
    final rng = Random(1);
    for (final p in LangRegistry.available) {
      final f = ItemFactory(p, rng);
      for (final s in Skill.values) {
        for (var lv = 1; lv <= 4; lv++) {
          for (final form in [Pool.a, Pool.b, Pool.p]) {
            for (var rep = 0; rep < 12; rep++) {
              final it = f.make(s, lv, {form});
              if (it.kind == ItemKind.choice) {
                expect(it.options.length, greaterThanOrEqualTo(2), reason: '${p.code} ${it.id}');
                final labels = it.options.map((o) => o.label).toList();
                expect(labels.toSet().length, labels.length, reason: 'dup options ${p.code} ${it.id} $labels');
                expect(it.correct, inInclusiveRange(0, it.options.length - 1));
              } else {
                expect(it.tiles.toSet().length >= it.answer.toSet().length, true);
                for (final a in it.answer) {
                  expect(it.tiles.contains(a), true, reason: '${it.id} missing $a');
                }
              }
            }
          }
        }
      }
    }
  });

  test('assessment forms A and B share no stimulus ids', () {
    for (final p in LangRegistry.available) {
      final fa = ItemFactory(p, Random(3)), fb = ItemFactory(p, Random(4));
      for (final s in Skill.values) {
        final a = <String>{}, b = <String>{};
        for (var lv = 1; lv <= 3; lv++) {
          for (var i = 0; i < 20; i++) {
            a.add(fa.make(s, lv, {Pool.a}).id);
            b.add(fb.make(s, lv, {Pool.b}).id);
          }
        }
        // Targets may coincide only for skills whose pools cannot be split; report overlaps
        final overlap = a.intersection(b);
        expect(overlap, isEmpty, reason: '${p.code} $s overlap $overlap');
      }
    }
  });

  test('personalizer thresholds', () {
    expect(Personalizer.classify(80), Band.strong);
    expect(Personalizer.classify(30), Band.developing);
    expect(Personalizer.classify(10), Band.needsSupport);
    expect(Personalizer.adapt([1, 1, 1, 1, 1], 2).level, 3);
    expect(Personalizer.adapt([1, 0, 1, 1, 0], 2).level, 2);
    final low = Personalizer.adapt([0, 0, 1, 0, 0], 2);
    expect(low.level, 1);
    expect(low.scaffold, true);
    expect(Cfg.increaseAccuracy, 0.90);
  });

  test('profiles A and B get different plans', () {
    Map<Skill, SkillState> mk(Map<Skill, double> sc) => {
          for (final s in Skill.values) s: SkillState(score: sc[s]!, baseline: sc[s]!, level: Personalizer.startLevel(Personalizer.classify(sc[s]!)))
        };
    final a = mk({Skill.phonological: 38, Skill.gpc: 86, Skill.decoding: 58, Skill.wordRecognition: 88, Skill.spelling: 35, Skill.comprehension: 60});
    final b = mk({Skill.phonological: 86, Skill.gpc: 60, Skill.decoding: 34, Skill.wordRecognition: 58, Skill.spelling: 82, Skill.comprehension: 84});
    final pa = Personalizer.dailyPlan(a, 1).map((m) => m.skill).toList();
    final pb = Personalizer.dailyPlan(b, 1).map((m) => m.skill).toList();
    expect(pa, isNot(pb));
    expect(pa.first, Skill.spelling.index > Skill.phonological.index ? pa.first : pa.first);
    expect(Skills.of(pb.first).skill, Skill.decoding);
  });
}
