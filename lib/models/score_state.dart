class ScoreState {
  final int mySets;
  final int oppSets;
  final int myGames;
  final int oppGames;
  final int myPts;
  final int oppPts;
  final String ptScore;
  final bool matchOver;
  final bool isTiebreak;
  final bool inFinalTb;
  final int setsToWin;
  final bool isDecidingPoint;
  final bool? serverStartsTiebreak; // null if not in TB, true if 'Me', false if 'Opp'
  final List<String> setResults;

  const ScoreState({
    this.mySets = 0,
    this.oppSets = 0,
    this.myGames = 0,
    this.oppGames = 0,
    this.myPts = 0,
    this.oppPts = 0,
    this.ptScore = '0-0',
    this.matchOver = false,
    this.isTiebreak = false,
    this.inFinalTb = false,
    this.setsToWin = 1,
    this.isDecidingPoint = false,
    this.serverStartsTiebreak,
    this.setResults = const [],
  });

  ScoreState copyWith({
    int? mySets,
    int? oppSets,
    int? myGames,
    int? oppGames,
    int? myPts,
    int? oppPts,
    String? ptScore,
    bool? matchOver,
    bool? isTiebreak,
    bool? inFinalTb,
    int? setsToWin,
    bool? isDecidingPoint,
    bool? Function()? serverStartsTiebreak,
    List<String>? setResults,
  }) =>
      ScoreState(
        mySets: mySets ?? this.mySets,
        oppSets: oppSets ?? this.oppSets,
        myGames: myGames ?? this.myGames,
        oppGames: oppGames ?? this.oppGames,
        myPts: myPts ?? this.myPts,
        oppPts: oppPts ?? this.oppPts,
        ptScore: ptScore ?? this.ptScore,
        matchOver: matchOver ?? this.matchOver,
        isTiebreak: isTiebreak ?? this.isTiebreak,
        inFinalTb: inFinalTb ?? this.inFinalTb,
        setsToWin: setsToWin ?? this.setsToWin,
        isDecidingPoint: isDecidingPoint ?? this.isDecidingPoint,
        serverStartsTiebreak:
            serverStartsTiebreak != null ? serverStartsTiebreak() : this.serverStartsTiebreak,
        setResults: setResults ?? this.setResults,
      );

  String get compactLabel {
    final setsPart = setResults.isEmpty ? '' : '${setResults.join('  ')}  ';
    final gamesPart = matchOver ? '' : '$myGames-$oppGames  ';
    final ptsPart = matchOver ? '' : ptScore;
    return '$setsPart$gamesPart$ptsPart'.trim();
  }
}
