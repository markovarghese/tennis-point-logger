## What changed
<!-- One-line summary. Use "add", "fix", "update", "remove" — not "changed". -->

## Why
<!-- Motivation: ticket link, user story, bug report, or just the reason. -->

## Type
<!-- Mark one -->
- [ ] Feature
- [ ] Bug fix
- [ ] Chore / refactor
- [ ] CI / infra

## Test plan
- [ ] Ran `flutter analyze` — no issues
- [ ] Ran `flutter test` — all unit tests pass
- [ ] Tested on device / emulator (Android)
- [ ] Verified golden path: _describe the flow you tested_
- [ ] No regressions in: _list adjacent features you spot-checked_
- [ ] Integration test passed (if Google Sheets / auth touched): `dart run "C:/Users/marko/patrol_cli_patched/bin/main.dart" test -t integration_test/e2e_match_flow_test.dart ...`

## Checklist
- [ ] Branch is up to date with `main`
- [ ] `pubspec.yaml` version bumped (patch → bug fix, minor → new feature, major → breaking change)
- [ ] No debug code or commented-out blocks left in
- [ ] CSV export still produces correct `TRUE`/`FALSE` values (if data model touched)
- [ ] `google-services.json` not committed (it is gitignored — keep it that way)
