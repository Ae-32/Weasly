import 'package:flutter/material.dart';
import '../utils/default_categories.dart';

/// Renders a category icon, using custom PNG asset fitted to placeholder size if available,
/// or falling back to standard Material Icon.
class CategoryIcon extends StatelessWidget {
  final String categoryName;
  final String? iconName;
  final double size;
  final double? containerSize;
  final BorderRadius? borderRadius;
  final Color? color;
  final BoxFit fit;

  const CategoryIcon({
    super.key,
    required this.categoryName,
    this.iconName,
    this.size = 20,
    this.containerSize,
    this.borderRadius,
    this.color,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = DefaultCategories.getCustomIconAsset(categoryName, iconName);
    final imageDimension = containerSize ?? size;

    if (assetPath != null) {
      Widget imageWidget = Image.asset(
        assetPath,
        width: imageDimension,
        height: imageDimension,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Icon(
          DefaultCategories.getIcon(iconName ?? ''),
          size: size,
          color: color,
        ),
      );

      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius!,
          child: imageWidget,
        );
      }

      return imageWidget;
    }

    return Icon(
      DefaultCategories.getIcon(iconName ?? ''),
      size: size,
      color: color,
    );
  }
}
