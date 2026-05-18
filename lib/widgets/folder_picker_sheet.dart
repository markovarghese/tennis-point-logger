import 'package:flutter/material.dart';
import '../models/match_settings.dart';
import '../theme.dart';
import 'sheet_header.dart';

Future<DriveFolder?> showFolderPickerSheet(
  BuildContext context, {
  required List<DriveFolder> folders,
  String? selectedId,
}) {
  return showModalBottomSheet<DriveFolder>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FolderPickerSheet(
      folders: folders,
      selectedId: selectedId,
    ),
  );
}

class _FolderPickerSheet extends StatelessWidget {
  final List<DriveFolder> folders;
  final String? selectedId;

  const _FolderPickerSheet({required this.folders, this.selectedId});

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
            'Choose Folder',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_outlined,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Google Drive',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: media.size.height * 0.5,
            ),
            child: folders.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No folders found.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: folders.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, i) {
                      final f = folders[i];
                      final selected = selectedId == f.id;
                      return _FolderTile(
                        folder: f,
                        selected: selected,
                        onTap: () => Navigator.pop(context, f),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final DriveFolder folder;
  final bool selected;
  final VoidCallback onTap;

  const _FolderTile({
    required this.folder,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 22,
                color: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                folder.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
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
