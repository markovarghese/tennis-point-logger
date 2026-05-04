import { Point } from '../types';

const boolVal = (v: boolean | null): string =>
  v === null ? '' : v ? '1' : '0';

export function generateCSV(points: Point[], opponent: string, playerName: string): string {
  const headers = [
    'Match Date & Time',
    'Play Time',
    'Opponent',
    `${playerName} Serve?`,
    'First Serve?',
    'Double Fault?',
    'Won?',
    "Loser's Forced Error?",
    "Loser's Forehand?",
  ];

  const rows = points.map(p => [
    p.matchDateTime,
    p.playTime,
    opponent,
    boolVal(p.myServe),
    boolVal(p.firstServe),
    boolVal(p.doubleFault),
    boolVal(p.serverWon),
    boolVal(p.forcedError),
    boolVal(p.loserForehand),
  ].join(','));

  return [headers.join(','), ...rows].join('\n');
}

// Convert a single point to a row array (A–I) for Sheets API
export function pointToSheetRow(
  p: Point,
  opponent: string,
): (string | number)[] {
  return [
    p.matchDateTime,
    p.playTime,
    opponent,
    p.myServe       === null ? '' : p.myServe       ? 1 : 0,
    p.firstServe    === null ? '' : p.firstServe    ? 1 : 0,
    p.doubleFault   === null ? '' : p.doubleFault   ? 1 : 0,
    p.serverWon     === null ? '' : p.serverWon     ? 1 : 0,
    p.forcedError   === null ? '' : p.forcedError   ? 1 : 0,
    p.loserForehand === null ? '' : p.loserForehand ? 1 : 0,
  ];
}
