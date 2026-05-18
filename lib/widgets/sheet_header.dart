import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared bottom-sheet header: drag pill + optional title and trailing close.
/// All modal sheets in the app start with this widget for visual consistency.
class SheetHeader extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final bool showCloseButton;
  final EdgeInsetsGeometry padding;

  const SheetHeader({
    super.key,
    this.title,
    this.trailing,
    this.showCloseButton = false,
    this.padding = const EdgeInsets.fromLTRB(24, 12, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        if (title != null || trailing != null || showCloseButton)
          Padding(
            padding: padding,
            child: Row(
              children: [
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleLarge,
                    ),
                  )
                else
                  const Spacer(),
                if (trailing != null) trailing!,
                if (showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Padding helper that includes the bottom safe-area inset for sheets.
EdgeInsets sheetContentPadding(BuildContext context, {EdgeInsets base = EdgeInsets.zero}) {
  final media = MediaQuery.of(context);
  return base + EdgeInsets.only(bottom: media.padding.bottom + media.viewInsets.bottom);
}
