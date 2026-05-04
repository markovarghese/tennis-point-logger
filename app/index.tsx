import React, { useState } from 'react';
import { View, StyleSheet } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { C } from '../src/theme/colors';
import { Tab } from '../src/types';
import { useMatchStore } from '../src/store/matchStore';
import SetupScreen from '../src/screens/SetupScreen';
import PointEntryScreen from '../src/screens/PointEntryScreen';
import HistoryScreen from '../src/screens/HistoryScreen';
import SettingsScreen from '../src/screens/SettingsScreen';
import ExportSheet from '../src/screens/ExportSheet';
import BottomNav from '../src/components/BottomNav';

export default function App() {
  const [tab, setTab] = useState<Tab>('match');
  const [showExport, setShowExport] = useState(false);
  const screen = useMatchStore(s => s.screen);

  // Hide bottom nav on history screen (full-screen)
  const showBottomNav = screen !== 'history';

  return (
    <View style={styles.container}>
      <StatusBar style="light" backgroundColor={C.primary} />

      <View style={styles.content}>
        {/* Match tab screens */}
        {tab === 'match' && screen === 'setup' && (
          <SetupScreen />
        )}
        {tab === 'match' && screen === 'entry' && (
          <PointEntryScreen onShowExport={() => setShowExport(true)} />
        )}
        {tab === 'match' && screen === 'history' && (
          <HistoryScreen />
        )}

        {/* Settings tab */}
        {tab === 'settings' && (
          <SettingsScreen />
        )}

        {/* Export modal (overlays everything) */}
        {showExport && (
          <ExportSheet onClose={() => setShowExport(false)} />
        )}
      </View>

      {showBottomNav && (
        <BottomNav
          tab={tab}
          onChange={t => {
            setTab(t);
            // When switching back to match tab from settings, stay on current screen
          }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: C.surface,
  },
  content: {
    flex: 1,
  },
});
