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
    final theme = Theme.of(context);
    final dateLabel = DateFormat('d MMM yyyy').format(_date);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'TENNIS LOGGER',
                style: eyebrowStyle(color: AppColors.primary).copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('New Match', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Set up your match to begin logging.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _RequiredFieldLabel(
                      label: 'Opponent Name',
                      required: true,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('opponent_name_field'),
                      controller: _opponentCtrl,
                      autofocus: false,
                      textInputAction: TextInputAction.done,
                      style: theme.textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Rafael N.',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    const _RequiredFieldLabel(label: 'Date', required: false),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dateLabel,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 16, 0, 24 + bottomPad),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('start_match_button'),
                onPressed: _canStart
                    ? () => widget.onStart(_opponentCtrl.text.trim(), _date)
                    : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start Match'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredFieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _RequiredFieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (required)
            const Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                '*',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
