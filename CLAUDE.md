# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Branch & PR Workflow

- Default branch is `main` (not `master`)
- NEVER push directly to main — it has branch protection. Always create a feature branch and open a PR.
- The active development branch is `flutter` — check which branch contains the code before editing files like README.md
- Verify current branch with `git branch --show-current` before making commits

## Shell Environment

- User runs PowerShell on Windows, NOT bash
- Do not use bash-isms: no backslash line continuations, no `$(pwd)`, no `&&` chaining assumptions
- Use PowerShell-compatible syntax: backtick for line continuation, `${PWD}`, `;` for command chaining
- Prefer cross-platform commands when writing docs/READMEs

## Guardrails

- Do NOT run setup/install commands (e.g., downloading Flutter SDK, launching emulators) without first confirming with the user
- For UI automation tasks, ask whether `flutter test` / integration tests would be faster than computer-use screenshot loops before starting
- When a tool/approach is failing repeatedly (emulator, URL fetch), stop after 2 attempts and ask for direction

## Commands

```bash
flutter pub get                              # fetch dependencies
flutter analyze                              # lint + type check
flutter test                                 # run all unit/widget tests
flutter test test/score_engine_test.dart     # run a single test file
flutter run                                  # debug on connected device/emulator
flutter build apk --release                  # → build/app/outputs/flutter-apk/app-release.apk
```

**Integration / E2E test** (requires patched patrol CLI + Pixel 7 Pro AVD booted):
```bash
dart run "C:/Users/marko/patrol_cli_patched/bin/main.dart" test \
  -t integration_test/e2e_match_flow_test.dart \
  --device emulator-5554 \
  --dart-define=TEST_ACCOUNT_EMAIL=<your@gmail.com> \
  --dart-define=TEST_FOLDER_NAME=test_folder
```

**Release:** bump `version` in `pubspec.yaml`, commit, then `git tag vX.Y.Z && git push origin vX.Y.Z`. CI enforces that the tag matches the pubspec version.

## Architecture

### State and navigation

All match state (`_points`, `_currentPoint`, `_settings`, `_scoreOverride`) lives in a single `_AppShellState` in `lib/main.dart`. There is no state management library — the shell passes state down as constructor arguments and receives updates via callbacks (`onFieldChange`, `onNext`, `onEditPoint`, etc.).

Navigation is a 2-tab `NavigationBar` (Match / Settings) combined with an internal `_AppScreen` enum (`setup → entry → history`). History covers the full screen and hides the bottom nav. There is no `Navigator` push/pop.

### Score engine

`lib/services/score_engine.dart` exports a single pure function:
```dart
ScoreState calcScore(List<TennisPoint> points, MatchFormat fmt)
```
It replays the entire point list on every call — no caching. Points with `serverWon == null` are skipped. The engine handles normal games, deuce/ad, regular tiebreaks, and final-set tiebreaks (10-pt or 6-pt per `FinalSetType`).

### Data model

- **`TennisPoint`** (`lib/models/point.dart`): 6 nullable `bool` fields (`myServe`, `firstServe`, `doubleFault`, `serverWon`, `forcedError`, `loserForehand`) plus an id and timestamp. `withField(key, value)` returns a new instance by string key (used by `TriChip`).
- **`MatchFormat`** (`lib/models/match_settings.dart`): immutable scoring config. Built-in USTA Junior presets: `l7_short`, `l7_regular`, `l6`, `l5`.
- **`AppSettings`** (`lib/models/match_settings.dart`): immutable, `copyWith` pattern. Holds the active `MatchFormat` plus all Google Sheets sync state (`GsState`, `SheetMode`, `DriveFolder`, `DriveSheet`, sheet ID). Persisted via `shared_preferences` in `SettingsScreen`.
- **`ScoreState`**: immutable output of `calcScore` — sets, games, point score string, `isTiebreak`, `matchOver`.

### No persistent match data

Match points are held in memory only during the session. Editing a past point in `HistoryScreen` calls `_handleEditPoint()`, which replaces the point in `_points` and re-triggers `_autoSync()`.

### Google Sheets integration

`GoogleAuthService` (`lib/services/google_auth_service.dart`) is a singleton initialised at startup. It wraps `google_sign_in` v7+, which uses Android Credential Manager — a **native** bottom sheet outside the Flutter widget tree. The integration test uses UIAutomator2 (via patrol) to tap the account row in that native sheet; all other test interactions are pure Dart.

Two sync modes:
- **Create** (`SheetMode.create`): copies a Drive template into a user-chosen folder; syncs append/update rows in the `Logger` named sheet (row index = `point index + 2`).
- **Existing** (`SheetMode.existing`): appends to a named range `LoggerData` in a user-chosen sheet; in-place updates are not supported for this mode.

### Setup requirements for Google features

- Set `_webClientId` in `lib/services/google_auth_service.dart` to your OAuth Web client ID.
- Place `android/app/google-services.json` (from Firebase Console) — gitignored, required for Crashlytics, must be added manually on each machine.
- Debug SHA-1 must be registered in Google Cloud Console per dev machine.
