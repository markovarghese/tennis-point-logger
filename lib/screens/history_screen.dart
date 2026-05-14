import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/point.dart';
import '../theme.dart';

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
    final theme = Theme.of(context);

    return CourtBackground(
      child: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${widget.opponentName} · ${widget.points.length} points',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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

          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: const Row(
              children: [
                SizedBox(width: 32, child: _ColHeader('#')),
                Expanded(child: _ColHeader('TIME')),
                SizedBox(width: 24, child: _ColHeader('MS')),
                SizedBox(width: 24, child: _ColHeader('1S')),
                SizedBox(width: 24, child: _ColHeader('DF')),
                SizedBox(width: 24, child: _ColHeader('SW')),
                SizedBox(width: 24, child: _ColHeader('FE')),
                SizedBox(width: 24, child: _ColHeader('LF')),
              ],
            ),
          ),

          // Rows
          Expanded(
            child: widget.points.isEmpty
                ? const Center(
                    child: Text(
                      'No points logged yet.',
                      style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                    ),
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
                                  ? AppColors.secondaryContainer.withValues(alpha: 0.1)
                                  : i.isEven
                                      ? Colors.transparent
                                      : AppColors.primary.withValues(alpha: 0.02),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '$origIdx',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.timeLabel,
                                          style: scoreTextStyle.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant),
                                        ),
                                        if (p.score != null)
                                          Text(
                                            p.score!.compactLabel,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                      ],
                                    ),
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
                            GlassPanel(
                              borderRadius: 0,
                              opacity: 0.9,
                              color: AppColors.primary,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EDITING POINT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...kFields.map((f) => Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: _InlineTriChip(
                                          value: getField(_editPoint!, f.key),
                                          label: f.label,
                                          onChange: (v) {
                                            final updated = _editPoint!.withField(f.key, v);
                                            setState(() => _editPoint = updated);
                                            widget.onEditPoint(updated);
                                          },
                                          triState: f.key == 'myServe' || f.key == 'serverWon',
                                        ),
                                      )),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: FilledButton(
                                      onPressed: _stopEdit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                      child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),

          // Bottom Bar
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  foregroundColor: AppColors.primary,
                ),
                child: const Text(
                  'BACK TO ENTRY',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.outline,
        letterSpacing: 1,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ChipMini extends StatelessWidget {
  final bool? value;
  const _ChipMini({required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value == null
              ? Colors.transparent
              : value == true
                  ? AppColors.primary
                  : AppColors.secondaryContainer,
          border: value == null ? Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid) : null,
        ),
        child: value != null
            ? Icon(
                value == true ? Icons.check : Icons.close,
                size: 10,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

class _InlineTriChip extends StatelessWidget {
  final bool? value;
  final String label;
  final ValueChanged<bool?> onChange;
  final bool triState;

  const _InlineTriChip({
    required this.value,
    required this.label,
    required this.onChange,
    required this.triState,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        _MiniBtn(label: 'Y', active: value == true, color: Colors.white, textColor: AppColors.primary, onTap: () => onChange(true)),
        const SizedBox(width: 8),
        _MiniBtn(label: 'N', active: value == false, color: Colors.white, textColor: AppColors.primary, onTap: () => onChange(false)),
        if (triState) ...[
          const SizedBox(width: 8),
          _MiniBtn(label: '—', active: value == null, color: Colors.white, textColor: AppColors.primary, onTap: () => onChange(null)),
        ],
      ],
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _MiniBtn({
    required this.label,
    required this.active,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? color : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active ? textColor : Colors.white,
          ),
        ),
      ),
    );
  }
}
