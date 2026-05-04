import React, { useState } from 'react';
import {
  View, Text, Pressable, FlatList, StyleSheet,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { C } from '../theme/colors';
import { useMatchStore } from '../store/matchStore';
import { Point, FIELD_KEYS, FIELD_LABELS } from '../types';
import TriChip from '../components/TriChip';

function ChipMini({ value }: { value: boolean | null }) {
  const bg  = value === null ? C.chipNull    : value ? C.chipYes    : C.chipNo;
  const txt = value === null ? '—'           : value ? '✓'          : '✗';
  const tc  = value === null ? C.chipNullText : value ? C.chipYesText : C.chipNoText;
  return (
    <View style={[s.miniDot, { backgroundColor: bg }]}>
      <Text style={[s.miniDotText, { color: tc }]}>{txt}</Text>
    </View>
  );
}

function HistoryRow({
  point, index, total, isEditing, onTap, onEdit, onDone,
}: {
  point: Point;
  index: number;
  total: number;
  isEditing: boolean;
  onTap: () => void;
  onEdit: (p: Point) => void;
  onDone: () => void;
}) {
  const num = total - index;
  const rowBg = isEditing ? C.secondaryContainer : index % 2 === 0 ? C.surface : '#EDF4F2';

  return (
    <View>
      <Pressable
        onPress={!isEditing ? onTap : undefined}
        style={[s.row, { backgroundColor: rowBg }]}
        android_ripple={!isEditing ? { color: 'rgba(0,0,0,0.06)' } : undefined}
      >
        <Text style={s.rowNum}>#{num}</Text>
        <Text style={s.rowTime}>{point.time}</Text>
        {FIELD_KEYS.map(k => (
          <ChipMini key={k} value={point[k]} />
        ))}
      </Pressable>

      {isEditing && (
        <View style={s.editPanel}>
          <Text style={s.editBanner}>Editing #{num} — changes save instantly</Text>
          <View style={s.editChips}>
            {FIELD_KEYS.map(k => (
              <TriChip
                key={k}
                compact
                value={point[k]}
                label={FIELD_LABELS[k]}
                onChange={v => onEdit({ ...point, [k]: v })}
              />
            ))}
          </View>
          <Pressable onPress={onDone} style={s.doneBtn} android_ripple={{ color: 'rgba(0,0,0,0.06)' }}>
            <Text style={s.doneBtnText}>Done</Text>
          </Pressable>
        </View>
      )}
    </View>
  );
}

export default function HistoryScreen() {
  const insets = useSafeAreaInsets();
  const { points, activeMatch, editPoint, setScreen } = useMatchStore();
  const [editingId, setEditingId] = useState<string | null>(null);

  const reversed = [...points].reverse();

  return (
    <View style={[s.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={s.header}>
        <Pressable onPress={() => setScreen('entry')} style={s.backBtn} android_ripple={{ color: 'rgba(0,0,0,0.06)', borderless: true }}>
          <Ionicons name="arrow-back" size={24} color={C.onSurface} />
        </Pressable>
        <View style={s.headerText}>
          <Text style={s.headerTitle}>Point History</Text>
          <Text style={s.headerSub}>{activeMatch?.opponent} · {points.length} points</Text>
        </View>
      </View>

      {/* Column labels */}
      <View style={s.colHeader}>
        <Text style={[s.colLabel, { width: 32 }]}>#</Text>
        <Text style={[s.colLabel, { flex: 1 }]}>Time</Text>
        <Text style={[s.colLabel, s.colShort]} numberOfLines={1}>MS</Text>
        <Text style={[s.colLabel, s.colShort]} numberOfLines={1}>1S</Text>
        <Text style={[s.colLabel, s.colShort]} numberOfLines={1}>DF</Text>
        <Text style={[s.colLabel, s.colShort]} numberOfLines={1}>W</Text>
        <Text style={[s.colLabel, s.colShort]} numberOfLines={1}>FE</Text>
        <Text style={[s.colLabel, s.colShort]} numberOfLines={1}>LF</Text>
      </View>

      <FlatList
        data={reversed}
        keyExtractor={item => item.id}
        renderItem={({ item, index }) => (
          <HistoryRow
            point={item}
            index={index}
            total={points.length}
            isEditing={editingId === item.id}
            onTap={() => setEditingId(item.id)}
            onEdit={updated => editPoint(updated)}
            onDone={() => setEditingId(null)}
          />
        )}
        ListEmptyComponent={
          <Text style={s.empty}>No points logged yet.</Text>
        }
      />

      {/* Back button */}
      <View style={[s.footer, { paddingBottom: Math.max(insets.bottom, 12) + 4 }]}>
        <Pressable onPress={() => setScreen('entry')} style={s.backToEntry} android_ripple={{ color: 'rgba(0,0,0,0.06)' }}>
          <Text style={s.backToEntryText}>← Back to Entry</Text>
        </Pressable>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: C.surface },
  header: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    paddingHorizontal: 16, paddingVertical: 12,
    borderBottomWidth: 1, borderBottomColor: C.outlineVariant,
  },
  backBtn: { padding: 8 },
  headerText: { flex: 1 },
  headerTitle: { fontSize: 18, fontWeight: '600', color: C.onSurface },
  headerSub: { fontSize: 12, color: C.onSurfaceVar },
  colHeader: {
    flexDirection: 'row', alignItems: 'center',
    paddingHorizontal: 16, paddingVertical: 6,
    backgroundColor: C.surfaceVariant,
    gap: 4,
  },
  colLabel: {
    fontSize: 9, fontWeight: '700', color: C.onSurfaceVar,
    textTransform: 'uppercase', letterSpacing: 0.5,
  },
  colShort: { width: 24, textAlign: 'center' },
  row: {
    flexDirection: 'row', alignItems: 'center',
    paddingHorizontal: 16, paddingVertical: 10,
    borderBottomWidth: 1, borderBottomColor: C.outlineVariant,
    gap: 4,
  },
  rowNum: { fontSize: 12, fontWeight: '600', color: C.primary, width: 32 },
  rowTime: { flex: 1, fontSize: 12, fontFamily: 'monospace', color: C.onSurfaceVar },
  miniDot: {
    width: 22, height: 22, borderRadius: 11,
    alignItems: 'center', justifyContent: 'center',
  },
  miniDotText: { fontSize: 11, fontWeight: '700' },
  editPanel: {
    backgroundColor: C.secondaryContainer,
    padding: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: C.outlineVariant,
    gap: 8,
  },
  editBanner: { fontSize: 12, fontWeight: '600', color: C.onSecondaryContainer },
  editChips: { gap: 6 },
  doneBtn: {
    height: 38, borderRadius: 100, backgroundColor: C.surfaceVariant,
    alignItems: 'center', justifyContent: 'center', marginTop: 4,
  },
  doneBtnText: { fontSize: 13, fontWeight: '600', color: C.onSurface },
  empty: { padding: 32, textAlign: 'center', color: C.onSurfaceVar, fontSize: 14 },
  footer: { paddingHorizontal: 16, paddingTop: 12 },
  backToEntry: {
    height: 48, borderRadius: 100, backgroundColor: C.surfaceVariant,
    alignItems: 'center', justifyContent: 'center',
  },
  backToEntryText: { fontSize: 14, fontWeight: '600', color: C.onSurface },
});
