/// All tunable engine constants live here — nothing is hard-coded in the UI.
class Cfg {
  // Skill banding. Skill scores are screening percentiles (0..100):
  // Strong ≥ 50th percentile, Developing 16th–50th, Needs Support < 16th.
  static const double strongCut = 50;
  static const double developingCut = 16;

  // ---------------- long-term game system ----------------
  // Difficulty ladder per skill (no global level anywhere).
  static const int minStep = 1;
  static const int maxStep = 10;
  static const double targetSuccess = .78; // aim for ~78 % success: hard enough to grow, easy enough to enjoy
  static const double kCalibration = .9; // big jumps while finding the level
  static const double kNormal = .35;
  static const int calibrationRounds = 2;
  static const double errorDecay = .93;
  static const double errorFocusAt = 2.0; // an error tag becomes a practice target
  static const int missesToScaffold = 2;
  static const int slowRtMs = 7000;
  static const double stableRange = .8;

  /// Screening percentile → starting step (upper limit exclusive, step).
  static const startStepTable = <(double, int)>[(5, 1), (16, 2), (30, 3), (50, 4), (70, 5), (85, 6), (101, 7)];

  // Round length depends on the quest, not on the clock.
  static const int itemsProbe = 6, itemsSupport = 5, itemsStandard = 6, itemsChallenge = 8, itemsBoss = 8, itemsMixed = 6;

  // Islands & cycles
  static const int chapterNodes = 10; // per skill island per cycle (node 10 = boss)
  static const int observatoryNodes = 6;
  static const int retestMinItemsPerSkill = 60;
  static const int boardSize = 3;

  // Skill points
  static const int pointsPerStar = 10;

  // Word recognition: answers slower than this are tagged "slow response"
  static const int slowResponseMs = 6000;

}
