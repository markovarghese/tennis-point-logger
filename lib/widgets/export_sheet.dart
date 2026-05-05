import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/match_settings.dart';
import '../models/point.dart';
import '../theme.dart';

Future<void> showExportSheet(
  BuildContext context,
  List<TennisPoint> points,
  String opponentName,
  DateTime matchDate, {
  required AppSettings settings,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExportSheet(
      points: points,
      opponentName: opponentName,
      matchDate: matchDate,
      settings: settings,
    ),
  );
}

class _ExportSheet extends StatefulWidget {
  final List<TennisPoint> points;
  final String opponentName;
  final DateTime matchDate;
  final AppSettings settings;

  const _ExportSheet({
    required this.points,
    required this.opponentName,
    required this.matchDate,
    required this.settings,
  });

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _copied = false;

  String get _csv {
    final dateStr = DateFormat('dd MMM yyyy HH:mm').format(widget.matchDate);
    final header = 'Match Date & Time,Play Time,Opponent,My Serve?,First Serve?,'
        'Double Fault?,Won?,Loser\'s Forced Error?,Loser\'s Forehand?';
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

  Future<void> _openInSheets() async {
    final connected = widget.settings.gsState == GsState.connected;
    final hasDest = widget.settings.selectedSheet != null ||
        widget.settings.selectedFolder != null;
    final msg = !connected
        ? 'Connect Google account in Settings first.'
        : !hasDest
            ? 'Choose a Google Sheets destination in Settings.'
            : 'Syncing ${widget.points.length} rows to '
              '${widget.settings.selectedSheet?.name ?? 'TennisLogger_${DateTime.now().year}.xlsx'}…';
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _saveToDevice() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(widget.matchDate);
      final file = File('${dir.path}/tennis_${widget.opponentName}_$dateStr.csv');
      await file.writeAsString(_csv);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Tennis match vs ${widget.opponentName}',
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
    final dateLabel = DateFormat('d MMM yyyy').format(widget.matchDate);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Export Match',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text(
            '${widget.opponentName} · $dateLabel · ${widget.points.length} pts',
            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVar),
          ),
          const SizedBox(height: 16),

          _ExportAction(
            icon: '📋',
            label: _copied ? '✓ Copied!' : 'Copy as CSV',
            sub: 'Paste into any spreadsheet',
            accent: _copied,
            onTap: _copyCSV,
          ),
          const SizedBox(height: 8),
          _ExportAction(
            icon: '📊',
            label: 'Open in Google Sheets',
            sub: widget.settings.gsState == GsState.connected
                ? 'Sync via Sheets API'
                : 'Connect Google in Settings',
            accent: false,
            onTap: _openInSheets,
          ),
          const SizedBox(height: 8),
          _ExportAction(
            icon: '💾',
            label: 'Save to device',
            sub: 'Download .csv file',
            accent: false,
            onTap: _saveToDevice,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.onSurface,
                shape: const StadiumBorder(),
              ),
              child: const Text('Close',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportAction extends StatelessWidget {
  final String icon, label, sub;
  final bool accent;
  final VoidCallback onTap;

  const _ExportAction({
    required this.icon, required this.label, required this.sub,
    required this.accent, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent ? AppColors.primaryContainer : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  Text(sub, style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVar)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
