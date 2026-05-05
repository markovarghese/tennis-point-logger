import '../models/point.dart';
import '../models/match_settings.dart';

class ScoreState {
  final int mySets;
  final int oppSets;
  final int myGames;
  final int oppGames;
  final String ptScore;
  final bool matchOver;
  final bool isTiebreak;
  final int setsToWin;

  const ScoreState({
    this.mySets = 0,
    this.oppSets = 0,
    this.myGames = 0,
    this.oppGames = 0,
    this.ptScore = '0-0',
    this.matchOver = false,
    this.isTiebreak = false,
    this.setsToWin = 1,
  });

  ScoreState copyWith({
    int? mySets, int? oppSets, int? myGames, int? oppGames,
    String? ptScore, bool? matchOver, bool? isTiebreak, int? setsToWin,
  }) => ScoreState(
    mySets: mySets ?? this.mySets,
    oppSets: oppSets ?? this.oppSets,
    myGames: myGames ?? this.myGames,
    oppGames: oppGames ?? this.oppGames,
    ptScore: ptScore ?? this.ptScore,
    matchOver: matchOver ?? this.matchOver,
    isTiebreak: isTiebreak ?? this.isTiebreak,
    setsToWin: setsToWin ?? this.setsToWin,
  );
}

ScoreState calcScore(List<TennisPoint> points, MatchFormat fmt) {
  final setsToWin = fmt.setsToWin;
  int mySets = 0, oppSets = 0;
  int myGames = 0, oppGames = 0;
  int myPts = 0, oppPts = 0;
  bool inTiebreak = false;
  bool inFinalTb = false;

  bool isFinalSet() => (mySets + oppSets) == fmt.setsInMatch - 1;

  bool shouldStartTiebreak() {
    if (fmt.tiebreakPoints == 0) return false;
    return myGames == fmt.gamesPerSet && oppGames == fmt.gamesPerSet;
  }

  void winGame(bool iWon) {
    if (iWon) myGames++; else oppGames++;
    myPts = 0;
    oppPts = 0;

    final myWonSet = myGames >= fmt.gamesPerSet && myGames - oppGames >= 2;
    final oppWonSet = oppGames >= fmt.gamesPerSet && oppGames - myGames >= 2;

    if (myWonSet || oppWonSet) {
      if (myWonSet) mySets++; else oppSets++;
      myGames = 0;
      oppGames = 0;
      inTiebreak = false;
      inFinalTb = false;
    } else if (shouldStartTiebreak()) {
      if (isFinalSet() && fmt.finalSet == FinalSetType.tenPointTb) {
        inFinalTb = true;
      } else {
        inTiebreak = true;
      }
    }
  }

  for (final p in points) {
    if (p.serverWon == null) continue;
    final iWon = (p.myServe == true && p.serverWon == true) ||
                 (p.myServe != true && p.serverWon == false);

    if (inFinalTb) {
      if (iWon) myPts++; else oppPts++;
      final tbTarget = fmt.finalSet == FinalSetType.sixPointTb ? 6 : 10;
      if (myPts >= tbTarget && myPts - oppPts >= 2) {
        mySets++;
        myGames = 0; oppGames = 0; myPts = 0; oppPts = 0;
        inFinalTb = false;
      } else if (oppPts >= tbTarget && oppPts - myPts >= 2) {
        oppSets++;
        myGames = 0; oppGames = 0; myPts = 0; oppPts = 0;
        inFinalTb = false;
      }
    } else if (inTiebreak) {
      if (iWon) myPts++; else oppPts++;
      final tbTarget = fmt.tiebreakPoints;
      if (myPts >= tbTarget && myPts - oppPts >= 2) {
        winGame(true);
      } else if (oppPts >= tbTarget && oppPts - myPts >= 2) {
        winGame(false);
      }
    } else if (!fmt.adScoring) {
      if (iWon) myPts++; else oppPts++;
      if (myPts >= 4 && myPts > oppPts) {
        winGame(true);
      } else if (oppPts >= 4 && oppPts > myPts) {
        winGame(false);
      } else if (myPts == 3 && oppPts == 3) {
        // No-ad: next point wins
        // Already tracked; whichever gets to 4 first wins
      }
    } else {
      if (iWon) myPts++; else oppPts++;
      if (myPts >= 4 && myPts - oppPts >= 2) {
        winGame(true);
      } else if (oppPts >= 4 && oppPts - myPts >= 2) {
        winGame(false);
      }
    }

    if (!inTiebreak && !inFinalTb && shouldStartTiebreak()) {
      if (isFinalSet() && fmt.finalSet != FinalSetType.full) {
        inFinalTb = true;
        myGames = 0;
        oppGames = 0;
      } else {
        inTiebreak = true;
      }
    }
  }

  String ptScore;
  if (inFinalTb || inTiebreak) {
    ptScore = '$myPts-$oppPts';
  } else if (!fmt.adScoring) {
    const labels = [0, 15, 30, 40];
    if (myPts == 3 && oppPts == 3) {
      ptScore = 'Deuce';
    } else {
      ptScore = '${labels[myPts.clamp(0, 3)]}-${labels[oppPts.clamp(0, 3)]}';
    }
  } else {
    if (myPts >= 3 && oppPts >= 3) {
      if (myPts == oppPts) {
        ptScore = 'Deuce';
      } else {
        ptScore = myPts > oppPts ? 'Adv Me' : 'Adv Opp';
      }
    } else {
      const labels = [0, 15, 30, 40];
      ptScore = '${labels[myPts.clamp(0, 3)]}-${labels[oppPts.clamp(0, 3)]}';
    }
  }

  final matchOver = mySets >= setsToWin || oppSets >= setsToWin;

  return ScoreState(
    mySets: mySets,
    oppSets: oppSets,
    myGames: myGames,
    oppGames: oppGames,
    ptScore: ptScore,
    matchOver: matchOver,
    isTiebreak: inTiebreak || inFinalTb,
    setsToWin: setsToWin,
  );
}
