import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Point, Match, Screen, ScoreOverride, FieldKey } from '../types';
import { newPoint } from '../utils/helpers';
import { fmtDateInput } from '../utils/helpers';

interface MatchState {
  activeMatch: Match | null;
  points: Point[];
  currentPoint: Point;
  screen: Screen;
  scoreOverride: ScoreOverride | null;

  startMatch: (opponent: string, date: string) => void;
  endMatch: () => void;
  updateField: (key: FieldKey, value: boolean | null) => void;
  nextPoint: () => void;
  editPoint: (updated: Point) => void;
  setScreen: (screen: Screen) => void;
  setScoreOverride: (override: ScoreOverride | null) => void;
}

export const useMatchStore = create<MatchState>()(
  persist(
    (set, get) => ({
      activeMatch: null,
      points: [],
      currentPoint: newPoint(),
      screen: 'setup',
      scoreOverride: null,

      startMatch(opponent, date) {
        const now = new Date();
        set({
          activeMatch: {
            id: `${Date.now()}`,
            opponent: opponent.trim(),
            date: date || fmtDateInput(now),
            createdAt: now.toISOString(),
          },
          points: [],
          currentPoint: newPoint(now),
          scoreOverride: null,
          screen: 'entry',
        });
      },

      endMatch() {
        set({ activeMatch: null, points: [], currentPoint: newPoint(), screen: 'setup', scoreOverride: null });
      },

      updateField(key, value) {
        set(s => ({ currentPoint: { ...s.currentPoint, [key]: value } }));
      },

      nextPoint() {
        const { currentPoint, points } = get();
        set({ points: [...points, currentPoint], currentPoint: newPoint() });
      },

      editPoint(updated) {
        set(s => ({ points: s.points.map(p => p.id === updated.id ? updated : p) }));
      },

      setScreen(screen) {
        set({ screen });
      },

      setScoreOverride(override) {
        set({ scoreOverride: override });
      },
    }),
    {
      name: 'tennis-match-store',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
