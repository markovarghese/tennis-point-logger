import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_logger/models/match_settings.dart';
import 'package:tennis_logger/models/point.dart';
import 'package:tennis_logger/services/score_engine.dart';

void main() {
  group('USTA Scoring Logic - L7 Short Sets', () {
    final fmt = MatchFormat.presets['l7_short_best_of_3']!;

    test('Tiebreaker at 4-4', () {
      var state = const ScoreState(setsToWin: 2);
      
      // Reach 4-4
      state = state.copyWith(myGames: 4, oppGames: 4);
      
      // Next point should be tiebreak
      final p = TennisPoint(id: '1', createdAt: DateTime.now(), myServe: true, serverWon: true);
      state = nextScore(state, p, fmt);
      
      expect(state.isTiebreak, true);
      expect(state.ptScore, '1-0');
    });

    test('Match Tiebreaker at 1-1 sets', () {
      var state = const ScoreState(setsToWin: 2, setResults: ['4-1', '1-4']);
      state = state.copyWith(mySets: 1, oppSets: 1);
      
      // Since it's 1-1 and bestOf3MatchTb, next point should trigger inFinalTb
      final p = TennisPoint(id: '1', createdAt: DateTime.now(), myServe: true, serverWon: true);
      state = nextScore(state, p, fmt);
      
      expect(state.inFinalTb, true);
      expect(state.ptScore, '1-0');
    });
  });

  group('No-Ad Scoring', () {
    final fmt = const MatchFormat(scoringType: ScoringType.noAd);

    test('Deciding point at 3-3 (40-40)', () {
      // We need a state where points are 3-3
      var s = const ScoreState(myPts: 3, oppPts: 2);
      s = nextScore(s, TennisPoint(id: 'x', createdAt: DateTime.now(), myServe: true, serverWon: false), fmt);
      
      expect(s.ptScore, 'Deciding Pt');
      expect(s.isDecidingPoint, true);
    });
  });

  group('Sudden Death Tiebreaker', () {
    final fmt = const MatchFormat(tiebreakWinType: TiebreakWinType.suddenDeath, setTiebreakPts: 7);

    test('Wins at 7-6', () {
      var state = const ScoreState(myGames: 6, oppGames: 6, isTiebreak: true, myPts: 6, oppPts: 6);
      final p = TennisPoint(id: '1', createdAt: DateTime.now(), myServe: true, serverWon: true);
      state = nextScore(state, p, fmt);
      
      expect(state.mySets, 1);
      expect(state.myGames, 0);
      expect(state.isTiebreak, false);
      expect(state.setResults.last, '7-6(7-6)');
    });
  });
}
