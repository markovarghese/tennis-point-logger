// E2E integration test: log a point → verify in Sheets → edit → re-verify.
//
// Prerequisites
// ─────────────
// 1. A patched patrol CLI is checked in at C:/Users/marko/patrol_cli_patched/
//    (do NOT use `dart pub global activate patrol_cli` — the standard CLI will
//    not work here).
// 2. Boot a Pixel 7 Pro AVD.
// 3. Run (replace <your@gmail.com> with the test Google account email):
//      dart run "C:/Users/marko/patrol_cli_patched/bin/main.dart" test \
//        -t integration_test/e2e_match_flow_test.dart \
//        --device emulator-5554 \
//        --dart-define=TEST_ACCOUNT_EMAIL=<your@gmail.com> \
//        --dart-define=TEST_FOLDER_NAME=test_folder
//
// The test uses UIAutomator2 (via patrol) to handle the native Android
// Credential Manager sheet that appears during Google Sign-In, so it can run
// fully unattended on any device/emulator where the test account is already
// added in Android account settings.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:tennis_logger/main.dart' as app;
import 'package:tennis_logger/services/google_auth_service.dart';

import 'helpers/sheets_verifier.dart';

// Passed via --dart-define at run time.
const _testAccountEmail =
    String.fromEnvironment('TEST_ACCOUNT_EMAIL', defaultValue: '');
const _testFolderName =
    String.fromEnvironment('TEST_FOLDER_NAME', defaultValue: 'test_folder');

void main() {
  patrolTest(
    'log point → verify score & Sheets → open history → edit → re-verify score & Sheets',
    config: const PatrolTesterConfig(
      visibleTimeout: Duration(seconds: 45),
      settleTimeout: Duration(seconds: 10),
    ),
    ($) async {
      assert(
        _testAccountEmail.isNotEmpty,
        'Pass --dart-define=TEST_ACCOUNT_EMAIL=you@gmail.com',
      );

      // ── Boot app ───────────────────────────────────────────────────────────
      await GoogleAuthService.instance.initialize();
      await $.pumpWidgetAndSettle(const app.TennisLoggerApp());

      // ── Step 1: Navigate to Settings ───────────────────────────────────────
      await $(find.text('Settings')).tap();
      await $.pumpAndSettle();

      // ── Step 2: Sign in with Google ────────────────────────────────────────
      await $(find.byKey(const Key('sign_in_button'))).tap();

      // Credential Manager native sheet — handled by UIAutomator2.
      // The sheet shows the account email as a tappable row.
      await $.platformAutomator.tap(Selector(text: _testAccountEmail));

      // Some Android versions show a "Continue" confirmation button.
      try {
        await $.platformAutomator.tap(
          Selector(text: 'Continue'),
          timeout: const Duration(seconds: 5),
        );
      } catch (_) {
        // Not always present; safe to ignore.
      }

      // Wait for the Flutter UI to reach the connected state.
      await $(find.byKey(const Key('google_connected')))
          .waitUntilVisible(timeout: const Duration(seconds: 30));
      await $.pumpAndSettle();

      // ── Step 3: Pick a Drive folder and wait for sheet creation ────────────
      await $(find.byKey(const Key('folder_picker'))).tap();
      await $.pumpAndSettle();

      // The folder picker modal lists Drive folders by name.
      // Scroll down in case the folder is below the initial viewport.
      await $(find.text(_testFolderName)).scrollTo();
      await $(find.text(_testFolderName)).tap();
      await $.pumpAndSettle();

      // Scroll sheet_status into view (it renders below the folder picker),
      // then wait for the sheet creation to complete.
      await $(find.byKey(const Key('sheet_status'))).scrollTo();
      await $(find.byKey(const Key('sheet_status')))
          .$(find.text('✓ Ready'))
          .waitUntilVisible(timeout: const Duration(seconds: 60));

      // Capture sheet ID now that it has been created.
      final sheetId = await SheetsVerifier.findLatestTestSheet();

      // ── Step 4: Start a match ──────────────────────────────────────────────
      await $(find.text('Match')).tap();
      await $.pumpAndSettle();

      await $(find.byKey(const Key('opponent_name_field')))
          .enterText('Test Opponent');
      await $.pumpAndSettle();

      await $(find.byKey(const Key('start_match_button'))).tap();
      await $.pumpAndSettle();

      // ── Step 5: Set chips — I serve (myServe=true) and I win (serverWon=true)
      // TriChip cycles: null → true → false → null. One tap = true.
      await $(find.byKey(const Key('chip_myServe'))).tap();
      await $.pumpAndSettle();

      await $(find.byKey(const Key('chip_serverWon'))).tap();
      await $.pumpAndSettle();

      // ── Step 6: Log the point (triggers auto-sync to Sheets) ───────────────
      await $(find.byKey(const Key('bottom_cta_button'))).tap();
      await $.pumpAndSettle();

      // Allow the Sheets API call to complete.
      await Future.delayed(const Duration(seconds: 5));

      // ── Step 7: Verify point 1 in Google Sheets ───────────────────────────
      await SheetsVerifier.assertPoint1(
        sheetId,
        expectedMyServe: true,
        expectedServerWon: true,
      );

      // ── Checkpoint A: score banner and history after point 1 ──────────────
      // myServe=T, serverWon=T → server (me) wins → score advances to 15-0.
      await $(find.text('15-0')).waitUntilVisible();

      await $(find.text('All (1)')).tap();
      await $.pumpAndSettle();
      await $(find.text('0-0  0-0  15-0')).waitUntilVisible();
      await $(find.text('← Back to Entry')).tap();
      await $.pumpAndSettle();

      // ── Step 8: Navigate back to point 1 to edit it ───────────────────────
      // After tapping "Next Point →" we are now on new point #2.
      // Tap ‹ to navigate to point #1.
      await $(find.byKey(const Key('nav_prev'))).tap();
      await $.pumpAndSettle();

      // ── Step 9: Edit point 1 — flip serverWon to false (I lose) ───────────
      // Current state: serverWon=true. One tap: true → false.
      await $(find.byKey(const Key('chip_serverWon'))).tap();
      await $.pumpAndSettle();

      // Edit saves immediately (auto-sync fires on chip change for past points).
      await Future.delayed(const Duration(seconds: 5));

      // ── Step 10: Navigate forward to confirm we leave point 1 ─────────────
      await $(find.byKey(const Key('nav_next'))).tap();
      await $.pumpAndSettle();

      // ── Step 11: Re-verify — serverWon should now be FALSE ─────────────────
      await SheetsVerifier.assertPoint1(
        sheetId,
        expectedMyServe: true,
        expectedServerWon: false,
      );

      // ── Checkpoint B: score recomputed in history after edit ──────────────
      // myServe=T, serverWon=F → server (me) loses → score is 0-15.
      await $(find.text('All (1)')).tap();
      await $.pumpAndSettle();
      await $(find.text('0-0  0-0  0-15')).waitUntilVisible();
      await $(find.text('← Back to Entry')).tap();
      await $.pumpAndSettle();
    },
  );
}
