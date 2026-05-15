import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

Future<bool?> showNewMatchConfirmSheet(
  BuildContext context, {
  required String opponentName,
  required DateTime matchDate,
  required int pointCount,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _NewMatchConfirmSheet(
      opponentName: opponentName,
      matchDate: matchDate,
      pointCount: pointCount,
    ),
  );
}

class _NewMatchConfirmSheet extends StatelessWidget {
  final String opponentName;
  final DateTime matchDate;
  final int pointCount;

  const _NewMatchConfirmSheet({
    required this.opponentName,
    required this.matchDate,
    required this.pointCount,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(matchDate);

    return GlassPanel(
      borderRadius: 28,
      opacity: 0.8,
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'DISCARD MATCH?',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Going back to Setup will discard the current match data.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_tennis, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opponentName.isEmpty ? 'Unknown Opponent' : opponentName,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                      ),
                      Text(
                        '$dateStr · $pointCount points',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('DISCARD & START NEW', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
