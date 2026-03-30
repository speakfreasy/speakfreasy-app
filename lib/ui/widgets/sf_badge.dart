import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// SFBadge - Badge component with variants
enum SFBadgeVariant { gold, success, error }

class SFBadge extends StatelessWidget {
  final String label;
  final SFBadgeVariant variant;
  final EdgeInsetsGeometry? padding;

  const SFBadge({
    super.key,
    required this.label,
    this.variant = SFBadgeVariant.gold,
    this.padding,
  });

  Color get _backgroundColor {
    switch (variant) {
      case SFBadgeVariant.gold:
        return SFColors.gold;
      case SFBadgeVariant.success:
        return SFColors.success;
      case SFBadgeVariant.error:
        return SFColors.error;
    }
  }

  Color get _textColor {
    switch (variant) {
      case SFBadgeVariant.gold:
        return SFColors.black;
      case SFBadgeVariant.success:
      case SFBadgeVariant.error:
        return SFColors.cream;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
