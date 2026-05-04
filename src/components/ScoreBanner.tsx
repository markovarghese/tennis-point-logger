import React from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { C } from '../theme/colors';
import { Score, ScoreOverride } from '../types';

interface Props {
  score: Score;
  opponentName: string;
  onTap?: () => void;
  override?: ScoreOverride | null;
}

export default function ScoreBanner({ score, opponentName, onTap, override }: Props) {
  const { mySets, oppSets, myGames, oppGames, ptScore, matchOver, isTiebreak, setsToWin } = score;

  const bannerBg = matchOver
    ? (mySets >= setsToWin ? C.winGreen : C.losRed)
    : C.primary;

  return (
    <Pressable onPress={onTap} style={[styles.banner, { backgroundColor: bannerBg }]}>
      {/* Override badge */}
      {override && (
        <View style={styles.overrideBadge}>
          <Text style={styles.overrideBadgeText}>OVERRIDE</Text>
        </View>
      )}

      {/* Me */}
      <View style={styles.side}>
        <Text style={styles.sideLabel}>Me</Text>
        <Text style={styles.setScore}>
          {mySets}
          <Text style={styles.gameScore}> {myGames}</Text>
        </Text>
      </View>

      {/* Centre */}
      <View style={styles.centre}>
        {isTiebreak && (
          <Text style={styles.tiebreakLabel}>TIEBREAK</Text>
        )}
        {matchOver ? (
          <Text style={styles.matchOverText}>
            {mySets >= setsToWin ? '🏆 Won' : '😞 Lost'}
          </Text>
        ) : (
          <Text style={styles.ptScore}>{ptScore}</Text>
        )}
        {onTap && <Text style={styles.tapHint}>tap to edit</Text>}
      </View>

      {/* Opponent */}
      <View style={styles.side}>
        <Text style={styles.sideLabel} numberOfLines={1}>{opponentName || 'Opponent'}</Text>
        <Text style={styles.setScore}>
          {oppSets}
          <Text style={styles.gameScore}> {oppGames}</Text>
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  banner: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  overrideBadge: {
    position: 'absolute',
    top: 4,
    right: 8,
    backgroundColor: 'rgba(255,255,255,0.25)',
    borderRadius: 100,
    paddingHorizontal: 8,
    paddingVertical: 2,
  },
  overrideBadgeText: {
    fontSize: 9,
    fontWeight: '700',
    color: '#fff',
    letterSpacing: 0.5,
  },
  side: {
    flex: 1,
    alignItems: 'center',
  },
  sideLabel: {
    fontSize: 10,
    color: 'rgba(255,255,255,0.7)',
    fontWeight: '500',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
    maxWidth: 80,
    textAlign: 'center',
  },
  setScore: {
    fontSize: 30,
    fontWeight: '700',
    color: '#fff',
    lineHeight: 36,
  },
  gameScore: {
    fontSize: 17,
    fontWeight: '400',
    opacity: 0.8,
  },
  centre: {
    alignItems: 'center',
    paddingHorizontal: 8,
  },
  tiebreakLabel: {
    fontSize: 9,
    color: 'rgba(255,255,255,0.7)',
    fontWeight: '700',
    letterSpacing: 0.5,
    marginBottom: 1,
  },
  ptScore: {
    fontSize: 14,
    fontWeight: '600',
    color: C.primaryContainer,
    letterSpacing: 1,
  },
  matchOverText: {
    fontSize: 13,
    fontWeight: '700',
    color: C.primaryContainer,
    letterSpacing: 0.5,
  },
  tapHint: {
    fontSize: 9,
    color: 'rgba(255,255,255,0.4)',
    marginTop: 1,
  },
});
