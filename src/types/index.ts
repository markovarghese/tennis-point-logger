export interface Point {
  id: string;
  matchDateTime: string;
  playTime: string;
  time: string;
  myServe: boolean | null;
  firstServe: boolean | null;
  doubleFault: boolean | null;
  serverWon: boolean | null;
  forcedError: boolean | null;
  loserForehand: boolean | null;
}

export interface Match {
  id: string;
  opponent: string;
  date: string;
  createdAt: string;
}

export type Screen = 'setup' | 'entry' | 'history';
export type Tab = 'match' | 'settings';

export type FinalSetFormat = 'Full' | '10-pt TB' | '6-pt TB';
export type NoAdChoice = 'Receiver' | 'Server';
export type FormatPreset = 'l7_short' | 'l7_regular' | 'l6' | 'l5' | 'custom';

export interface MatchFormat {
  formatPreset: FormatPreset;
  setsInMatch: number;
  gamesPerSet: number;
  adScoring: boolean;
  tiebreakPoints: number;
  finalSet: FinalSetFormat;
  noAdChoice: NoAdChoice;
  note: string;
}

export interface Score {
  mySets: number;
  oppSets: number;
  myGames: number;
  oppGames: number;
  ptScore: string;
  matchOver: boolean;
  isTiebreak: boolean;
  setsToWin: number;
}

export interface ScoreOverride {
  mySets: number;
  oppSets: number;
  myGames: number;
  oppGames: number;
  myPts: number;
  oppPts: number;
}

export type GoogleState = 'disconnected' | 'connecting' | 'connected';
export type SheetMode = 'create' | 'existing';

export interface DriveFolder {
  id: string;
  name: string;
}

export interface DriveSheet {
  id: string;
  name: string;
  modified: string;
}

export interface Settings extends MatchFormat {
  playerName: string;
  gsState: GoogleState;
  gsAccount: string;
  sheetMode: SheetMode;
  selectedFolder: DriveFolder | null;
  selectedSheet: DriveSheet | null;
  autoSyncPerPoint: boolean;
  syncOnMatchEnd: boolean;
  keepOfflineCopy: boolean;
}

export const FIELD_KEYS = [
  'myServe',
  'firstServe',
  'doubleFault',
  'serverWon',
  'forcedError',
  'loserForehand',
] as const;

export type FieldKey = typeof FIELD_KEYS[number];

export const FIELD_LABELS: Record<FieldKey, string> = {
  myServe:       'Serve?',
  firstServe:    'First Serve?',
  doubleFault:   'Double Fault?',
  serverWon:     'Won?',
  forcedError:   "Loser's Forced Error?",
  loserForehand: "Loser's Forehand?",
};

export const FIELD_COLS: Record<FieldKey, string> = {
  myServe:       'D',
  firstServe:    'E',
  doubleFault:   'F',
  serverWon:     'G',
  forcedError:   'H',
  loserForehand: 'I',
};
