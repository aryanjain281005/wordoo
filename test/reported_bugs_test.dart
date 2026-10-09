import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/models/models.dart';

/// Regression tests for bugs reported by the team (10 Oct).
void main() {
  final c = GameContent.of('en');
  final fam = c.rhymeFamily;

  test('Sound Orchestra: every right answer really rhymes, no wrong answer does (all 4 levels)', () {
    final gen = ItemGen(c, rng: Random(11));
    for (var l = 1; l <= 4; l++) {
      for (var k = 0; k < 200; k++) {
        final it = gen.forLevel(GameId.soundOrchestra, l);
        final target = it.say.split(' ').last.replaceAll('?', '');
        final right = it.options[it.correct].label;
        expect(fam[target], isNotNull, reason: target);
        expect(fam[right], fam[target], reason: '$target → $right');
        for (final o in it.options.where((o) => o.label != right)) {
          expect(fam[o.label] == fam[target], isFalse, reason: '$target: ${o.label} also rhymes');
        }
      }
    }
    // the words that broke level 2 are no longer used as rhymes
    for (final w in ['owl', 'bowl', 'cow', 'snow', 'horse', 'cheese', 'boot', 'foot', 'pie', 'cookie', 'swan']) {
      expect(fam.containsKey(w), isFalse, reason: w);
    }
  });

  test('Word Detective: levels 1–2 show the signs plainly (no fog)', () {
    final gen = ItemGen(c, rng: Random(2));
    for (final l in [1, 2]) {
      expect(gen.forLevel(GameId.wordDetective, l).level, lessThan(6), reason: 'fog starts at step 6 (level 3)');
    }
    expect(gen.forLevel(GameId.wordDetective, 3).level, greaterThanOrEqualTo(6));
  });
}
