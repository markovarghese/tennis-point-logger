import 'package:flutter/material.dart';
import '../services/score_engine.dart';
import '../models/match_settings.dart';
import '../theme.dart';

class ScoreOverride {
  final int mySets, oppSets, myGames, oppGames;
  const ScoreOverride({
    required this.mySets, required this.oppSets,
    required this.myGames, required this.oppGames,
  });
}

Future<ScoreOverride?> showScoreOverrideSheet(
  BuildContext context,
  MatchFormat fmt,
  ScoreState current,
) {
  return showModalBottomSheet<ScoreOverride>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScoreOverrideSheet(fmt: fmt, current: current),
  );
}

class _ScoreOverrideSheet extends StatefulWidget {
  final MatchFormat fmt;
  final ScoreState current;
  const _ScoreOverrideSheet({required this.fmt, required this.current});

  @override
  State<_ScoreOverrideSheet> createState() => _ScoreOverrideSheetState();
}

class _ScoreOverrideSheetState extends State<_ScoreOverrideSheet> {
  late int mySets, oppSets, myGames, oppGames;

  @override
  void initState() {
    super.initState();
    mySets = widget.current.mySets;
    oppSets = widget.current.oppSets;
    myGames = widget.current.myGames;
    oppGames = widget.current.oppGames;
  }

  @override
  Widget build(BuildContext context) {
    final setsToWin = widget.fmt.setsToWin;
    final setOptions = List.generate(setsToWin, (i) => i);
    final gameOptions = List.generate(widget.fmt.gamesPerSet + 1, (i) => i);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set Current Score',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.onSurface)),
                      SizedBox(height: 2),
                      Text('Tap a number to select it, then hit Apply',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVar)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.onSurfaceVar,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _PickerRow(
                  leftLabel: 'My Sets', leftValue: mySets,
                  rightLabel: 'Opp Sets', rightValue: oppSets,
                  options: setOptions,
                  onLeft: (v) => setState(() => mySets = v),
                  onRight: (v) => setState(() => oppSets = v),
                ),
                const SizedBox(height: 8),
                _PickerRow(
                  leftLabel: 'My Games', leftValue: myGames,
                  rightLabel: 'Opp Games', rightValue: oppGames,
                  options: gameOptions,
                  onLeft: (v) => setState(() => myGames = v),
                  onRight: (v) => setState(() => oppGames = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "New points will be appended — override doesn't delete history.",
              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVar),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  ScoreOverride(
                    mySets: mySets, oppSets: oppSets,
                    myGames: myGames, oppGames: oppGames,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Apply Score Override',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String leftLabel, rightLabel;
  final int leftValue, rightValue;
  final List<int> options;
  final ValueChanged<int> onLeft, onRight;

  const _PickerRow({
    required this.leftLabel, required this.leftValue,
    required this.rightLabel, required this.rightValue,
    required this.options, required this.onLeft, required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(child: _NumPicker(label: leftLabel, value: leftValue,
            options: options, onChange: onLeft)),
          Container(width: 1, height: 60, color: AppColors.outlineVariant,
            margin: const EdgeInsets.symmetric(horizontal: 8)),
          Expanded(child: _NumPicker(label: rightLabel, value: rightValue,
            options: options, onChange: onRight)),
        ],
      ),
    );
  }
}

class _NumPicker extends StatelessWidget {
  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChange;

  const _NumPicker({
    required this.label, required this.value,
    required this.options, required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVar, letterSpacing: 0.5,
            )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('$value', style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary,
              )),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
          children: options.map((o) {
            final sel = value == o;
            return GestureDetector(
              onTap: () => onChange(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: sel ? [BoxShadow(
                    color: AppColors.primaryContainer,
                    blurRadius: 0, spreadRadius: 3,
                  )] : null,
                ),
                alignment: Alignment.center,
                child: Text('$o', style: TextStyle(
                  fontSize: 15,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  color: sel ? AppColors.onPrimary : AppColors.onSurface,
                )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
