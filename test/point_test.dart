import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_logger/models/point.dart';
import 'package:tennis_logger/models/score_state.dart';

void main() {
  final dt = DateTime(2024, 6, 15, 9, 30, 45);
  TennisPoint blank() => TennisPoint(id: 'x', createdAt: dt);

  group('boolVal', () {
    test('null → empty string', () => expect(blank().boolVal(null), ''));
    test('true → "TRUE"', () => expect(blank().boolVal(true), 'TRUE'));
    test('false → "FALSE"', () => expect(blank().boolVal(false), 'FALSE'));
  });

  group('withField', () {
    test('sets myServe', () {
      expect(blank().withField('myServe', true).myServe, true);
    });
    test('sets serverWon to false', () {
      expect(blank().withField('serverWon', false).serverWon, false);
    });
    test('sets field to null', () {
      final p = TennisPoint(id: 'x', createdAt: dt, myServe: true);
      expect(p.withField('myServe', null).myServe, null);
    });
    test('unknown key leaves all fields null', () {
      final p = blank().withField('bogus', true);
      expect(p.myServe, null);
      expect(p.serverWon, null);
    });
    test('preserves unrelated fields', () {
      final p = TennisPoint(id: 'x', createdAt: dt, myServe: true, serverWon: false);
      final updated = p.withField('firstServe', true);
      expect(updated.myServe, true);
      expect(updated.serverWon, false);
      expect(updated.firstServe, true);
    });
  });

  group('copyWith', () {
    test('no overrides preserves all fields', () {
      final p = TennisPoint(id: 'orig', createdAt: dt, myServe: true, serverWon: false);
      final copy = p.copyWith();
      expect(copy.id, 'orig');
      expect(copy.myServe, true);
      expect(copy.serverWon, false);
    });
    test('overrides a single field', () {
      final p = TennisPoint(id: 'x', createdAt: dt, myServe: true);
      expect(p.copyWith(serverWon: () => true).serverWon, true);
    });
    test('can set a field to null via override', () {
      final p = TennisPoint(id: 'x', createdAt: dt, myServe: true);
      expect(p.copyWith(myServe: () => null).myServe, null);
    });
  });

  group('timeLabel', () {
    test('formats as HH:MM:SS with zero-padding', () {
      expect(blank().timeLabel, '09:30:45');
    });
  });

  group('toCsvRow', () {
    test('produces exactly 15 columns', () {
      expect(blank().toCsvRow('2024-06-15', 'Opp').length, 15);
    });
    test('first column is match date', () {
      expect(blank().toCsvRow('2024-06-15', 'Opp')[0], '2024-06-15');
    });
    test('second column is time label', () {
      expect(blank().toCsvRow('2024-06-15', 'Opp')[1], '09:30:45');
    });
    test('third column is opponent name', () {
      expect(blank().toCsvRow('2024-06-15', 'Smith')[2], 'Smith');
    });
    test('bool columns encoded correctly', () {
      final p = TennisPoint(
        id: 'x', createdAt: dt,
        myServe: true, firstServe: false,
        doubleFault: false, serverWon: true,
        forcedError: false, loserForehand: false,
      );
      final row = p.toCsvRow('2024-06-15', 'Opp');
      expect(row[3], 'TRUE');   // myServe
      expect(row[4], 'FALSE');  // firstServe
      expect(row[5], 'FALSE');  // doubleFault
      expect(row[6], 'TRUE');   // serverWon
      expect(row[7], 'FALSE');  // forcedError
      expect(row[8], 'FALSE');  // loserForehand
    });
    test('score columns empty when score is null', () {
      final row = blank().toCsvRow('2024-06-15', 'Opp');
      for (final col in [9, 10, 11, 12, 13, 14]) {
        expect(row[col], '');
      }
    });
    test('score columns populated when score is set', () {
      final p = TennisPoint(
        id: 'x', createdAt: dt,
        score: const ScoreState(mySets: 1, oppSets: 0, myGames: 3, oppGames: 2, myPts: 1, oppPts: 2),
      );
      final row = p.toCsvRow('2024-06-15', 'Opp');
      expect(row[9], '1');   // mySets
      expect(row[10], '0');  // oppSets
      expect(row[11], '3');  // myGames
      expect(row[12], '2');  // oppGames
      expect(row[13], '1');  // myPts
      expect(row[14], '2');  // oppPts
    });
  });
}
