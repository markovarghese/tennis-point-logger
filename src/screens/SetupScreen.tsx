import React, { useState } from 'react';
import {
  View, Text, TextInput, Pressable, StyleSheet, KeyboardAvoidingView, Platform, ScrollView,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { C } from '../theme/colors';
import { useMatchStore } from '../store/matchStore';
import { fmtDateInput } from '../utils/helpers';

export default function SetupScreen() {
  const insets = useSafeAreaInsets();
  const startMatch = useMatchStore(s => s.startMatch);
  const [opponent, setOpponent] = useState('');
  const [date, setDate] = useState(fmtDateInput(new Date()));

  const canStart = opponent.trim().length > 0;

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 12 }]}>
        <Text style={styles.appLabel}>Tennis Logger</Text>
        <Text style={styles.title}>New Match</Text>
        <Text style={styles.subtitle}>Set up your match to begin logging</Text>
      </View>

      <ScrollView contentContainerStyle={styles.form} keyboardShouldPersistTaps="handled">
        {/* Opponent */}
        <View style={styles.field}>
          <Text style={styles.fieldLabel}>Opponent Name *</Text>
          <TextInput
            style={styles.input}
            value={opponent}
            onChangeText={setOpponent}
            placeholder="e.g. Rafael N."
            placeholderTextColor={C.outline}
            autoFocus
            returnKeyType="next"
          />
        </View>

        {/* Date */}
        <View style={styles.field}>
          <Text style={styles.fieldLabel}>Date</Text>
          <TextInput
            style={styles.input}
            value={date}
            onChangeText={setDate}
            placeholder="YYYY-MM-DD"
            placeholderTextColor={C.outline}
            keyboardType="numeric"
          />
        </View>
      </ScrollView>

      {/* CTA */}
      <View style={[styles.cta, { paddingBottom: Math.max(insets.bottom, 16) + 8 }]}>
        <Pressable
          onPress={() => canStart && startMatch(opponent, date)}
          disabled={!canStart}
          style={({ pressed }) => [
            styles.startBtn,
            !canStart && styles.startBtnDisabled,
            pressed && canStart && { opacity: 0.85 },
          ]}
          android_ripple={canStart ? { color: 'rgba(255,255,255,0.2)' } : undefined}
        >
          <Text style={[styles.startBtnText, !canStart && styles.startBtnTextDisabled]}>
            Start Match →
          </Text>
        </Pressable>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: C.surface },
  header: {
    backgroundColor: C.primary,
    paddingHorizontal: 20,
    paddingBottom: 24,
    gap: 4,
  },
  appLabel: {
    fontSize: 11, color: 'rgba(255,255,255,0.7)',
    fontWeight: '600', letterSpacing: 1, textTransform: 'uppercase',
  },
  title: { fontSize: 26, fontWeight: '700', color: '#fff' },
  subtitle: { fontSize: 13, color: 'rgba(255,255,255,0.7)' },
  form: { padding: 24, gap: 20 },
  field: { gap: 6 },
  fieldLabel: {
    fontSize: 13, fontWeight: '600', color: C.onSurfaceVar, letterSpacing: 0.3,
  },
  input: {
    height: 52, borderRadius: 8, paddingHorizontal: 16,
    borderWidth: 1, borderColor: C.outlineVariant,
    backgroundColor: C.surface,
    fontSize: 16, color: C.onSurface,
  },
  cta: { paddingHorizontal: 20 },
  startBtn: {
    height: 56, borderRadius: 100, backgroundColor: C.primary,
    alignItems: 'center', justifyContent: 'center',
    shadowColor: C.primary,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.4,
    shadowRadius: 8,
    elevation: 4,
  },
  startBtnDisabled: {
    backgroundColor: C.outlineVariant,
    shadowOpacity: 0,
    elevation: 0,
  },
  startBtnText: { fontSize: 16, fontWeight: '600', color: C.onPrimary, letterSpacing: 0.5 },
  startBtnTextDisabled: { color: C.onSurfaceVar },
});
