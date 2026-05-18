import 'package:flutter/material.dart';
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
    if (key == 'serverWon' && val == null && _displayPoint.serverWon != null) {
      return;
    }

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
    final result = await showScoreOverrideSheet(
      context,
      widget.format,
      _displayScore,
    );
    if (result != null) widget.onScoreOverride(result, _viewIdx);
  }

  Future<void> _handleBack() async {
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
    if (confirm == true) widget.onBackToSetup();
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
        ? 'New Point · #${total + 1}'
        : 'Point #${_viewIdx! + 1} of $total';

    return Column(
      children: [
        _TopBar(
          gsState: widget.gsState,
          canExport: widget.points.isNotEmpty,
          onBack: _handleBack,
          onExport: widget.onExport,
        ),
        const _ThinDivider(),
        const SizedBox(height: 8),
        ScoreBanner(
          score: _displayScore,
          opponentName: widget.opponentName,
          onTap: _openOverrideEditor,
        ),
        _NavStrip(
          pointLabel: pointLabel,
          timeLabel: _displayPoint.timeLabel.substring(0, 5),
          totalPoints: total,
          canPrev: prevIdx != null,
          canNext: nextIdx != null || !_isNew,
          onPrev: prevIdx != null ? () => _goTo(prevIdx) : null,
          onNext: nextIdx != null
              ? () => _goTo(nextIdx)
              : (!_isNew ? () => _goTo(null) : null),
          onOpenHistory: total > 0 ? widget.onOpenHistory : null,
        ),
        if (!_isNew)
          _EditingPill(
            pointIdx: _viewIdx!,
            autoSaveFlash: _autoSaveFlash,
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 90,
            ),
            itemCount: kFields.length,
            itemBuilder: (context, i) {
              final f = kFields[i];
              return TriChip(
                key: Key('chip_${f.key}'),
                value: getField(_displayPoint, f.key),
                label: _shortLabel(f.key, f.label),
                onChange: (v) => _handleChipChange(f.key, v),
              );
            },
          ),
        ),
        _BottomCta(
          isNew: _isNew,
          isLastCommitted: isLastCommitted,
          onNewPoint: !_isNew ? () => _goTo(null) : null,
          onDelete: !_isNew ? _handleDelete : null,
        ),
      ],
    );
  }

  String _shortLabel(String key, String fallback) {
    switch (key) {
      case 'myServe':
        return 'My Serve?';
      case 'firstServe':
        return '1st Serve?';
      case 'doubleFault':
        return 'Double Fault?';
      case 'serverWon':
        return 'Server Won?';
      case 'forcedError':
        return 'Forced Error?';
      case 'loserForehand':
        return 'Loser Forehand?';
      default:
        return fallback;
    }
  }
}

class _TopBar extends StatelessWidget {
  final GsState gsState;
  final bool canExport;
  final VoidCallback onBack;
  final VoidCallback onExport;

  const _TopBar({
    required this.gsState,
    required this.canExport,
    required this.onBack,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          const Spacer(),
          _SyncStatusPill(state: gsState),
          const Spacer(),
          IconButton(
            onPressed: canExport ? onExport : null,
            icon: Icon(
              Icons.ios_share,
              color: canExport ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusPill extends StatelessWidget {
  final GsState state;
  const _SyncStatusPill({required this.state});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (state) {
      GsState.connected => (Icons.cloud_done, 'SYNCED'),
      GsState.connecting => (Icons.sync, 'SYNCING'),
      GsState.disconnected => (Icons.cloud_off, 'OFFLINE'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: eyebrowStyle().copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

class _NavStrip extends StatelessWidget {
  final String pointLabel;
  final String timeLabel;
  final int totalPoints;
  final bool canPrev;
  final bool canNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onOpenHistory;

  const _NavStrip({
    required this.pointLabel,
    required this.timeLabel,
    required this.totalPoints,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            IconButton(
              key: const Key('nav_prev'),
              onPressed: onPrev,
              icon: Icon(
                Icons.chevron_left,
                color: canPrev ? AppColors.primary : AppColors.outlineVariant,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pointLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onOpenHistory,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                'ALL ($totalPoints)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            IconButton(
              key: const Key('nav_next'),
              onPressed: onNext,
              icon: Icon(
                Icons.chevron_right,
                color: canNext ? AppColors.primary : AppColors.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditingPill extends StatelessWidget {
  final int pointIdx;
  final bool autoSaveFlash;

  const _EditingPill({required this.pointIdx, required this.autoSaveFlash});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: autoSaveFlash
            ? AppColors.primaryContainer
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            autoSaveFlash ? Icons.check_circle : Icons.edit_note,
            size: 18,
            color: autoSaveFlash
                ? AppColors.primary
                : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              autoSaveFlash
                  ? 'Saved'
                  : 'Editing point #${pointIdx + 1} — changes save instantly',
              style: theme.textTheme.bodySmall?.copyWith(
                color: autoSaveFlash
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final bool isNew;
  final bool isLastCommitted;
  final VoidCallback? onNewPoint;
  final VoidCallback? onDelete;

  const _BottomCta({
    required this.isNew,
    required this.isLastCommitted,
    required this.onNewPoint,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final padding = EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPad);

    if (isNew) {
      // Disabled placeholder while user is filling in chips. The commit
      // happens automatically when `serverWon` is set; the button is here
      // as a visual affordance matching the spec.
      return Padding(
        padding: padding,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            key: const Key('bottom_cta_button'),
            onPressed: null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              foregroundColor: AppColors.onSurfaceVariant,
              disabledBackgroundColor: AppColors.surfaceContainerHigh,
              disabledForegroundColor: AppColors.onSurfaceVariant,
              minimumSize: const Size(0, 56),
              shape: const StadiumBorder(),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('New Point', style: TextStyle(fontWeight: FontWeight.w500)),
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
        padding: padding,
        child: Row(
          children: [
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  key: const Key('bottom_cta_button'),
                  onPressed: onNewPoint,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New Point'),
                      SizedBox(width: 8),
                      Icon(Icons.add, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          key: const Key('bottom_cta_button'),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 20),
          label: const Text('Delete Point'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
