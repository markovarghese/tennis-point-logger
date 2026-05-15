import 'package:flutter/material.dart';
import '../services/score_engine.dart';
import '../theme.dart';

class ScoreBanner extends StatelessWidget {
  final ScoreState score;
  final String opponentName;
  final VoidCallback? onTap;

  const ScoreBanner({
    super.key,
    required this.score,
    required this.opponentName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassPanel(
          borderRadius: 12,
          padding: const EdgeInsets.all(12),
          opacity: 0.8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Player 1 (Me)
              _PlayerScore(
                label: 'Player',
                points: score.matchOver ? (score.mySets >= score.setsToWin ? 'WIN' : 'LOSS') : score.ptScore.split('-')[0],
                sets: score.mySets,
                games: score.myGames,
                color: AppColors.primary,
              ),

              // VS / Status
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (score.isTiebreak)
                    const Text(
                      'TIEBREAK',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.outline,
                        letterSpacing: 1,
                      ),
                    ),
                  Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  if (onTap != null)
                    const Text(
                      'EDIT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.outline,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),

              // Player 2 (Opponent)
              _PlayerScore(
                label: opponentName.isEmpty ? 'Opponent' : opponentName,
                points: score.matchOver ? (score.oppSets >= score.setsToWin ? 'WIN' : 'LOSS') : score.ptScore.split('-')[1],
                sets: score.oppSets,
                games: score.oppGames,
                color: AppColors.secondaryContainer,
                isRight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final String label;
  final String points;
  final int sets;
  final int games;
  final Color color;
  final bool isRight;

  const _PlayerScore({
    required this.label,
    required this.points,
    required this.sets,
    required this.games,
    required this.color,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (isRight) ...[
              _SubScore(label: 'S', value: sets),
              const SizedBox(width: 4),
              _SubScore(label: 'G', value: games),
              const SizedBox(width: 12),
            ],
            Text(
              points,
              style: scoreTextStyle.copyWith(
                fontSize: 36,
                color: color,
              ),
            ),
            if (!isRight) ...[
              const SizedBox(width: 12),
              _SubScore(label: 'S', value: sets),
              const SizedBox(width: 4),
              _SubScore(label: 'G', value: games),
            ],
          ],
        ),
      ],
    );
  }
}

class _SubScore extends StatelessWidget {
  final String label;
  final int value;

  const _SubScore({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.outlineVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:$value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
