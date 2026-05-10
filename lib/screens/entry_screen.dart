import 'package:flutter/material.dart';
import '../models/point.dart';
import '../models/match_settings.dart';
import '../models/score_state.dart';
import '../theme.dart';
import '../widgets/tri_chip.dart';
import '../widgets/score_banner.dart';
import '../widgets/score_override_sheet.dart';

class EntryScreen extends StatefulWidget {
  final List<TennisPoint> points;
  final TennisPoint currentPoint;
  final ScoreState matchStartScore;
  final String opponentName;
  final MatchFormat format;
  final GsState gsState;
  final void Function(String key, bool? value) onFieldChange;
  final VoidCallback onNext;
  final VoidCallback onOpenHistory;
  final VoidCallback onBackToSetup;
  final VoidCallback onExport;
  final void Function(TennisPoint edited) onEditPoint;
  final void Function(ScoreOverride override, int? viewIdx) onScoreOverride;

  const EntryScreen({
    super.key,
    required this.points,
    required this.currentPoint,
    required this.matchStartScore,
    required this.opponentName,
    required this.format,
    required this.gsState,
    required this.onFieldChange,
    required this.onNext,
    required this.onOpenHistory,
    required this.onBackToSetup,
    required this.onExport,
    required this.onEditPoint,
    required this.onScoreOverride,
  });

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  // null = current new point; non-null = viewing a saved point by index
  int? _viewIdx;
  bool _autoSaveFlash = false;

  bool get _isNew => _viewIdx == null;

  TennisPoint get _displayPoint =>
      _isNew ? widget.currentPoint : widget.points[_viewIdx!];

  ScoreState get _displayScore {
    if (_isNew) {
      return widget.points.isEmpty
          ? widget.matchStartScore
          : widget.points.last.score ?? widget.matchStartScore;
    }
    return widget.points[_viewIdx!].score ?? widget.matchStartScore;
  }

  void _goTo(int? idx) => setState(() => _viewIdx = idx);

  void _handleChipChange(String key, bool? val) {
    if (_isNew) {
      widget.onFieldChange(key, val);
    } else {
      final updated = _displayPoint.withField(key, val);
      widget.onEditPoint(updated);
      setState(() => _autoSaveFlash = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _autoSaveFlash = false);
      });
    }
  }

  Future<void> _openOverrideEditor() async {
    final result = await showScoreOverrideSheet(context, widget.format, _displayScore);
    if (result != null) widget.onScoreOverride(result, _viewIdx);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.points.length;
    final prevIdx = _isNew
        ? (total > 0 ? total - 1 : null)
        : (_viewIdx! > 0 ? _viewIdx! - 1 : null);
    final nextIdx = _isNew
        ? null
        : (_viewIdx! < total - 1 ? _viewIdx! + 1 : null);

    final pointLabel = _isNew
        ? 'New · #${total + 1}'
        : 'Point #${_viewIdx! + 1} of $total';

    final synced = widget.gsState == GsState.connected;

    return Column(
      children: [
        // Top strip: ◀ Setup | sync dot | Export ↑
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              TextButton(
                onPressed: widget.onBackToSetup,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVar,
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('◀ Setup',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: synced ? const Color(0xFF34A853) : AppColors.outline,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(synced ? 'Synced' : 'No sync',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVar)),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.points.isEmpty ? null : widget.onExport,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  disabledForegroundColor: AppColors.outlineVariant,
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Export ↑',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        // Score banner — shows score after last saved point (or the edited point)
        ScoreBanner(
          score: _displayScore,
          opponentName: widget.opponentName,
          onTap: _openOverrideEditor,
        ),

        // Navigation strip
        _NavStrip(
          pointLabel: pointLabel,
          timeLabel: _displayPoint.timeLabel,
          isNew: _isNew,
          autoSaveFlash: _autoSaveFlash,
          canPrev: prevIdx != null,
          canNext: nextIdx != null || !_isNew,
          totalPoints: total,
          onPrev: prevIdx != null ? () => _goTo(prevIdx) : null,
          onNext: nextIdx != null
              ? () => _goTo(nextIdx)
              : !_isNew
                  ? () => _goTo(null)
                  : null,
          onOpenHistory: widget.onOpenHistory,
        ),

        // Editing context pill
        if (!_isNew)
          _EditingPill(
            pointIdx: _viewIdx!,
            autoSaveFlash: _autoSaveFlash,
            onNewPoint: () => _goTo(null),
          ),

        // Toggle chips
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: kFields.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final f = kFields[i];
              return TriChip(
                key: Key('chip_${f.key}'),
                value: getField(_displayPoint, f.key),
                label: f.label,
                onChange: (v) => _handleChipChange(f.key, v),
              );
            },
          ),
        ),

        // Bottom CTA
        _BottomCta(
          isNew: _isNew,
          onNext: _isNew
              ? () {
                  widget.onNext();
                  setState(() => _viewIdx = null);
                }
              : () => _goTo(null),
        ),
      ],
    );
  }
}

class _NavStrip extends StatelessWidget {
  final String pointLabel, timeLabel;
  final bool isNew, autoSaveFlash, canPrev, canNext;
  final int totalPoints;
  final VoidCallback? onPrev, onNext, onOpenHistory;

  const _NavStrip({
    required this.pointLabel,
    required this.timeLabel,
    required this.isNew,
    required this.autoSaveFlash,
    required this.canPrev,
    required this.canNext,
    required this.totalPoints,
    required this.onPrev,
    required this.onNext,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _NavBtn(
            key: const Key('nav_prev'),
            onTap: onPrev,
            child: Text('‹',
                style: TextStyle(
                  fontSize: 22,
                  color: canPrev ? AppColors.primary : AppColors.outlineVariant,
                )),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text(pointLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isNew ? AppColors.primary : AppColors.secondary,
                      )),
                  Text(
                    '⏱ $timeLabel${autoSaveFlash ? '  ✓ saved' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.onSurfaceVar,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _NavBtn(
            key: const Key('nav_next'),
            onTap: onNext,
            child: Text('›',
                style: TextStyle(
                  fontSize: 22,
                  color: (canNext || !isNew)
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                )),
          ),
          TextButton(
            onPressed: onOpenHistory,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
              foregroundColor: AppColors.primary,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'All ($totalPoints)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _NavBtn({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Center(child: child),
      ),
    );
  }
}

class _EditingPill extends StatelessWidget {
  final int pointIdx;
  final bool autoSaveFlash;
  final VoidCallback onNewPoint;

  const _EditingPill({
    required this.pointIdx,
    required this.autoSaveFlash,
    required this.onNewPoint,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: autoSaveFlash ? AppColors.chipYes : AppColors.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              autoSaveFlash
                  ? '✓ Auto-saved'
                  : 'Editing point #${pointIdx + 1} — changes save instantly',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: onNewPoint,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 26),
              shape: const StadiumBorder(),
            ),
            child: const Text('+ New point',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final bool isNew;
  final VoidCallback onNext;

  const _BottomCta({required this.isNew, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        color: AppColors.surface,
      ),
      child: SizedBox(
        width: double.infinity,
        height: isNew ? 56 : 52,
        child: FilledButton(
          key: const Key('bottom_cta_button'),
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: const StadiumBorder(),
            elevation: 2,
          ),
          child: Text(
            isNew ? 'Next Point →' : '← Back to current point',
            style: TextStyle(
              fontSize: isNew ? 16 : 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
