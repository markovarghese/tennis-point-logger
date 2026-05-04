import { Point } from '../types';

const pad = (n: number) => String(n).padStart(2, '0');

export const fmtTime = (d: Date) =>
  `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;

export const fmtDate = (d: Date) =>
  d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });

export const fmtDateInput = (d: Date) =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

export function newPoint(now = new Date()): Point {
  return {
    id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
    matchDateTime: now.toLocaleString('en-GB'),
    playTime: fmtTime(now),
    time: fmtTime(now),
    myServe:       null,
    firstServe:    null,
    doubleFault:   null,
    serverWon:     null,
    forcedError:   null,
    loserForehand: null,
  };
}
