# Tennis Point Logger

A mobile app for rapid point-by-point tennis match data entry, built with Flutter and Material You (Material Design 3).

> **Branch note:** the Flutter app lives on the `flutter` branch (where this README sits). The `main` branch holds only a short stub README and `LICENSE`. If you landed here from the GitHub default branch, run `git checkout flutter` first.

## What it does

Tennis Point Logger is designed for players, parents, and coaches who want to capture detailed shot-by-shot statistics during a tennis match without slowing the match down. Each point is logged with six binary tags, the running score is computed automatically, and the data can be exported or synced to a Google Sheet for analysis.

**Per-point data captured**

For every point, you tap one chip per question (Yes / No / unknown):

- **My Serve?** — were you the server
- **First Serve?** — went in on the first try
- **Double Fault?** — point ended on a double fault
- **Won?** — server won the point
- **Loser's Forced Error?** — point ended in a forced error
- **Loser's Forehand?** — final shot was off the loser's forehand

**Features**

- **Format-aware scoring engine** — sets, games, deuce/no-ad, configurable tiebreaks, and the USTA Junior presets (Levels 5/6/7 and Level 7 short sets)
- **Live score banner** — tracks sets, games, and points; detects tiebreaks and match end; tap to manually override the running score
- **History view** — review and edit any prior point; changes auto-save and propagate through the score engine
- **Match setup** — opponent name, match date, format preset
- **Export** — copy as CSV, save to device, or sync to Google Sheets (see below)
- **Google Sheets sync** — sign in with Google, pick a Drive folder for a new spreadsheet *or* an existing sheet, and choose your sync cadence (after every point, on match end, or offline-only)

## Project layout

```
.
├── android/              # Android native project
├── lib/
│   ├── main.dart         # App shell + navigation
│   ├── theme.dart        # Material You color tokens
│   ├── models/           # TennisPoint, MatchFormat, AppSettings
│   ├── services/         # Score engine
│   ├── screens/          # Setup, Entry, History, Settings
│   └── widgets/          # ScoreBanner, TriChip, ExportSheet, …
├── pubspec.yaml
└── .github/workflows/    # CI: analyze, test, build APK
```

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| **Flutter SDK** | 3.16+ (Dart 3.3+) | `flutter --version` to check |
| **Git** | any recent | for cloning |
| **Android Studio** *or* command-line Android SDK | with Android SDK 34+ and platform-tools | for Android builds |
| **Java JDK** | 17 | for the Android Gradle build |
| **Xcode** | 15+ | **iOS only** — required, only available on macOS |
| **CocoaPods** | latest | **iOS only** — `sudo gem install cocoapods` |
| A physical device or emulator | | Android emulator, iOS simulator, or USB-connected phone |

Verify your toolchain with:

```bash
flutter doctor
```

Resolve any red ✗ marks before proceeding (Flutter's output tells you exactly what's missing).

## Running locally

```bash
# 1. Clone the repo
git clone https://github.com/<your-org>/tennis-point-logger.git
cd tennis-point-logger

# 2. Switch to the app branch
git checkout flutter

# 3. Fetch dependencies
flutter pub get

# 4. List connected devices / emulators
flutter devices

# 5. Run in debug mode on the first available device
flutter run

# Or target a specific device
flutter run -d <device-id>
```

Hot reload (`r`) and hot restart (`R`) work in the running terminal.

### Running tests and the analyzer

```bash
flutter analyze
flutter test
```

## Deploying to Android

The repo already contains a working `android/` project.

### 1. Debug install (development)

Connect a phone with USB debugging enabled (or boot an emulator) and run:

```bash
flutter run --release   # full-speed build, still installable from your machine
```

### 2. Release APK (sideload / share an installable file)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Transfer the `.apk` to a phone and install it (the user must enable "Install unknown apps" for the source).

### 3. Release App Bundle (Google Play)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

Before publishing to Google Play, you need to **sign** the build:

1. Generate an upload keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (do **not** commit this file):
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```
3. Wire the signing config into `android/app/build.gradle` per the [Flutter signing docs](https://docs.flutter.dev/deployment/android#signing-the-app).
4. Re-run `flutter build appbundle --release`.
5. Upload the `.aab` via the [Google Play Console](https://play.google.com/console) → create the app, fill in store listing, attach the bundle to an Internal/Closed/Open testing track, then promote to Production.

### CI builds

`.github/workflows/build.yml` runs `flutter analyze`, `flutter test`, and `flutter build apk --release` on every push, uploading the APK as a workflow artifact.

## Deploying to iPhone

> **macOS required.** iOS builds cannot be produced on Windows or Linux — Xcode is Apple-only.

The repo currently does **not** include an `ios/` folder. You'll generate it once with the Flutter CLI.

### 1. Generate the iOS project (one-time)

From a Mac, in the repo root on the `flutter` branch:

```bash
flutter create --platforms=ios --org com.example .
flutter pub get
cd ios && pod install && cd ..
```

Replace `com.example` with your reverse-DNS bundle identifier (e.g. `com.yourname.tennislogger`). Commit the new `ios/` folder.

### 2. Run on a simulator

```bash
open -a Simulator              # boot the iOS simulator
flutter run -d "iPhone 15"     # or whatever device shows in `flutter devices`
```

### 3. Run on a physical iPhone

1. Connect the iPhone via USB and trust the computer.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Select the **Runner** target → **Signing & Capabilities** → set your Apple Developer **Team** (a free Apple ID works for personal-device installs but expires after 7 days; a paid $99/yr Apple Developer account is required for App Store distribution and longer-lived provisioning).
4. Pick your iPhone in the device dropdown and press ▶︎ in Xcode, **or** run:
   ```bash
   flutter run --release -d <iphone-device-id>
   ```

### 4. Release build for TestFlight / App Store

1. **Apple Developer Program membership** ($99/yr) at [developer.apple.com](https://developer.apple.com).
2. In [App Store Connect](https://appstoreconnect.apple.com), create the app record (bundle ID, name, SKU).
3. Build the release archive:
   ```bash
   flutter build ipa --release
   # Output: build/ios/ipa/<your-app>.ipa
   ```
4. Upload via Xcode (`Window → Organizer → Distribute App`) or with `xcrun altool` / Transporter.
5. Once processed, the build appears in App Store Connect → assign it to a **TestFlight** group for beta testers, or submit it for App Store review.

Apple's full guide: <https://docs.flutter.dev/deployment/ios>.

## Google sync setup

Google Sign-In and Sheets sync are fully implemented in the code. Before they will work you need to register the app in **Google Cloud Console** and create OAuth credentials. Do this once per development environment (the debug SHA-1 is machine-specific).

### 1. Create a Google Cloud project

1. Go to [console.cloud.google.com](https://console.cloud.google.com) → **New Project** → name it (e.g. `tennis-point-logger`) → **Create**.
2. With the project selected, go to **APIs & Services → Library** and enable:
   - **Google Drive API**
   - **Google Sheets API**

### 2. Configure the OAuth consent screen

1. Go to **APIs & Services → OAuth consent screen** (new UI: **Google Auth Platform → Overview**).
2. Click **Get started** (or **Create**), choose **External**, fill in an app name and your email, and complete the wizard.
3. Under **Test users**, add every Gmail address you want to test with while the app is in development.

### 3. Get your debug SHA-1

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

Copy the `SHA1:` value. You'll need a new one for each machine you develop on, and a different one for a release keystore when publishing.

### 4. Create OAuth client IDs

Go to **APIs & Services → Credentials** (new UI: **Google Auth Platform → Clients**) → **+ Create Client**.

**Android client** (required to trust the installed app):
- Application type: **Android**
- Package name: `com.markovarghese.tennispointlogger`
- SHA-1: paste the value from step 3
- → **Create**

**Web client** (used by the Flutter SDK to obtain ID tokens):
- Application type: **Web application**
- → **Create**
- Copy the **Client ID** — it ends in `.apps.googleusercontent.com`

### 5. Set the Web client ID in the code

Open [`lib/services/google_auth_service.dart`](lib/services/google_auth_service.dart) and replace the `_webClientId` constant with your Web client ID:

```dart
static const _webClientId = '<YOUR_WEB_CLIENT_ID>.apps.googleusercontent.com';
```

### Notes

- No `google-services.json` is required for this setup — the `google_sign_in` Flutter package uses the Web client ID directly.
- For a **release build** (Play Store), repeat step 3 with your upload/release keystore and create a second Android OAuth client for that SHA-1.
- iOS support requires a separate iOS OAuth client (bundle ID only, no SHA-1) and a `GoogleService-Info.plist` — see the [google_sign_in iOS setup guide](https://pub.dev/packages/google_sign_in#ios-integration).

## License

See [LICENSE](LICENSE).
