import React from 'react';
import { Pressable, Text, View, StyleSheet } from 'react-native';
import { C } from '../theme/colors';

interface Props {
  value: boolean | null;
  label: string;
  onChange: (v: boolean | null) => void;
  compact?: boolean;
}

export default function TriChip({ value, label, onChange, compact = false }: Props) {
  function cycle() {
    onChange(value === null ? true : value === true ? false : null);
  }

  const bg     = value === null ? C.chipNull    : value ? C.chipYes    : C.chipNo;
  const textC  = value === null ? C.chipNullText : value ? C.chipYesText : C.chipNoText;
  const mark   = value === null ? '—'           : value ? '✓'           : '✗';
  const markBg = value === null ? C.outlineVariant : value ? C.syncGreen : C.error;

  const h = compact ? 40 : 52;
  const dotSize = compact ? 22 : 28;
  const fontSize = compact ? 12 : 14;
  const markFontSize = compact ? 11 : 14;

  return (
    <Pressable
      onPress={cycle}
      style={({ pressed }) => [
        styles.chip,
        { backgroundColor: bg, height: h, opacity: pressed ? 0.8 : 1 },
        compact && styles.chipCompact,
      ]}
      android_ripple={{ color: 'rgba(0,0,0,0.08)', borderless: false }}
    >
      <View style={[styles.dot, { width: dotSize, height: dotSize, backgroundColor: markBg }]}>
        <Text style={[styles.dotText, { fontSize: markFontSize }]}>{mark}</Text>
      </View>
      <Text style={[styles.label, { color: textC, fontSize }]} numberOfLines={1}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 100,
    paddingHorizontal: 10,
    gap: 8,
    width: '100%',
  },
  chipCompact: {
    paddingHorizontal: 8,
  },
  dot: {
    borderRadius: 100,
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  dotText: {
    color: '#fff',
    fontWeight: '700',
  },
  label: {
    flex: 1,
    fontWeight: '500',
  },
});
