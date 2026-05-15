import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/match_settings.dart';
import '../services/app_log.dart';
import '../services/google_auth_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  const SettingsScreen({super.key, required this.settings, required this.onChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _s;
  bool _templateEditing = false;
  bool _creatingSheet = false;
  late TextEditingController _templateCtrl;
  String _lastPresetId = 'l7_standard_single';

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _templateCtrl = TextEditingController(text: _s.templateUrl);
    if (_s.formatPreset != 'custom') {
      _lastPresetId = _s.formatPreset;
    }
  }

  @override
  void dispose() {
    _templateCtrl.dispose();
    super.dispose();
  }

  String? _parseSheetId(String url) {
    final m = RegExp(r'spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    return m?.group(1);
  }

  ({String name, String shortId})? _templateInfo(String url) {
    final id = _parseSheetId(url);
    if (id == null) return null;
    final isDefault = id == _parseSheetId(AppSettings.defaultTemplateUrl);
    return (
      name: isDefault ? 'TennisAnalysis (default)' : 'Custom template',
      shortId: '${id.substring(0, id.length.clamp(0, 8))}…',
    );
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
    final result = await showModalBottomSheet<DriveFolder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerModal<DriveFolder>(
        title: 'Choose Folder',
        subtitle: 'Google Drive',
        items: folders,
        isFolder: true,
      ),
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
        templateId, result.id, 'TennisPointLogger_$ts',
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
    final result = await showModalBottomSheet<DriveSheet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerModal<DriveSheet>(
        title: 'Choose Spreadsheet',
        subtitle: 'Google Drive',
        items: driveSheets,
        isFolder: false,
      ),
    );
    if (result != null) {
      AppLog.info('settings: existing sheet → "${result.name}"');
      _update(_s.copyWith(selectedSheet: result, sheetsId: result.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CourtBackground(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure your tracker preferences and integrations.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Google Account
            const _SectionHeader(icon: Icons.account_circle, title: 'Google Account', color: AppColors.primary),
            _buildGoogleAccountSection(key: const Key('google_connected')),

            // Google Sheets Integration
            if (_s.gsState == GsState.connected) ...[
              const _SectionHeader(icon: Icons.table_chart, title: 'Google Sheets', color: AppColors.primary),
              _buildSheetsIntegrationSection(),
            ],

            // Match Format
            const _SectionHeader(icon: Icons.scoreboard, title: 'Match Format', color: Color(0xFFA23F00)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                   GlassPanel(
                    borderRadius: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'USTA TOURNAMENT LEVEL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...MatchFormat.presets.keys.map((id) => _PresetCard(
                          title: MatchFormat.presetLabels[id] ?? id,
                          subtitle: MatchFormat.presetSubtitles[id] ?? '',
                          selected: _s.formatPreset == id,
                          onTap: () => _applyPreset(id),
                        )),
                        _PresetCard(
                          title: 'Custom',
                          subtitle: '',
                          selected: _s.formatPreset == 'custom',
                          onTap: _switchToCustom,
                        ),
                        
                        if (_s.formatPreset == 'custom') ...[
                          const Divider(height: 32),
                          _MatchParamRow(
                            label: 'Sets to Win',
                            value: '${_s.format.setsToWin}',
                            onAdd: () => _updateCustomFormat(_s.format.matchFormatType == MatchFormatType.singleSet 
                                ? _s.format.copyWith(matchFormatType: MatchFormatType.bestOf3MatchTb)
                                : _s.format),
                            onRemove: () => _updateCustomFormat(_s.format.matchFormatType != MatchFormatType.singleSet
                                ? _s.format.copyWith(matchFormatType: MatchFormatType.singleSet)
                                : _s.format),
                          ),
                          const SizedBox(height: 16),
                          _MatchParamRow(
                            label: 'Games per Set',
                            value: '${_s.format.setWinThreshold}',
                            onAdd: () => _updateCustomFormat(_s.format.copyWith(setWinThreshold: _s.format.setWinThreshold + 1, setTiebreakAt: _s.format.setTiebreakAt + 1)),
                            onRemove: () => _updateCustomFormat(_s.format.copyWith(setWinThreshold: _s.format.setWinThreshold - 1, setTiebreakAt: _s.format.setTiebreakAt - 1)),
                          ),
                          const SizedBox(height: 16),
                          _SegmentedRow(
                            label: 'Deuce Scoring',
                            options: const ['Ad', 'No-Ad'],
                            selectedIdx: _s.format.scoringType == ScoringType.ad ? 0 : 1,
                            onChanged: (idx) => _updateCustomFormat(_s.format.copyWith(scoringType: idx == 0 ? ScoringType.ad : ScoringType.noAd)),
                          ),
                          const SizedBox(height: 16),
                          _SegmentedRow(
                            label: 'Set Tie-breaker',
                            options: const ['Tie-breaker', 'Win by 2'],
                            selectedIdx: _s.format.tiebreakWinType == TiebreakWinType.twoPointMargin ? 0 : 1,
                            onChanged: (idx) => _updateCustomFormat(_s.format.copyWith(tiebreakWinType: idx == 0 ? TiebreakWinType.twoPointMargin : TiebreakWinType.suddenDeath)),
                          ),
                          const SizedBox(height: 16),
                          _SegmentedRow(
                            label: 'Match Tie-breaker (Final Set)',
                            options: const ['Match TB', 'Standard', 'Win by 2'],
                            selectedIdx: _s.format.matchFormatType == MatchFormatType.bestOf3MatchTb ? 0 : (_s.format.matchFormatType == MatchFormatType.bestOf3FullSet ? 1 : 2),
                            onChanged: (idx) => _updateCustomFormat(_s.format.copyWith(matchFormatType: idx == 0 ? MatchFormatType.bestOf3MatchTb : (idx == 1 ? MatchFormatType.bestOf3FullSet : MatchFormatType.singleSet))),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // System
            const _SectionHeader(icon: Icons.info, title: 'System', color: AppColors.outline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: GlassPanel(
                borderRadius: 12,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Version',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
                        ),
                        Text(
                          'v2.4.1',
                          style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogSheet(context),
                        icon: const Icon(Icons.bug_report, size: 18),
                        label: const Text('VIEW DEBUG LOGS'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          side: const BorderSide(color: AppColors.outline, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _updateCustomFormat(MatchFormat fmt) {
    _update(_s.copyWith(formatPreset: 'custom', format: fmt));
  }

  Widget _buildGoogleAccountSection({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassPanel(
        borderRadius: 12,
        child: Column(
          children: [
            if (_s.gsState == GsState.connected) ...[
              Row(
                children: [
                  const Icon(Icons.cloud_done, color: Color(0xFF34A853)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status: Connected',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                        Text(
                          _s.gsAccount ?? '',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _disconnectGoogle,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ] else if (_s.gsState == GsState.connecting) ...[
              const Center(child: CircularProgressIndicator())
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.cloud_off, color: AppColors.outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: Not Signed In',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                        Text(
                          'Sign in to enable cloud sync',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('sign_in_button'),
                  onPressed: _connectGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('SIGN IN WITH GOOGLE', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSheetsIntegrationSection() {
    final mode = _s.sheetMode;
    final folder = _s.selectedFolder;
    final sheet = _s.selectedSheet;
    final info = _templateInfo(_s.templateUrl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassPanel(
        borderRadius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode toggle
            Row(
              children: [
                for (final entry in const [
                  MapEntry(SheetMode.create, 'Create New'),
                  MapEntry(SheetMode.existing, 'Use Existing'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: mode == entry.key,
                        onSelected: (val) => _update(_s.copyWith(sheetMode: entry.key)),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: mode == entry.key ? Colors.white : AppColors.onSurface,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (mode == SheetMode.create) ...[
              _PickerRow(
                key: const Key('folder_picker'),
                icon: Icons.folder_open,
                title: folder?.name ?? 'Choose Folder',
                subtitle: 'Where to create match sheets',
                onTap: _pickFolder,
              ),
              if (_creatingSheet) const LinearProgressIndicator(),
              if (folder != null && !_creatingSheet)
                Container(
                  key: const Key('sheet_status'),
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF34A853), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _s.sheetsId != null ? '✓ Ready' : '⚠ Sync Failed',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              _PickerRow(
                icon: Icons.table_view,
                title: sheet?.name ?? 'Choose Sheet',
                subtitle: 'Select an existing spreadsheet',
                onTap: _pickSheet,
              ),
            ],
            const Divider(height: 32),
            const Text(
              'TEMPLATE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    info?.name ?? 'Default Template',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: Icon(_templateEditing ? Icons.check : Icons.edit, size: 18),
                  onPressed: () {
                    if (_templateEditing) {
                      _update(_s.copyWith(templateUrl: _templateCtrl.text));
                    }
                    setState(() => _templateEditing = !_templateEditing);
                  },
                ),
              ],
            ),
            if (_templateEditing)
              TextField(
                controller: _templateCtrl,
                decoration: const InputDecoration(hintText: 'Paste Sheets URL'),
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final int selectedIdx;
  final ValueChanged<int> onChanged;

  const _SegmentedRow({
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(options.length, (i) {
              final sel = i == selectedIdx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      options[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppColors.onSurfaceVariant,
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

class _MatchParamRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MatchParamRow({required this.label, required this.value, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurface),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(onPressed: onRemove, icon: const Icon(Icons.remove, size: 18)),
              Container(
                width: 40,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border.symmetric(vertical: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
                ),
                child: Text(
                  value,
                  style: scoreTextStyle.copyWith(fontSize: 16),
                ),
              ),
              IconButton(onPressed: onAdd, icon: const Icon(Icons.add, size: 18)),
            ],
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

  const _PickerRow({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
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

void _showLogSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LogSheet(),
  );
}

class _LogSheet extends StatelessWidget {
  const _LogSheet();

  @override
  Widget build(BuildContext context) {
    final entries = AppLog.entries;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  const Text('Debug Log', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  )),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: AppLog.formatted()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Log copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copy all'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineVariant),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text('No log entries yet.',
                        style: TextStyle(color: AppColors.onSurfaceVariant)),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[entries.length - 1 - i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.timeStr, style: const TextStyle(
                                fontSize: 11, fontFamily: 'monospace',
                                color: AppColors.onSurfaceVariant,
                              )),
                              const SizedBox(width: 8),
                              Container(
                                width: 6, height: 6,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: e.isError ? Colors.red : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(e.message, style: const TextStyle(
                                  fontSize: 12, fontFamily: 'monospace',
                                  color: AppColors.onSurface, height: 1.4,
                                )),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerModal<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<T> items;
  final bool isFolder;

  const _PickerModal({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.isFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.onSurface)),
                Text(subtitle, style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Text(
                        'No items found.',
                        style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ...items.map((item) {
                    final folder = item is DriveFolder ? item : null;
                    final sheet = item is DriveSheet ? item : null;
                    final name = folder?.name ?? sheet?.name ?? '';
                    final modified = sheet?.modified;
                    return InkWell(
                      onTap: () => Navigator.pop(context, item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Text(isFolder ? '📁' : '📊',
                              style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                    style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface)),
                                  if (modified != null)
                                    Text('Modified $modified',
                                      style: const TextStyle(
                                        fontSize: 11, color: AppColors.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            const Text('›', style: TextStyle(fontSize: 18, color: AppColors.outline)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.onSurface,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Cancel',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
