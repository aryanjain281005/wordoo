import '../engine/campaign.dart';

/// Which guardian tells the story beat on each island.
const islandGuardian = {
  IslandId.forest: 'bhalu',
  IslandId.valley: 'arya',
  IslandId.ocean: 'kachhua',
  IslandId.village: 'ullu',
  IslandId.treasure: 'madhu',
  IslandId.castle: 'pari',
  IslandId.observatory: 'milo',
};

/// Voice-line id of the story beat that opens a quest (matches assets/story/lines_en.json).
String beatLineFor(Quest q, Campaign c) {
  final n = q.island == IslandId.observatory ? 6 : 10;
  final idx = q.node >= 0 ? q.node : (c.islands[q.island]!.tier * 3 + q.title.length) % n;
  return 'beat_${q.island.name}_${idx % n}';
}
