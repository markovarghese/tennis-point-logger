import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
// ignore: depend_on_referenced_packages
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:intl/intl.dart';
import '../models/match_settings.dart';

class GoogleAuthService {
  static final GoogleAuthService instance = GoogleAuthService._();
  GoogleAuthService._();

  static const _webClientId =
      '324487874581-bc41ekrre3elr3qm68nta9ljn254uo06.apps.googleusercontent.com';

  static const _scopes = [
    drive.DriveApi.driveFileScope,
    drive.DriveApi.driveReadonlyScope,
    sheets.SheetsApi.spreadsheetsScope,
  ];

  GoogleSignInAccount? _currentAccount;

  Future<void> initialize() async {
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
  }

  Future<String?> signIn() async {
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: _scopes,
      );
      _currentAccount = account;
      return account.email;
    } on GoogleSignInException {
      return null;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _currentAccount = null;
  }

  Future<gapis.AuthClient> _getClient() async {
    final account = _currentAccount;
    if (account == null) throw Exception('Not authenticated');
    final authorization =
        await account.authorizationClient.authorizeScopes(_scopes);
    return authorization.authClient(scopes: _scopes);
  }

  Future<List<DriveFolder>> listFolders() async {
    final client = await _getClient();
    final driveApi = drive.DriveApi(client);
    final result = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
      orderBy: 'name',
    );
    return (result.files ?? [])
        .where((f) => f.id != null && f.name != null)
        .map((f) => DriveFolder(id: f.id!, name: f.name!))
        .toList();
  }

  Future<List<DriveSheet>> listSheets() async {
    final client = await _getClient();
    final driveApi = drive.DriveApi(client);
    final result = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name,modifiedTime)',
      orderBy: 'modifiedTime desc',
    );
    return (result.files ?? [])
        .where((f) => f.id != null && f.name != null)
        .map((f) => DriveSheet(
              id: f.id!,
              name: f.name!,
              modified: _fmt(f.modifiedTime),
            ))
        .toList();
  }

  /// Appends [rows] to an existing spreadsheet. Does not write a header row.
  /// [range] controls which sheet/range is targeted (e.g. `'LoggerData'`).
  Future<void> appendToSheet(
      String spreadsheetId, List<List<String>> rows,
      {String range = 'A1', String? sheetName}) async {
    final client = await _getClient();
    final sheetsApi = sheets.SheetsApi(client);

    // If range is a named range (like LoggerData), it shouldn't have a sheet prefix.
    // If it's a cell range (like A1), it needs the sheet prefix.
    // A simple heuristic: if it contains only letters and numbers and is not A1-style, it's likely named.
    final bool isNamedRange = !range.contains(':') && !RegExp(r'^[A-Z]+\d+$').hasMatch(range);

    String targetRange;
    if (sheetName != null && !isNamedRange) {
      targetRange = "'$sheetName'!$range";
    } else {
      targetRange = range;
    }

    await sheetsApi.spreadsheets.values.append(
      sheets.ValueRange(values: rows.map((r) => r.cast<Object>()).toList()),
      spreadsheetId,
      targetRange,
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
  }

  /// Appends one data row to the LoggerData table on the Logger tab of a
  /// template-based spreadsheet.
  ///
  /// The first point is written into the seed row (row 2), which already holds
  /// formulae from [copyTemplate]. Every subsequent point inserts a new row
  /// with [inheritFromBefore] so formulae copy down automatically. If the sheet
  /// grid has no room for the insert, rows are added first.
  Future<void> appendRowToLogger(
      String spreadsheetId, List<String> rowData) async {
    final client = await _getClient();
    final sheetsApi = sheets.SheetsApi(client);

    // Get Logger tab properties (numeric ID and current grid row count).
    final meta = await sheetsApi.spreadsheets.get(
      spreadsheetId,
      $fields: 'sheets.properties',
    );
    final loggerSheet = (meta.sheets ?? [])
        .where((s) => s.properties?.title == 'Logger')
        .firstOrNull;
    if (loggerSheet == null) throw Exception('Logger tab not found');

    final numericId = loggerSheet.properties!.sheetId!;
    var rowCount = loggerSheet.properties!.gridProperties?.rowCount ?? 1000;

    // Read column A (always a plain-data column) to locate the last filled row.
    final colA = await sheetsApi.spreadsheets.values.get(
      spreadsheetId,
      'Logger!A:A',
    );
    final colAValues = colA.values ?? [];
    // colAValues[0] is the header; find the last non-empty entry after it.
    int lastDataRow = 1; // 1-based; 1 = header only
    for (int i = 1; i < colAValues.length; i++) {
      if (colAValues[i].isNotEmpty) lastDataRow = i + 1;
    }

    final targetRow = lastDataRow + 1; // 1-based row to write into

    if (targetRow > 2) {
      // Expand the grid if there is no room for an insert at targetRow.
      if (targetRow > rowCount) {
        final toAdd = targetRow - rowCount + 10;
        await sheetsApi.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(
            requests: [
              sheets.Request(
                appendDimension: sheets.AppendDimensionRequest(
                  sheetId: numericId,
                  dimension: 'ROWS',
                  length: toAdd,
                ),
              ),
            ],
          ),
          spreadsheetId,
        );
        rowCount += toAdd;
      }

      // Insert a row at targetRow, inheriting formulae from the row above.
      await sheetsApi.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(
          requests: [
            sheets.Request(
              insertDimension: sheets.InsertDimensionRequest(
                range: sheets.DimensionRange(
                  sheetId: numericId,
                  dimension: 'ROWS',
                  startIndex: targetRow - 1, // 0-based → inserts before this position
                  endIndex: targetRow,
                ),
                inheritFromBefore: true,
              ),
            ),
          ],
        ),
        spreadsheetId,
      );
    }

    // Write the data into the target row (formulae columns are left untouched).
    await sheetsApi.spreadsheets.values.update(
      sheets.ValueRange(values: [rowData.cast<Object>()]),
      spreadsheetId,
      'Logger!A$targetRow',
      valueInputOption: 'USER_ENTERED',
    );
  }

  /// Reads a range from a spreadsheet and returns it as a list of string rows.
  Future<List<List<String>>> readSheetValues(
      String spreadsheetId, String range) async {
    final client = await _getClient();
    final sheetsApi = sheets.SheetsApi(client);
    final response =
        await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    return (response.values ?? [])
        .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
        .toList();
  }

  /// Updates an existing row in the spreadsheet.
  /// [range] should be in A1 notation, e.g., 'Logger!A5'.
  Future<void> updateRow(
      String spreadsheetId, String range, List<String> rowData) async {
    final client = await _getClient();
    final sheetsApi = sheets.SheetsApi(client);
    await sheetsApi.spreadsheets.values.update(
      sheets.ValueRange(values: [rowData.cast<Object>()]),
      spreadsheetId,
      range,
      valueInputOption: 'USER_ENTERED',
    );
  }

  /// Copies the template spreadsheet [templateId] into [folderId], names it
  /// [title], prepares the LoggerData table for fresh data (preserving formulae
  /// in the first data row), and returns the new spreadsheet ID.
  Future<String> copyTemplate(
      String templateId, String folderId, String title) async {
    final client = await _getClient();
    final driveApi = drive.DriveApi(client);

    final copied = await driveApi.files.copy(
      drive.File(name: title, parents: [folderId]),
      templateId,
    );
    final sheetId = copied.id!;

    final sheetsApi = sheets.SheetsApi(client);

    // LoggerData is a Table inside the "Logger" sheet tab (not a separate tab).
    // Find that tab by name to get its numeric ID and row count.
    final spreadsheet = await sheetsApi.spreadsheets.get(
      sheetId,
      $fields: 'sheets.properties',
    );
    final loggerSheet = (spreadsheet.sheets ?? [])
        .where((s) => s.properties?.title == 'Logger')
        .firstOrNull;

    if (loggerSheet != null) {
      final numericId = loggerSheet.properties!.sheetId!;
      final rowCount = loggerSheet.properties!.gridProperties?.rowCount ?? 2;

      // Read row 2 (first data row) as formulas to identify which cells contain
      // formulae vs plain data. Formulae must be preserved so they auto-populate
      // when new rows are appended; plain-data cells are cleared.
      final row2Response = await sheetsApi.spreadsheets.values.get(
        sheetId,
        'Logger!2:2',
        valueRenderOption: 'FORMULA',
      );
      final row2Values = row2Response.values?.firstOrNull ?? [];

      final rangesToClear = <String>[];
      for (int i = 0; i < row2Values.length; i++) {
        final cell = row2Values[i]?.toString() ?? '';
        if (!cell.startsWith('=')) {
          rangesToClear.add('Logger!${_columnLetter(i)}2');
        }
      }
      if (rangesToClear.isNotEmpty) {
        await sheetsApi.spreadsheets.values.batchClear(
          sheets.BatchClearValuesRequest(ranges: rangesToClear),
          sheetId,
        );
      }

      // Delete rows 3 onwards, keeping header (row 1) and the seed row 2 that
      // holds the formulae. One trailing row is left intact — Sheets requires
      // at least one non-frozen row to remain.
      if (rowCount > 3) {
        await sheetsApi.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(
            requests: [
              sheets.Request(
                deleteDimension: sheets.DeleteDimensionRequest(
                  range: sheets.DimensionRange(
                    sheetId: numericId,
                    dimension: 'ROWS',
                    startIndex: 2,          // 0-based → row 3
                    endIndex: rowCount - 1, // leave last row intact
                  ),
                ),
              ),
            ],
          ),
          sheetId,
        );
      }
    }

    return sheetId;
  }

  /// Converts a 0-based column index to an A1-notation column letter (A, B, …, Z, AA, …).
  static String _columnLetter(int index) {
    var result = '';
    var n = index + 1;
    while (n > 0) {
      n--;
      result = String.fromCharCode('A'.codeUnitAt(0) + n % 26) + result;
      n ~/= 26;
    }
    return result;
  }

  /// Creates a new spreadsheet (optionally inside [folderId]) and writes
  /// [rows] (including header) into it. Returns the new spreadsheet ID.
  Future<String> createSheet(
      String title, String? folderId, List<List<String>> rows) async {
    final client = await _getClient();

    String spreadsheetId;

    if (folderId != null) {
      // Use Drive API so we can set the parent folder
      final driveApi = drive.DriveApi(client);
      final file = await driveApi.files.create(
        drive.File(
          name: title,
          mimeType: 'application/vnd.google-apps.spreadsheet',
          parents: [folderId],
        ),
      );
      spreadsheetId = file.id!;
    } else {
      final sheetsApi = sheets.SheetsApi(client);
      final created = await sheetsApi.spreadsheets.create(
        sheets.Spreadsheet(
          properties: sheets.SpreadsheetProperties(title: title),
        ),
      );
      spreadsheetId = created.spreadsheetId!;
    }

    if (rows.isNotEmpty) {
      final sheetsApi = sheets.SheetsApi(client);
      await sheetsApi.spreadsheets.values.append(
        sheets.ValueRange(values: rows.map((r) => r.cast<Object>()).toList()),
        spreadsheetId,
        'A1',
        valueInputOption: 'USER_ENTERED',
      );
    }

    return spreadsheetId;
  }

  String _fmt(DateTime? dt) =>
      dt == null ? '' : DateFormat('d MMM yyyy').format(dt);
}
