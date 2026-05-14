import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_log.dart';
import '../theme.dart';

class SetupScreen extends StatefulWidget {
  final void Function(String opponent, DateTime date) onStart;

  const SetupScreen({super.key, required this.onStart});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _opponentCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  bool get _canStart => _opponentCtrl.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      AppLog.info('setup: date → ${DateFormat('d MMM yyyy').format(picked)}');
      setState(() => _date = picked);
    }
  }

  @override
  void dispose() {
    _opponentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(_date);
    final theme = Theme.of(context);

    return Scaffold(
      body: CourtBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_tennis, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'MATCH TRACKER',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New Match',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set up your match to begin logging.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Form in GlassPanel
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassPanel(
                    borderRadius: 8,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OPPONENT NAME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const Key('opponent_name_field'),
                          controller: _opponentCtrl,
                          autofocus: true,
                          style: theme.textTheme.bodyLarge,
                          decoration: const InputDecoration(
                            hintText: 'Enter name',
                            hintStyle: TextStyle(color: AppColors.outlineVariant),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.outlineVariant, width: 2),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.outlineVariant, width: 2),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.secondaryContainer, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'DATE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.outlineVariant, width: 2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dateLabel,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 18, color: AppColors.outline),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // CTA
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    key: const Key('start_match_button'),
                    onPressed: _canStart
                        ? () => widget.onStart(_opponentCtrl.text.trim(), _date)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondaryContainer,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.outlineVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 4,
                      shadowColor: AppColors.secondaryContainer.withValues(alpha: 0.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'START MATCH',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
