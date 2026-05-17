import 'score_state.dart';

class TennisPoint {
  final String id;
  final DateTime createdAt;
  bool? myServe;
  bool firstServe;
  bool doubleFault;
  bool? serverWon;
  bool forcedError;
  bool loserForehand;
  ScoreState? score;

  TennisPoint({
    required this.id,
    required this.createdAt,
    this.myServe,
    this.firstServe = true,
    this.doubleFault = false,
    this.serverWon,
    this.forcedError = false,
    this.loserForehand = true,
    this.score,
  });

  factory TennisPoint.fresh() {
    final now = DateTime.now();
    return TennisPoint(
      id: '${now.millisecondsSinceEpoch}_${now.microsecond}',
      createdAt: now,
    );
  }

  TennisPoint withScore(ScoreState s) => TennisPoint(
        id: id,
        createdAt: createdAt,
        myServe: myServe,
        firstServe: firstServe,
        doubleFault: doubleFault,
        serverWon: serverWon,
        forcedError: forcedError,
        loserForehand: loserForehand,
        score: s,
      );

  TennisPoint copyWith({
    bool? Function()? myServe,
    bool? firstServe,
    bool? doubleFault,
    bool? Function()? serverWon,
    bool? forcedError,
    bool? loserForehand,
  }) {
    return TennisPoint(
      id: id,
      createdAt: createdAt,
      myServe: myServe != null ? myServe() : this.myServe,
      firstServe: firstServe ?? this.firstServe,
      doubleFault: doubleFault ?? this.doubleFault,
      serverWon: serverWon != null ? serverWon() : this.serverWon,
      forcedError: forcedError ?? this.forcedError,
      loserForehand: loserForehand ?? this.loserForehand,
      score: score,
    );
  }

  TennisPoint withField(String key, bool? value) {
    return TennisPoint(
      id: id,
      createdAt: createdAt,
      myServe: key == 'myServe' ? value : myServe,
      firstServe: key == 'firstServe' ? value! : firstServe,
      doubleFault: key == 'doubleFault' ? value! : doubleFault,
      serverWon: key == 'serverWon' ? value : serverWon,
      forcedError: key == 'forcedError' ? value! : forcedError,
      loserForehand: key == 'loserForehand' ? value! : loserForehand,
      score: score,
    );
  }

  String get timeLabel {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    final s = createdAt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String boolVal(bool? v) => v == null ? '' : v ? 'TRUE' : 'FALSE';

  List<String> toCsvRow(String matchDateTime, String opponent) => [
        matchDateTime,
        timeLabel,
        opponent,
        boolVal(myServe),
        boolVal(firstServe),
        boolVal(doubleFault),
        boolVal(serverWon),
        boolVal(forcedError),
        boolVal(loserForehand),
        score?.mySets.toString() ?? '',
        score?.oppSets.toString() ?? '',
        score?.myGames.toString() ?? '',
        score?.oppGames.toString() ?? '',
        score?.myPts.toString() ?? '',
        score?.oppPts.toString() ?? '',
      ];
}

const List<({String key, String label, String abbr})> kFields = [
  (key: 'myServe', label: 'My Serve?', abbr: 'MS'),
  (key: 'firstServe', label: "Server's First Serve?", abbr: '1S'),
  (key: 'doubleFault', label: 'Server Double Fault?', abbr: 'DF'),
  (key: 'serverWon', label: 'Server Won?', abbr: 'SW'),
  (key: 'forcedError', label: "Loser's Forced Error?", abbr: 'FE'),
  (key: 'loserForehand', label: "Loser's Forehand?", abbr: 'LF'),
];

bool? getField(TennisPoint p, String key) => switch (key) {
      'myServe' => p.myServe,
      'firstServe' => p.firstServe,
      'doubleFault' => p.doubleFault,
      'serverWon' => p.serverWon,
      'forcedError' => p.forcedError,
      'loserForehand' => p.loserForehand,
      _ => null,
    };
