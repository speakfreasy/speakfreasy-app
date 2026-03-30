import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// SFAvatar - Avatar component with optional creator ring
class SFAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final double size;
  final bool showCreatorRing;
  final double? ringWidth;

  const SFAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.size = 40,
    this.showCreatorRing = false,
    this.ringWidth,
  });

  String _getInitials() {
    if (displayName == null || displayName!.isEmpty) return '?';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // If showCreatorRing is true, increase size to account for where ring would have been
    final displaySize = showCreatorRing ? size * 1.3 : size;

    return SizedBox(
      width: displaySize,
      height: displaySize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                width: displaySize,
                height: displaySize,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: SFColors.gold,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: SFColors.black,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: SFColors.gold,
                    child: Center(
                      child: Text(
                        _getInitials(),
                        style: TextStyle(
                          color: SFColors.black,
                          fontSize: displaySize * 0.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: SFColors.gold,
                child: Center(
                  child: Text(
                    _getInitials(),
                    style: TextStyle(
                      color: SFColors.black,
                      fontSize: displaySize * 0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
