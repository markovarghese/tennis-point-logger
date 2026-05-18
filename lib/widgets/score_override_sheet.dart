import 'package:flutter/material.dart';
import '../models/score_state.dart';
import '../models/match_settings.dart';
import '../theme.dart';
import 'sheet_header.dart';

class ScoreOverride {
  final int mySets, oppSets, myGames, oppGames, myPts, oppPts;
  const ScoreOverride({
    required this.mySets,
    required this.oppSets,
    required this.myGames,
    required this.oppGames,
    this.myPts = 0,
    this.oppPts = 0,
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
  late int mySets, oppSets, myGames, oppGames, myPts, oppPts;

  @override
  void initState() {
    super.initState();
    mySets = widget.current.mySets;
    oppSets = widget.current.oppSets;
    myGames = widget.current.myGames;
    oppGames = widget.current.oppGames;
    myPts = widget.current.myPts;
    oppPts = widget.current.oppPts;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom + media.padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(
            title: 'Score Override',
            showCloseButton: true,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  _StepperRow(
                    label: 'My Sets',
                    value: mySets,
                    onChanged: (v) => setState(() => mySets = v.clamp(0, 5)),
                  ),
                  const SizedBox(height: 8),
                  _StepperRow(
                    label: 'Opponent Sets',
                    value: oppSets,
                    onChanged: (v) => setState(() => oppSets = v.clamp(0, 5)),
                  ),
                  const SizedBox(height: 8),
                  _StepperRow(
                    label: 'My Games',
                    value: myGames,
                    onChanged: (v) => setState(() => myGames = v.clamp(0, 12)),
                  ),
                  const SizedBox(height: 8),
                  _StepperRow(
                    label: 'Opponent Games',
                    value: oppGames,
                    onChanged: (v) => setState(() => oppGames = v.clamp(0, 12)),
                  ),
                  const SizedBox(height: 8),
                  _StepperRow(
                    label: 'My Points',
                    value: myPts,
                    onChanged: (v) => setState(() => myPts = v.clamp(0, 30)),
                  ),
                  const SizedBox(height: 8),
                  _StepperRow(
                    label: 'Opponent Points',
                    value: oppPts,
                    onChanged: (v) => setState(() => oppPts = v.clamp(0, 30)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  ScoreOverride(
                    mySets: mySets,
                    oppSets: oppSets,
                    myGames: myGames,
                    oppGames: oppGames,
                    myPts: myPts,
                    oppPts: oppPts,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  minimumSize: const Size(0, 56),
                ),
                child: const Text(
                  'Apply Score Override',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
          ),
          _CircleIconButton(
            icon: Icons.remove,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 48,
            child: Center(
              child: Text(
                '$value',
                style: scoreDisplayStyle(
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          _CircleIconButton(
            icon: Icons.add,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: AppColors.onSurface),
        ),
      ),
    );
  }
}
