import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_logger/services/google_auth_service.dart';

// Column indices in the Logger tab data rows (0-based, matching toCsvRow order).
// A: matchDateTime, B: timeLabel, C: opponent,
// D: myServe, E: firstServe, F: doubleFault, G: serverWon,
// H: forcedError, I: loserForehand
const _colMyServe = 3;
const _colServerWon = 6;

class SheetsVerifier {
  /// Returns the ID of the most recently modified sheet whose name starts with
  /// 'TennisPointLogger_'. Call this after the test has created the sheet.
  static Future<String> findLatestTestSheet() async {
    // listSheets() returns sheets sorted by modifiedTime desc.
    final all = await GoogleAuthService.instance.listSheets();
    final match = all.firstWhere(
      (s) => s.name.startsWith('TennisPointLogger_'),
      orElse: () => throw Exception(
          'No TennisPointLogger_* sheet found in Google Drive'),
    );
    return match.id;
  }

  /// Reads a single data row (1-based [rowNumber]) from the Logger tab and
  /// returns its cells as a list of strings.
  static Future<List<String>> readLoggerRow(
      String spreadsheetId, int rowNumber) async {
    final rows = await GoogleAuthService.instance.readSheetValues(
      spreadsheetId,
      'Logger!A$rowNumber:I$rowNumber',
    );
    if (rows.isEmpty) return [];
    // Pad to 9 columns so callers can index safely.
    final row = rows.first;
    while (row.length < 9) {
      row.add('');
    }
    return row;
  }

  /// Asserts that the 4 stat columns in [rowNumber] are never blank.
  /// firstServe(E=4), doubleFault(F=5), forcedError(H=7), loserForehand(I=8)
  /// must always be TRUE or FALSE — never an empty string.
  static Future<void> assertStatFieldsNonBlank(
      String spreadsheetId, int rowNumber) async {
    final row = await readLoggerRow(spreadsheetId, rowNumber);
    for (final col in [4, 5, 7, 8]) {
      expect(row[col], isNot(''),
          reason: 'stat field col $col in row $rowNumber must not be blank');
    }
  }

  /// Asserts that the first data row (row 2) of [spreadsheetId] has
  /// myServe=[expectedMyServe] and serverWon=[expectedServerWon].
  static Future<void> assertPoint1(
    String spreadsheetId, {
    required bool expectedMyServe,
    required bool expectedServerWon,
  }) async {
    final row = await readLoggerRow(spreadsheetId, 2);
    expect(
      row[_colMyServe],
      expectedMyServe ? 'TRUE' : 'FALSE',
      reason: 'myServe (col D) in row 2',
    );
    expect(
      row[_colServerWon],
      expectedServerWon ? 'TRUE' : 'FALSE',
      reason: 'serverWon (col G) in row 2',
    );
  }
}
