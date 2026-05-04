import React, { useState } from 'react';
import {
  View, Text, TextInput, Pressable, ScrollView, StyleSheet, Switch, Modal,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { C } from '../theme/colors';
import { useSettingsStore } from '../store/settingsStore';
import { Settings, DriveFolder, DriveSheet } from '../types';

// ─── Sub-components ───────────────────────────────────────────────────────────

function SectionTitle({ title }: { title: string }) {
  return (
    <View style={s.sectionTitle}>
      <Text style={s.sectionTitleText}>{title}</Text>
    </View>
  );
}

function FormatRow({ label, sub, children }: { label: string; sub?: string; children: React.ReactNode }) {
  return (
    <View style={s.formatRow}>
      <View style={s.formatRowText}>
        <Text style={s.formatRowLabel}>{label}</Text>
        {sub ? <Text style={s.formatRowSub}>{sub}</Text> : null}
      </View>
      {children}
    </View>
  );
}

function SegPicker({
  options, value, onChange,
}: { options: string[]; value: string; onChange: (v: string) => void }) {
  return (
    <View style={s.segPicker}>
      {options.map(opt => (
        <Pressable
          key={opt}
          onPress={() => onChange(opt)}
          style={[s.segBtn, value === opt && s.segBtnActive]}
          android_ripple={{ color: 'rgba(0,0,0,0.08)' }}
        >
          <Text style={[s.segBtnText, value === opt && s.segBtnTextActive]}>{opt}</Text>
        </Pressable>
      ))}
    </View>
  );
}

function PickerModal({
  title, subtitle, items, onSelect, onClose,
}: {
  title: string;
  subtitle: string;
  items: (DriveFolder | DriveSheet)[];
  onSelect: (item: DriveFolder | DriveSheet) => void;
  onClose: () => void;
}) {
  return (
    <Modal animationType="slide" transparent visible onRequestClose={onClose}>
      <Pressable style={s.modalOverlay} onPress={onClose}>
        <Pressable style={s.modalSheet} onPress={e => e.stopPropagation()}>
          <View style={s.modalHandle} />
          <Text style={s.modalTitle}>{title}</Text>
          <Text style={s.modalSubtitle}>{subtitle}</Text>
          <ScrollView>
            {items.map(item => (
              <Pressable
                key={item.id}
                onPress={() => onSelect(item)}
                style={s.pickerItem}
                android_ripple={{ color: 'rgba(0,0,0,0.06)' }}
              >
                <Text style={s.pickerItemIcon}>
                  {'modified' in item ? '📊' : '📁'}
                </Text>
                <View style={s.pickerItemText}>
                  <Text style={s.pickerItemName}>{item.name}</Text>
                  {'modified' in item && (
                    <Text style={s.pickerItemSub}>Modified {(item as DriveSheet).modified}</Text>
                  )}
                </View>
                <Text style={s.pickerItemChevron}>›</Text>
              </Pressable>
            ))}
          </ScrollView>
          <Pressable onPress={onClose} style={s.pickerCancelBtn} android_ripple={{ color: 'rgba(0,0,0,0.06)' }}>
            <Text style={s.pickerCancelText}>Cancel</Text>
          </Pressable>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

// ─── Mock data (replaced by real Drive API once user authenticates) ────────────
const MOCK_FOLDERS: DriveFolder[] = [
  { id: 'f1', name: 'Tennis' },
  { id: 'f2', name: 'Sports Data' },
  { id: 'f3', name: 'My Drive (root)' },
  { id: 'f4', name: 'Training 2026' },
];

const MOCK_SHEETS: DriveSheet[] = [
  { id: 's1', name: 'TennisAnalysis.xlsx', modified: '2 May 2026' },
  { id: 's2', name: 'Match Log 2025',      modified: '12 Jan 2026' },
  { id: 's3', name: 'Training Stats',      modified: '30 Apr 2026' },
];

const PRESETS = [
  { id: 'l7_short'  as const, label: 'Level 7 — Short Sets',  sub: 'First to 4 games · 4–4 = 7-pt set TB · split sets = match TB' },
  { id: 'l7_regular'as const, label: 'Level 7 — One Set',     sub: '1 set to 6 games · 7-pt tiebreak at 6-all · no-ad' },
  { id: 'l6'        as const, label: 'Level 6',                sub: '6-game sets · best of 3 · 7-pt tiebreak · no-ad' },
  { id: 'l5'        as const, label: 'Level 5',                sub: '6-game sets · best of 3 · 7-pt tiebreak · ad scoring' },
  { id: 'custom'    as const, label: 'Custom',                  sub: 'Configure manually below' },
];

// ─── Main ─────────────────────────────────────────────────────────────────────
export default function SettingsScreen() {
  const insets = useSafeAreaInsets();
  const { settings, updateSettings, applyPreset } = useSettingsStore();

  const [showFolderPicker, setShowFolderPicker] = useState(false);
  const [showSheetPicker,  setShowSheetPicker]  = useState(false);
  const [gsConnecting,     setGsConnecting]     = useState(false);

  function handleConnect() {
    setGsConnecting(true);
    // TODO: replace with real expo-auth-session Google OAuth flow
    setTimeout(() => {
      setGsConnecting(false);
      updateSettings({ gsState: 'connected', gsAccount: 'user@gmail.com' });
    }, 1800);
  }

  function handleDisconnect() {
    updateSettings({
      gsState: 'disconnected', gsAccount: '',
      selectedFolder: null, selectedSheet: null,
    });
  }

  const year = new Date().getFullYear();

  return (
    <View style={[s.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={s.header}>
        <Text style={s.appLabel}>Tennis Logger</Text>
        <Text style={s.headerTitle}>Settings</Text>
      </View>

      <ScrollView showsVerticalScrollIndicator={false}>

        {/* ── Player ── */}
        <SectionTitle title="Player" />
        <View style={s.inputRow}>
          <Text style={s.inputLabel}>Your name (used in "{settings.playerName} Serve?" column)</Text>
          <TextInput
            style={s.textInput}
            value={settings.playerName}
            onChangeText={v => updateSettings({ playerName: v || 'Me' })}
            placeholder="Your name"
            placeholderTextColor={C.outline}
          />
        </View>

        {/* ── Google Account ── */}
        <SectionTitle title="Google Account" />

        {settings.gsState === 'disconnected' && (
          <View style={s.gsRow}>
            <Text style={s.gsDesc}>
              Connect your Google account to sync match data directly to Google Sheets.
            </Text>
            <Pressable onPress={handleConnect} style={s.googleBtn} android_ripple={{ color: 'rgba(255,255,255,0.2)' }}>
              <Text style={s.googleBtnText}>G  Sign in with Google</Text>
            </Pressable>
          </View>
        )}

        {gsConnecting && (
          <View style={s.gsRow}>
            <Text style={s.gsDesc}>Opening Google sign-in…</Text>
          </View>
        )}

        {settings.gsState === 'connected' && (
          <View>
            <View style={s.gsConnectedRow}>
              <View style={s.gsAvatar}>
                <Text style={s.gsAvatarText}>{settings.gsAccount[0]?.toUpperCase()}</Text>
              </View>
              <View style={s.gsAccountInfo}>
                <Text style={s.gsAccountLabel}>Google connected</Text>
                <Text style={s.gsAccountEmail}>{settings.gsAccount}</Text>
              </View>
              <View style={s.gsDot} />
            </View>
            <Pressable onPress={handleDisconnect} style={s.disconnectBtn}>
              <Text style={s.disconnectBtnText}>Disconnect account</Text>
            </Pressable>
          </View>
        )}

        {/* ── Sheet destination ── */}
        {settings.gsState === 'connected' && (
          <>
            <SectionTitle title="Google Sheets Destination" />

            {/* Mode toggle */}
            <View style={s.modeToggle}>
              {(['create', 'existing'] as const).map((mode, i) => (
                <Pressable
                  key={mode}
                  onPress={() => updateSettings({ sheetMode: mode })}
                  style={[s.modeBtn, settings.sheetMode === mode && s.modeBtnActive]}
                >
                  <Text style={[s.modeBtnText, settings.sheetMode === mode && s.modeBtnTextActive]}>
                    {i === 0 ? 'Create new sheet' : 'Use existing sheet'}
                  </Text>
                </Pressable>
              ))}
            </View>

            {settings.sheetMode === 'create' && (
              <View style={s.sheetSection}>
                <Text style={s.sheetDesc}>
                  Choose a Google Drive folder. The app will create{' '}
                  <Text style={{ fontWeight: '700' }}>TennisLogger_{year}.xlsx</Text> there.
                </Text>
                <Pressable
                  onPress={() => setShowFolderPicker(true)}
                  style={[s.browseBtn, settings.selectedFolder && s.browseBtnSelected]}
                >
                  <Text style={s.browseIcon}>{settings.selectedFolder ? '📁' : '📂'}</Text>
                  <View style={s.browseBtnText}>
                    <Text style={[s.browseBtnLabel, settings.selectedFolder && { color: C.onPrimaryContainer }]}>
                      {settings.selectedFolder?.name ?? 'Choose folder'}
                    </Text>
                    {!settings.selectedFolder && (
                      <Text style={s.browseBtnSub}>Tap to browse Google Drive</Text>
                    )}
                  </View>
                  <Text style={s.browseBtnChevron}>›</Text>
                </Pressable>
                {settings.selectedFolder && (
                  <View style={s.confirmCard}>
                    <Text style={s.confirmCardIcon}>📊</Text>
                    <View style={s.confirmCardText}>
                      <Text style={s.confirmCardName}>TennisLogger_{year}.xlsx</Text>
                      <Text style={s.confirmCardSub}>Will be created in {settings.selectedFolder.name}</Text>
                    </View>
                    <Text style={s.confirmCardBadge}>✓ Ready</Text>
                  </View>
                )}
              </View>
            )}

            {settings.sheetMode === 'existing' && (
              <View style={s.sheetSection}>
                <Text style={s.sheetDesc}>
                  Pick an existing Google Sheet. Data will be appended to the{' '}
                  <Text style={{ fontWeight: '700' }}>logger</Text> tab, columns A–I.
                </Text>
                <Pressable
                  onPress={() => setShowSheetPicker(true)}
                  style={[s.browseBtn, settings.selectedSheet && s.browseBtnSelected]}
                >
                  <Text style={s.browseIcon}>{settings.selectedSheet ? '📊' : '🔍'}</Text>
                  <View style={s.browseBtnText}>
                    <Text style={[s.browseBtnLabel, settings.selectedSheet && { color: C.onPrimaryContainer }]}>
                      {settings.selectedSheet?.name ?? 'Browse sheets'}
                    </Text>
                    {settings.selectedSheet ? (
                      <Text style={s.browseBtnSub}>Last modified {settings.selectedSheet.modified}</Text>
                    ) : (
                      <Text style={s.browseBtnSub}>Tap to choose from Google Drive</Text>
                    )}
                  </View>
                  <Text style={s.browseBtnChevron}>›</Text>
                </Pressable>
                {settings.selectedSheet && (
                  <View style={s.confirmCard}>
                    <Text style={s.confirmCardIcon}>✅</Text>
                    <View style={s.confirmCardText}>
                      <Text style={s.confirmCardName}>Connected to {settings.selectedSheet.name}</Text>
                      <Text style={s.confirmCardSub}>Appending to "logger" tab, cols A–I</Text>
                    </View>
                  </View>
                )}
              </View>
            )}

            {/* Sync behaviour */}
            <SectionTitle title="Sync Behaviour" />
            <SyncToggleRow
              label="Auto-sync after each point"
              sub="Sends each row immediately"
              value={settings.autoSyncPerPoint}
              onChange={v => updateSettings({ autoSyncPerPoint: v })}
            />
            <SyncToggleRow
              label="Sync on match end only"
              sub="Batch upload when match finishes"
              value={settings.syncOnMatchEnd}
              onChange={v => updateSettings({ syncOnMatchEnd: v })}
            />
            <SyncToggleRow
              label="Keep offline copy"
              sub="Store data locally even when synced"
              value={settings.keepOfflineCopy}
              onChange={v => updateSettings({ keepOfflineCopy: v })}
            />
          </>
        )}

        {/* ── Match Format ── */}
        <SectionTitle title="Match Format" />

        <View style={s.presetsSection}>
          <Text style={s.presetsLabel}>USTA Junior Presets</Text>
          {PRESETS.map(preset => {
            const active = (settings.formatPreset || 'l7_short') === preset.id;
            return (
              <Pressable
                key={preset.id}
                onPress={() => applyPreset(preset.id)}
                style={[s.presetBtn, active && s.presetBtnActive]}
                android_ripple={{ color: 'rgba(0,0,0,0.06)' }}
              >
                <View style={[s.presetRadio, active && s.presetRadioActive]}>
                  {active && <View style={s.presetRadioDot} />}
                </View>
                <View style={s.presetText}>
                  <Text style={s.presetLabel}>{preset.label}</Text>
                  <Text style={s.presetSub}>{preset.sub}</Text>
                </View>
              </Pressable>
            );
          })}
          {!!settings.note && (
            <View style={s.noteCard}>
              <Text style={s.noteIcon}>ℹ️</Text>
              <Text style={s.noteText}>{settings.note}</Text>
            </View>
          )}
        </View>

        {/* Custom format controls */}
        <FormatRow label="Sets in a match" sub="Best of…">
          <SegPicker
            options={['1','2','3','5']}
            value={String(settings.setsInMatch || 2)}
            onChange={v => updateSettings({ setsInMatch: parseInt(v), formatPreset: 'custom', note: '' })}
          />
        </FormatRow>
        <FormatRow label="Games per set" sub="Standard is 6">
          <SegPicker
            options={['4','6','8']}
            value={String(settings.gamesPerSet || 6)}
            onChange={v => updateSettings({ gamesPerSet: parseInt(v), formatPreset: 'custom', note: '' })}
          />
        </FormatRow>
        <FormatRow label="Deuce scoring">
          <SegPicker
            options={['Ad','No-Ad']}
            value={settings.adScoring ? 'Ad' : 'No-Ad'}
            onChange={v => updateSettings({ adScoring: v === 'Ad', formatPreset: 'custom', note: '' })}
          />
        </FormatRow>
        <FormatRow label="Tiebreak points" sub="At 6-6 (or last set)">
          <SegPicker
            options={['7','10','None']}
            value={settings.tiebreakPoints === 0 ? 'None' : String(settings.tiebreakPoints || 7)}
            onChange={v => updateSettings({ tiebreakPoints: v === 'None' ? 0 : parseInt(v), formatPreset: 'custom', note: '' })}
          />
        </FormatRow>
        <FormatRow label="Final set" sub="How is the last set decided?">
          <SegPicker
            options={['Full','10-pt TB','6-pt TB']}
            value={settings.finalSet || '10-pt TB'}
            onChange={v => updateSettings({ finalSet: v as Settings['finalSet'], formatPreset: 'custom', note: '' })}
          />
        </FormatRow>
        <FormatRow label="No-Ad final point" sub="Who chooses serve side?">
          <SegPicker
            options={['Receiver','Server']}
            value={settings.noAdChoice || 'Receiver'}
            onChange={v => updateSettings({ noAdChoice: v as Settings['noAdChoice'], formatPreset: 'custom', note: '' })}
          />
        </FormatRow>

        {/* About */}
        <SectionTitle title="About" />
        <View style={[s.aboutSection, { paddingBottom: Math.max(insets.bottom, 16) + 16 }]}>
          <Text style={s.aboutLine}>Tennis Logger v1.0.0</Text>
          <Text style={s.aboutSubLine}>Built with React Native (Expo)</Text>
          <Text style={s.aboutSubLine}>Google Sheets API v4</Text>
        </View>
      </ScrollView>

      {/* Folder picker */}
      {showFolderPicker && (
        <PickerModal
          title="Choose Folder"
          subtitle="Google Drive"
          items={MOCK_FOLDERS}
          onSelect={f => { updateSettings({ selectedFolder: f as DriveFolder }); setShowFolderPicker(false); }}
          onClose={() => setShowFolderPicker(false)}
        />
      )}

      {/* Sheet picker */}
      {showSheetPicker && (
        <PickerModal
          title="Choose Spreadsheet"
          subtitle="Google Drive"
          items={MOCK_SHEETS}
          onSelect={sh => { updateSettings({ selectedSheet: sh as DriveSheet }); setShowSheetPicker(false); }}
          onClose={() => setShowSheetPicker(false)}
        />
      )}
    </View>
  );
}

function SyncToggleRow({
  label, sub, value, onChange,
}: { label: string; sub: string; value: boolean; onChange: (v: boolean) => void }) {
  return (
    <View style={s.syncRow}>
      <View style={s.syncRowText}>
        <Text style={s.syncRowLabel}>{label}</Text>
        <Text style={s.syncRowSub}>{sub}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ false: C.surfaceVariant, true: C.primary }}
        thumbColor={value ? C.onPrimary : C.outline}
      />
    </View>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: C.surface },
  header: { backgroundColor: C.primary, paddingHorizontal: 20, paddingBottom: 18, paddingTop: 4 },
  appLabel: { fontSize: 11, color: 'rgba(255,255,255,0.7)', fontWeight: '600', letterSpacing: 1, textTransform: 'uppercase' },
  headerTitle: { fontSize: 24, fontWeight: '700', color: '#fff', marginTop: 4 },
  sectionTitle: { backgroundColor: C.surfaceVariant, paddingHorizontal: 20, paddingVertical: 8 },
  sectionTitleText: { fontSize: 11, fontWeight: '700', color: C.onSurfaceVar, textTransform: 'uppercase', letterSpacing: 1 },
  inputRow: { padding: 16, borderBottomWidth: 1, borderBottomColor: C.outlineVariant },
  inputLabel: { fontSize: 12, fontWeight: '600', color: C.onSurfaceVar, marginBottom: 6 },
  textInput: {
    height: 48, borderRadius: 8, paddingHorizontal: 14,
    borderWidth: 1, borderColor: C.outlineVariant, backgroundColor: C.surface,
    fontSize: 15, color: C.onSurface,
  },
  gsRow: { padding: 16, borderBottomWidth: 1, borderBottomColor: C.outlineVariant, gap: 12 },
  gsDesc: { fontSize: 13, color: C.onSurfaceVar, lineHeight: 20 },
  googleBtn: {
    height: 48, borderRadius: 100, backgroundColor: C.primary,
    alignItems: 'center', justifyContent: 'center',
  },
  googleBtnText: { fontSize: 14, fontWeight: '600', color: C.onPrimary },
  gsConnectedRow: {
    flexDirection: 'row', alignItems: 'center', gap: 14,
    paddingHorizontal: 20, paddingVertical: 14,
  },
  gsAvatar: {
    width: 44, height: 44, borderRadius: 22,
    backgroundColor: C.primaryContainer,
    alignItems: 'center', justifyContent: 'center',
  },
  gsAvatarText: { fontSize: 18, fontWeight: '700', color: C.onPrimaryContainer },
  gsAccountInfo: { flex: 1 },
  gsAccountLabel: { fontSize: 14, fontWeight: '600', color: C.onSurface },
  gsAccountEmail: { fontSize: 12, color: C.onSurfaceVar },
  gsDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: C.syncGreen },
  disconnectBtn: {
    marginHorizontal: 20, marginBottom: 14, height: 40, borderRadius: 100,
    borderWidth: 1, borderColor: C.outlineVariant, alignItems: 'center', justifyContent: 'center',
  },
  disconnectBtnText: { fontSize: 13, color: C.error, fontWeight: '600' },
  modeToggle: {
    flexDirection: 'row', gap: 8, padding: 14,
    borderBottomWidth: 1, borderBottomColor: C.outlineVariant,
  },
  modeBtn: {
    flex: 1, height: 38, borderRadius: 100,
    backgroundColor: C.surfaceVariant, alignItems: 'center', justifyContent: 'center',
  },
  modeBtnActive: { backgroundColor: C.primaryContainer },
  modeBtnText: { fontSize: 12, fontWeight: '400', color: C.onSurfaceVar },
  modeBtnTextActive: { fontWeight: '700', color: C.onPrimaryContainer },
  sheetSection: { padding: 14, borderBottomWidth: 1, borderBottomColor: C.outlineVariant, gap: 12 },
  sheetDesc: { fontSize: 13, color: C.onSurfaceVar, lineHeight: 20 },
  browseBtn: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    minHeight: 56, borderRadius: 12,
    borderWidth: 1.5, borderStyle: 'dashed', borderColor: C.outlineVariant,
    backgroundColor: C.surfaceVariant, padding: 12,
  },
  browseBtnSelected: { borderColor: C.primary, backgroundColor: C.primaryContainer + '44' },
  browseIcon: { fontSize: 22 },
  browseBtnText: { flex: 1 },
  browseBtnLabel: { fontSize: 14, fontWeight: '600', color: C.onSurfaceVar },
  browseBtnSub: { fontSize: 12, color: C.outline, marginTop: 1 },
  browseBtnChevron: { fontSize: 16, color: C.outline },
  confirmCard: {
    flexDirection: 'row', alignItems: 'center', gap: 10,
    padding: 10, borderRadius: 10, backgroundColor: C.secondaryContainer,
  },
  confirmCardIcon: { fontSize: 18 },
  confirmCardText: { flex: 1 },
  confirmCardName: { fontSize: 13, fontWeight: '600', color: C.onSecondaryContainer },
  confirmCardSub: { fontSize: 11, color: C.onSurfaceVar, marginTop: 1 },
  confirmCardBadge: { fontSize: 11, color: C.syncGreen, fontWeight: '700' },
  syncRow: {
    flexDirection: 'row', alignItems: 'center', gap: 14,
    paddingHorizontal: 20, paddingVertical: 14,
    borderBottomWidth: 1, borderBottomColor: C.outlineVariant,
  },
  syncRowText: { flex: 1 },
  syncRowLabel: { fontSize: 14, color: C.onSurface, fontWeight: '500' },
  syncRowSub: { fontSize: 12, color: C.onSurfaceVar, marginTop: 2 },
  presetsSection: { padding: 14, borderBottomWidth: 1, borderBottomColor: C.outlineVariant, gap: 8 },
  presetsLabel: { fontSize: 12, fontWeight: '600', color: C.onSurfaceVar, marginBottom: 2 },
  presetBtn: {
    flexDirection: 'row', alignItems: 'center', gap: 12, padding: 12,
    borderRadius: 12, borderWidth: 1.5, borderColor: C.outlineVariant, backgroundColor: C.surface,
  },
  presetBtnActive: { borderColor: C.primary, backgroundColor: C.primaryContainer + '55' },
  presetRadio: {
    width: 20, height: 20, borderRadius: 10,
    borderWidth: 2, borderColor: C.outline,
    alignItems: 'center', justifyContent: 'center',
  },
  presetRadioActive: { borderColor: C.primary, backgroundColor: C.primary },
  presetRadioDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: '#fff' },
  presetText: { flex: 1 },
  presetLabel: { fontSize: 14, fontWeight: '600', color: C.onSurface },
  presetSub: { fontSize: 12, color: C.onSurfaceVar, marginTop: 1 },
  noteCard: {
    flexDirection: 'row', alignItems: 'flex-start', gap: 10,
    padding: 10, borderRadius: 10, backgroundColor: C.tertiaryContainer,
    marginTop: 4,
  },
  noteIcon: { fontSize: 16 },
  noteText: { flex: 1, fontSize: 12, color: C.onSurface, lineHeight: 18 },
  formatRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: 20, paddingVertical: 12,
    borderBottomWidth: 1, borderBottomColor: C.outlineVariant, gap: 12,
  },
  formatRowText: { flex: 1 },
  formatRowLabel: { fontSize: 14, color: C.onSurface, fontWeight: '500' },
  formatRowSub: { fontSize: 11, color: C.onSurfaceVar, marginTop: 1 },
  segPicker: { flexDirection: 'row', gap: 4, flexShrink: 0 },
  segBtn: {
    height: 34, minWidth: 44, paddingHorizontal: 10, borderRadius: 100, borderWidth: 0,
    backgroundColor: C.surfaceVariant, alignItems: 'center', justifyContent: 'center',
  },
  segBtnActive: { backgroundColor: C.primaryContainer },
  segBtnText: { fontSize: 13, fontWeight: '400', color: C.onSurfaceVar },
  segBtnTextActive: { fontWeight: '700', color: C.onPrimaryContainer },
  aboutSection: { paddingHorizontal: 20, paddingTop: 14, gap: 4 },
  aboutLine: { fontSize: 13, color: C.onSurfaceVar },
  aboutSubLine: { fontSize: 12, color: C.outline },
  modalOverlay: { flex: 1, backgroundColor: C.scrim, justifyContent: 'flex-end' },
  modalSheet: {
    backgroundColor: C.surface,
    borderTopLeftRadius: 20, borderTopRightRadius: 20,
    padding: 20, maxHeight: '70%',
  },
  modalHandle: {
    width: 40, height: 4, borderRadius: 2,
    backgroundColor: C.outlineVariant,
    alignSelf: 'center', marginBottom: 16,
  },
  modalTitle: { fontSize: 18, fontWeight: '700', color: C.onSurface },
  modalSubtitle: { fontSize: 12, color: C.onSurfaceVar, marginTop: 2, marginBottom: 12 },
  pickerItem: {
    flexDirection: 'row', alignItems: 'center', gap: 14,
    paddingVertical: 14, paddingHorizontal: 4,
    borderBottomWidth: 1, borderBottomColor: C.outlineVariant,
  },
  pickerItemIcon: { fontSize: 24 },
  pickerItemText: { flex: 1 },
  pickerItemName: { fontSize: 15, fontWeight: '500', color: C.onSurface },
  pickerItemSub: { fontSize: 12, color: C.onSurfaceVar, marginTop: 1 },
  pickerItemChevron: { fontSize: 18, color: C.outline },
  pickerCancelBtn: {
    height: 48, borderRadius: 100, backgroundColor: C.surfaceVariant,
    alignItems: 'center', justifyContent: 'center', marginTop: 12,
  },
  pickerCancelText: { fontSize: 14, fontWeight: '600', color: C.onSurface },
});
