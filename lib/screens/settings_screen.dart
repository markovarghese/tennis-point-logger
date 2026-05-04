import 'package:flutter/material.dart';
import '../models/match_settings.dart';
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

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _nameCtrl = TextEditingController(text: _s.playerName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
          _SectionTitle('Player'),
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

          // Match Format
          _SectionTitle('Match Format'),

          // Preset picker
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

          // Sync behaviour
          _SectionTitle('Sync Behaviour'),
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

          // About
          _SectionTitle('About'),
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
              ],
            ),
          ),
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
            activeColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.outline,
            inactiveTrackColor: AppColors.surfaceVariant,
          ),
        ],
      ),
    );
  }
}
