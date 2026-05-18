// Drives the app through every screen and modal defined in the
// `material_synthesis` design pack and writes a PNG of each into
// `docs/screenshots/temp/` via the matching test_driver.
//
// Run on a booted Pixel 7 Pro AVD with:
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart \
//     -d emulator-5554

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tennis_logger/main.dart' as app;
import 'package:tennis_logger/models/match_settings.dart';
import 'package:tennis_logger/theme.dart';
import 'package:tennis_logger/widgets/folder_picker_sheet.dart';
import 'package:tennis_logger/widgets/sheet_picker_sheet.dart';
import 'package:tennis_logger/services/app_log.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `convertFlutterSurfaceToImage()` may only be called once per test. We
  // call it up front and then take as many screenshots as we like.
  Future<void> snap(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await binding.takeScreenshot(name);
  }

  testWidgets('capture all design screens', (tester) async {
    await tester.pumpWidget(const app.TennisLoggerApp());
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();

    // 1. Setup screen.
    await snap(tester, '01_setup');

    // Start the match.
    await tester.enterText(
      find.byKey(const Key('opponent_name_field')),
      'R. Nadal',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_match_button')));
    await tester.pumpAndSettle();

    // Log 7 points to make the score banner non-trivial. After each commit
    // the app shows the just-logged point in "view" mode; tapping the right
    // chevron (`nav_next`) when on the most recent committed point returns
    // to "new point" mode so the next point can be logged.
    Future<void> logPoint({required bool serverWon}) async {
      await tester.tap(
        find.byKey(Key('chip_serverWon_${serverWon ? 'Y' : 'N'}')),
      );
      await tester.pumpAndSettle();
      // After commit we are in view mode for the just-saved point; return
      // to new-point mode.
      final next = find.byKey(const Key('nav_next'));
      if (next.evaluate().isNotEmpty) {
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
    }

    for (final won in [true, true, false, true, true, false, true]) {
      await logPoint(serverWon: won);
    }

    // Partially fill the current point so chips show selected states.
    await tester.tap(find.byKey(const Key('chip_myServe_Y')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chip_firstServe_Y')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chip_doubleFault_N')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chip_forcedError_N')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chip_loserForehand_Y')));
    await tester.pumpAndSettle();

    // 2. Entry screen.
    await snap(tester, '02_entry');

    // 3. Score override modal — tap the score banner.
    await tester.tap(find.text('VS'));
    await tester.pumpAndSettle();
    expect(find.text('Score Override'), findsOneWidget);
    await snap(tester, '03_score_override');
    // The X icon inside the sheet header — scoped to BottomSheet so we don't
    // accidentally tap an N chip's close icon rendered behind the modal.
    await tester.tap(find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byIcon(Icons.close),
    ));
    await tester.pumpAndSettle();

    // 4. Export modal.
    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();
    expect(find.text('Export Match'), findsOneWidget);
    await snap(tester, '04_export');
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // 5. History screen.
    await tester.tap(find.textContaining('ALL ('));
    await tester.pumpAndSettle();
    expect(find.text('Point History'), findsOneWidget);
    await snap(tester, '05_history');
    await tester.tap(find.text('Back to Entry'));
    await tester.pumpAndSettle();

    // 6. Discard match modal — back button on entry with points present.
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();
    expect(find.text('Discard active match?'), findsOneWidget);
    await snap(tester, '06_discard_match');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 7. Settings screen.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Match Format'), findsOneWidget);
    await snap(tester, '07_settings');

    // 8. Debug log sheet — populate with some entries first.
    AppLog.info('match: started vs R. Nadal');
    AppLog.info('settings: opened');
    AppLog.info('sync: ok → logger sheet');
    AppLog.error('sync: failed', 'network timeout');
    AppLog.info('match: point #1 logged');
    // The System card sits at the bottom of the settings ListView; scroll
    // until the "View Debug Logs" button is on screen.
    await tester.scrollUntilVisible(
      find.text('View Debug Logs'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Debug Logs'));
    await tester.pumpAndSettle();
    expect(find.text('Debug Log'), findsOneWidget);
    await snap(tester, '08_debug_log');
  });

  testWidgets('capture folder picker', (tester) async {
    await tester.pumpWidget(_PickerShowcase.folder());
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await snap(tester, '09_folder_picker');
  });

  testWidgets('capture sheet picker', (tester) async {
    await tester.pumpWidget(_PickerShowcase.sheet());
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await snap(tester, '10_sheet_picker');
  });
}

/// Minimal scaffolding around the folder/sheet picker sheets so they can be
/// captured without going through Google sign-in.
class _PickerShowcase extends StatelessWidget {
  final void Function(BuildContext) opener;

  const _PickerShowcase({required this.opener});

  factory _PickerShowcase.folder() {
    const folders = [
      DriveFolder(id: 'tm', name: 'Tennis Matches'),
      DriveFolder(id: 'lg', name: 'Logs'),
      DriveFolder(id: 's24', name: '2024 Season'),
      DriveFolder(id: 'pd', name: 'Practice Drills'),
      DriveFolder(id: 'cf', name: 'Coaching Feedback'),
    ];
    return _PickerShowcase(
      opener: (ctx) => showFolderPickerSheet(
        ctx,
        folders: folders,
        selectedId: 'tm',
      ),
    );
  }

  factory _PickerShowcase.sheet() {
    const sheets = [
      DriveSheet(id: 'a', name: 'Tennis 2024', modified: '2 days ago'),
      DriveSheet(id: 'b', name: 'Practice Log', modified: 'a week ago'),
      DriveSheet(id: 'c', name: 'Match Sheet — Spring', modified: '1 mo ago'),
      DriveSheet(id: 'd', name: 'Drills', modified: '3 mo ago'),
    ];
    return _PickerShowcase(
      opener: (ctx) => showSheetPickerSheet(
        ctx,
        sheets: sheets,
        selectedId: 'a',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Builder(
            builder: (ctx) => FilledButton(
              onPressed: () => opener(ctx),
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );
  }
}
