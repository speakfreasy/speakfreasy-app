import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// SFDivider - Divider component with optional text
class SFDivider extends StatelessWidget {
  final String? text;
  final double? thickness;
  final double? indent;
  final double? endIndent;

  const SFDivider({
    super.key,
    this.text,
    this.thickness,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return Divider(
        color: SFColors.border,
        thickness: thickness ?? 1,
        indent: indent,
        endIndent: endIndent,
      );
    }

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: SFColors.border,
            thickness: thickness ?? 1,
            indent: indent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: SFColors.creamMuted,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: SFColors.border,
            thickness: thickness ?? 1,
            endIndent: endIndent,
          ),
        ),
      ],
    );
  }
}
