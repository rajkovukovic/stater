import 'package:flutter/material.dart';

class TriStateSelector extends StatelessWidget {
  final String? nullLabel;
  final String? trueLabel;
  final String? falseLabel;
  final Color? dropdownColor;
  final void Function(bool?)? onChanged;
  final TextStyle? textStyle;
  final bool? value;

  const TriStateSelector({
    super.key,
    this.dropdownColor,
    required this.value,
    required this.onChanged,
    this.nullLabel,
    this.trueLabel,
    this.falseLabel,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<bool?>(
      dropdownColor: dropdownColor,
      value: value,
      onChanged: onChanged,
      items: [
        DropdownMenuItem(
            value: null, child: Text(nullLabel ?? 'null', style: textStyle)),
        DropdownMenuItem(
            value: true, child: Text(trueLabel ?? 'true', style: textStyle)),
        DropdownMenuItem(
            value: false, child: Text(falseLabel ?? 'false', style: textStyle)),
      ],
    );
  }
}
