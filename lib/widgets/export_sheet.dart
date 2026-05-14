import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/point.dart';
import '../theme.dart';

Future<void> showExportSheet(
  BuildContext context,
  List<TennisPoint> points,
  String opponentName,
  DateTime matchDate,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
        "Server Double Fault?,Server Won?,Loser's Forced Error?,Loser's Forehand?";
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
      final file = File('${dir.path}/tennis_${widget.opponentName}_$dateStr.csv');
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
    final dateLabel = DateFormat('d MMM yyyy').format(widget.matchDate);

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
          Text(
            'EXPORT MATCH',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.opponentName} · $dateLabel',
            style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          _ExportAction(
            icon: Icons.copy,
            label: _copied ? 'COPIED!' : 'COPY AS CSV',
            sub: 'Paste into any spreadsheet',
            active: _copied,
            onTap: _copyCSV,
          ),
          const SizedBox(height: 12),
          _ExportAction(
            icon: Icons.save_alt,
            label: 'SAVE TO DEVICE',
            sub: 'Download .csv file',
            active: false,
            onTap: _saveToDevice,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                foregroundColor: AppColors.primary,
              ),
              child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportAction extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final bool active;
  final VoidCallback onTap;

  const _ExportAction({
    required this.icon, required this.label, required this.sub,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.white : AppColors.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.white70 : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
