import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Settings } from '../types';

const DEFAULT_SETTINGS: Settings = {
  playerName: 'Me',
  gsState: 'disconnected',
  gsAccount: '',
  sheetMode: 'create',
  selectedFolder: null,
  selectedSheet: null,
  autoSyncPerPoint: true,
  syncOnMatchEnd: false,
  keepOfflineCopy: true,
  // Level 7 short sets default
  formatPreset: 'l7_short',
  setsInMatch: 3,
  gamesPerSet: 4,
  adScoring: false,
  tiebreakPoints: 7,
  finalSet: '10-pt TB',
  noAdChoice: 'Receiver',
  note: 'Short sets to 4. At 4–4 a 7-pt set tiebreak. Split sets → 10-pt match tiebreak.',
};

interface SettingsState {
  settings: Settings;
  updateSettings: (patch: Partial<Settings>) => void;
  applyPreset: (id: Settings['formatPreset']) => void;
}

const PRESETS: Record<string, Partial<Settings>> = {
  l7_short: {
    formatPreset: 'l7_short', setsInMatch: 3, gamesPerSet: 4,
    adScoring: false, tiebreakPoints: 7, finalSet: '10-pt TB', noAdChoice: 'Receiver',
    note: 'Short sets to 4. At 4–4 a 7-pt set tiebreak. Split sets → 10-pt match tiebreak.',
  },
  l7_regular: {
    formatPreset: 'l7_regular', setsInMatch: 1, gamesPerSet: 6,
    adScoring: false, tiebreakPoints: 7, finalSet: 'Full', noAdChoice: 'Receiver',
    note: 'Single set to 6 games. 7-pt tiebreak at 6-all. No-ad.',
  },
  l6: {
    formatPreset: 'l6', setsInMatch: 3, gamesPerSet: 6,
    adScoring: false, tiebreakPoints: 7, finalSet: '10-pt TB', noAdChoice: 'Receiver',
    note: '',
  },
  l5: {
    formatPreset: 'l5', setsInMatch: 3, gamesPerSet: 6,
    adScoring: true, tiebreakPoints: 7, finalSet: 'Full', noAdChoice: 'Receiver',
    note: '',
  },
  custom: { formatPreset: 'custom', note: '' },
};

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      settings: DEFAULT_SETTINGS,

      updateSettings(patch) {
        set(s => ({ settings: { ...s.settings, ...patch } }));
      },

      applyPreset(id) {
        const preset = PRESETS[id];
        if (preset) {
          set(s => ({ settings: { ...s.settings, ...preset } }));
        }
      },
    }),
    {
      name: 'tennis-settings-store',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
