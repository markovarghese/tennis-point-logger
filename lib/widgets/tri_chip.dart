import 'package:flutter/material.dart';
import '../theme.dart';

/// Binary Y/N chip pair with an eyebrow label above. The "Tri" name is kept
/// for backwards compatibility; the spec defines only two visible states
/// (true and false). A null underlying value renders both chips inactive.
class TriChip extends StatelessWidget {
  final bool? value;
  final String label;
  final ValueChanged<bool?> onChange;

  const TriChip({
    super.key,
    required this.value,
    required this.label,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final baseKey = key is ValueKey ? (key as ValueKey).value.toString() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: eyebrowStyle(),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _ChipButton(
                key: baseKey != null ? Key('${baseKey}_Y') : null,
                label: 'Y',
                icon: Icons.check,
                state: value == true ? _ChipState.activeYes : _ChipState.inactive,
                onTap: () => onChange(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChipButton(
                key: baseKey != null ? Key('${baseKey}_N') : null,
                label: 'N',
                icon: Icons.close,
                state: value == false ? _ChipState.activeNo : _ChipState.inactive,
                onTap: () => onChange(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _ChipState { inactive, activeYes, activeNo }

class _ChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final _ChipState state;
  final VoidCallback onTap;

  const _ChipButton({
    super.key,
    required this.label,
    required this.icon,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      _ChipState.activeYes => AppColors.primary,
      _ChipState.activeNo => AppColors.secondary,
      _ChipState.inactive => AppColors.surfaceContainerHighest,
    };
    final fg = switch (state) {
      _ChipState.inactive => AppColors.onSurfaceVariant,
      _ => Colors.white,
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
