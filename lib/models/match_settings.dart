enum FinalSetType { full, tenPointTb, sixPointTb }

class MatchFormat {
  final int setsInMatch;
  final int gamesPerSet;
  final bool adScoring;
  final int tiebreakPoints; // 0 = no tiebreak
  final FinalSetType finalSet;

  const MatchFormat({
    this.setsInMatch = 3,
    this.gamesPerSet = 4,
    this.adScoring = false,
    this.tiebreakPoints = 7,
    this.finalSet = FinalSetType.tenPointTb,
  });

  int get setsToWin => (setsInMatch / 2).ceil();

  MatchFormat copyWith({
    int? setsInMatch,
    int? gamesPerSet,
    bool? adScoring,
    int? tiebreakPoints,
    FinalSetType? finalSet,
  }) => MatchFormat(
    setsInMatch: setsInMatch ?? this.setsInMatch,
    gamesPerSet: gamesPerSet ?? this.gamesPerSet,
    adScoring: adScoring ?? this.adScoring,
    tiebreakPoints: tiebreakPoints ?? this.tiebreakPoints,
    finalSet: finalSet ?? this.finalSet,
  );

  static const Map<String, MatchFormat> presets = {
    'l7_short': MatchFormat(
      setsInMatch: 3, gamesPerSet: 4, adScoring: false,
      tiebreakPoints: 7, finalSet: FinalSetType.tenPointTb,
    ),
    'l7_regular': MatchFormat(
      setsInMatch: 1, gamesPerSet: 6, adScoring: false,
      tiebreakPoints: 7, finalSet: FinalSetType.full,
    ),
    'l6': MatchFormat(
      setsInMatch: 3, gamesPerSet: 6, adScoring: false,
      tiebreakPoints: 7, finalSet: FinalSetType.tenPointTb,
    ),
    'l5': MatchFormat(
      setsInMatch: 3, gamesPerSet: 6, adScoring: true,
      tiebreakPoints: 7, finalSet: FinalSetType.full,
    ),
  };

  static const Map<String, String> presetLabels = {
    'l7_short':   'Level 7 — Short Sets',
    'l7_regular': 'Level 7 — One Set',
    'l6':         'Level 6',
    'l5':         'Level 5',
    'custom':     'Custom',
  };

  static const Map<String, String> presetSubtitles = {
    'l7_short':   'First to 4 games · 4–4 = 7-pt set TB · split sets = match TB',
    'l7_regular': '1 set to 6 games · 7-pt tiebreak at 6-all · no-ad',
    'l6':         '6-game sets · best of 3 · 7-pt tiebreak · no-ad',
    'l5':         '6-game sets · best of 3 · 7-pt tiebreak · ad scoring',
    'custom':     'Configure manually below',
  };

  static const Map<String, String> presetNotes = {
    'l7_short': 'Short sets to 4. At 4–4 a 7-pt set tiebreak. Split sets → 10-pt match tiebreak.',
    'l7_regular': 'Single set to 6 games. 7-pt tiebreak at 6-all.',
    'l6': '',
    'l5': '',
    'custom': '',
  };
}

class AppSettings {
  final String playerName;
  final String formatPreset;
  final MatchFormat format;
  final bool autoSyncAfterPoint;
  final bool syncOnMatchEnd;
  final bool keepOfflineCopy;

  const AppSettings({
    this.playerName = 'Me',
    this.formatPreset = 'l7_short',
    this.format = const MatchFormat(),
    this.autoSyncAfterPoint = true,
    this.syncOnMatchEnd = false,
    this.keepOfflineCopy = true,
  });

  AppSettings copyWith({
    String? playerName,
    String? formatPreset,
    MatchFormat? format,
    bool? autoSyncAfterPoint,
    bool? syncOnMatchEnd,
    bool? keepOfflineCopy,
  }) => AppSettings(
    playerName: playerName ?? this.playerName,
    formatPreset: formatPreset ?? this.formatPreset,
    format: format ?? this.format,
    autoSyncAfterPoint: autoSyncAfterPoint ?? this.autoSyncAfterPoint,
    syncOnMatchEnd: syncOnMatchEnd ?? this.syncOnMatchEnd,
    keepOfflineCopy: keepOfflineCopy ?? this.keepOfflineCopy,
  );
}
