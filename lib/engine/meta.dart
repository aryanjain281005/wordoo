import 'campaign.dart';

/// Long-term rewards (GAME_DESIGN §5). Everything here is earned by playing and tied to real reading,
/// never bought, never random loot, and nothing is ever taken away.

/// One collectable thing inside a collection, unlocked when the collection's counter reaches [at].
class CollectItem {
  final int at;
  final String emoji, name;
  const CollectItem(this.at, this.emoji, this.name);
}

/// A collection that grows from one game's persistent counter.
class CollectionDef {
  final String id, name, emoji, game, unit;
  final List<CollectItem> items;
  const CollectionDef(this.id, this.name, this.emoji, this.game, this.unit, this.items);

  List<CollectItem> unlockedAt(int count) => items.where((i) => count >= i.at).toList();
  CollectItem? nextAt(int count) {
    for (final i in items) {
      if (count < i.at) return i;
    }
    return null;
  }
}

/// Thresholds that start easy and stretch out, so new things keep arriving for months.
List<int> _ladder(int n, {int first = 1}) {
  final out = <int>[];
  var v = first, step = 1;
  for (var i = 0; i < n; i++) {
    out.add(v);
    if (i % 3 == 2) step++;
    v += step;
  }
  return out;
}

List<CollectItem> _items(List<(String, String)> l, {int first = 1}) {
  final at = _ladder(l.length, first: first);
  return [for (var i = 0; i < l.length; i++) CollectItem(at[i], l[i].$1, l[i].$2)];
}

final collections = <CollectionDef>[
  CollectionDef('band', 'Band Stickers', '🎻', 'Sound Orchestra', 'sounds heard right', _items([
    ('🥁', 'Tabla Beat'), ('🎵', 'Bansuri Breeze'), ('🎺', 'Trumpet Toot'), ('🎸', 'Sitar Strum'), ('🪘', 'Dhol Boom'), ('🎹', 'Harmonium Hum'),
    ('🎷', 'Jazzy Sax'), ('🔔', 'Temple Bell'), ('🎻', 'Violin Swirl'), ('🎼', 'Song Sheet'), ('🎤', 'Koyal Solo'), ('🌟', 'Full Band Star'),
  ])),
  CollectionDef('lanterns', 'Lantern Colours', '🏮', 'Letter Archer', 'lanterns lit', _items([
    ('🔴', 'Ruby Red'), ('🟠', 'Mango Orange'), ('🟡', 'Marigold Yellow'), ('🟢', 'Parrot Green'), ('🔵', 'Peacock Blue'), ('🟣', 'Jamun Purple'),
    ('💗', 'Lotus Pink'), ('🤎', 'Chai Brown'), ('⚪', 'Moon White'), ('🌈', 'Rainbow'), ('✨', 'Sparkle'), ('🌟', 'Golden Lantern'),
  ])),
  CollectionDef('sea', 'Sea Log', '🐠', 'Word Rocket', 'words blended', _items([
    ('🐟', 'Silver Fish'), ('🐠', 'Clown Fish'), ('🦀', 'Red Crab'), ('🐡', 'Puffer Fish'), ('🐢', 'Sea Turtle'), ('🦐', 'Shrimp'),
    ('🐙', 'Octopus'), ('🦑', 'Squid'), ('🐬', 'Dolphin'), ('🦈', 'Friendly Shark'), ('🐋', 'Blue Whale'), ('🦪', 'Pearl Oyster'),
  ])),
  CollectionDef('cases', 'Case Files', '🗂️', 'Word Detective', 'clues found', _items([
    ('🔍', 'Rookie Lens'), ('📒', 'Clue Notebook'), ('🕵️', 'Detective Hat'), ('🐾', 'Paw-Print Kit'), ('🔦', 'Torch'), ('🗝️', 'Secret Key'),
    ('🧭', 'Compass'), ('📜', 'Old Map'), ('🎩', 'Top Hat'), ('🏅', 'Gold Badge'), ('🦉', 'Ullu’s Feather'), ('👑', 'Chief Inspector'),
  ], first: 3)),
  CollectionDef('hive', 'Hive Bees', '🐝', 'Spelling Hive', 'words spelt', _items([
    ('🐝', 'Baby Bee'), ('🍯', 'Honey Jar'), ('🌻', 'Sunflower'), ('🌼', 'Daisy'), ('🌸', 'Blossom'), ('🌺', 'Hibiscus'),
    ('🏵️', 'Rosette'), ('🌷', 'Tulip'), ('💐', 'Bouquet'), ('🍀', 'Clover'), ('🌹', 'Rose'), ('👑', 'Queen’s Crown'),
  ])),
  CollectionDef('library', 'Story Library', '📚', 'Story Quest', 'stories understood', _items([
    ('📕', 'Red Book'), ('📗', 'Green Book'), ('📘', 'Blue Book'), ('📙', 'Orange Book'), ('📔', 'Diary'), ('📓', 'Notebook'),
    ('📒', 'Yellow Book'), ('📚', 'Book Stack'), ('🔖', 'Bookmark'), ('🪶', 'Quill'), ('🏰', 'Castle Tower'), ('✨', 'Kitabu’s Ending'),
  ])),
];

/// Story Gems: one per finished island chapter, every season.
const islandGem = {
  IslandId.forest: ('💚', 'Emerald of Sounds'),
  IslandId.valley: ('💜', 'Amethyst of Letters'),
  IslandId.ocean: ('💙', 'Sapphire of Blends'),
  IslandId.village: ('🧡', 'Amber of Words'),
  IslandId.treasure: ('💛', 'Topaz of Spelling'),
  IslandId.castle: ('💗', 'Rose Quartz of Stories'),
  IslandId.observatory: ('🤍', 'Star Diamond'),
};

String gemId(int season, IslandId i) => 's$season:${i.name}';

/// Cosy streak: every day played makes a flower bloom on the Story Tree. Missing a day never removes
/// anything; a "rain day" (one day off between two play days) keeps the run going.
class CozyStreak {
  final int flowers; // total different days played (only ever grows)
  final int run; // days in the current run (rain days do not break it)
  final bool rainDayUsed; // the latest gap was covered by a rain day
  const CozyStreak(this.flowers, this.run, this.rainDayUsed);

  factory CozyStreak.from(Set<String> days, {DateTime? today}) {
    if (days.isEmpty) return const CozyStreak(0, 0, false);
    final d = days.map(DateTime.parse).toList()..sort();
    var run = 1;
    var rain = false;
    for (var i = d.length - 1; i > 0; i--) {
      final gap = d[i].difference(d[i - 1]).inDays;
      if (gap <= 1) {
        run++;
      } else if (gap == 2) {
        run++;
        if (i == d.length - 1) rain = true;
      } else {
        break;
      }
    }
    final now = today ?? DateTime.now();
    final since = DateTime(now.year, now.month, now.day).difference(d.last).inDays;
    // the run is still "alive" for today and for one rain day after the last visit
    return CozyStreak(d.length, since <= 2 ? run : 0, rain || since == 2);
  }
}

/// Surprise gifts reward effort, not luck: each mistake a child works through adds effort points;
/// at [giftEvery] points Milo finds a gift. Deterministic, never random.
const giftEvery = 6;
const effortGifts = [
  ('🎈', 'Balloon'), ('🪁', 'Kite'), ('🧸', 'Teddy'), ('🪀', 'Yo-yo'), ('🎨', 'Paint Set'), ('🧩', 'Puzzle Piece'),
  ('🚂', 'Toy Train'), ('🪅', 'Piñata'), ('🛼', 'Roller Skate'), ('🎐', 'Wind Chime'), ('🪃', 'Boomerang'), ('🎠', 'Carousel Horse'),
];

/// Guardian teaser for the island the next quest is on ("Next time…").
String teaserLineId(IslandId i) => 'tease_${i.name}';
