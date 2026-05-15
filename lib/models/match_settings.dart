enum ScoringType { ad, noAd }

enum TiebreakWinType { twoPointMargin, suddenDeath }

enum MatchFormatType { bestOf3MatchTb, bestOf3FullSet, singleSet }

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
  final int setWinThreshold;
  final int setTiebreakAt;
  final ScoringType scoringType;
  final TiebreakWinType tiebreakWinType;
  final MatchFormatType matchFormatType;
  final int setTiebreakPts;
  final int matchTiebreakPts;

  const MatchFormat({
    this.setWinThreshold = 6,
    this.setTiebreakAt = 6,
    this.scoringType = ScoringType.noAd,
    this.tiebreakWinType = TiebreakWinType.twoPointMargin,
    this.matchFormatType = MatchFormatType.singleSet,
    this.setTiebreakPts = 7,
    this.matchTiebreakPts = 10,
  });

  int get setsToWin => matchFormatType == MatchFormatType.singleSet ? 1 : 2;

  MatchFormat copyWith({
    int? setWinThreshold,
    int? setTiebreakAt,
    ScoringType? scoringType,
    TiebreakWinType? tiebreakWinType,
    MatchFormatType? matchFormatType,
    int? setTiebreakPts,
    int? matchTiebreakPts,
  }) =>
      MatchFormat(
        setWinThreshold: setWinThreshold ?? this.setWinThreshold,
        setTiebreakAt: setTiebreakAt ?? this.setTiebreakAt,
        scoringType: scoringType ?? this.scoringType,
        tiebreakWinType: tiebreakWinType ?? this.tiebreakWinType,
        matchFormatType: matchFormatType ?? this.matchFormatType,
        setTiebreakPts: setTiebreakPts ?? this.setTiebreakPts,
        matchTiebreakPts: matchTiebreakPts ?? this.matchTiebreakPts,
      );

  static const Map<String, MatchFormat> presets = {
    'l1_l4_full': MatchFormat(
      setWinThreshold: 6,
      setTiebreakAt: 6,
      scoringType: ScoringType.ad,
      tiebreakWinType: TiebreakWinType.twoPointMargin,
      matchFormatType: MatchFormatType.bestOf3FullSet,
    ),
    'l1_l4_match_tb': MatchFormat(
      setWinThreshold: 6,
      setTiebreakAt: 6,
      scoringType: ScoringType.ad,
      tiebreakWinType: TiebreakWinType.twoPointMargin,
      matchFormatType: MatchFormatType.bestOf3MatchTb,
    ),
    'l5_l6_standard': MatchFormat(
      setWinThreshold: 6,
      setTiebreakAt: 6,
      scoringType: ScoringType.noAd,
      tiebreakWinType: TiebreakWinType.twoPointMargin,
      matchFormatType: MatchFormatType.bestOf3MatchTb,
    ),
    'l7_standard_single': MatchFormat(
      setWinThreshold: 6,
      setTiebreakAt: 6,
      scoringType: ScoringType.noAd,
      tiebreakWinType: TiebreakWinType.twoPointMargin,
      matchFormatType: MatchFormatType.singleSet,
    ),
    'l7_short_best_of_3': MatchFormat(
      setWinThreshold: 4,
      setTiebreakAt: 4,
      scoringType: ScoringType.noAd,
      tiebreakWinType: TiebreakWinType.twoPointMargin,
      matchFormatType: MatchFormatType.bestOf3MatchTb,
    ),
    'l7_timed_standard': MatchFormat(
      setWinThreshold: 6,
      setTiebreakAt: 6,
      scoringType: ScoringType.noAd,
      tiebreakWinType: TiebreakWinType.suddenDeath,
      matchFormatType: MatchFormatType.singleSet,
    ),
    'l7_timed_short': MatchFormat(
      setWinThreshold: 4,
      setTiebreakAt: 4,
      scoringType: ScoringType.noAd,
      tiebreakWinType: TiebreakWinType.suddenDeath,
      matchFormatType: MatchFormatType.singleSet,
    ),
    'pro_set_standard': MatchFormat(
      setWinThreshold: 8,
      setTiebreakAt: 8,
      scoringType: ScoringType.noAd,
      tiebreakWinType: TiebreakWinType.twoPointMargin,
      matchFormatType: MatchFormatType.singleSet,
    ),
    'pro_set_sudden_death': MatchFormat(
      setWinThreshold: 8,
      setTiebreakAt: 8,
      scoringType: ScoringType.noAd,
      tiebreakWinType: TiebreakWinType.suddenDeath,
      matchFormatType: MatchFormatType.singleSet,
    ),
  };

  static const Map<String, String> presetLabels = {
    'l1_l4_full': 'Level 1-4 (Full 3rd Set)',
    'l1_l4_match_tb': 'Level 1-4 (Match Tiebreak)',
    'l5_l6_standard': 'Level 5-6 Standard',
    'l7_standard_single': 'Level 7 Standard (Single Set)',
    'l7_short_best_of_3': 'Level 7 Short Sets (Best of 3)',
    'l7_timed_standard': 'Level 7 Timed (Standard Set)',
    'l7_timed_short': 'Level 7 Timed (Short Set)',
    'pro_set_standard': 'Pro-Set (Standard)',
    'pro_set_sudden_death': 'Pro-Set (Sudden Death)',
    'custom': 'Custom',
  };

  static const Map<String, String> presetSubtitles = {
    'l1_l4_full': '6-game sets · Ad scoring · Full 3rd set',
    'l1_l4_match_tb': '6-game sets · Ad scoring · 10-pt Match TB',
    'l5_l6_standard': '6-game sets · No-Ad scoring · 10-pt Match TB',
    'l7_standard_single': '6-game sets · No-Ad scoring · Single Set',
    'l7_short_best_of_3': '4-game Short Sets · No-Ad scoring · 10-pt Match TB',
    'l7_timed_standard': '6-game sets · No-Ad scoring · Sudden Death TB',
    'l7_timed_short': '4-game sets · No-Ad scoring · Sudden Death TB',
    'pro_set_standard': '8-game set · No-Ad scoring · 7-pt TB at 8-8',
    'pro_set_sudden_death': '8-game set · No-Ad scoring · Sudden Death TB at 8-8',
    'custom': 'Configure manually below',
  };
}

class AppSettings {
  final String formatPreset;
  final MatchFormat format;

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
    this.formatPreset = 'l7_standard_single',
    this.format = const MatchFormat(),
    this.gsState = GsState.disconnected,
    this.gsAccount,
    this.sheetMode = SheetMode.create,
    this.selectedFolder,
    this.selectedSheet,
    this.sheetsId,
    this.templateUrl = defaultTemplateUrl,
  });

  AppSettings copyWith({
    String? formatPreset,
    MatchFormat? format,
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
  }) =>
      AppSettings(
        formatPreset: formatPreset ?? this.formatPreset,
        format: format ?? this.format,
        gsState: gsState ?? this.gsState,
        gsAccount: clearGsAccount ? null : (gsAccount ?? this.gsAccount),
        sheetMode: sheetMode ?? this.sheetMode,
        selectedFolder: clearSelectedFolder ? null : (selectedFolder ?? this.selectedFolder),
        selectedSheet: clearSelectedSheet ? null : (selectedSheet ?? this.selectedSheet),
        sheetsId: clearSheetsId ? null : (sheetsId ?? this.sheetsId),
        templateUrl: templateUrl ?? this.templateUrl,
      );
}
