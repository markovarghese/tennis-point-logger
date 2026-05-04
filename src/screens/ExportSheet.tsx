import React, { useState } from 'react';
import {
  View, Text, Pressable, StyleSheet, Modal, Share, Platform,
} from 'react-native';
import { C } from '../theme/colors';
import { useMatchStore } from '../store/matchStore';
import { useSettingsStore } from '../store/settingsStore';
import { generateCSV } from '../utils/csvExport';
import * as Clipboard from 'expo-clipboard';

interface Props {
  onClose: () => void;
}

export default function ExportSheet({ onClose }: Props) {
  const { activeMatch, points } = useMatchStore();
  const { settings } = useSettingsStore();
  const [copied, setCopied] = useState(false);

  if (!activeMatch) return null;

  const csv = generateCSV(points, activeMatch.opponent, settings.playerName);

  async function copyCSV() {
    await Clipboard.setStringAsync(csv);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  async function shareCSV() {
    await Share.share({
      message: csv,
      title: `TennisLog_${activeMatch.opponent}_${activeMatch.date}.csv`,
    });
  }

  const actions = [
    {
      icon: '📋',
      label: copied ? '✓ Copied!' : 'Copy as CSV',
      sub: 'Paste into any spreadsheet',
      onPress: copyCSV,
      accent: copied,
    },
    {
      icon: '📤',
      label: 'Share CSV file',
      sub: Platform.OS === 'android' ? 'Share via Android sheet' : 'Share via iOS sheet',
      onPress: shareCSV,
      accent: false,
    },
    {
      icon: '📊',
      label: 'Open in Google Sheets',
      sub: settings.gsState === 'connected' ? 'Sync via Sheets API' : 'Connect Google account in Settings',
      onPress: () => {},
      accent: false,
      disabled: settings.gsState !== 'connected',
    },
  ];

  return (
    <Modal animationType="slide" transparent visible onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable style={styles.sheet} onPress={e => e.stopPropagation()}>
          <View style={styles.handle} />
          <Text style={styles.title}>Export Match</Text>
          <Text style={styles.meta}>
            {activeMatch.opponent} · {activeMatch.date} · {points.length} pts
          </Text>

          {actions.map(item => (
            <Pressable
              key={item.label}
              onPress={item.onPress}
              disabled={item.disabled}
              style={[
                styles.actionBtn,
                item.accent && styles.actionBtnAccent,
                item.disabled && styles.actionBtnDisabled,
              ]}
              android_ripple={{ color: 'rgba(0,0,0,0.08)' }}
            >
              <Text style={styles.actionIcon}>{item.icon}</Text>
              <View style={styles.actionText}>
                <Text style={[styles.actionLabel, item.disabled && styles.actionLabelDisabled]}>
                  {item.label}
                </Text>
                <Text style={styles.actionSub}>{item.sub}</Text>
              </View>
            </Pressable>
          ))}

          <Pressable onPress={onClose} style={styles.closeBtn} android_ripple={{ color: 'rgba(0,0,0,0.06)' }}>
            <Text style={styles.closeBtnText}>Close</Text>
          </Pressable>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1, backgroundColor: C.scrim, justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: C.surface,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 24,
    paddingBottom: 32,
    gap: 12,
  },
  handle: {
    width: 40, height: 4, borderRadius: 2,
    backgroundColor: C.outlineVariant,
    alignSelf: 'center',
    marginBottom: 8,
  },
  title: { fontSize: 20, fontWeight: '700', color: C.onSurface },
  meta: { fontSize: 13, color: C.onSurfaceVar, marginBottom: 4 },
  actionBtn: {
    flexDirection: 'row', alignItems: 'center', gap: 16,
    padding: 14, backgroundColor: C.surfaceVariant, borderRadius: 16,
  },
  actionBtnAccent: { backgroundColor: C.primaryContainer },
  actionBtnDisabled: { opacity: 0.5 },
  actionIcon: { fontSize: 24 },
  actionText: { flex: 1 },
  actionLabel: { fontSize: 15, fontWeight: '600', color: C.onSurface },
  actionLabelDisabled: { color: C.onSurfaceVar },
  actionSub: { fontSize: 12, color: C.onSurfaceVar, marginTop: 1 },
  closeBtn: {
    height: 48, borderRadius: 100, backgroundColor: C.surfaceVariant,
    alignItems: 'center', justifyContent: 'center', marginTop: 4,
  },
  closeBtnText: { fontSize: 14, fontWeight: '600', color: C.onSurface },
});
