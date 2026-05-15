import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return GlassPanel(
      borderRadius: 28,
      opacity: 0.9,
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SCORE OVERRIDE',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 32),
          _StepperRow(
            label: 'MY SETS',
            value: mySets,
            onChanged: (v) => setState(() => mySets = v.clamp(0, 5)),
          ),
          const SizedBox(height: 16),
          _StepperRow(
            label: 'OPP SETS',
            value: oppSets,
            onChanged: (v) => setState(() => oppSets = v.clamp(0, 5)),
          ),
          const Divider(height: 32, color: Colors.white24),
          _StepperRow(
            label: 'MY GAMES',
            value: myGames,
            onChanged: (v) => setState(() => myGames = v.clamp(0, 12)),
          ),
          const SizedBox(height: 16),
          _StepperRow(
            label: 'OPP GAMES',
            value: oppGames,
            onChanged: (v) => setState(() => oppGames = v.clamp(0, 12)),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                ScoreOverride(
                  mySets: mySets, oppSets: oppSets,
                  myGames: myGames, oppGames: oppGames,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('APPLY OVERRIDE', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
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

  const _StepperRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
        ),
        Container(
          width: 48,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: scoreTextStyle.copyWith(fontSize: 24, color: Colors.white),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        ),
      ],
    );
  }
}
