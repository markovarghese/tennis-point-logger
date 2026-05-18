import 'package:flutter/material.dart';
import '../models/match_settings.dart';
import '../theme.dart';
import 'sheet_header.dart';

Future<DriveSheet?> showSheetPickerSheet(
  BuildContext context, {
  required List<DriveSheet> sheets,
  String? selectedId,
}) {
  return showModalBottomSheet<DriveSheet>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SheetPickerSheet(
      sheets: sheets,
      selectedId: selectedId,
    ),
  );
}

class _SheetPickerSheet extends StatelessWidget {
  final List<DriveSheet> sheets;
  final String? selectedId;

  const _SheetPickerSheet({required this.sheets, this.selectedId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: media.padding.bottom + media.viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(),
          const SizedBox(height: 8),
          Text(
            'Select Spreadsheet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: media.size.height * 0.5,
            ),
            child: sheets.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No spreadsheets found.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: sheets.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, i) {
                      final s = sheets[i];
                      final selected = selectedId == s.id;
                      return _SheetTile(
                        sheet: s,
                        selected: selected,
                        onTap: () => Navigator.pop(context, s),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final DriveSheet sheet;
  final bool selected;
  final VoidCallback onTap;

  const _SheetTile({
    required this.sheet,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.table_chart_outlined,
                size: 22,
                color: AppColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheet.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (sheet.modified.isNotEmpty)
                    Text(
                      'Last modified ${sheet.modified}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check,
                size: 20,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
