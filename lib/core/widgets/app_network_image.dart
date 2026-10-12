import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Network image with shimmer placeholder, error fallback and rounded corners.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.radius = AppSpacing.radiusMd,
    this.aspectRatio,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double radius;
  final double? aspectRatio;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: AppSpacing.medium,
        placeholder: (_, _) => Shimmer.fromColors(
          baseColor: AppColors.cream,
          highlightColor: AppColors.ivory,
          child: Container(color: AppColors.cream),
        ),
        errorWidget: (_, _, _) => Container(
          color: AppColors.cream,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.taupeLight,
          ),
        ),
      ),
    );

    if (aspectRatio != null) {
      image = AspectRatio(aspectRatio: aspectRatio!, child: image);
    }
    return image;
  }
}
