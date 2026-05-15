import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_logger/models/match_settings.dart';
import 'package:tennis_logger/models/point.dart';
import 'package:tennis_logger/services/score_engine.dart';

// I win the point (my serve, server wins)
TennisPoint _myPt() => TennisPoint(
    id: 'p', createdAt: DateTime(2024), myServe: true, serverWon: true);

// Opponent wins the point (my serve, server loses)
TennisPoint _oppPt() => TennisPoint(
    id: 'p', createdAt: DateTime(2024), myServe: true, serverWon: false);

// I win when opponent is serving (opp serve, server loses = I win)
TennisPoint _myPtOppServe() => TennisPoint(
    id: 'p', createdAt: DateTime(2024), myServe: false, serverWon: false);

// Opponent wins while serving
TennisPoint _oppPtOppServe() => TennisPoint(
    id: 'p', createdAt: DateTime(2024), myServe: false, serverWon: true);

// Point with no result — must be skipped by score engine
TennisPoint _nullPt() => TennisPoint(id: 'p', createdAt: DateTime(2024));

List<TennisPoint> _myGame() => List.generate(4, (_) => _myPt());
List<TennisPoint> _oppGame() => List.generate(4, (_) => _oppPt());

// 4-game set won by me (for l7_short_best_of_3 format, setWinThreshold=4)
List<TennisPoint> _mySet4() =>
    [_myGame(), _myGame(), _myGame(), _myGame()].expand((g) => g).toList();

// 4-game set won by opponent
List<TennisPoint> _oppSet4() =>
    [_oppGame(), _oppGame(), _oppGame(), _oppGame()].expand((g) => g).toList();

// 6-game set won by me (standard format)
List<TennisPoint> _mySet6() =>
    List.generate(6, (_) => _myGame()).expand((g) => g).toList();

// No-ad, 6-game sets, best of 3, full final set
const _fmt = MatchFormat(
  setWinThreshold: 6,
  scoringType: ScoringType.noAd,
  matchFormatType: MatchFormatType.bestOf3FullSet,
);

// Ad scoring, 6-game sets, best of 3, full final set
const _fmtAd = MatchFormat(
  setWinThreshold: 6,
  scoringType: ScoringType.ad,
  matchFormatType: MatchFormatType.bestOf3FullSet,
);

void main() {
  group('initial state', () {
    test('empty list returns zeroed score', () {
      final s = calcScore([], _fmt);
      expect(s.mySets, 0);
      expect(s.oppSets, 0);
      expect(s.myGames, 0);
      expect(s.oppGames, 0);
      expect(s.ptScore, '0-0');
      expect(s.matchOver, false);
      expect(s.isTiebreak, false);
    });

    test('setsToWin reflects match format type', () {
      expect(calcScore([], _fmt).setsToWin, 2);
      expect(
          calcScore([], MatchFormat.presets['l7_standard_single']!).setsToWin,
          1);
    });
  });

  group('point score labels — no-ad', () {
    test('1-0 → 15-0', () => expect(calcScore([_myPt()], _fmt).ptScore, '15-0'));
    test('0-1 → 0-15', () => expect(calcScore([_oppPt()], _fmt).ptScore, '0-15'));
    test('2-0 → 30-0', () {
      expect(calcScore([_myPt(), _myPt()], _fmt).ptScore, '30-0');
    });
    test('3-0 → 40-0', () {
      expect(calcScore(List.generate(3, (_) => _myPt()), _fmt).ptScore, '40-0');
    });
    test('1-1 → 15-15', () {
      expect(calcScore([_myPt(), _oppPt()], _fmt).ptScore, '15-15');
    });
    test('3-3 → Deciding Pt', () {
      final pts = [_myPt(), _myPt(), _myPt(), _oppPt(), _oppPt(), _oppPt()];
      final s = calcScore(pts, _fmt);
      expect(s.ptScore, 'Deciding Pt');
      expect(s.isDecidingPoint, true);
    });
  });

  group('point score labels — ad scoring', () {
    test('3-3 → Deuce', () {
      final pts = [_myPt(), _myPt(), _myPt(), _oppPt(), _oppPt(), _oppPt()];
      expect(calcScore(pts, _fmtAd).ptScore, 'Deuce');
    });
    test('4-3 (after deuce) → Adv Me', () {
      final pts = [
        _myPt(), _myPt(), _myPt(),
        _oppPt(), _oppPt(), _oppPt(),
        _myPt(),
      ];
      expect(calcScore(pts, _fmtAd).ptScore, 'Adv Me');
    });
    test('3-4 (after deuce) → Adv Opp', () {
      final pts = [
        _myPt(), _myPt(), _myPt(),
        _oppPt(), _oppPt(), _oppPt(),
        _oppPt(),
      ];
      expect(calcScore(pts, _fmtAd).ptScore, 'Adv Opp');
    });
    test('4-4 (after deuce) → Deuce again', () {
      final pts = [
        _myPt(), _myPt(), _myPt(),
        _oppPt(), _oppPt(), _oppPt(),
        _myPt(), _oppPt(),
      ];
      expect(calcScore(pts, _fmtAd).ptScore, 'Deuce');
    });
  });

  group('game wins', () {
    test('4 points wins a game (no-ad)', () {
      final s = calcScore(_myGame(), _fmt);
      expect(s.myGames, 1);
      expect(s.oppGames, 0);
      expect(s.ptScore, '0-0');
    });
    test('opponent wins a game', () {
      final s = calcScore(_oppGame(), _fmt);
      expect(s.myGames, 0);
      expect(s.oppGames, 1);
    });
    test('no-ad deciding point: next point wins the game', () {
      final pts = [
        _myPt(), _myPt(), _myPt(),
        _oppPt(), _oppPt(), _oppPt(), // 3-3 deciding pt
        _myPt(),                       // 4-3 → game
      ];
      final s = calcScore(pts, _fmt);
      expect(s.myGames, 1);
      expect(s.ptScore, '0-0');
    });
    test('ad scoring: must win by 2 from deuce', () {
      final pts = [
        _myPt(), _myPt(), _myPt(),
        _oppPt(), _oppPt(), _oppPt(), // deuce
        _myPt(), _oppPt(),             // adv me, back to deuce
        _myPt(), _myPt(),              // adv me, then game
      ];
      final s = calcScore(pts, _fmtAd);
      expect(s.myGames, 1);
      expect(s.ptScore, '0-0');
    });
    test('I win while opponent is serving', () {
      final s = calcScore([_myPtOppServe()], _fmt);
      expect(s.ptScore, '15-0');
    });
    test('opponent wins while serving', () {
      final s = calcScore([_oppPtOppServe()], _fmt);
      expect(s.ptScore, '0-15');
    });
  });

  group('set wins', () {
    test('6-0 wins a set', () {
      final s = calcScore(_mySet6(), _fmt);
      expect(s.mySets, 1);
      expect(s.myGames, 0);
      expect(s.oppGames, 0);
    });
    test('6-3 wins a set', () {
      final pts = [
        ..._myGame(), ..._oppGame(), // 1-1
        ..._myGame(), ..._oppGame(), // 2-2
        ..._myGame(), ..._oppGame(), // 3-3
        ..._myGame(), ..._myGame(), ..._myGame(), // 6-3
      ];
      final s = calcScore(pts, _fmt);
      expect(s.mySets, 1);
    });
    test('opponent wins a set', () {
      final pts = List.generate(6, (_) => _oppGame()).expand((g) => g).toList();
      final s = calcScore(pts, _fmt);
      expect(s.oppSets, 1);
      expect(s.mySets, 0);
    });
  });

  group('match over', () {
    test('winning 2 sets ends the match (best of 3)', () {
      final pts = [
        ..._mySet6(), // set 1
        ..._mySet6(), // set 2
      ];
      final s = calcScore(pts, _fmt);
      expect(s.mySets, 2);
      expect(s.matchOver, true);
    });
    test('winning 1 set ends a single-set match', () {
      final fmt = MatchFormat.presets['l7_standard_single']!;
      final pts = List.generate(6, (_) => _myGame()).expand((g) => g).toList();
      final s = calcScore(pts, fmt);
      expect(s.mySets, 1);
      expect(s.matchOver, true);
    });
    test('opponent winning 2 sets ends the match', () {
      final pts = [
        ...List.generate(6, (_) => _oppGame()).expand((g) => g),
        ...List.generate(6, (_) => _oppGame()).expand((g) => g),
      ];
      final s = calcScore(pts, _fmt);
      expect(s.oppSets, 2);
      expect(s.matchOver, true);
    });
  });

  group('null points are skipped', () {
    test('null serverWon point does not affect score', () {
      final s = calcScore([_nullPt(), _nullPt(), _myPt()], _fmt);
      expect(s.ptScore, '15-0');
    });
    test('all null points → zeroed state', () {
      final s = calcScore(List.generate(10, (_) => _nullPt()), _fmt);
      expect(s.myGames, 0);
      expect(s.ptScore, '0-0');
    });
    test('null points between real points are ignored', () {
      final pts = [_myPt(), _nullPt(), _myPt(), _nullPt(), _myPt()];
      expect(calcScore(pts, _fmt).ptScore, '40-0');
    });
  });

  group('match tiebreak (l7_short_best_of_3 — 10-pt match TB after 1-1 sets)', () {
    // 4-game sets, no-ad, set TB at 4-4 (7-pt), match TB after 1-1 sets (10-pt)
    final fmt = MatchFormat.presets['l7_short_best_of_3']!;

    test('match TB is active after splitting first two sets', () {
      final pts = [
        ..._mySet4(),  // me wins set 1 (4-0)
        ..._oppSet4(), // opp wins set 2 (4-0)
        _myPt(),       // first point of match TB
      ];
      final s = calcScore(pts, fmt);
      expect(s.isTiebreak, true);
      expect(s.inFinalTb, true);
      expect(s.ptScore, '1-0');
    });

    test('winning 10-pt match TB wins the match', () {
      final pts = [
        ..._mySet4(),
        ..._oppSet4(),
        ...List.generate(10, (_) => _myPt()), // win 10-0
      ];
      final s = calcScore(pts, fmt);
      expect(s.mySets, 2);
      expect(s.matchOver, true);
      expect(s.isTiebreak, false);
    });

    test('opponent wins 10-pt match TB', () {
      final pts = [
        ..._mySet4(),
        ..._oppSet4(),
        ...List.generate(10, (_) => _oppPt()),
      ];
      final s = calcScore(pts, fmt);
      expect(s.oppSets, 2);
      expect(s.matchOver, true);
    });

    test('10-pt match TB requires 2-point margin', () {
      final pts = [
        ..._mySet4(),
        ..._oppSet4(),
        // 9-9 in match TB, then I win 2 more
        ...List.generate(9, (_) => _myPt()),
        ...List.generate(9, (_) => _oppPt()),
        _myPt(), _myPt(), // 11-9
      ];
      final s = calcScore(pts, fmt);
      expect(s.mySets, 2);
      expect(s.matchOver, true);
    });
  });

  group('set tiebreak (l7_short_best_of_3 — 7-pt set TB at 4-4)', () {
    final fmt = MatchFormat.presets['l7_short_best_of_3']!;

    test('set TB activates at 4-4 games', () {
      final pts = [
        // Alternate to 4-4 in the first set
        ..._oppGame(), ..._myGame(),
        ..._oppGame(), ..._myGame(),
        ..._oppGame(), ..._myGame(),
        ..._oppGame(), ..._myGame(),
        _myPt(), // first point of set TB
      ];
      final s = calcScore(pts, fmt);
      expect(s.isTiebreak, true);
      expect(s.inFinalTb, false);
      expect(s.ptScore, '1-0');
    });

    test('winning set TB wins the set, not the match', () {
      final pts = [
        ..._oppGame(), ..._myGame(),
        ..._oppGame(), ..._myGame(),
        ..._oppGame(), ..._myGame(),
        ..._oppGame(), ..._myGame(), // 4-4
        ...List.generate(7, (_) => _myPt()), // win set TB 7-0
      ];
      final s = calcScore(pts, fmt);
      expect(s.mySets, 1);
      expect(s.matchOver, false);
      expect(s.isTiebreak, false);
    });
  });
}
