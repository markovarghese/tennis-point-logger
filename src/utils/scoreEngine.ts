import { Point, MatchFormat, Score } from '../types';

export function calcScore(points: Point[], fmt: Partial<MatchFormat> = {}): Score {
  const {
    setsInMatch    = 2,
    gamesPerSet    = 6,
    adScoring      = false,
    tiebreakPoints = 7,
    finalSet       = '10-pt TB',
  } = fmt;

  const setsToWin = Math.ceil(setsInMatch / 2);

  let mySets = 0, oppSets = 0;
  let myGames = 0, oppGames = 0;
  let myPts = 0, oppPts = 0;
  let inTiebreak = false;
  let inFinalTB = false;

  function isFinalSet() {
    return (mySets + oppSets) === setsInMatch - 1;
  }

  function shouldStartTiebreak() {
    if (tiebreakPoints === 0) return false;
    return myGames === gamesPerSet && oppGames === gamesPerSet;
  }

  function winGame(iWon: boolean) {
    if (iWon) myGames++; else oppGames++;
    myPts = 0; oppPts = 0;

    const myWonSet  = myGames >= gamesPerSet && myGames - oppGames >= 2;
    const oppWonSet = oppGames >= gamesPerSet && oppGames - myGames >= 2;

    if (myWonSet || oppWonSet) {
      if (myWonSet) mySets++; else oppSets++;
      myGames = 0; oppGames = 0;
      inTiebreak = false;
      inFinalTB  = false;
    } else if (shouldStartTiebreak()) {
      if (isFinalSet() && finalSet === '10-pt TB') {
        inFinalTB = true;
        myGames = 0; oppGames = 0;
      } else {
        inTiebreak = true;
      }
    }
  }

  for (const p of points) {
    if (p.serverWon === null) continue;
    // iWon = true if "I" won this point (player won if: I served and server won, OR opponent served and server lost)
    const iWon = (p.myServe === true && p.serverWon === true) ||
                 (p.myServe === false && p.serverWon === false) ||
                 (p.myServe === null && p.serverWon === true); // fallback when serve unknown

    if (inFinalTB) {
      if (iWon) myPts++; else oppPts++;
      const tbTarget = finalSet === '6-pt TB' ? 6 : 10;
      if (myPts >= tbTarget && myPts - oppPts >= 2) {
        mySets++; myGames = 0; oppGames = 0; myPts = 0; oppPts = 0; inFinalTB = false;
      } else if (oppPts >= tbTarget && oppPts - myPts >= 2) {
        oppSets++; myGames = 0; oppGames = 0; myPts = 0; oppPts = 0; inFinalTB = false;
      }
    } else if (inTiebreak) {
      if (iWon) myPts++; else oppPts++;
      const tbTarget = tiebreakPoints;
      if (myPts >= tbTarget && myPts - oppPts >= 2) winGame(true);
      else if (oppPts >= tbTarget && oppPts - myPts >= 2) winGame(false);
    } else if (!adScoring) {
      // No-ad: first to 4 pts; at 3-3 next point wins
      if (iWon) myPts++; else oppPts++;
      if (myPts >= 4 && myPts > oppPts) winGame(true);
      else if (oppPts >= 4 && oppPts > myPts) winGame(false);
    } else {
      // Ad scoring: need 4+ pts and lead by 2
      if (iWon) myPts++; else oppPts++;
      if (myPts >= 4 && myPts - oppPts >= 2) winGame(true);
      else if (oppPts >= 4 && oppPts - myPts >= 2) winGame(false);
    }

    // Check if final set should start as match TB (at 6-6 or gamesPerSet-gamesPerSet in final set)
    if (!inTiebreak && !inFinalTB && shouldStartTiebreak() && !inFinalTB) {
      if (isFinalSet() && finalSet !== 'Full') {
        inFinalTB = true;
        myGames = 0; oppGames = 0;
      } else {
        inTiebreak = true;
      }
    }
  }

  // Build display point score
  let ptScore: string;
  const tennisLabels = [0, 15, 30, 40];

  if (inFinalTB || inTiebreak) {
    ptScore = `${myPts}–${oppPts}`;
  } else if (!adScoring) {
    if (myPts === 3 && oppPts === 3) ptScore = 'Deuce';
    else ptScore = `${tennisLabels[Math.min(myPts, 3)]}–${tennisLabels[Math.min(oppPts, 3)]}`;
  } else {
    if (myPts >= 3 && oppPts >= 3) {
      if (myPts === oppPts) ptScore = 'Deuce';
      else ptScore = myPts > oppPts ? 'Adv Me' : 'Adv Opp';
    } else {
      ptScore = `${tennisLabels[Math.min(myPts, 3)]}–${tennisLabels[Math.min(oppPts, 3)]}`;
    }
  }

  const matchOver = mySets >= setsToWin || oppSets >= setsToWin;
  const isTiebreak = inTiebreak || inFinalTB;

  return { mySets, oppSets, myGames, oppGames, ptScore, matchOver, isTiebreak, setsToWin };
}
