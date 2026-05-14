# Tennis Point Logger — App Description for UI Redesign

## Overview

Tennis Point Logger is a mobile app for recording and analyzing tennis match points in real time. The target user is a player or coach who wants to log every point during a match (who served, first/second serve, outcome, error type) and optionally sync that data to Google Sheets for later analysis. The app uses a simple, sequential workflow: configure the match → log points one by one → review history → export data.

The app has **4 main screens** and **5 modal overlays**, navigated via a bottom navigation bar (Match tab / Settings tab) plus an internal screen stack on the Match tab.

---

## Screen 1: Setup Screen

**Purpose:** Configure a new match before logging begins.

**Header block:**
- App label: "TENNIS LOGGER"
- Screen title: "New Match"
- Subtitle: "Set up your match to begin logging"

**Form fields:**
- **Opponent Name** — Required text input. Placeholder: "e.g. Rafael N." Keyboard auto-opens on arrival.
- **Date** — Tappable field showing a formatted date (e.g. "13 May 2026"). Tapping opens a native date picker calendar. Defaults to today.

**Primary action:**
- **"Start Match →"** button — Disabled until the opponent name field has text. Tapping transitions to the Entry Screen.

---

## Screen 2: Entry Screen

**Purpose:** Log each individual point during an active match. This is the app's core screen — the user spends most of their time here.

**Top bar:**
- **"◀ Setup"** button — returns to setup. If points have been logged, it triggers the **Discard Match Confirmation** modal.
- **Sync status indicator** — shows a status dot and label: "Synced" (green dot) when connected and data is uploaded, or "No sync" (grey dot) when offline or disconnected.
- **"Export ↑"** button — disabled if no points have been logged. Tapping opens the Export Sheet modal.

**Score Banner:**
- Shows the current match score:
  - Player name + set score + game score
  - Current point score (e.g. "30 – 15") or, when in a tiebreak, the tiebreak point score. A "Tiebreak" label appears when relevant.
  - Opponent name + set score + game score
- Communicates match outcome visually when the match ends (won or lost).
- Tappable: opens the Score Override Sheet modal so the user can manually adjust the score.

**Navigation Strip:**
- **Previous button "‹"** — go to the previous logged point for review/editing. Disabled if at the first point.
- **Center info** — shows context:
  - If on a new unsaved point: "New · #5" (point number)
  - If reviewing a past point: "Point #3 of 4"
  - A timestamp (e.g., "⏱ 14:02:45"); briefly flashes "✓ saved" after auto-saving.
- **Next button "›"** — go to the next point. Disabled if already at the newest point.
- **"All (12)"** button — shows the total count of logged points and opens the History Screen.

**Editing context banner (only visible when reviewing a past point):**
- Shows: "Editing point #3 — changes save instantly" with a **"+ New point"** button.
- Briefly changes to "✓ Auto-saved" (with a green background flash) after a change is saved.

**Toggle Chips (the main logging interface):**
- A scrollable list of 6 toggle chips. Each chip represents one data field for the current point.
- Each chip shows the field's label and its current state: Yes (✓) / No (✗) / Unanswered (—).
- Tapping a chip cycles its value.
- The 6 fields in order:
  1. **My Serve?** — Three states: Yes / No / Unanswered. Tracks who served.
  2. **Server's First Serve?** — Two states: Yes / No.
  3. **Server Double Fault?** — Two states: Yes / No.
  4. **Server Won?** — Three states: Yes / No / Unanswered. The outcome of the point. Points left as Unanswered are skipped by the score engine.
  5. **Loser's Forced Error?** — Two states: Yes / No.
  6. **Loser's Forehand?** — Two states: Yes / No.

**Primary action button:**
- When on a new unsaved point: **"Next Point →"** — saves the current point and creates a new blank entry.
- When reviewing a past point: **"← Back to current point"** — returns to the unsaved new entry.

---

## Screen 3: History Screen

**Purpose:** Review and edit all logged points in a scrollable table. Covers the full screen, hiding the bottom navigation bar.

**Header:**
- Back button — returns to Entry Screen.
- Title: "Point History"
- Subtitle: opponent name and total point count (e.g. "Rafael N. · 12 points")

**Column header row (fixed at top of table):**
- Abbreviated labels with tooltips revealing their full names:
  - "#" — Point number
  - "Time" — Timestamp
  - "MS" — My Serve
  - "1S" — First Serve
  - "DF" — Double Fault
  - "SW" — Server Won
  - "FE" — Forced Error
  - "LF" — Loser Forehand

**Point rows (most recent first):**
- Each row shows: point number | timestamp + **compact score** (e.g., "0-0 0-0 15-0") | state indicator for each of the 6 fields (Yes / No / Unanswered)
- Tapping a row expands it to reveal an **Inline Editor** directly below the row.

**Inline Editor (expands below a tapped row):**
- Label: "Editing Point #3 — changes save instantly"
- 6 toggle chips (same as Entry Screen) for editing each field.
- **"Done"** button — collapses the editor.

**Bottom action:**
- **"← Back to Entry"** — returns to the Entry Screen.

---

## Screen 4: Settings Screen

**Purpose:** Configure the player's name, Google account integration, match format rules, and sync behavior. Accessible at any time via the Settings tab in the bottom navigation bar.

**Header:**
- App label: "TENNIS LOGGER"
- Screen title: "Settings"

---

### Section: Player

- **Your Name** — Text field. Used to label the player's columns in Google Sheets exports (mapped to "My Serve?").

---

### Section: Google Account

**Disconnected state:**
- Description explaining that connecting allows sync to Google Sheets.
- **"Sign in with Google"** button — triggers the Google OAuth sign-in flow.

**Connecting state:**
- Loading indicator + "Opening Google sign-in…" label while the auth flow is in progress.

**Connected state:**
- Shows the connected account's avatar initial, "Google connected" label, and email address.
- **"Disconnect account"** button — signs out of Google and clears sync state.

---

### Section: Google Sheets Destination (only visible when signed in)

**Mode toggle** — Two mutually exclusive choices:
- **"Create new sheet"** — app copies a template spreadsheet into a chosen Drive folder.
- **"Use existing sheet"** — app connects to a spreadsheet the user already has.

**Create mode:**
- Detailed info about copying the template and preserving formulae in the "Logger" tab.
- **Folder Picker button** — shows "Choose folder" or the name of the selected folder. Tapping opens the Folder Picker modal.
- **Status indicator** (appears after folder is selected): shows the auto-generated sheet name (e.g., `TennisPointLogger_202605141200`) and a status of loading / "✓ Ready" / "⚠ Failed."

**Existing mode:**
- **Spreadsheet Picker button** — shows "Browse sheets" or the selected sheet name and its last modified date. Tapping opens the Sheet Picker modal.
- **Connected status** (appears after sheet is selected): confirms the sheet name and that data will append to the "LoggerData" table.

---

### Section: Sheet Template

This section manages the Google Sheets template used when creating new sheets. The app clears data from the template on copy but **preserves formulae** (cells starting with `=`) so pivot tables and charts stay linked.

**Display mode (template is set):**
- Template name, short ID, and confirmation badges: "Logger tab ✓" "LoggerData ✓."
- **"Change"** button to enter edit mode.

**Empty mode (no template set):**
- Prompt: "Set template sheet" — "Paste a Google Sheets URL."

**Edit mode:**
- **Google Sheets URL** — text field for entering the template URL.
- Info explaining required template structure (must have a "Logger" tab and a named range "LoggerData").
- **"Cancel"** button, **"Reset"** button (resets to default template), **"Save"** button (disabled until URL is valid).

---

### Section: Sync Behaviour (only visible when signed in)

Three toggle switches:

1. **Auto-sync after each point** — sends each row immediately when "Next Point" is tapped.
2. **Sync on match end only** — batch uploads when the match finishes.
3. **Keep offline copy** — stores all data locally even when synced.

---

### Section: Match Format

Defines the scoring rules for the match.

**Preset selector** — 5 selectable options with detailed subtitles and info notes:
1. "Level 7 — Short Sets" (Sub: "First to 4 games · 4–4 = 7-pt set TB · split sets = match TB")
2. "Level 7 — One Set"
3. "Level 6"
4. "Level 5"
5. "Custom" — activates automatically when any custom option differs from a preset

**Custom format controls** — 5 settings using segmented pickers:

| Setting | Options |
|---|---|
| Sets in a match | 1 · 2 · 3 · 5 |
| Games per set | 4 · 6 · 8 |
| Deuce scoring | Ad · No-Ad |
| Tiebreak points | 7 · 10 · None |
| Final set | Full · 10-pt TB · 6-pt TB |

---

### Section: About

- App version (e.g., v1.0.0) and technology credits (Material You, Sheets API v4).
- **"View debug log"** button — opens the Debug Log Sheet modal.

---

## Modal Overlay 1: Score Override Sheet

**Triggered by:** Tapping the Score Banner on the Entry Screen.
**Type:** Bottom sheet.

**Purpose:** Manually set the current match score.

**Controls:**
- Number pickers for: My Sets, Opp Sets, My Games, Opp Games.
- Point score picker (e.g., 0, 15, 30, 40, Ad).
- **"Apply Score Override"** button.
- **Close (×)** button.

---

## Modal Overlay 2: Export Sheet

**Triggered by:** "Export ↑" button on the Entry Screen.
**Type:** Bottom sheet.

**Purpose:** Export match data out of the app.

**Header:** "Export Match" — shows opponent name, date, and point count.

**Two export actions:**
1. **Copy as CSV** — copies data to clipboard. Gives "✓ Copied!" feedback after tap.
2. **Save to device** — triggers the **native system share sheet** to share the .csv file with other apps.

**"Close"** button.

---

## Modal Overlay 3: Folder Picker Modal

**Triggered by:** Folder Picker button in Settings (Create mode).
**Type:** Bottom sheet.

**Purpose:** Browse Google Drive folders.

**Content:** Scrollable list of Drive folders.

**"Cancel"** button.

---

## Modal Overlay 4: Sheet Picker Modal

**Triggered by:** Spreadsheet Picker button in Settings (Existing mode).
**Type:** Bottom sheet.

**Purpose:** Browse Google Sheets files in Drive.

**Content:** Scrollable list of spreadsheets with name and last modified date.

**"Cancel"** button.

---

## Modal Overlay 5: Debug Log Sheet

**Triggered by:** "View debug log" button in the Settings About section.
**Type:** Resizable bottom sheet.

**Purpose:** View internal app logs.

**Header:** "Debug Log" title + **"Copy all"** button.

**Content:** Scrollable list of log entries with timestamps and severity dots (Red for error, Blue for info).

---

## Modal Overlay 6: Discard Match Confirmation

**Triggered by:** Tapping "◀ Setup" on the Entry Screen when points have been logged.
**Type:** Bottom sheet.

**Purpose:** Warn the user that going back will lose current match data.

**Content:**
- Warning icon and "Discard active match?" title.
- Summary of current match (Opponent name, date, point count).
- **"Discard & Start New Match"** button (Red).
- **"Cancel"** button.

---

## Navigation Map

```
App start
  └─► Setup Screen
        └─► [Start Match →] ──► Entry Screen
              ├─ [◀ Setup] ──(if points logged)──► Discard Match Confirmation (modal)
              │                                      └─ [Discard] ──► Setup Screen
              ├─ [Export ↑] ─────────────────► Export Sheet (modal)
              ├─ [Score Banner tap] ─────────► Score Override Sheet (modal)
              ├─ [All (N)] ──────────────────► History Screen
              │     └─ [← Back to Entry] ──► Entry Screen
              └─ Bottom Nav [Settings tab] ──► Settings Screen
                    ├─ [Sign in with Google] ──► Native OAuth sheet
                    ├─ [Folder Picker] ────────► Folder Picker Modal
                    ├─ [Spreadsheet Picker] ───► Sheet Picker Modal
                    └─ [View debug log] ───────► Debug Log Sheet (modal)
```

---

## Key UX Patterns

- **No persistent storage of match data** — points live in memory during the session only; Google Sheets or CSV export is the only persistence.
- **Auto-save when editing history** — changes to past points in the History Screen save immediately without a save button.
- **Score is derived, not stored** — the score banner recalculates from the full point list every time; "Server Won?" being unanswered skips that point in score calculation.
- **Three-state chips** — most fields support Yes / No / Unanswered (✓ / ✗ / —), letting the user log partial data and fill in details later.
