import React, { useState, useCallback } from 'react';
import {
  View, Text, Pressable, ScrollView, StyleSheet,
} from 'react-native';
import { C } from '../theme/colors';
import { useMatchStore } from '../store/matchStore';
import { useSettingsStore } from '../store/settingsStore';
import { calcScore } from '../utils/scoreEngine';
import { FIELD_KEYS, FIELD_LABELS, FieldKey } from '../types';
import ScoreBanner from '../components/ScoreBanner';
import ScoreOverrideEditor from '../components/ScoreOverrideEditor';
import TriChip from '../components/TriChip';

interface Props {
  onShowExport: () => void;
}

export default function PointEntryScreen({ onShowExport }: Props) {
  const {
    points, currentPoint, activeMatch, scoreOverride,
    updateField, nextPoint, editPoint, setScreen, setScoreOverride, endMatch,
  } = useMatchStore();
  const { settings } = useSettingsStore();

  const [viewIdx, setViewIdx] = useState<number | null>(null);
  const [autoSaveFlash, setAutoSaveFlash] = useState(false);
  const [showOverride, setShowOverride] = useState(false);

  const isNew = viewIdx === null;
  const displayPoint = isNew ? currentPoint : points[viewIdx!];
  const total = points.length;

  const calcedScore = calcScore(points, settings);
  const score = scoreOverride
    ? {
        ...calcedScore,
        mySets:   scoreOverride.mySets,
        oppSets:  scoreOverride.oppSets,
        myGames:  scoreOverride.myGames,
        oppGames: scoreOverride.oppGames,
      }
    : calcedScore;

  const prevIdx = isNew
    ? (total > 0 ? total - 1 : null)
    : (viewIdx! > 0 ? viewIdx! - 1 : null);
  const nextIdx = isNew
    ? null
    : (viewIdx! < total - 1 ? viewIdx! + 1 : null);

  const pointLabel = isNew
    ? `New · #${total + 1}`
    : `Point #${viewIdx! + 1} of ${total}`;

  const handleChipChange = useCallback((key: FieldKey, val: boolean | null) => {
    if (isNew) {
      updateField(key, val);
    } else {
      editPoint({ ...points[viewIdx!], [key]: val });
      setAutoSaveFlash(true);
      setTimeout(() => setAutoSaveFlash(false), 800);
    }
  }, [isNew, viewIdx, points, updateField, editPoint]);

  function handleNext() {
    nextPoint();
    setViewIdx(null);
  }

  // Build field labels (first field uses player name)
  const fieldLabel = (key: FieldKey) => {
    if (key === 'myServe') return `${settings.playerName} Serve?`;
    return FIELD_LABELS[key];
  };

  const syncDot = settings.gsState === 'connected'
    ? { color: C.syncGreen, label: 'Synced' }
    : { color: C.outline,    label: 'No sync' };

  return (
    <View style={styles.container}>
      {/* Toolbar */}
      <View style={styles.toolbar}>
        <Pressable onPress={endMatch} style={styles.toolbarBtn}>
          <Text style={styles.toolbarBtnText}>◀ Setup</Text>
        </Pressable>
        <View style={styles.syncIndicator}>
          <View style={[styles.syncDot, { backgroundColor: syncDot.color }]} />
          <Text style={styles.syncLabel}>{syncDot.label}</Text>
        </View>
        <Pressable onPress={onShowExport} style={styles.toolbarBtn}>
          <Text style={[styles.toolbarBtnText, { color: C.primary }]}>Export ↑</Text>
        </Pressable>
      </View>

      {/* Score banner */}
      <ScoreBanner
        score={score}
        opponentName={activeMatch?.opponent ?? ''}
        onTap={() => setShowOverride(true)}
        override={scoreOverride}
      />

      {/* Override editor modal */}
      {showOverride && (
        <ScoreOverrideEditor
          fmt={settings}
          current={score}
          onApply={v => { setScoreOverride(v); setShowOverride(false); }}
          onClose={() => setShowOverride(false)}
        />
      )}

      {/* Nav strip */}
      <View style={styles.navStrip}>
        <Pressable
          onPress={() => prevIdx !== null && setViewIdx(prevIdx)}
          disabled={prevIdx === null}
          style={[styles.navBtn, prevIdx === null && styles.navBtnDisabled]}
          android_ripple={{ color: 'rgba(0,0,0,0.06)', borderless: true }}
        >
          <Text style={[styles.navArrow, prevIdx !== null && { color: C.primary }]}>‹</Text>
        </Pressable>

        <View style={styles.navCenter}>
          <Text style={[styles.navLabel, isNew && { color: C.primary }]}>{pointLabel}</Text>
          <Text style={styles.navTime}>
            ⏱ {displayPoint?.time}
            {!isNew && autoSaveFlash ? '  ✓ saved' : ''}
          </Text>
        </View>

        <Pressable
          onPress={() => nextIdx !== null ? setViewIdx(nextIdx) : setViewIdx(null)}
          style={styles.navBtn}
          android_ripple={{ color: 'rgba(0,0,0,0.06)', borderless: true }}
        >
          <Text style={[styles.navArrow, { color: (nextIdx !== null || !isNew) ? C.primary : C.outlineVariant }]}>›</Text>
        </Pressable>

        <Pressable onPress={() => setScreen('history')} style={styles.allBtn}>
          <Text style={styles.allBtnText}>All ({total})</Text>
        </Pressable>
      </View>

      {/* Editing banner */}
      {!isNew && (
        <View style={[styles.editBanner, autoSaveFlash && styles.editBannerFlash]}>
          <Text style={styles.editBannerText}>
            {autoSaveFlash ? '✓ Auto-saved' : `Editing point #${viewIdx! + 1} — changes save instantly`}
          </Text>
          <Pressable onPress={() => setViewIdx(null)} style={styles.newPtBtn}>
            <Text style={styles.newPtBtnText}>+ New point</Text>
          </Pressable>
        </View>
      )}

      {/* Toggle chips */}
      <ScrollView
        style={styles.chips}
        contentContainerStyle={styles.chipsContent}
        showsVerticalScrollIndicator={false}
      >
        {FIELD_KEYS.map(key => (
          <TriChip
            key={key}
            value={displayPoint?.[key] ?? null}
            label={fieldLabel(key)}
            onChange={v => handleChipChange(key, v)}
          />
        ))}
      </ScrollView>

      {/* CTA */}
      {isNew ? (
        <View style={styles.cta}>
          <Pressable onPress={handleNext} style={styles.nextBtn} android_ripple={{ color: 'rgba(255,255,255,0.2)' }}>
            <Text style={styles.nextBtnText}>Next Point →</Text>
          </Pressable>
        </View>
      ) : (
        <View style={styles.cta}>
          <Pressable onPress={() => setViewIdx(null)} style={styles.backToNewBtn} android_ripple={{ color: 'rgba(255,255,255,0.2)' }}>
            <Text style={styles.nextBtnText}>← Back to current point</Text>
          </Pressable>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: C.surface },
  toolbar: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: 12, paddingTop: 8, backgroundColor: C.surface,
  },
  toolbarBtn: { padding: 6 },
  toolbarBtnText: { fontSize: 13, color: C.onSurfaceVar, fontWeight: '500' },
  syncIndicator: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  syncDot: { width: 8, height: 8, borderRadius: 4 },
  syncLabel: { fontSize: 11, color: C.onSurfaceVar },
  navStrip: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: C.surfaceVariant,
    borderBottomWidth: 1, borderBottomColor: C.outlineVariant,
    gap: 2, paddingHorizontal: 4,
  },
  navBtn: {
    width: 44, height: 44,
    alignItems: 'center', justifyContent: 'center',
    borderRadius: 22,
  },
  navBtnDisabled: {},
  navArrow: { fontSize: 28, color: C.outlineVariant, lineHeight: 32 },
  navCenter: { flex: 1, alignItems: 'center', paddingVertical: 6 },
  navLabel: { fontSize: 13, fontWeight: '600', color: C.secondary },
  navTime: { fontSize: 11, fontFamily: 'monospace', color: C.onSurfaceVar },
  allBtn: { paddingHorizontal: 10, paddingVertical: 4 },
  allBtnText: { fontSize: 11, fontWeight: '600', color: C.primary },
  editBanner: {
    backgroundColor: C.tertiaryContainer,
    paddingHorizontal: 16, paddingVertical: 6,
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
  },
  editBannerFlash: { backgroundColor: C.chipYes },
  editBannerText: { fontSize: 12, fontWeight: '600', color: C.onSurface, flex: 1 },
  newPtBtn: {
    height: 26, paddingHorizontal: 12, borderRadius: 100,
    backgroundColor: C.surfaceVariant, justifyContent: 'center',
  },
  newPtBtnText: { fontSize: 11, fontWeight: '600', color: C.onSurface },
  chips: { flex: 1 },
  chipsContent: { padding: 12, gap: 8 },
  cta: {
    paddingHorizontal: 16, paddingVertical: 10,
    paddingBottom: 14,
    borderTopWidth: 1, borderTopColor: C.outlineVariant,
  },
  nextBtn: {
    height: 56, borderRadius: 100, backgroundColor: C.primary,
    alignItems: 'center', justifyContent: 'center',
    shadowColor: C.primary,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.4,
    shadowRadius: 8,
    elevation: 4,
  },
  backToNewBtn: {
    height: 52, borderRadius: 100, backgroundColor: C.primary,
    alignItems: 'center', justifyContent: 'center',
    shadowColor: C.primary,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 3,
  },
  nextBtnText: { fontSize: 16, fontWeight: '600', color: C.onPrimary, letterSpacing: 0.5 },
});
