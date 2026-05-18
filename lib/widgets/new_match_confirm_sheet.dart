import 'package:flutter/material.dart';
import '../theme.dart';
import 'sheet_header.dart';

Future<bool?> showNewMatchConfirmSheet(
  BuildContext context, {
  required String opponentName,
  required DateTime matchDate,
  required int pointCount,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NewMatchConfirmSheet(
      opponentName: opponentName,
      pointCount: pointCount,
    ),
  );
}

class _NewMatchConfirmSheet extends StatelessWidget {
  final String opponentName;
  final int pointCount;

  const _NewMatchConfirmSheet({
    required this.opponentName,
    required this.pointCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final opp = opponentName.isEmpty ? 'Unknown' : opponentName;

    return Padding(
      padding: EdgeInsets.only(
        bottom: media.padding.bottom + media.viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(),
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Discard active match?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
            child: Text(
              'This action cannot be undone. All recorded points and '
              'statistics for this match will be permanently lost.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Opponent',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opp,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  _SummaryRow(
                    label: 'Points Recorded',
                    valueWidget: Text(
                      '$pointCount',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onError,
                  minimumSize: const Size(0, 56),
                ),
                child: const Text(
                  'Discard & Start New Match',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final Widget valueWidget;

  const _SummaryRow({required this.label, required this.valueWidget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }
}
