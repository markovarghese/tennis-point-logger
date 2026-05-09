import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_logger/models/point.dart';

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
    test('produces exactly 9 columns', () {
      expect(blank().toCsvRow('2024-06-15', 'Opp').length, 9);
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
        doubleFault: null, serverWon: true,
        forcedError: false, loserForehand: null,
      );
      final row = p.toCsvRow('2024-06-15', 'Opp');
      expect(row[3], 'TRUE');  // myServe
      expect(row[4], 'FALSE');  // firstServe
      expect(row[5], '');   // doubleFault null
      expect(row[6], 'TRUE');  // serverWon
      expect(row[7], 'FALSE');  // forcedError
      expect(row[8], '');   // loserForehand null
    });
  });
}
