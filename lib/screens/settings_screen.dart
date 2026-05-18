import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_settings.dart';
import '../services/app_log.dart';
import '../services/google_auth_service.dart';
import '../theme.dart';
import '../widgets/folder_picker_sheet.dart';
import '../widgets/sheet_picker_sheet.dart';
import '../widgets/debug_log_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _s;
  bool _creatingSheet = false;
  String _lastPresetId = 'l7_standard_single';

  // Visible presets in the design — the top four "USTA Tournament Level"
  // tiles plus the Custom Configuration card.
  static const List<String> _featuredPresets = [
    'l1_l4_full',
    'l1_l4_match_tb',
    'l5_l6_standard',
    'l7_standard_single',
  ];

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    if (_s.formatPreset != 'custom') {
      _lastPresetId = _s.formatPreset;
    }
  }

  void _update(AppSettings updated) {
    setState(() => _s = updated);
    widget.onChanged(updated);
  }

  void _applyPreset(String id) {
    final fmt = MatchFormat.presets[id];
    if (fmt == null) return;
    AppLog.info('settings: format preset → $id');
    _lastPresetId = id;
    _update(_s.copyWith(formatPreset: id, format: fmt));
  }

  void _switchToCustom() {
    if (_s.formatPreset == 'custom') return;
    AppLog.info('settings: format preset → custom (inherited from $_lastPresetId)');
    final lastFmt = MatchFormat.presets[_lastPresetId] ?? const MatchFormat();
    _update(_s.copyWith(formatPreset: 'custom', format: lastFmt));
  }

  void _updateCustomFormat(MatchFormat fmt) {
    _update(_s.copyWith(formatPreset: 'custom', format: fmt));
  }

  Future<void> _connectGoogle() async {
    _update(_s.copyWith(gsState: GsState.connecting));
    try {
      final email = await GoogleAuthService.instance.signIn();
      if (!mounted) return;
      if (email != null) {
        AppLog.info('auth: signed in as $email');
        _update(_s.copyWith(gsState: GsState.connected, gsAccount: email));
      } else {
        AppLog.info('auth: sign-in cancelled');
        _update(_s.copyWith(gsState: GsState.disconnected));
      }
    } catch (e) {
      if (!mounted) return;
      AppLog.error('auth: sign-in failed', e);
      _update(_s.copyWith(gsState: GsState.disconnected));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }

  Future<void> _disconnectGoogle() async {
    await GoogleAuthService.instance.signOut();
    AppLog.info('auth: signed out');
    if (!mounted) return;
    _update(_s.copyWith(
      gsState: GsState.disconnected,
      clearGsAccount: true,
      clearSelectedFolder: true,
      clearSelectedSheet: true,
      clearSheetsId: true,
    ));
  }

  String? _parseSheetId(String url) {
    final m = RegExp(r'spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    return m?.group(1);
  }

  Future<void> _pickFolder() async {
    List<DriveFolder> folders;
    try {
      folders = await GoogleAuthService.instance.listFolders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load folders: $e')),
      );
      return;
    }
    if (!mounted) return;
    final result = await showFolderPickerSheet(
      context,
      folders: folders,
      selectedId: _s.selectedFolder?.id,
    );
    if (result == null || !mounted) return;
    AppLog.info('settings: folder → "${result.name}"');
    _update(_s.copyWith(selectedFolder: result, clearSheetsId: true));
    final templateId = _parseSheetId(_s.templateUrl);
    if (templateId == null) return;
    setState(() => _creatingSheet = true);
    try {
      final ts = DateFormat('yyyyMMddHHmm').format(DateTime.now());
      final sheetId = await GoogleAuthService.instance.copyTemplate(
        templateId,
        result.id,
        'TennisPointLogger_$ts',
      );
      if (!mounted) return;
      AppLog.info('settings: sheet created');
      _update(_s.copyWith(sheetsId: sheetId));
    } catch (e) {
      if (!mounted) return;
      AppLog.error('settings: sheet create failed', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create sheet: $e')),
      );
    } finally {
      if (mounted) setState(() => _creatingSheet = false);
    }
  }

  Future<void> _pickSheet() async {
    List<DriveSheet> driveSheets;
    try {
      driveSheets = await GoogleAuthService.instance.listSheets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load spreadsheets: $e')),
      );
      return;
    }
    if (!mounted) return;
    final result = await showSheetPickerSheet(
      context,
      sheets: driveSheets,
      selectedId: _s.selectedSheet?.id,
    );
    if (result != null) {
      AppLog.info('settings: existing sheet → "${result.name}"');
      _update(_s.copyWith(selectedSheet: result, sheetsId: result.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
            child: Row(
              children: [
                const Icon(Icons.sports_tennis, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Match Tracker',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Configure your tracker preferences and integrations.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _GoogleAccountCard(
            state: _s.gsState,
            account: _s.gsAccount,
            onConnect: _connectGoogle,
            onDisconnect: _disconnectGoogle,
          ),
          if (_s.gsState == GsState.connected) ...[
            const SizedBox(height: 16),
            _SheetsIntegrationCard(
              settings: _s,
              creatingSheet: _creatingSheet,
              onPickFolder: _pickFolder,
              onPickSheet: _pickSheet,
              onModeChange: (m) =>
                  _update(_s.copyWith(sheetMode: m)),
            ),
          ],
          const SizedBox(height: 16),
          _MatchFormatCard(
            settings: _s,
            featuredPresets: _featuredPresets,
            onApplyPreset: _applyPreset,
            onSwitchToCustom: _switchToCustom,
            onUpdateCustomFormat: _updateCustomFormat,
          ),
          const SizedBox(height: 16),
          _SystemCard(onShowLogs: () => showDebugLogSheet(context)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _GoogleAccountCard extends StatelessWidget {
  final GsState state;
  final String? account;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _GoogleAccountCard({
    required this.state,
    required this.account,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = state == GsState.connected;
    final isConnecting = state == GsState.connecting;

    return _SectionCard(
      icon: Icons.account_circle_outlined,
      title: 'Google Account',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected
                          ? 'Status: Connected'
                          : 'Status: Not Signed In',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? (account ?? '')
                          : 'Sign in to enable cloud sync.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: isConnected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isConnecting
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : isConnected
                    ? OutlinedButton.icon(
                        onPressed: onDisconnect,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Sign out'),
                      )
                    : FilledButton.icon(
                        key: const Key('sign_in_button'),
                        onPressed: onConnect,
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Sign in with Google'),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SheetsIntegrationCard extends StatelessWidget {
  final AppSettings settings;
  final bool creatingSheet;
  final VoidCallback onPickFolder;
  final VoidCallback onPickSheet;
  final ValueChanged<SheetMode> onModeChange;

  const _SheetsIntegrationCard({
    required this.settings,
    required this.creatingSheet,
    required this.onPickFolder,
    required this.onPickSheet,
    required this.onModeChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      icon: Icons.table_chart_outlined,
      title: 'Google Sheets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<SheetMode>(
                  segments: const [
                    ButtonSegment(
                      value: SheetMode.create,
                      label: Text('Create New'),
                    ),
                    ButtonSegment(
                      value: SheetMode.existing,
                      label: Text('Use Existing'),
                    ),
                  ],
                  selected: {settings.sheetMode},
                  onSelectionChanged: (s) => onModeChange(s.first),
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (settings.sheetMode == SheetMode.create) ...[
            _PickerRow(
              key: const Key('folder_picker'),
              icon: Icons.folder_open,
              title: settings.selectedFolder?.name ?? 'Choose Folder',
              subtitle: 'Where to create match sheets',
              onTap: onPickFolder,
            ),
            if (creatingSheet) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (settings.selectedFolder != null && !creatingSheet) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('sheet_status'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: settings.sheetsId != null
                      ? AppColors.primaryContainer.withValues(alpha: 0.4)
                      : AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      settings.sheetsId != null
                          ? Icons.check_circle
                          : Icons.error_outline,
                      size: 18,
                      color: settings.sheetsId != null
                          ? AppColors.primary
                          : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      settings.sheetsId != null
                          ? 'Sheet ready'
                          : 'Sync failed',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            _PickerRow(
              icon: Icons.table_view,
              title: settings.selectedSheet?.name ?? 'Choose Sheet',
              subtitle: 'Select an existing spreadsheet',
              onTap: onPickSheet,
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchFormatCard extends StatelessWidget {
  final AppSettings settings;
  final List<String> featuredPresets;
  final ValueChanged<String> onApplyPreset;
  final VoidCallback onSwitchToCustom;
  final ValueChanged<MatchFormat> onUpdateCustomFormat;

  const _MatchFormatCard({
    required this.settings,
    required this.featuredPresets,
    required this.onApplyPreset,
    required this.onSwitchToCustom,
    required this.onUpdateCustomFormat,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.scoreboard_outlined,
      title: 'Match Format',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'USTA TOURNAMENT LEVEL',
              style: eyebrowStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          for (final id in featuredPresets) ...[
            _PresetTile(
              title: MatchFormat.presetLabels[id] ?? id,
              subtitle: MatchFormat.presetSubtitles[id] ?? '',
              selected: settings.formatPreset == id,
              onTap: () => onApplyPreset(id),
            ),
            const SizedBox(height: 8),
          ],
          _CustomConfigCard(
            isCustom: settings.formatPreset == 'custom',
            format: settings.format,
            onActivate: onSwitchToCustom,
            onChange: onUpdateCustomFormat,
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.3)
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomConfigCard extends StatelessWidget {
  final bool isCustom;
  final MatchFormat format;
  final VoidCallback onActivate;
  final ValueChanged<MatchFormat> onChange;

  const _CustomConfigCard({
    required this.isCustom,
    required this.format,
    required this.onActivate,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isCustom ? null : onActivate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCustom ? AppColors.primary : AppColors.outlineVariant,
              width: isCustom ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Configuration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isCustom) ...[
                const SizedBox(height: 2),
                Text(
                  'Tap to configure manually.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              if (isCustom) ...[
                const SizedBox(height: 16),
                _SegmentRow(
                  label: 'GAMES PER SET',
                  options: const ['4', '6', '8'],
                  selectedIdx: switch (format.setWinThreshold) {
                    4 => 0,
                    8 => 2,
                    _ => 1,
                  },
                  onChanged: (i) {
                    final val = [4, 6, 8][i];
                    onChange(format.copyWith(
                      setWinThreshold: val,
                      setTiebreakAt: val,
                    ));
                  },
                ),
                const SizedBox(height: 16),
                _SegmentRow(
                  label: 'SCORING TYPE',
                  options: const ['Ad', 'No-Ad'],
                  selectedIdx: format.scoringType == ScoringType.ad ? 0 : 1,
                  onChanged: (i) => onChange(format.copyWith(
                    scoringType: i == 0 ? ScoringType.ad : ScoringType.noAd,
                  )),
                ),
                const SizedBox(height: 16),
                _SegmentRow(
                  label: 'SET TIEBREAK TRIGGER',
                  options: const ['4-4', '6-6', '8-8'],
                  selectedIdx: switch (format.setTiebreakAt) {
                    4 => 0,
                    8 => 2,
                    _ => 1,
                  },
                  onChanged: (i) {
                    final val = [4, 6, 8][i];
                    onChange(format.copyWith(setTiebreakAt: val));
                  },
                ),
                const SizedBox(height: 16),
                _DecidingSetSelector(
                  format: format,
                  onChange: onChange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DecidingSetSelector extends StatelessWidget {
  final MatchFormat format;
  final ValueChanged<MatchFormat> onChange;

  const _DecidingSetSelector({
    required this.format,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DECIDING SET LOGIC', style: eyebrowStyle()),
        const SizedBox(height: 8),
        _DecidingOption(
          label: 'None (Single Set)',
          selected: format.matchFormatType == MatchFormatType.singleSet,
          onTap: () => onChange(format.copyWith(
            matchFormatType: MatchFormatType.singleSet,
          )),
        ),
        const SizedBox(height: 6),
        _DecidingOption(
          label: 'Full 3rd Set',
          selected: format.matchFormatType == MatchFormatType.bestOf3FullSet,
          onTap: () => onChange(format.copyWith(
            matchFormatType: MatchFormatType.bestOf3FullSet,
          )),
        ),
        const SizedBox(height: 6),
        _DecidingOption(
          label: '10-Point Match Tiebreak',
          selected: format.matchFormatType == MatchFormatType.bestOf3MatchTb,
          onTap: () => onChange(format.copyWith(
            matchFormatType: MatchFormatType.bestOf3MatchTb,
          )),
        ),
      ],
    );
  }
}

class _DecidingOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DecidingOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary
          : AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final int selectedIdx;
  final ValueChanged<int> onChanged;

  const _SegmentRow({
    required this.label,
    required this.options,
    required this.selectedIdx,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: eyebrowStyle()),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: List.generate(options.length, (i) {
              final sel = i == selectedIdx;
              return Expanded(
                child: Material(
                  color: sel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => onChanged(i),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          options[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: sel
                                ? AppColors.onPrimary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  final VoidCallback onShowLogs;

  const _SystemCard({required this.onShowLogs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      icon: Icons.info_outline,
      title: 'System',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                'v2.4.1',
                style: scoreDisplayStyle(
                  size: 14,
                  color: AppColors.onSurface,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onShowLogs,
              icon: const Icon(
                Icons.bug_report_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              label: Text(
                'View Debug Logs',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
