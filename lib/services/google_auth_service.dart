import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
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
  Future<void> appendToSheet(
      String spreadsheetId, List<List<String>> rows) async {
    final client = await _getClient();
    final sheetsApi = sheets.SheetsApi(client);
    await sheetsApi.spreadsheets.values.append(
      sheets.ValueRange(values: rows.map((r) => r.cast<Object>()).toList()),
      spreadsheetId,
      'A1',
      valueInputOption: 'USER_ENTERED',
    );
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
