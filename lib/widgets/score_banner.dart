import 'package:flutter/material.dart';
import '../services/score_engine.dart';
import '../theme.dart';

class ScoreBanner extends StatelessWidget {
  final ScoreState score;
  final String opponentName;
  final VoidCallback? onTap;
  final bool hasOverride;

  const ScoreBanner({
    super.key,
    required this.score,
    required this.opponentName,
    this.onTap,
    this.hasOverride = false,
  });

  Color get _bg {
    if (!score.matchOver) return AppColors.primary;
    return score.mySets >= score.setsToWin
        ? const Color(0xFF1B5E20)
        : const Color(0xFF7F0000);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: _bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                // Me column
                Expanded(child: _TeamScore(
                  label: 'Me',
                  sets: score.mySets,
                  games: score.myGames,
                )),

                // Centre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (score.isTiebreak)
                        const Text(
                          'TIEBREAK',
                          style: TextStyle(
                            fontSize: 9, color: Color(0xB3FFFFFF),
                            fontWeight: FontWeight.w700, letterSpacing: 0.5,
                          ),
                        ),
                      if (score.matchOver)
                        Text(
                          score.mySets >= score.setsToWin ? '🏆 Won' : '😞 Lost',
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.primaryContainer, letterSpacing: 0.5,
                          ),
                        )
                      else
                        Text(
                          score.ptScore,
                          style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.primaryContainer, letterSpacing: 1,
                          ),
                        ),
                      if (onTap != null)
                        const Text(
                          'tap to edit',
                          style: TextStyle(fontSize: 9, color: Color(0x66FFFFFF)),
                        ),
                    ],
                  ),
                ),

                // Opponent column
                Expanded(child: _TeamScore(
                  label: opponentName.isEmpty ? 'Opponent' : opponentName,
                  sets: score.oppSets,
                  games: score.oppGames,
                )),
              ],
            ),

            if (hasOverride)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(64),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'OVERRIDE',
                    style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: Colors.white, letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  final String label;
  final int sets;
  final int games;

  const _TeamScore({required this.label, required this.sets, required this.games});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10, color: Color(0xB3FFFFFF),
            fontWeight: FontWeight.w500, letterSpacing: 0.5,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$sets',
              style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white, height: 1,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              '$games',
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w400,
                color: Color(0xCCFFFFFF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
