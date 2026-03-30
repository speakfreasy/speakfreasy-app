import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// SFButton - Button component with variants
enum SFButtonVariant { primary, secondary, ghost }

class SFButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SFButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const SFButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SFButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(SFColors.black),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ],
    );

    switch (variant) {
      case SFButtonVariant.primary:
        return Container(
          decoration: BoxDecoration(
            gradient: SFColors.goldGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: padding ?? const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: buttonContent,
              ),
            ),
          ),
        );

      case SFButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            side: const BorderSide(color: SFColors.gold, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: buttonContent,
        );

      case SFButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            foregroundColor: SFColors.gold,
          ),
          child: buttonContent,
        );
    }
  }
}
