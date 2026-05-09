import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TENNIS LOGGER',
                  style: TextStyle(
                    fontSize: 11, color: Color(0xB3FFFFFF),
                    fontWeight: FontWeight.w600, letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'New Match',
                  style: TextStyle(
                    fontSize: 26, color: Colors.white, fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Set up your match to begin logging',
                  style: TextStyle(fontSize: 13, color: Color(0xB3FFFFFF)),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Opponent
                  const Text(
                    'Opponent Name *',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVar, letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('opponent_name_field'),
                    controller: _opponentCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16, color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'e.g. Rafael N.',
                      hintStyle: const TextStyle(color: AppColors.outline),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Date
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVar, letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.surface,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateLabel,
                              style: const TextStyle(
                                fontSize: 16, color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.onSurfaceVar),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CTA
          Padding(
            padding: EdgeInsets.fromLTRB(
              20, 0, 20, 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                key: const Key('start_match_button'),
                onPressed: _canStart
                    ? () => widget.onStart(_opponentCtrl.text.trim(), _date)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.outlineVariant,
                  foregroundColor: AppColors.onPrimary,
                  disabledForegroundColor: AppColors.onSurfaceVar,
                  shape: const StadiumBorder(),
                  elevation: _canStart ? 2 : 0,
                ),
                child: const Text(
                  'Start Match →',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
