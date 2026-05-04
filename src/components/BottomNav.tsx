import React from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { C } from '../theme/colors';
import { Tab } from '../types';

interface Props {
  tab: Tab;
  onChange: (tab: Tab) => void;
}

const ITEMS: { id: Tab; label: string; icon: keyof typeof Ionicons.glyphMap; activeIcon: keyof typeof Ionicons.glyphMap }[] = [
  { id: 'match',    label: 'Match',    icon: 'tennisball-outline',  activeIcon: 'tennisball' },
  { id: 'settings', label: 'Settings', icon: 'settings-outline',    activeIcon: 'settings' },
];

export default function BottomNav({ tab, onChange }: Props) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.nav, { paddingBottom: Math.max(insets.bottom, 8) }]}>
      {ITEMS.map(item => {
        const active = tab === item.id;
        return (
          <Pressable
            key={item.id}
            onPress={() => onChange(item.id)}
            style={styles.item}
            android_ripple={{ color: 'rgba(0,0,0,0.06)', borderless: true }}
          >
            <View style={[styles.pill, active && styles.pillActive]}>
              <Ionicons
                name={active ? item.activeIcon : item.icon}
                size={24}
                color={active ? C.primary : C.outline}
              />
            </View>
            <Text style={[styles.label, active && styles.labelActive]}>
              {item.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  nav: {
    flexDirection: 'row',
    backgroundColor: C.surface,
    borderTopWidth: 1,
    borderTopColor: C.outlineVariant,
  },
  item: {
    flex: 1,
    alignItems: 'center',
    paddingTop: 8,
    gap: 4,
  },
  pill: {
    width: 64,
    height: 32,
    borderRadius: 100,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pillActive: {
    backgroundColor: C.secondaryContainer,
  },
  label: {
    fontSize: 12,
    color: C.onSurfaceVar,
    fontWeight: '400',
  },
  labelActive: {
    color: C.primary,
    fontWeight: '600',
  },
});
