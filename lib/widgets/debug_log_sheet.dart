import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_log.dart';
import '../theme.dart';
import 'sheet_header.dart';

Future<void> showDebugLogSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _DebugLogSheet(),
  );
}

class _DebugLogSheet extends StatelessWidget {
  const _DebugLogSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final entries = AppLog.entries.reversed.toList();

    return SizedBox(
      height: media.size.height * 0.75,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: media.padding.bottom + media.viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Debug Log',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: AppLog.formatted()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Log copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.content_copy, size: 18),
                    label: Text(
                      'COPY ALL',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: AppColors.outlineVariant,
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'No log entries yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        final striped = i.isOdd;
                        return Container(
                          color: e.isError
                              ? AppColors.errorContainer.withValues(alpha: 0.3)
                              : striped
                                  ? AppColors.surfaceContainer
                                      .withValues(alpha: 0.4)
                                  : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 76,
                                child: Text(
                                  e.timeStr,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: e.isError
                                        ? AppColors.error
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.message,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: e.isError
                                        ? AppColors.error
                                        : AppColors.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
