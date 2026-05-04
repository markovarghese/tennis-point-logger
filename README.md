# Tennis Point Logger

Mobile app for rapid point-by-point tennis match data entry. Built with React Native (Expo) for Android-first with an iOS CI/CD path.

## Features

- **Quick point entry** — 3-state toggle chips (null / yes / no) for each attribute
- **Live score tracking** — format-aware engine supporting no-ad, ad, tiebreaks (7-pt / 10-pt / 6-pt), best-of-2/3
- **USTA Junior presets** — Level 7 (short sets & one set), Level 6, Level 5 one-tap configuration
- **Inline editing** — ‹/› nav to flip through past points and correct mistakes
- **Score override** — manually resync the score when resuming after a break
- **Google Sheets sync** — appends columns A–I to your existing `TennisAnalysis.xlsx` logger sheet
- **CSV export** — copy/share match data at any time

## Column mapping (Google Sheets)

| Col | Field | App field |
|-----|-------|-----------|
| A | Match Date & Time | auto |
| B | Play Time | auto |
| C | Opponent | match setup |
| D | `<Player>` Serve? | My Serve? toggle |
| E | First Serve? | toggle |
| F | Double Fault? | toggle |
| G | Won? | toggle |
| H | Loser's Forced Error? | toggle |
| I | Loser's Forehand? | toggle |
| J–O | Calculated columns | handled by Sheets formulas |

## Setup

```bash
npm install
npx expo start
```

## CI/CD

- **Android** → EAS Build → Google Play Internal Track
- **iOS** → EAS Build → TestFlight
- **OTA** → `expo-updates` on every `main` push

Add `EXPO_TOKEN` to your GitHub repository secrets, then configure `eas.json` with your project ID from `eas init`.

## Google Sheets Integration

1. Create a Google Cloud project and enable the Sheets API + Drive API
2. Create an OAuth 2.0 client (Android + iOS)
3. Add your client IDs to `src/services/googleSheets.ts`
4. In app Settings → sign in with Google → choose a folder or existing sheet
