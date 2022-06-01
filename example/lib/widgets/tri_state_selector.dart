import 'package:flutter/material.dart';

class TriStateSelector extends StatelessWidget {
  final bool? value;
  final void Function(bool?)? onChanged;
  final String? nullLabel;
  final String? trueLabel;
  final String? falseLabel;

  const TriStateSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.nullLabel,
    this.trueLabel,
    this.falseLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<bool?>(
      value: value,
      onChanged: onChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(nullLabel ?? 'null')),
        DropdownMenuItem(value: true, child: Text(trueLabel ?? 'true')),
        DropdownMenuItem(value: false, child: Text(falseLabel ?? 'false')),
      ],
    );
  }
}
