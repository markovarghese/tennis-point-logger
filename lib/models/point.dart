class TennisPoint {
  final String id;
  final DateTime createdAt;
  bool? myServe;
  bool? firstServe;
  bool? doubleFault;
  bool? serverWon;
  bool? forcedError;
  bool? loserForehand;

  TennisPoint({
    required this.id,
    required this.createdAt,
    this.myServe,
    this.firstServe,
    this.doubleFault,
    this.serverWon,
    this.forcedError,
    this.loserForehand,
  });

  factory TennisPoint.fresh() {
    final now = DateTime.now();
    return TennisPoint(
      id: '${now.millisecondsSinceEpoch}_${now.microsecond}',
      createdAt: now,
    );
  }

  TennisPoint copyWith({
    bool? Function()? myServe,
    bool? Function()? firstServe,
    bool? Function()? doubleFault,
    bool? Function()? serverWon,
    bool? Function()? forcedError,
    bool? Function()? loserForehand,
  }) {
    return TennisPoint(
      id: id,
      createdAt: createdAt,
      myServe: myServe != null ? myServe() : this.myServe,
      firstServe: firstServe != null ? firstServe() : this.firstServe,
      doubleFault: doubleFault != null ? doubleFault() : this.doubleFault,
      serverWon: serverWon != null ? serverWon() : this.serverWon,
      forcedError: forcedError != null ? forcedError() : this.forcedError,
      loserForehand: loserForehand != null ? loserForehand() : this.loserForehand,
    );
  }

  TennisPoint withField(String key, bool? value) {
    return TennisPoint(
      id: id,
      createdAt: createdAt,
      myServe: key == 'myServe' ? value : myServe,
      firstServe: key == 'firstServe' ? value : firstServe,
      doubleFault: key == 'doubleFault' ? value : doubleFault,
      serverWon: key == 'serverWon' ? value : serverWon,
      forcedError: key == 'forcedError' ? value : forcedError,
      loserForehand: key == 'loserForehand' ? value : loserForehand,
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
  ];
}

const List<({String key, String label, String abbr})> kFields = [
  (key: 'myServe',       label: 'My Serve?',                abbr: 'MS'),
  (key: 'firstServe',    label: "Server's First Serve?",    abbr: '1S'),
  (key: 'doubleFault',   label: 'Server Double Fault?',     abbr: 'DF'),
  (key: 'serverWon',     label: 'Server Won?',              abbr: 'SW'),
  (key: 'forcedError',   label: "Loser's Forced Error?",    abbr: 'FE'),
  (key: 'loserForehand', label: "Loser's Forehand?",        abbr: 'LF'),
];

bool? getField(TennisPoint p, String key) => switch (key) {
  'myServe'       => p.myServe,
  'firstServe'    => p.firstServe,
  'doubleFault'   => p.doubleFault,
  'serverWon'     => p.serverWon,
  'forcedError'   => p.forcedError,
  'loserForehand' => p.loserForehand,
  _               => null,
};
