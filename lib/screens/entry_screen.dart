import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/point.dart';
import '../models/match_settings.dart';
import '../models/score_state.dart';
import '../theme.dart';
import '../widgets/tri_chip.dart';
import '../widgets/score_banner.dart';
import '../widgets/score_override_sheet.dart';
import '../widgets/new_match_confirm_sheet.dart';

class EntryScreen extends StatefulWidget {
  final List<TennisPoint> points;
  final TennisPoint currentPoint;
  final ScoreState matchStartScore;
  final String opponentName;
  final DateTime matchDate;
  final MatchFormat format;
  final GsState gsState;
  final void Function(String key, bool? value) onFieldChange;
  final VoidCallback onCommitPoint;
  final void Function(int idx) onDeletePoint;
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
    required this.matchDate,
    required this.format,
    required this.gsState,
    required this.onFieldChange,
    required this.onCommitPoint,
    required this.onDeletePoint,
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
    // Block clearing serverWon once it has a value
    if (key == 'serverWon' && val == null && _displayPoint.serverWon != null) return;

    if (_isNew) {
      final serverWonWasNull = widget.currentPoint.serverWon == null;
      widget.onFieldChange(key, val);
      if (key == 'serverWon' && val != null && serverWonWasNull) {
        widget.onCommitPoint();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _viewIdx = widget.points.length - 1);
        });
      }
    } else {
      final updated = _displayPoint.withField(key, val);
      widget.onEditPoint(updated);
      setState(() => _autoSaveFlash = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _autoSaveFlash = false);
      });
    }
  }

  void _handleDelete() {
    final idx = _viewIdx!;
    final isLast = idx == widget.points.length - 1;
    widget.onDeletePoint(idx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _viewIdx = isLast ? null : idx);
    });
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
    final isLastCommitted = !_isNew && _viewIdx == total - 1;

    final pointLabel = _isNew
        ? 'New · #${total + 1}'
        : 'Point #${_viewIdx! + 1} of $total';

    final synced = widget.gsState == GsState.connected;

    return CourtBackground(
      child: Column(
        children: [
          // Top Bar
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (widget.points.isEmpty) {
                        widget.onBackToSetup();
                        return;
                      }
                      final confirm = await showNewMatchConfirmSheet(
                        context,
                        opponentName: widget.opponentName,
                        matchDate: widget.matchDate,
                        pointCount: widget.points.length,
                      );
                      if (confirm == true) {
                        widget.onBackToSetup();
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        synced ? Icons.cloud_done : Icons.cloud_off,
                        size: 16,
                        color: synced ? AppColors.primary : AppColors.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        synced ? 'SYNCED' : 'OFFLINE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.outline,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.points.isEmpty ? null : widget.onExport,
                    icon: const Icon(Icons.ios_share, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),

          // Score Banner
          ScoreBanner(
            score: _displayScore,
            opponentName: widget.opponentName,
            onTap: _openOverrideEditor,
          ),

          // Navigation Strip
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
            ),

          // Chips List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              itemCount: kFields.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, i) {
                final f = kFields[i];
                return TriChip(
                  key: Key('chip_${f.key}'),
                  value: getField(_displayPoint, f.key),
                  label: f.label,
                  onChange: (v) => _handleChipChange(f.key, v),
                  triState: f.key == 'serverWon' && getField(_displayPoint, 'serverWon') == null,
                );
              },
            ),
          ),

          // Bottom CTA
          _buildBottomCta(context, isLastCommitted),
        ],
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context, bool isLastCommitted) {
    final bottomPad = 20.0 + MediaQuery.of(context).padding.bottom;

    if (_isNew) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton(
            key: const Key('bottom_cta_button'),
            onPressed: null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondaryContainer,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.secondaryContainer.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('NEW POINT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
                SizedBox(width: 8),
                Icon(Icons.add, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    if (isLastCommitted) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 64,
                child: FilledButton(
                  key: const Key('bottom_cta_button'),
                  onPressed: () => _goTo(null),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: AppColors.secondaryContainer.withValues(alpha: 0.2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('NEW POINT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      SizedBox(width: 8),
                      Icon(Icons.add, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 64,
              child: OutlinedButton(
                onPressed: _handleDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('DELETE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      );
    }

    // Non-last committed point: delete only
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: OutlinedButton(
          key: const Key('bottom_cta_button'),
          onPressed: _handleDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, size: 20),
              SizedBox(width: 8),
              Text('DELETE POINT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
        ),
      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _NavBtn(
            key: const Key('nav_prev'),
            onTap: onPrev,
            child: Icon(Icons.chevron_left, color: canPrev ? AppColors.primary : AppColors.outlineVariant),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pointLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFamily: GoogleFonts.inter().fontFamily,
                  ),
                ),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onOpenHistory,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 32),
              foregroundColor: AppColors.primary,
            ),
            child: Text(
              'ALL ($totalPoints)',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
          _NavBtn(
            key: const Key('nav_next'),
            onTap: onNext,
            child: Icon(Icons.chevron_right, color: (canNext || !isNew) ? AppColors.primary : AppColors.outlineVariant),
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
    return IconButton(
      onPressed: onTap,
      icon: child,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
    );
  }
}

class _EditingPill extends StatelessWidget {
  final int pointIdx;
  final bool autoSaveFlash;

  const _EditingPill({required this.pointIdx, required this.autoSaveFlash});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: autoSaveFlash ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        autoSaveFlash
            ? '✓ Saved'
            : 'Editing point #${pointIdx + 1} — changes save instantly',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: autoSaveFlash ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
