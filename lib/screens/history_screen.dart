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

  void _toggleEdit(TennisPoint p) {
    setState(() => _editingId = _editingId == p.id ? null : p.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reversed = widget.points.reversed.toList();
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              opponentName: widget.opponentName,
              pointCount: widget.points.length,
              onBack: widget.onBack,
            ),
            Expanded(
              child: widget.points.isEmpty
                  ? const _EmptyState()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: AppColors.surfaceContainerLow,
                          child: Column(
                            children: [
                              const _ColumnHeaderRow(),
                              const Divider(
                                height: 1,
                                color: AppColors.outlineVariant,
                              ),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: reversed.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                  itemBuilder: (context, i) {
                                    final p = reversed[i];
                                    final origIdx =
                                        widget.points.length - 1 - i;
                                    final pointNum = origIdx + 1;
                                    return _PointRow(
                                      point: p,
                                      pointNum: pointNum,
                                      isEditing: _editingId == p.id,
                                      onTap: () => _toggleEdit(p),
                                      onFieldChange: (key, val) {
                                        widget.onEditPoint(
                                          p.withField(key, val),
                                        );
                                      },
                                      theme: theme,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: widget.onBack,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text('Back to Entry'),
                    ],
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

class _Header extends StatelessWidget {
  final String opponentName;
  final int pointCount;
  final VoidCallback onBack;

  const _Header({
    required this.opponentName,
    required this.pointCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Point History',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  opponentName.isEmpty
                      ? '$pointCount pts'
                      : 'vs. $opponentName ($pointCount pts)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const IconButton(
            onPressed: null,
            icon: Icon(
              Icons.more_vert,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnHeaderRow extends StatelessWidget {
  const _ColumnHeaderRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Container(
      color: AppColors.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 76, child: Text('# / Time', style: labelStyle)),
          for (final f in kFields)
            Expanded(
              child: Text(
                f.abbr,
                textAlign: TextAlign.center,
                style: labelStyle,
              ),
            ),
        ],
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final TennisPoint point;
  final int pointNum;
  final bool isEditing;
  final VoidCallback onTap;
  final void Function(String key, bool? val) onFieldChange;
  final ThemeData theme;

  const _PointRow({
    required this.point,
    required this.pointNum,
    required this.isEditing,
    required this.onTap,
    required this.onFieldChange,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hh = point.createdAt.hour.toString().padLeft(2, '0');
    final mm = point.createdAt.minute.toString().padLeft(2, '0');
    final scoreLabel = point.score?.compactLabel ?? '';

    return Material(
      color: isEditing
          ? AppColors.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$pointNum',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$hh:$mm',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        if (scoreLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              scoreLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (final f in kFields)
                    Expanded(
                      child: Center(
                        child: _StatusIcon(value: getField(point, f.key)),
                      ),
                    ),
                ],
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                _InlineEditor(
                  point: point,
                  onFieldChange: onFieldChange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final bool? value;
  const _StatusIcon({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return const Icon(
        Icons.radio_button_unchecked,
        size: 22,
        color: AppColors.outline,
      );
    }
    if (value == true) {
      return const Icon(
        Icons.check_circle_outline,
        size: 22,
        color: AppColors.primary,
      );
    }
    return const Icon(
      Icons.cancel_outlined,
      size: 22,
      color: AppColors.secondary,
    );
  }
}

class _InlineEditor extends StatelessWidget {
  final TennisPoint point;
  final void Function(String key, bool? val) onFieldChange;

  const _InlineEditor({required this.point, required this.onFieldChange});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 86,
      ),
      itemCount: kFields.length,
      itemBuilder: (context, i) {
        final f = kFields[i];
        return TriChip(
          key: Key('edit_${point.id}_${f.key}'),
          value: getField(point, f.key),
          label: f.label,
          onChange: (v) => onFieldChange(f.key, v),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'No points logged yet.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
