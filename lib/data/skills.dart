import 'package:flutter/material.dart';
import '../models/models.dart';

class SkillMeta {
  final Skill skill;
  final String name; // adult-facing parameter name
  final String shortName;
  final String emoji;
  final String region; // child-facing map region
  final String regionTag; // small subtitle
  final String station; // first-adventure station title
  final Color color;
  final List<GameId> games;
  final GameId demoGame;
  final String support; // plain-language description for adults
  const SkillMeta(this.skill, this.name, this.shortName, this.emoji, this.region, this.regionTag, this.station,
      this.color, this.games, this.demoGame, this.support);
}

class GameMeta {
  final GameId id;
  final Skill skill;
  final String name;
  final String emoji;
  final String tagline;
  final String how; // one-line spoken/visible explanation
  final bool playable;
  final Color color;
  const GameMeta(this.id, this.skill, this.name, this.emoji, this.tagline, this.how, this.playable, this.color);
}

class Skills {
  static const all = Skill.values;

  static const meta = <Skill, SkillMeta>{
    Skill.phonological: SkillMeta(
        Skill.phonological, 'Phonological Awareness', 'Sounds', '👂', 'Sound Forest', 'Foundations', 'Find the Sounds',
        Color(0xFF2FA866), [GameId.soundOrchestra, GameId.soundNinja], GameId.soundOrchestra,
        'Hearing, blending and changing the sounds inside spoken words.'),
    Skill.gpc: SkillMeta(Skill.gpc, 'Grapheme–Phoneme Correspondence', 'Letters & Sounds', '🏹', 'Symbol Valley', 'Letters',
        'Match the Letters', Color(0xFF8E5BE0), [GameId.letterArcher, GameId.soundPortal], GameId.letterArcher,
        'Connecting written letters / aksharas with the sounds they make.'),
    Skill.decoding: SkillMeta(Skill.decoding, 'Decoding', 'Decoding', '🚀', 'Word Ocean', 'Decoding', 'Read the Words',
        Color(0xFF1E88E5), [GameId.wordRocket, GameId.wordBuilder], GameId.wordRocket,
        'Blending written sound units into a spoken word.'),
    Skill.wordRecognition: SkillMeta(Skill.wordRecognition, 'Word Recognition', 'Word Recognition', '🔍', 'Word Village',
        'Familiar words', 'Spot the Word', Color(0xFFF08A24), [GameId.wordDetective, GameId.wordFlash],
        GameId.wordDetective, 'Quickly and accurately recognising familiar written words.'),
    Skill.spelling: SkillMeta(Skill.spelling, 'Spelling / Writing', 'Spelling', '🐝', 'Treasure Island', 'Spelling',
        'Spell it Right', Color(0xFFE0A100), [GameId.spellingHive, GameId.magicWriter], GameId.spellingHive,
        'Building and writing words from sounds and written units.'),
    Skill.comprehension: SkillMeta(Skill.comprehension, 'Reading Comprehension', 'Comprehension', '📖', 'Story Castle',
        'Comprehension', 'Story Challenge', Color(0xFFE0568A), [GameId.storyQuest], GameId.storyQuest,
        'Understanding what happened, why it happened, and what comes next.'),
  };

  static const games = <GameId, GameMeta>{
    GameId.soundOrchestra: GameMeta(GameId.soundOrchestra, Skill.phonological, 'Sound Orchestra', '🎻',
        'Hear it. Match it.', 'Listen, then pick the matching sound.', true, Color(0xFF2FA866)),
    GameId.soundNinja: GameMeta(GameId.soundNinja, Skill.phonological, 'Sound Ninja', '⚔️', 'Slice the sounds.',
        'Remove or swap sounds in spoken words.', false, Color(0xFF2FA866)),
    GameId.letterArcher: GameMeta(GameId.letterArcher, Skill.gpc, 'Letter Archer', '🏹', 'Hear a sound, hit the letter.',
        'Listen, then shoot the matching letter.', true, Color(0xFF8E5BE0)),
    GameId.soundPortal: GameMeta(GameId.soundPortal, Skill.gpc, 'Sound Portal', '🌀', 'Connect symbols to sounds.',
        'Link written patterns with their sounds.', false, Color(0xFF8E5BE0)),
    GameId.wordRocket: GameMeta(GameId.wordRocket, Skill.decoding, 'Word Rocket', '🚀', 'Blend sounds. Launch!',
        'Blend the sounds to power the rocket.', true, Color(0xFF1E88E5)),
    GameId.wordBuilder: GameMeta(GameId.wordBuilder, Skill.decoding, 'Word Builder', '🏗️', 'Build unknown words.',
        'Construct new words from sound pieces.', false, Color(0xFF1E88E5)),
    GameId.wordDetective: GameMeta(GameId.wordDetective, Skill.wordRecognition, 'Word Detective', '🕵️',
        'Spot the right word.', 'Find the word you hear among look-alikes.', true, Color(0xFFF08A24)),
    GameId.wordFlash: GameMeta(GameId.wordFlash, Skill.wordRecognition, 'Word Flash', '⚡', 'Peek, hide, find.',
        'See a word briefly, then find it.', false, Color(0xFFF08A24)),
    GameId.spellingHive: GameMeta(GameId.spellingHive, Skill.spelling, 'Spelling Hive', '🐝', 'Build the word with tiles.',
        'Hear the word, then build it with tiles.', true, Color(0xFFE0A100)),
    GameId.magicWriter: GameMeta(GameId.magicWriter, Skill.spelling, 'Magic Writer', '✨', 'Trace and write.',
        'Trace letters and short words.', false, Color(0xFFE0A100)),
    GameId.storyQuest: GameMeta(GameId.storyQuest, Skill.comprehension, 'Story Quest', '📖', 'Read. Think. Answer.',
        'Read a tiny story, then answer.', true, Color(0xFFE0568A)),
  };

  static SkillMeta of(Skill s) => meta[s]!;
  static GameMeta game(GameId g) => games[g]!;
}

class Collectible {
  final String id, name, emoji;
  final int stars; // stars needed
  final String kind; // hat | friend | room | gear
  const Collectible(this.id, this.name, this.emoji, this.stars, this.kind);
}

class Collectibles {
  static const all = [
    Collectible('hat-explorer', 'Explorer Hat', '🤠', 5, 'hat'),
    Collectible('friend-cat', 'Blue Kitten', '🐱', 10, 'friend'),
    Collectible('room-plant', 'Magic Plant', '🌱', 15, 'room'),
    Collectible('hat-wizard', 'Wizard Hat', '🧙', 22, 'hat'),
    Collectible('gear-compass', 'Treasure Map', '🗺️', 30, 'gear'),
    Collectible('room-globe', 'Story Globe', '🌍', 38, 'room'),
    Collectible('hat-crown', 'Gold Crown', '👑', 48, 'hat'),
    Collectible('friend-owl', 'Wise Owl', '🦉', 58, 'friend'),
    Collectible('room-lamp', 'Star Lamp', '💡', 70, 'room'),
    Collectible('gear-telescope', 'Telescope', '🔭', 85, 'gear'),
  ];
}

class BadgeDef {
  final String id, name, emoji;
  const BadgeDef(this.id, this.name, this.emoji);
}

class Badges {
  static const first = BadgeDef('first', 'First Adventure', '🌉');
  static BadgeDef forSkill(Skill s) => BadgeDef('skill-${s.name}', '${Skills.of(s).region} Explorer', Skills.of(s).emoji);
  static const day = BadgeDef('day', 'Daily Adventurer', '🌟');
  static const week = BadgeDef('week', 'Week Champion', '🏆');
  static const levelUp = BadgeDef('levelup', 'Level Climber', '🧗');
}

class BandInfo {
  static String label(Band b) => switch (b) {
        Band.strong => 'Strong',
        Band.developing => 'Developing',
        Band.needsSupport => 'Needs Support',
      };
  static Color color(Band b) => switch (b) {
        Band.strong => const Color(0xFF2FA866),
        Band.developing => const Color(0xFFF2A21B),
        Band.needsSupport => const Color(0xFFEF7A3C),
      };
  static String childLine(Band b) => switch (b) {
        Band.strong => 'Ready for bigger challenges',
        Band.developing => 'Getting stronger every day',
        Band.needsSupport => 'Let’s practise this together',
      };
}
