import 'package:flutter/material.dart';
import '../models/point.dart';
import '../theme.dart';
import '../widgets/tri_chip.dart';

class HistoryScreen extends StatefulWidget {
  final List<TennisPoint> points;
  final String opponentName;
  final VoidCallback onBack;
  final void Function(TennisPoint edited) onEditPoint;

  const HistoryScreen({
    super.key,
    required this.points,
    required this.opponentName,
    required this.onBack,
    required this.onEditPoint,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _editingId;
  TennisPoint? _editPoint;

  void _startEdit(TennisPoint p) {
    setState(() {
      _editingId = p.id;
      _editPoint = p;
    });
  }

  void _stopEdit() => setState(() {
    _editingId = null;
    _editPoint = null;
  });

  @override
  Widget build(BuildContext context) {
    final reversed = widget.points.reversed.toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                color: AppColors.onSurface,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Point History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
                    Text('${widget.opponentName} · ${widget.points.length} points',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVar)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Column headers
        Container(
          color: AppColors.surfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: const Row(
            children: [
              SizedBox(width: 36, child: _ColHeader('#')),
              Expanded(child: _ColHeader('Time')),
              SizedBox(width: 24, child: _ColHeader('MS', tooltip: 'My Serve')),
              SizedBox(width: 24, child: _ColHeader('1S', tooltip: 'First Serve')),
              SizedBox(width: 24, child: _ColHeader('DF', tooltip: 'Double Fault')),
              SizedBox(width: 24, child: _ColHeader('SW', tooltip: 'Server Won')),
              SizedBox(width: 24, child: _ColHeader('FE', tooltip: 'Forced Error')),
              SizedBox(width: 24, child: _ColHeader('LF', tooltip: 'Loser Forehand')),
            ],
          ),
        ),

        // Rows
        Expanded(
          child: widget.points.isEmpty
              ? const Center(
                  child: Text('No points logged yet.',
                    style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVar)),
                )
              : ListView.builder(
                  itemCount: reversed.length,
                  itemBuilder: (context, i) {
                    final p = reversed[i];
                    final origIdx = widget.points.length - i;
                    final isEditing = _editingId == p.id;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: isEditing ? _stopEdit : () => _startEdit(p),
                          child: Container(
                            color: isEditing
                                ? AppColors.secondaryContainer
                                : i.isEven
                                    ? AppColors.surface
                                    : const Color(0xFFEDF4F2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text('#$origIdx',
                                    style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                                ),
                                Expanded(
                                  child: Text(p.timeLabel,
                                    style: const TextStyle(
                                      fontSize: 12, fontFamily: 'monospace',
                                      color: AppColors.onSurfaceVar)),
                                ),
                                ...kFields.map((f) => SizedBox(
                                  width: 24,
                                  child: _ChipMini(value: getField(p, f.key)),
                                )),
                              ],
                            ),
                          ),
                        ),
                        if (isEditing && _editPoint != null)
                          _InlineEditor(
                            point: _editPoint!,
                            pointIdx: origIdx,
                            onFieldChange: (key, val) {
                              final updated = _editPoint!.withField(key, val);
                              setState(() => _editPoint = updated);
                              widget.onEditPoint(updated);
                            },
                            onDone: _stopEdit,
                          ),
                        const Divider(height: 1, color: AppColors.outlineVariant),
                      ],
                    );
                  },
                ),
        ),

        // Back button
        Padding(
          padding: EdgeInsets.fromLTRB(
            16, 12, 16, 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.tonal(
              onPressed: widget.onBack,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.onSurface,
                shape: const StadiumBorder(),
              ),
              child: const Text('← Back to Entry',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final String? tooltip;
  const _ColHeader(this.text, {this.tooltip});

  @override
  Widget build(BuildContext context) {
    final w = Tooltip(
      message: tooltip ?? text,
      child: Text(text,
        style: const TextStyle(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVar, letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
    return w;
  }
}

class _ChipMini extends StatelessWidget {
  final bool? value;
  const _ChipMini({required this.value});

  Color get _bg => value == null
      ? AppColors.chipNull
      : value == true ? AppColors.chipYes : AppColors.chipNo;

  Color get _text => value == null
      ? AppColors.chipNullText
      : value == true ? AppColors.chipYesText : AppColors.chipNoText;

  String get _mark => value == null ? '—' : value == true ? '✓' : '✗';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 22, height: 22,
        decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(_mark,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _text)),
      ),
    );
  }
}

class _InlineEditor extends StatelessWidget {
  final TennisPoint point;
  final int pointIdx;
  final void Function(String key, bool? val) onFieldChange;
  final VoidCallback onDone;

  const _InlineEditor({
    required this.point, required this.pointIdx,
    required this.onFieldChange, required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editing Point #$pointIdx — changes save instantly',
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.onSecondaryContainer),
          ),
          const SizedBox(height: 8),
          ...kFields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TriChip(
              value: getField(point, f.key),
              label: f.label,
              compact: true,
              onChange: (v) => onFieldChange(f.key, v),
            ),
          )),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton.tonal(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.onSurface,
                shape: const StadiumBorder(),
              ),
              child: const Text('Done',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
