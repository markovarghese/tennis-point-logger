import 'package:flutter/material.dart';
import '../theme.dart';

class TriChip extends StatelessWidget {
  final bool? value;
  final String label;
  final ValueChanged<bool?> onChange;
  final bool compact;
  final bool triState;

  const TriChip({
    super.key,
    required this.value,
    required this.label,
    required this.onChange,
    this.compact = false,
    this.triState = true,
  });

  // triState=true: cycles null → true → false → null
  // triState=false: cycles true → false → true (no null)
  bool? get _next => triState
      ? (value == null ? true : value == true ? false : null)
      : (value == true ? false : true);

  Color get _bg => value == null
      ? AppColors.chipNull
      : value == true
          ? AppColors.chipYes
          : AppColors.chipNo;

  Color get _textColor => value == null
      ? AppColors.chipNullText
      : value == true
          ? AppColors.chipYesText
          : AppColors.chipNoText;

  Color get _markBg => value == null
      ? AppColors.outlineVariant
      : value == true
          ? AppColors.chipYesMark
          : AppColors.chipNoMark;

  String get _mark => value == null ? '—' : value == true ? '✓' : '✗';

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 22.0 : 28.0;
    final fontSize = compact ? 12.0 : 14.0;
    final markFontSize = compact ? 11.0 : 14.0;
    final vPad = compact ? 6.0 : 10.0;
    final hPad = compact ? 10.0 : 14.0;
    final gap = compact ? 6.0 : 8.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChange(_next),
        borderRadius: BorderRadius.circular(100),
        splashColor: _bg.withAlpha(120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.fromLTRB(vPad, vPad, hPad, vPad),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: markSize,
                height: markSize,
                decoration: BoxDecoration(
                  color: _markBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _mark,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: markFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
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
