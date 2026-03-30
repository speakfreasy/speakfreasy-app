import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// SFCard - Card component with optional decorative corners
class SFCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool decorativeCorners;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const SFCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.decorativeCorners = false,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? SFColors.charcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SFColors.border, width: 1),
      ),
      child: child,
    );

    if (decorativeCorners) {
      cardContent = Stack(
        children: [
          cardContent,
          // Decorative corner decorations
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: SFColors.gold, width: 2),
                  left: BorderSide(color: SFColors.gold, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: SFColors.gold, width: 2),
                  right: BorderSide(color: SFColors.gold, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: SFColors.gold, width: 2),
                  left: BorderSide(color: SFColors.gold, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: SFColors.gold, width: 2),
                  right: BorderSide(color: SFColors.gold, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}
