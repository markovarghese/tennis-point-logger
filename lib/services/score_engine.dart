import '../models/point.dart';
import '../models/match_settings.dart';
import '../models/score_state.dart';

export '../models/score_state.dart';

ScoreState nextScore(ScoreState prev, TennisPoint point, MatchFormat fmt) {
  if (point.serverWon == null) return prev;

  final iWon = (point.myServe == true && point.serverWon == true) ||
      (point.myServe != true && point.serverWon == false);

  int mySets = prev.mySets, oppSets = prev.oppSets;
  int myGames = prev.myGames, oppGames = prev.oppGames;
  int myPts = prev.myPts, oppPts = prev.oppPts;
  bool inTiebreak = prev.isTiebreak && !prev.inFinalTb;
  bool inFinalTb = prev.inFinalTb;
  bool? serverStartsTiebreak = prev.serverStartsTiebreak;
  final setsToWin = prev.setsToWin;
  final List<String> setResults = List.from(prev.setResults);

  bool shouldStartSetTiebreak() {
    return myGames == fmt.setTiebreakAt && oppGames == fmt.setTiebreakAt;
  }

  void winSet(bool won, {String? tbScore}) {
    if (won) {
      mySets++;
      if (tbScore != null) {
        setResults.add('7-6($tbScore)');
      } else {
        setResults.add('$myGames-$oppGames');
      }
    } else {
      oppSets++;
      if (tbScore != null) {
        setResults.add('6-7($tbScore)');
      } else {
        setResults.add('$myGames-$oppGames');
      }
    }
    myGames = 0;
    oppGames = 0;
    myPts = 0;
    oppPts = 0;
    inTiebreak = false;
    inFinalTb = false;
    serverStartsTiebreak = null;
    
    // Check for Match Tiebreak transition
    if (fmt.matchFormatType == MatchFormatType.bestOf3MatchTb && mySets == 1 && oppSets == 1) {
      inFinalTb = true;
      // Note: serverStartsTiebreak will be set at the end of nextScore
    }
  }

  void winGame(bool won) {
    if (won) {
      myGames++;
    } else {
      oppGames++;
    }
    myPts = 0;
    oppPts = 0;

    final myWonSet = (myGames >= fmt.setWinThreshold && myGames - oppGames >= 2);
    final oppWonSet = (oppGames >= fmt.setWinThreshold && oppGames - myGames >= 2);

    if (myWonSet || oppWonSet) {
      winSet(myWonSet);
    } else if (shouldStartSetTiebreak()) {
      inTiebreak = true;
      serverStartsTiebreak = point.myServe;
    }
  }

  if (inFinalTb) {
    if (iWon) {
      myPts++;
    } else {
      oppPts++;
    }
    final tbTarget = fmt.matchTiebreakPts;
    final isSuddenDeath = fmt.tiebreakWinType == TiebreakWinType.suddenDeath;

    bool myWon = false, oppWon = false;
    if (isSuddenDeath) {
      myWon = myPts >= tbTarget;
      oppWon = oppPts >= tbTarget;
    } else {
      myWon = myPts >= tbTarget && myPts - oppPts >= 2;
      oppWon = oppPts >= tbTarget && oppPts - myPts >= 2;
    }

    if (myWon || oppWon) {
      mySets += myWon ? 1 : 0;
      oppSets += oppWon ? 1 : 0;
      setResults.add('1-0($myPts-$oppPts)');
      myGames = 0;
      oppGames = 0;
      myPts = 0;
      oppPts = 0;
      inFinalTb = false;
      serverStartsTiebreak = null;
    }
  } else if (inTiebreak) {
    if (iWon) {
      myPts++;
    } else {
      oppPts++;
    }
    final tbTarget = fmt.setTiebreakPts;
    final isSuddenDeath = fmt.tiebreakWinType == TiebreakWinType.suddenDeath;

    if (isSuddenDeath) {
      if (myPts >= tbTarget) {
        winSet(true, tbScore: '$myPts-$oppPts');
      } else if (oppPts >= tbTarget) {
        winSet(false, tbScore: '$myPts-$oppPts');
      }
    } else {
      if (myPts >= tbTarget && myPts - oppPts >= 2) {
        winSet(true, tbScore: '$myPts-$oppPts');
      } else if (oppPts >= tbTarget && oppPts - myPts >= 2) {
        winSet(false, tbScore: '$myPts-$oppPts');
      }
    }
  } else {
    // Normal game
    if (iWon) {
      myPts++;
    } else {
      oppPts++;
    }

    if (fmt.scoringType == ScoringType.noAd) {
      if (myPts >= 4 && myPts > oppPts) {
        winGame(true);
      } else if (oppPts >= 4 && oppPts > myPts) {
        winGame(false);
      }
    } else {
      if (myPts >= 4 && myPts - oppPts >= 2) {
        winGame(true);
      } else if (oppPts >= 4 && oppPts - myPts >= 2) {
        winGame(false);
      }
    }
  }

  // Final check for transitions that might have been triggered by manual point logging
  // (e.g. if ScoreState was manipulated or point was the first of the set)
  if (!inTiebreak && !inFinalTb) {
     if (fmt.matchFormatType == MatchFormatType.bestOf3MatchTb && mySets == 1 && oppSets == 1 && myGames == 0 && oppGames == 0) {
        inFinalTb = true;
     } else if (shouldStartSetTiebreak()) {
        inTiebreak = true;
     }
     if ((inFinalTb || inTiebreak) && serverStartsTiebreak == null) {
        serverStartsTiebreak = point.myServe;
     }
  }

  final label = ptScoreLabel(
    myPts: myPts,
    oppPts: oppPts,
    isTiebreak: inTiebreak || inFinalTb,
    scoringType: fmt.scoringType,
  );

  return ScoreState(
    mySets: mySets,
    oppSets: oppSets,
    myGames: myGames,
    oppGames: oppGames,
    myPts: myPts,
    oppPts: oppPts,
    ptScore: label.ptScore,
    matchOver: mySets >= setsToWin || oppSets >= setsToWin,
    isTiebreak: inTiebreak || inFinalTb,
    inFinalTb: inFinalTb,
    setsToWin: setsToWin,
    isDecidingPoint: label.isDecidingPoint,
    serverStartsTiebreak: serverStartsTiebreak,
    setResults: setResults,
  );
}

ScoreState calcScore(List<TennisPoint> points, MatchFormat fmt) {
  var state = ScoreState(setsToWin: fmt.setsToWin);
  for (final p in points) {
    state = nextScore(state, p, fmt);
  }
  return state;
}

/// Renders the raw `(myPts, oppPts)` point counters into the user-facing
/// score label plus a flag indicating a no-ad deciding point. Tiebreaks
/// (regular set and final/match) always show numerically.
({String ptScore, bool isDecidingPoint}) ptScoreLabel({
  required int myPts,
  required int oppPts,
  required bool isTiebreak,
  required ScoringType scoringType,
}) {
  if (isTiebreak) {
    return (ptScore: '$myPts-$oppPts', isDecidingPoint: false);
  }
  const labels = [0, 15, 30, 40];
  if (scoringType == ScoringType.noAd) {
    if (myPts >= 3 && oppPts >= 3) {
      return (ptScore: 'Deciding Pt', isDecidingPoint: true);
    }
    return (
      ptScore:
          '${labels[myPts.clamp(0, 3)]}-${labels[oppPts.clamp(0, 3)]}',
      isDecidingPoint: false,
    );
  }
  if (myPts >= 3 && oppPts >= 3) {
    if (myPts == oppPts) {
      return (ptScore: 'Deuce', isDecidingPoint: false);
    }
    return (
      ptScore: myPts > oppPts ? 'Adv Me' : 'Adv Opp',
      isDecidingPoint: false,
    );
  }
  return (
    ptScore: '${labels[myPts.clamp(0, 3)]}-${labels[oppPts.clamp(0, 3)]}',
    isDecidingPoint: false,
  );
}
