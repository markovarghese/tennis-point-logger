import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _nameCtrl;
  bool _templateEditing = false;
  bool _creatingSheet = false;
  late TextEditingController _templateCtrl;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _nameCtrl = TextEditingController(text: _s.playerName);
    _templateCtrl = TextEditingController(text: _s.templateUrl);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _templateCtrl.dispose();
    super.dispose();
  }

  // Returns the spreadsheet ID extracted from a Google Sheets URL, or null.
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
    _update(_s.copyWith(formatPreset: id, format: fmt));
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

    // Clear any previously-created sheet so the UI resets to "creating".
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TENNIS LOGGER', style: TextStyle(
                  fontSize: 11, color: Color(0xB3FFFFFF),
                  fontWeight: FontWeight.w600, letterSpacing: 1,
                )),
                SizedBox(height: 4),
                Text('Settings', style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white,
                )),
              ],
            ),
          ),

          // Player
          const _SectionTitle('Player'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your name (used in "My Serve?" column)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVar)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(fontSize: 15, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onChanged: (v) => _update(_s.copyWith(playerName: v)),
                  onEditingComplete: () {
                    AppLog.info('settings: playerName → "${_nameCtrl.text}"');
                    FocusScope.of(context).unfocus();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),

          // Google Account
          const _SectionTitle('Google Account'),
          _buildGoogleAccountSection(),

          // Google Sheets Destination + Sync Behaviour (only when connected)
          if (_s.gsState == GsState.connected) ...[
            const _SectionTitle('Google Sheets Destination'),
            _buildSheetsDestinationSection(),
            const _SectionTitle('Sheet Template'),
            _buildSheetTemplateSection(),
            const _SectionTitle('Sync Behaviour'),
            _SyncRow(
              label: 'Auto-sync after each point',
              sub: 'Sends each row immediately on "Next Point"',
              value: _s.autoSyncAfterPoint,
              onChanged: (v) {
                AppLog.info('settings: autoSyncAfterPoint → $v');
                _update(_s.copyWith(autoSyncAfterPoint: v));
              },
            ),
            _SyncRow(
              label: 'Sync on match end only',
              sub: 'Batch upload when you finish the match',
              value: _s.syncOnMatchEnd,
              onChanged: (v) {
                AppLog.info('settings: syncOnMatchEnd → $v');
                _update(_s.copyWith(syncOnMatchEnd: v));
              },
            ),
            _SyncRow(
              label: 'Keep offline copy',
              sub: 'Store all data locally even when synced',
              value: _s.keepOfflineCopy,
              onChanged: (v) {
                AppLog.info('settings: keepOfflineCopy → $v');
                _update(_s.copyWith(keepOfflineCopy: v));
              },
            ),
          ],

          // Match Format
          const _SectionTitle('Match Format'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('USTA Junior Presets',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVar)),
                const SizedBox(height: 10),
                ...['l7_short', 'l7_regular', 'l6', 'l5', 'custom'].map((id) {
                  final selected = (_s.formatPreset) == id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: id == 'custom' ? null : () => _applyPreset(id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryContainer.withAlpha(85)
                              : AppColors.surface,
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.outlineVariant,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? AppColors.primary : AppColors.outline,
                                  width: 2,
                                ),
                                color: selected ? AppColors.primary : Colors.transparent,
                              ),
                              child: selected
                                  ? const Center(child: CircleAvatar(
                                      radius: 4, backgroundColor: Colors.white))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(MatchFormat.presetLabels[id] ?? id,
                                    style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface)),
                                  Text(MatchFormat.presetSubtitles[id] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12, color: AppColors.onSurfaceVar)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if ((MatchFormat.presetNotes[_s.formatPreset] ?? '').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ℹ️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          MatchFormat.presetNotes[_s.formatPreset] ?? '',
                          style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurface, height: 1.5),
                        )),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Custom format controls
          const Divider(height: 1, color: AppColors.outlineVariant),
          _FormatRow(
            label: 'Sets in a match',
            sub: 'Best of…',
            child: _SegPicker(
              options: const ['1', '2', '3', '5'],
              value: '${_s.format.setsInMatch}',
              onChanged: (v) {
                AppLog.info('settings: setsInMatch → $v');
                _update(_s.copyWith(
                  formatPreset: 'custom',
                  format: _s.format.copyWith(setsInMatch: int.parse(v)),
                ));
              },
            ),
          ),
          _FormatRow(
            label: 'Games per set',
            sub: 'Standard is 6',
            child: _SegPicker(
              options: const ['4', '6', '8'],
              value: '${_s.format.gamesPerSet}',
              onChanged: (v) {
                AppLog.info('settings: gamesPerSet → $v');
                _update(_s.copyWith(
                  formatPreset: 'custom',
                  format: _s.format.copyWith(gamesPerSet: int.parse(v)),
                ));
              },
            ),
          ),
          _FormatRow(
            label: 'Deuce scoring',
            child: _SegPicker(
              options: const ['Ad', 'No-Ad'],
              value: _s.format.adScoring ? 'Ad' : 'No-Ad',
              onChanged: (v) {
                AppLog.info('settings: adScoring → $v');
                _update(_s.copyWith(
                  formatPreset: 'custom',
                  format: _s.format.copyWith(adScoring: v == 'Ad'),
                ));
              },
            ),
          ),
          _FormatRow(
            label: 'Tiebreak points',
            sub: 'At 6-6 (or last set)',
            child: _SegPicker(
              options: const ['7', '10', 'None'],
              value: _s.format.tiebreakPoints == 0
                  ? 'None'
                  : '${_s.format.tiebreakPoints}',
              onChanged: (v) {
                AppLog.info('settings: tiebreakPoints → $v');
                _update(_s.copyWith(
                  formatPreset: 'custom',
                  format: _s.format.copyWith(
                    tiebreakPoints: v == 'None' ? 0 : int.parse(v)),
                ));
              },
            ),
          ),
          _FormatRow(
            label: 'Final set',
            sub: 'How is the last set decided?',
            child: _SegPicker(
              options: const ['Full', '10-pt TB', '6-pt TB'],
              value: switch (_s.format.finalSet) {
                FinalSetType.full => 'Full',
                FinalSetType.tenPointTb => '10-pt TB',
                FinalSetType.sixPointTb => '6-pt TB',
              },
              onChanged: (v) {
                AppLog.info('settings: finalSet → $v');
                _update(_s.copyWith(
                  formatPreset: 'custom',
                  format: _s.format.copyWith(
                    finalSet: switch (v) {
                      '6-pt TB' => FinalSetType.sixPointTb,
                      'Full' => FinalSetType.full,
                      _ => FinalSetType.tenPointTb,
                    },
                  ),
                ));
              },
            ),
          ),

          // About
          const _SectionTitle('About'),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tennis Logger v1.0.0',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVar)),
                SizedBox(height: 4),
                Text('Built with Flutter',
                  style: TextStyle(fontSize: 12, color: AppColors.outline)),
                SizedBox(height: 2),
                Text('Material Design 3 (Material You)',
                  style: TextStyle(fontSize: 12, color: AppColors.outline)),
                SizedBox(height: 2),
                Text('Google Sheets API v4',
                  style: TextStyle(fontSize: 12, color: AppColors.outline)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: OutlinedButton.icon(
              onPressed: () => _showLogSheet(context),
              icon: const Icon(Icons.list_alt_outlined, size: 18),
              label: const Text('View debug log'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVar,
                side: const BorderSide(color: AppColors.outlineVariant),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetTemplateSection() {
    final info = _templateInfo(_s.templateUrl);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When you create a new sheet, the app copies this template, then clears the '
            'LoggerData table while preserving any formulae — keeping the Logger tab structure, pivot tables and charts intact.',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVar, height: 1.5),
          ),
          const SizedBox(height: 12),

          if (!_templateEditing && info != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.onSurface)),
                        Text('id: ${info.shortId}',
                          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVar,
                            fontFamily: 'monospace')),
                        const SizedBox(height: 8),
                        const Wrap(
                          spacing: 6,
                          children: [
                            _Pill('Logger tab ✓'),
                            _Pill('LoggerData ✓'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _templateCtrl.text = _s.templateUrl;
                      _templateEditing = true;
                    }),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 32),
                      shape: const StadiumBorder(),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Change',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],

          if (!_templateEditing && info == null) ...[
            GestureDetector(
              onTap: () => setState(() {
                _templateCtrl.text = '';
                _templateEditing = true;
              }),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant, width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Row(
                  children: [
                    Text('📋', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Set template sheet',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVar)),
                          Text('Paste a Google Sheets URL',
                            style: TextStyle(fontSize: 12, color: AppColors.outline)),
                        ],
                      ),
                    ),
                    Text('›', style: TextStyle(fontSize: 18, color: AppColors.outline)),
                  ],
                ),
              ),
            ),
          ],

          if (_templateEditing) ...[
            const Text('Google Sheets URL',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVar)),
            const SizedBox(height: 6),
            TextField(
              controller: _templateCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 15, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'https://docs.google.com/spreadsheets/d/…',
                hintStyle: const TextStyle(color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'The template must contain a Logger tab with a LoggerData table (cols A–I). '
                'Pivot tables, charts and formulas in cols J–O are preserved on copy.',
                style: TextStyle(fontSize: 11, color: AppColors.onSurface, height: 1.5),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _templateEditing = false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.outlineVariant),
                      foregroundColor: AppColors.onSurface,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      AppLog.info('settings: template URL reset to default');
                      _templateCtrl.text = AppSettings.defaultTemplateUrl;
                      _update(_s.copyWith(templateUrl: AppSettings.defaultTemplateUrl));
                      setState(() => _templateEditing = false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.outlineVariant),
                      foregroundColor: AppColors.onSurfaceVar,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _parseSheetId(_templateCtrl.text) != null
                        ? () {
                            AppLog.info('settings: template URL saved');
                            _update(_s.copyWith(templateUrl: _templateCtrl.text));
                            setState(() => _templateEditing = false);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.outlineVariant,
                      foregroundColor: AppColors.onPrimary,
                      disabledForegroundColor: AppColors.onSurfaceVar,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoogleAccountSection() {
    switch (_s.gsState) {
      case GsState.disconnected:
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect your Google account to sync match data directly to Google Sheets.',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVar, height: 1.5),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  key: const Key('sign_in_button'),
                  onPressed: _connectGoogle,
                  icon: const _GoogleLogo(size: 20),
                  label: const Text('Sign in with Google',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        );

      case GsState.connecting:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
          ),
          child: const Column(
            children: [
              SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              SizedBox(height: 12),
              Text('Opening Google sign-in…',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVar)),
            ],
          ),
        );

      case GsState.connected:
        final email = _s.gsAccount ?? '';
        final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
        return Container(
          key: const Key('google_connected'),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                    ),
                    alignment: Alignment.center,
                    child: Text(initial,
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Google connected',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.onSurface)),
                        Text(email,
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVar)),
                      ],
                    ),
                  ),
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF34A853),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: _disconnectGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: const StadiumBorder(),
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Disconnect account',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSheetsDestinationSection() {
    final mode = _s.sheetMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode toggle
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
          ),
          child: Row(
            children: [
              for (final entry in const [
                MapEntry(SheetMode.create, 'Create new sheet'),
                MapEntry(SheetMode.existing, 'Use existing sheet'),
              ])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: entry.key == SheetMode.create ? 0 : 4,
                      right: entry.key == SheetMode.create ? 4 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => _update(_s.copyWith(sheetMode: entry.key)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: mode == entry.key
                              ? AppColors.primaryContainer
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(entry.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: mode == entry.key
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: mode == entry.key
                                ? AppColors.onPrimaryContainer
                                : AppColors.onSurfaceVar,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Mode-specific body
        if (mode == SheetMode.create)
          _buildCreateMode()
        else
          _buildExistingMode(),
      ],
    );
  }

  Widget _buildCreateMode() {
    final folder = _s.selectedFolder;
    final ts = DateFormat('yyyyMMddHHmm').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVar, height: 1.5),
              children: [
                const TextSpan(text: 'Pick a Drive folder. The app will '),
                const TextSpan(
                  text: 'copy your template sheet',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                TextSpan(text: ' there as TennisPointLogger_$ts, then clear the '),
                const TextSpan(
                  text: 'LoggerData',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const TextSpan(text: ' table so you start fresh — pivot tables, charts and formulas in the '),
                const TextSpan(
                  text: 'Logger',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const TextSpan(text: ' tab are preserved.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PickerButton(
            key: const Key('folder_picker'),
            icon: folder != null ? '📁' : '📂',
            title: folder?.name ?? 'Choose folder',
            sub: folder == null ? 'Tap to browse Google Drive' : null,
            highlighted: folder != null,
            onTap: _pickFolder,
          ),
          if (folder != null) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('sheet_status'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TennisPointLogger_$ts',
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.onSecondaryContainer)),
                        Text(
                          _creatingSheet
                              ? 'Copying template to ${folder.name}…'
                              : _s.sheetsId != null
                                  ? 'Copy of template → ${folder.name}, LoggerData ready'
                                  : 'Tap folder above to retry',
                          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVar)),
                      ],
                    ),
                  ),
                  if (_creatingSheet)
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_s.sheetsId != null)
                    const Text('✓ Ready',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF34A853),
                      ))
                  else
                    const Text('⚠ Failed',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExistingMode() {
    final sheet = _s.selectedSheet;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVar, height: 1.5),
              children: [
                TextSpan(text: 'Pick an existing Google Sheet. Rows are appended to the '),
                TextSpan(
                  text: 'LoggerData',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                TextSpan(text: ' table on the '),
                TextSpan(
                  text: 'Logger',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                TextSpan(text: ' tab — make sure the sheet has both, or copy from your template first.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PickerButton(
            icon: sheet != null ? '📊' : '🔍',
            title: sheet?.name ?? 'Browse sheets',
            sub: sheet != null
                ? 'Last modified ${sheet.modified}'
                : 'Tap to choose from Google Drive',
            subStyleVariant: sheet != null,
            highlighted: sheet != null,
            onTap: _pickSheet,
          ),
          if (sheet != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connected to ${sheet.name}',
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.onSecondaryContainer)),
                        const Text('Appending to LoggerData table on Logger tab',
                          style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVar)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
                        style: TextStyle(color: AppColors.onSurfaceVar)),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        // Show newest first
                        final e = entries[entries.length - 1 - i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.timeStr, style: const TextStyle(
                                fontSize: 11, fontFamily: 'monospace',
                                color: AppColors.onSurfaceVar,
                              )),
                              const SizedBox(width: 8),
                              Container(
                                width: 6, height: 6,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: e.isError
                                      ? Colors.red
                                      : AppColors.primary,
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVar, letterSpacing: 1,
        ),
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  final String label;
  final String? sub;
  final Widget child;

  const _FormatRow({required this.label, this.sub, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                  fontSize: 14, color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                if (sub != null)
                  Text(sub!, style: const TextStyle(
                    fontSize: 11, color: AppColors.onSurfaceVar, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          child,
        ],
      ),
    );
  }
}

class _SegPicker extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _SegPicker({required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final sel = value == opt;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              constraints: const BoxConstraints(minWidth: 44),
              decoration: BoxDecoration(
                color: sel ? AppColors.primaryContainer : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Text(opt, style: TextStyle(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                color: sel ? AppColors.onPrimaryContainer : AppColors.onSurfaceVar,
              )),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SyncRow extends StatelessWidget {
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SyncRow({
    required this.label, required this.sub,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                  fontSize: 14, color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVar)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.outline,
            inactiveTrackColor: AppColors.surfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final String icon;
  final String title;
  final String? sub;
  final bool subStyleVariant;
  final bool highlighted;
  final VoidCallback onTap;

  const _PickerButton({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
    this.subStyleVariant = false,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.primaryContainer.withAlpha(68)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted ? AppColors.primary : AppColors.outlineVariant,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: highlighted
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVar,
                    )),
                  if (sub != null)
                    Text(sub!,
                      style: TextStyle(
                        fontSize: 12,
                        color: subStyleVariant
                            ? AppColors.onSurfaceVar
                            : AppColors.outline,
                      )),
                ],
              ),
            ),
            const Text('›', style: TextStyle(fontSize: 18, color: AppColors.outline)),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    // Simple G-circle stand-in (matches design's branded button look)
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle, color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size * 0.7,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text,
        style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: AppColors.onPrimaryContainer, letterSpacing: 0.3,
        )),
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
                  fontSize: 12, color: AppColors.onSurfaceVar)),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Text(
                        isFolder
                            ? 'No folders found in Google Drive.'
                            : 'No spreadsheets found in Google Drive.',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.onSurfaceVar),
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
                                        fontSize: 11, color: AppColors.onSurfaceVar)),
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
