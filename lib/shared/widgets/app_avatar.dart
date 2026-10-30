import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 22,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? radius * 2;
    final avatarBackground = backgroundColor ?? AppColors.surfaceContainerHigh;
    final avatarForeground = foregroundColor ?? AppColors.primary;

    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarBackground,
      child: ClipOval(child: _buildImage(resolvedSize, avatarForeground)),
    );
  }

  Widget _buildImage(double size, Color fallbackColor) {
    final hasValidUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (!hasValidUrl) {
      return Icon(Icons.person, size: size * 0.5, color: fallbackColor);
    }

    return Image.network(
      imageUrl!,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.person, size: size * 0.5, color: fallbackColor);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: SizedBox(
            width: size * 0.45,
            height: size * 0.45,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fallbackColor,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
}
