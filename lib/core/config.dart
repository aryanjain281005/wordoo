/// All tunable engine constants live here — nothing is hard-coded in the UI.
class Cfg {
  // Adaptive difficulty thresholds (recent accuracy 0..1)
  static const double increaseAccuracy = 0.90;
  static const double maintainAccuracy = 0.60;

  // How many recent attempts per skill the engine looks at
  static const int recentWindow = 8;
  static const int minAttemptsToAdapt = 4;

  // Micro adaptation inside a single game round
  static const int streakToLevelUp = 2;
  static const int missesToLevelDown = 2;

  // Difficulty levels
  static const int minLevel = 1;
  static const int maxLevel = 4;
  static const int levelStrong = 3;
  static const int levelDeveloping = 2;
  static const int levelNeedsSupport = 1;

  // Skill banding. Skill scores are screening percentiles (0..100):
  // Strong ≥ 50th percentile, Developing 16th–50th, Needs Support < 16th.
  static const double strongCut = 50;
  static const double developingCut = 16;

  // Practice shape
  static const int itemsPerRound = 5;
  static const int missionsPerDay = 3;
  static const int daysPerWeek = 7;
  static const int targetMinutesPerDay = 10;

  // Word recognition: answers slower than this are tagged "slow response"
  static const int slowResponseMs = 6000;

  // Skill points
  static const int pointsPerStar = 10;
}
