import 'package:flutter/material.dart';
import '../theme.dart';

class TriChip extends StatelessWidget {
  final bool? value;
  final String label;
  final ValueChanged<bool?> onChange;
  final bool triState;

  const TriChip({
    super.key,
    required this.value,
    required this.label,
    required this.onChange,
    this.triState = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseKey = key is ValueKey ? (key as ValueKey).value.toString() : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
        ),
        Row(
          children: [
            _ChipButton(
              key: baseKey != null ? Key('${baseKey}_Y') : null,
              label: 'Y',
              icon: Icons.check,
              active: value == true,
              activeColor: AppColors.primary,
              onTap: () => onChange(true),
            ),
            const SizedBox(width: 8),
            _ChipButton(
              key: baseKey != null ? Key('${baseKey}_N') : null,
              label: 'N',
              icon: Icons.close,
              active: value == false,
              activeColor: AppColors.secondaryContainer,
              onTap: () => onChange(false),
            ),
            if (triState) ...[
              const SizedBox(width: 8),
              _ChipButton(
                key: baseKey != null ? Key('${baseKey}_null') : null,
                label: '',
                icon: Icons.remove,
                active: value == null,
                activeColor: AppColors.outline,
                isDashed: true,
                onTap: () => onChange(null),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  final bool isDashed;

  const _ChipButton({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64,
          decoration: BoxDecoration(
            color: active ? activeColor : const Color(0xFFEDEEED), // surface-container
            borderRadius: BorderRadius.circular(12),
            border: isDashed && !active
                ? Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid) // Simplified dashed as Border doesn't support dash natively easily
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? Colors.white : AppColors.onSurface,
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
