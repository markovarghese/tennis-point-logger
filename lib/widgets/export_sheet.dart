import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/point.dart';
import '../theme.dart';
import 'sheet_header.dart';

Future<void> showExportSheet(
  BuildContext context,
  List<TennisPoint> points,
  String opponentName,
  DateTime matchDate,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ExportSheet(
      points: points,
      opponentName: opponentName,
      matchDate: matchDate,
    ),
  );
}

class _ExportSheet extends StatefulWidget {
  final List<TennisPoint> points;
  final String opponentName;
  final DateTime matchDate;

  const _ExportSheet({
    required this.points,
    required this.opponentName,
    required this.matchDate,
  });

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _copied = false;

  String get _csv {
    final dateStr = DateFormat('dd MMM yyyy HH:mm').format(widget.matchDate);
    const header = "Match Date & Time,Play Time,Opponent,My Serve?,Server's First Serve?,"
        "Server Double Fault?,Server Won?,Loser's Forced Error?,Loser's Forehand?,"
        "My Sets,Opp Sets,My Games,Opp Games,My Points,Opp Points";
    final rows = widget.points
        .map((p) => p.toCsvRow(dateStr, widget.opponentName).join(','))
        .join('\n');
    return '$header\n$rows';
  }

  Future<void> _copyCSV() async {
    await Clipboard.setData(ClipboardData(text: _csv));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _saveToDevice() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(widget.matchDate);
      final file = File(
        '${dir.path}/tennis_${widget.opponentName}_$dateStr.csv',
      );
      await file.writeAsString(_csv);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          text: 'Tennis match vs ${widget.opponentName}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final dateLabel = DateFormat('MMM d').format(widget.matchDate);
    final opp = widget.opponentName.isEmpty
        ? 'Opponent'
        : widget.opponentName;

    return Padding(
      padding: EdgeInsets.only(
        bottom: media.padding.bottom + media.viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(),
          const SizedBox(height: 8),
          Text(
            'Export Match',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'vs. $opp • $dateLabel • ${widget.points.length} pts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ExportOption(
                  icon: Icons.content_copy,
                  title: _copied ? 'Copied!' : 'Copy as CSV',
                  subtitle: 'Paste into any spreadsheet',
                  onTap: _copyCSV,
                ),
                const SizedBox(height: 12),
                _ExportOption(
                  icon: Icons.save_alt,
                  title: 'Save to device',
                  subtitle: 'Export as a .csv file',
                  onTap: _saveToDevice,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 56),
                ),
                child: const Text('Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.onSecondary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
