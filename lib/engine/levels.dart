import '../models/models.dart';

/// Every game has exactly 4 levels. All 4 levels of a game use the SAME concept; only the difficulty rises.
/// [steps] are the difficulty steps (1–10) the item generator uses for levels 1–4.
class GameLevels {
  final String concept; // one line the child/parent sees, e.g. "Find the word that rhymes"
  final List<String> names; // short level names, shown on the level tiles
  final List<int> steps;
  const GameLevels(this.concept, this.names, this.steps);
}

const levelsPerGame = 4;

/// How many levels of an island's main game unlock its second game.
const unlockSecondAfter = 2;

/// Share of first-try correct answers needed to clear a level (otherwise: "Almost! Play it again").
const levelPassAccuracy = .5;

const gameLevels = <GameId, GameLevels>{
  // Sound Forest
  GameId.soundOrchestra: GameLevels('Find the word that rhymes', ['Easy rhymes', 'Tricky rhymes', 'Listen only', 'Rhyme master'], [2, 3, 5, 7]),
  GameId.soundNinja: GameLevels('Slice the word into its pieces', ['2 beats', '3 beats', 'Long words', 'Every sound'], [1, 2, 3, 4]),
  // Symbol Valley
  GameId.letterArcher: GameLevels('Hit the letter that makes the sound', ['First letters', 'Look-alikes b d p q', 'Letter pairs sh ch', 'Sound teams ar or'], [2, 5, 6, 8]),
  GameId.soundPortal: GameLevels('Connect the sound to its letters', ['Letters', 'Look-alikes', 'Vowel teams ee oa', 'Tricky teams igh ph'], [3, 5, 7, 9]),
  // Word Ocean
  GameId.wordRocket: GameLevels('Blend the sounds into a word', ['3-sound words', 'Blends & pairs', 'Long words', 'Alien names'], [2, 4, 6, 8]),
  GameId.wordBuilder: GameLevels('Build the word from sound blocks', ['Short words', 'Blends', 'Bigger words', 'Made-up names'], [1, 3, 5, 9]),
  // Word Village
  GameId.wordDetective: GameLevels('Find the word you hear', ['Different words', 'Same first letter', 'One letter apart', 'Look-alike traps'], [2, 4, 6, 8]),
  GameId.wordFlash: GameLevels('Remember the flashed word', ['2-second flash', '1.5-second flash', '1-second flash', 'Blink flash'], [2, 4, 6, 9]),
  // Treasure Island
  GameId.spellingHive: GameLevels('Spell the word with letter tiles', ['Short words', 'Letter pairs', 'Longer words', 'Tricky spellings'], [2, 4, 6, 8]),
  GameId.magicWriter: GameLevels('Write the word with your finger', ['Trace it', 'Write with hints', 'Longer words', 'No hints'], [1, 3, 5, 7]),
  // Story Castle
  GameId.storyQuest: GameLevels('Read the story and answer', ['Tiny stories', 'Short stories', 'Why stories', 'Big stories'], [3, 5, 7, 9]),
  // Star Observatory (mixed): every skill at the matching level of its main game
  GameId.starObservatory: GameLevels('Every skill in one sky', ['Star map 1', 'Star map 2', 'Star map 3', 'Star map 4'], [1, 2, 3, 4]),
};

GameLevels levelsOf(GameId g) => gameLevels[g]!;
int levelStep(GameId g, int level, {int bump = 0}) => (levelsOf(g).steps[(level - 1).clamp(0, 3)] + bump).clamp(1, 10);

// ---------------- Story v3: keys ----------------

/// Keys a level can give: normal levels up to 3, the boss level (level 4) up to 5.
int maxKeysFor(int level) => level >= levelsPerGame ? 5 : 3;

/// Keys for one play of a level, from first-try right answers (GAME_DESIGN_V3 §3.1).
/// Normal: 100 % → 3, ≥ 80 % → 2, ≥ 50 % → 1. Boss: 100 % → 5, ≥ 75 % → 3, ≥ 50 % → 1. Less than half → 0.
int keysFor(int level, int right, int total) {
  if (total <= 0) return 0;
  final a = right / total;
  if (a < levelPassAccuracy) return 0;
  if (level >= levelsPerGame) return a >= 1 ? 5 : (a >= .75 ? 3 : 1);
  return a >= 1 ? 3 : (a >= .8 ? 2 : 1);
}

/// All keys one game can give (3 + 3 + 3 + 5).
const keysPerGame = 14;

/// The Storm Trial (7th island): 30 mixed questions, 5 per skill; pass with 21.
const trialQuestions = 30, trialPerSkill = 5, trialPassMark = 21;
