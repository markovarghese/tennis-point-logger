import 'package:flutter/material.dart';
import '../models/score_state.dart';
import '../theme.dart';

/// Top-of-entry score card. Two columns (Player / Opponent) separated by a
/// centred "VS" divider. Each column shows the player's current point in a
/// large monospaced numeral plus small S:x / G:y pill badges. Tapping the
/// card opens the score-override sheet.
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

  String _pointFor(bool me) {
    if (score.matchOver) {
      final won = me
          ? score.mySets >= score.setsToWin
          : score.oppSets >= score.setsToWin;
      return won ? 'W' : 'L';
    }
    final parts = score.ptScore.split('-');
    if (parts.isEmpty) return '0';
    if (parts.length == 1) return parts.first;
    return me ? parts.first : parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (score.isDecidingPoint)
                  const _StatusPill(
                    label: 'DECIDING POINT',
                    background: AppColors.error,
                    foreground: AppColors.onError,
                  )
                else if (score.isTiebreak)
                  _StatusPill(
                    label: score.inFinalTb ? 'MATCH TIEBREAK' : 'TIEBREAK',
                    background: AppColors.surfaceContainerHigh,
                    foreground: AppColors.onSurfaceVariant,
                  )
                else
                  const SizedBox.shrink(),
                if (score.isDecidingPoint || score.isTiebreak)
                  const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PlayerColumn(
                        label: 'Player',
                        point: _pointFor(true),
                        sets: score.mySets,
                        games: score.myGames,
                        pointColor: AppColors.primary,
                        setBadgeColor: AppColors.primaryContainer,
                        setBadgeFg: AppColors.onPrimaryContainer,
                        alignEnd: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'VS',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.outlineVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PlayerColumn(
                        label: opponentName.isEmpty ? 'Opponent' : opponentName,
                        point: _pointFor(false),
                        sets: score.oppSets,
                        games: score.oppGames,
                        pointColor: AppColors.secondary,
                        setBadgeColor: AppColors.secondaryContainer,
                        setBadgeFg: AppColors.onSecondaryContainer,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  final String label;
  final String point;
  final int sets;
  final int games;
  final Color pointColor;
  final Color setBadgeColor;
  final Color setBadgeFg;
  final bool alignEnd;

  const _PlayerColumn({
    required this.label,
    required this.point,
    required this.sets,
    required this.games,
    required this.pointColor,
    required this.setBadgeColor,
    required this.setBadgeFg,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final badges = [
      _ScoreBadge(text: 'S:$sets', background: setBadgeColor, foreground: setBadgeFg),
      const SizedBox(width: 4),
      _ScoreBadge(
        text: 'G:$games',
        background: AppColors.surfaceContainerHigh,
        foreground: AppColors.onSurfaceVariant,
      ),
    ];

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: alignEnd
              ? [
                  ...badges,
                  const SizedBox(width: 8),
                  Text(point, style: scoreDisplayStyle(size: 40, color: pointColor)),
                ]
              : [
                  Text(point, style: scoreDisplayStyle(size: 40, color: pointColor)),
                  const SizedBox(width: 8),
                  ...badges,
                ],
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _ScoreBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
