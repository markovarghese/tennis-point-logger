import 'dart:async';
import 'package:flutter/material.dart';
import '../models/match_settings.dart';
import '../theme.dart';

const _mockFolders = [
  DriveFolder(id: 'f1', name: 'Tennis'),
  DriveFolder(id: 'f2', name: 'Sports Data'),
  DriveFolder(id: 'f3', name: 'My Drive (root)'),
  DriveFolder(id: 'f4', name: 'Training 2026'),
];

const _mockSheets = [
  DriveSheet(id: 's1', name: 'TennisAnalysis.xlsx', modified: '2 May 2026'),
  DriveSheet(id: 's2', name: 'Match Log 2025', modified: '12 Jan 2026'),
  DriveSheet(id: 's3', name: 'Training Stats', modified: '30 Apr 2026'),
];

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
  Timer? _connectingTimer;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _nameCtrl = TextEditingController(text: _s.playerName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _connectingTimer?.cancel();
    super.dispose();
  }

  void _update(AppSettings updated) {
    setState(() => _s = updated);
    widget.onChanged(updated);
  }

  void _applyPreset(String id) {
    final fmt = MatchFormat.presets[id];
    if (fmt == null) return;
    _update(_s.copyWith(formatPreset: id, format: fmt));
  }

  void _connectGoogle() {
    _update(_s.copyWith(gsState: GsState.connecting));
    _connectingTimer?.cancel();
    _connectingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _update(_s.copyWith(
        gsState: GsState.connected,
        gsAccount: 'you@gmail.com',
      ));
    });
  }

  void _disconnectGoogle() {
    _connectingTimer?.cancel();
    _update(_s.copyWith(
      gsState: GsState.disconnected,
      clearGsAccount: true,
      clearSelectedFolder: true,
      clearSelectedSheet: true,
      clearSheetsId: true,
    ));
  }

  Future<void> _pickFolder() async {
    final result = await showModalBottomSheet<DriveFolder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PickerModal<DriveFolder>(
        title: 'Choose Folder',
        subtitle: 'Google Drive',
        items: _mockFolders,
        isFolder: true,
      ),
    );
    if (result != null) {
      _update(_s.copyWith(selectedFolder: result));
    }
  }

  Future<void> _pickSheet() async {
    final result = await showModalBottomSheet<DriveSheet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PickerModal<DriveSheet>(
        title: 'Choose Spreadsheet',
        subtitle: 'Google Drive',
        items: _mockSheets,
        isFolder: false,
      ),
    );
    if (result != null) {
      _update(_s.copyWith(
        selectedSheet: result,
        sheetsId: result.id,
      ));
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
            const _SectionTitle('Sync Behaviour'),
            _SyncRow(
              label: 'Auto-sync after each point',
              sub: 'Sends each row immediately on "Next Point"',
              value: _s.autoSyncAfterPoint,
              onChanged: (v) => _update(_s.copyWith(autoSyncAfterPoint: v)),
            ),
            _SyncRow(
              label: 'Sync on match end only',
              sub: 'Batch upload when you finish the match',
              value: _s.syncOnMatchEnd,
              onChanged: (v) => _update(_s.copyWith(syncOnMatchEnd: v)),
            ),
            _SyncRow(
              label: 'Keep offline copy',
              sub: 'Store all data locally even when synced',
              value: _s.keepOfflineCopy,
              onChanged: (v) => _update(_s.copyWith(keepOfflineCopy: v)),
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
              onChanged: (v) => _update(_s.copyWith(
                formatPreset: 'custom',
                format: _s.format.copyWith(setsInMatch: int.parse(v)),
              )),
            ),
          ),
          _FormatRow(
            label: 'Games per set',
            sub: 'Standard is 6',
            child: _SegPicker(
              options: const ['4', '6', '8'],
              value: '${_s.format.gamesPerSet}',
              onChanged: (v) => _update(_s.copyWith(
                formatPreset: 'custom',
                format: _s.format.copyWith(gamesPerSet: int.parse(v)),
              )),
            ),
          ),
          _FormatRow(
            label: 'Deuce scoring',
            child: _SegPicker(
              options: const ['Ad', 'No-Ad'],
              value: _s.format.adScoring ? 'Ad' : 'No-Ad',
              onChanged: (v) => _update(_s.copyWith(
                formatPreset: 'custom',
                format: _s.format.copyWith(adScoring: v == 'Ad'),
              )),
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
              onChanged: (v) => _update(_s.copyWith(
                formatPreset: 'custom',
                format: _s.format.copyWith(
                  tiebreakPoints: v == 'None' ? 0 : int.parse(v)),
              )),
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
              onChanged: (v) => _update(_s.copyWith(
                formatPreset: 'custom',
                format: _s.format.copyWith(
                  finalSet: switch (v) {
                    '6-pt TB' => FinalSetType.sixPointTb,
                    'Full' => FinalSetType.full,
                    _ => FinalSetType.tenPointTb,
                  },
                ),
              )),
            ),
          ),

          // About
          const _SectionTitle('About'),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 40),
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
    final year = DateTime.now().year;
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
          _buildCreateMode(year)
        else
          _buildExistingMode(),
      ],
    );
  }

  Widget _buildCreateMode(int year) {
    final folder = _s.selectedFolder;
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
                const TextSpan(text: 'Choose a Google Drive folder. The app will create a new spreadsheet named '),
                TextSpan(
                  text: 'TennisLogger_$year.xlsx',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const TextSpan(text: ' there.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PickerButton(
            icon: folder != null ? '📁' : '📂',
            title: folder?.name ?? 'Choose folder',
            sub: folder == null ? 'Tap to browse Google Drive' : null,
            highlighted: folder != null,
            onTap: _pickFolder,
          ),
          if (folder != null) ...[
            const SizedBox(height: 10),
            Container(
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
                        Text('TennisLogger_$year.xlsx',
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.onSecondaryContainer)),
                        Text('Will be created in ${folder.name}',
                          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVar)),
                      ],
                    ),
                  ),
                  const Text('✓ Ready',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFF34A853),
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
                TextSpan(text: 'Pick an existing Google Sheet. Data will be appended to the '),
                TextSpan(
                  text: 'logger',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                TextSpan(text: ' tab, columns A–I.'),
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
                        const Text('Appending to "logger" tab, cols A–I',
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
