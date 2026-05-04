import React, { useState } from 'react';
import {
  View, Text, Pressable, ScrollView, StyleSheet, Modal,
} from 'react-native';
import { C } from '../theme/colors';
import { MatchFormat, ScoreOverride } from '../types';

interface Props {
  fmt: Partial<MatchFormat>;
  current: { mySets: number; oppSets: number; myGames: number; oppGames: number };
  onApply: (override: ScoreOverride) => void;
  onClose: () => void;
}

function NumPicker({
  label, value, options, onChange,
}: {
  label: string; value: number; options: number[]; onChange: (v: number) => void;
}) {
  return (
    <View style={s.pickerCol}>
      <View style={s.pickerHeader}>
        <Text style={s.pickerLabel}>{label}</Text>
        <View style={s.currentBadge}>
          <Text style={s.currentBadgeText}>{value}</Text>
        </View>
      </View>
      <View style={s.pickerRow}>
        {options.map(o => {
          const selected = value === o;
          return (
            <Pressable
              key={o}
              onPress={() => onChange(o)}
              style={[s.numBtn, selected && s.numBtnSelected]}
              android_ripple={{ color: 'rgba(0,0,0,0.1)' }}
            >
              <Text style={[s.numBtnText, selected && s.numBtnTextSelected]}>{o}</Text>
              {selected && <View style={s.checkDot} />}
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

export default function ScoreOverrideEditor({ fmt, current, onApply, onClose }: Props) {
  const {
    setsInMatch = 2,
    gamesPerSet = 6,
  } = fmt;

  const setsToWin = Math.ceil(setsInMatch / 2);
  const gameNums = Array.from({ length: gamesPerSet + 1 }, (_, i) => i);
  const setNums  = Array.from({ length: setsToWin }, (_, i) => i);
  const ptNums   = [0, 1, 2, 3, 4];

  const [mySets,   setMySets]   = useState(current.mySets   || 0);
  const [oppSets,  setOppSets]  = useState(current.oppSets  || 0);
  const [myGames,  setMyGames]  = useState(current.myGames  || 0);
  const [oppGames, setOppGames] = useState(current.oppGames || 0);
  const [myPts,    setMyPts]    = useState(0);
  const [oppPts,   setOppPts]   = useState(0);

  return (
    <Modal animationType="slide" transparent visible onRequestClose={onClose}>
      <Pressable style={s.overlay} onPress={onClose}>
        <Pressable style={s.sheet} onPress={e => e.stopPropagation()}>
          <View style={s.handle} />

          {/* Header */}
          <View style={s.header}>
            <View>
              <Text style={s.title}>Set Current Score</Text>
              <Text style={s.subtitle}>Tap a number to select it, then hit Apply</Text>
            </View>
            <Pressable onPress={onClose} style={s.closeBtn}>
              <Text style={s.closeBtnText}>✕</Text>
            </Pressable>
          </View>

          <ScrollView showsVerticalScrollIndicator={false}>
            {/* Sets */}
            <View style={s.pickerSection}>
              <NumPicker label="My Sets"   value={mySets}   options={setNums}  onChange={setMySets} />
              <View style={s.divider} />
              <NumPicker label="Opp Sets"  value={oppSets}  options={setNums}  onChange={setOppSets} />
            </View>

            {/* Games */}
            <View style={s.pickerSection}>
              <NumPicker label="My Games"  value={myGames}  options={gameNums} onChange={setMyGames} />
              <View style={s.divider} />
              <NumPicker label="Opp Games" value={oppGames} options={gameNums} onChange={setOppGames} />
            </View>

            {/* Points */}
            <View style={s.pickerSection}>
              <NumPicker label="My Pts"    value={myPts}    options={ptNums}   onChange={setMyPts} />
              <View style={s.divider} />
              <NumPicker label="Opp Pts"   value={oppPts}   options={ptNums}   onChange={setOppPts} />
            </View>

            <Text style={s.note}>
              New points will be appended — override doesn't delete history.
            </Text>

            <Pressable
              onPress={() => onApply({ mySets, oppSets, myGames, oppGames, myPts, oppPts })}
              style={s.applyBtn}
              android_ripple={{ color: 'rgba(255,255,255,0.2)' }}
            >
              <Text style={s.applyBtnText}>Apply Score Override</Text>
            </Pressable>
          </ScrollView>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const s = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: C.scrim,
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: C.surface,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    paddingBottom: 32,
    maxHeight: '85%',
  },
  handle: {
    width: 40, height: 4, borderRadius: 2,
    backgroundColor: C.outlineVariant,
    alignSelf: 'center',
    marginBottom: 16,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  title: { fontSize: 18, fontWeight: '700', color: C.onSurface },
  subtitle: { fontSize: 12, color: C.onSurfaceVar, marginTop: 2 },
  closeBtn: { padding: 4 },
  closeBtnText: { fontSize: 22, color: C.onSurfaceVar },
  pickerSection: {
    backgroundColor: C.surfaceVariant,
    borderRadius: 12,
    padding: 14,
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 12,
  },
  divider: { width: 1, backgroundColor: C.outlineVariant },
  pickerCol: { alignItems: 'center', gap: 8, flex: 1 },
  pickerHeader: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  pickerLabel: {
    fontSize: 11, color: C.onSurfaceVar, fontWeight: '600',
    textTransform: 'uppercase', letterSpacing: 0.5,
  },
  currentBadge: {
    backgroundColor: C.primaryContainer,
    borderRadius: 100,
    paddingHorizontal: 9,
    paddingVertical: 1,
  },
  currentBadgeText: { fontSize: 13, fontWeight: '700', color: C.primary },
  pickerRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 6, justifyContent: 'center', maxWidth: 150 },
  numBtn: {
    minWidth: 40, height: 40, borderRadius: 10,
    backgroundColor: C.surfaceVariant,
    borderWidth: 2, borderColor: 'transparent',
    alignItems: 'center', justifyContent: 'center',
  },
  numBtnSelected: {
    backgroundColor: C.primary,
    borderColor: C.primary,
    shadowColor: C.primary,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.4,
    shadowRadius: 4,
    elevation: 4,
  },
  numBtnText: { fontSize: 15, fontWeight: '400', color: C.onSurface },
  numBtnTextSelected: { color: C.onPrimary, fontWeight: '700' },
  checkDot: {
    position: 'absolute', top: -5, right: -5,
    width: 14, height: 14, borderRadius: 7,
    backgroundColor: C.primary,
    borderWidth: 2, borderColor: C.surface,
  },
  note: {
    fontSize: 11, color: C.onSurfaceVar, textAlign: 'center',
    marginBottom: 16,
  },
  applyBtn: {
    height: 52, borderRadius: 100, backgroundColor: C.primary,
    alignItems: 'center', justifyContent: 'center',
    shadowColor: C.primary,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.35,
    shadowRadius: 8,
    elevation: 4,
  },
  applyBtnText: { fontSize: 15, fontWeight: '700', color: C.onPrimary },
});
