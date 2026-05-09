enum FinalSetType { full, tenPointTb, sixPointTb }

enum GsState { disconnected, connecting, connected }

enum SheetMode { create, existing }

class DriveFolder {
  final String id;
  final String name;
  const DriveFolder({required this.id, required this.name});
}

class DriveSheet {
  final String id;
  final String name;
  final String modified;
  const DriveSheet({required this.id, required this.name, required this.modified});
}

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

  // Google Sheets sync state
  final GsState gsState;
  final String? gsAccount;
  final SheetMode sheetMode;
  final DriveFolder? selectedFolder;
  final DriveSheet? selectedSheet;
  final String? sheetsId;
  final String templateUrl;

  static const String defaultTemplateUrl =
      'https://docs.google.com/spreadsheets/d/1008JYJw2JpdYMP2plfEfGABnEBzNGvryx6FJE08WoP4/edit?usp=sharing';

  const AppSettings({
    this.playerName = 'Me',
    this.formatPreset = 'l7_short',
    this.format = const MatchFormat(),
    this.autoSyncAfterPoint = true,
    this.syncOnMatchEnd = false,
    this.keepOfflineCopy = true,
    this.gsState = GsState.disconnected,
    this.gsAccount,
    this.sheetMode = SheetMode.create,
    this.selectedFolder,
    this.selectedSheet,
    this.sheetsId,
    this.templateUrl = defaultTemplateUrl,
  });

  AppSettings copyWith({
    String? playerName,
    String? formatPreset,
    MatchFormat? format,
    bool? autoSyncAfterPoint,
    bool? syncOnMatchEnd,
    bool? keepOfflineCopy,
    GsState? gsState,
    String? gsAccount,
    bool clearGsAccount = false,
    SheetMode? sheetMode,
    DriveFolder? selectedFolder,
    bool clearSelectedFolder = false,
    DriveSheet? selectedSheet,
    bool clearSelectedSheet = false,
    String? sheetsId,
    bool clearSheetsId = false,
    String? templateUrl,
  }) => AppSettings(
    playerName: playerName ?? this.playerName,
    formatPreset: formatPreset ?? this.formatPreset,
    format: format ?? this.format,
    autoSyncAfterPoint: autoSyncAfterPoint ?? this.autoSyncAfterPoint,
    syncOnMatchEnd: syncOnMatchEnd ?? this.syncOnMatchEnd,
    keepOfflineCopy: keepOfflineCopy ?? this.keepOfflineCopy,
    gsState: gsState ?? this.gsState,
    gsAccount: clearGsAccount ? null : (gsAccount ?? this.gsAccount),
    sheetMode: sheetMode ?? this.sheetMode,
    selectedFolder: clearSelectedFolder ? null : (selectedFolder ?? this.selectedFolder),
    selectedSheet: clearSelectedSheet ? null : (selectedSheet ?? this.selectedSheet),
    sheetsId: clearSheetsId ? null : (sheetsId ?? this.sheetsId),
    templateUrl: templateUrl ?? this.templateUrl,
  );
}
