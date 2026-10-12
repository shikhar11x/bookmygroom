import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../data/mock/mock_data.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    return Padding(
      padding: AppSpacing.screenInsets,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: SizedBox(
          height: 380,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: reduce ? 1 : 1.1, end: 1),
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: AppNetworkImage(url: MockData.heroImage, radius: 0),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1],
                    colors: [Colors.transparent, Color(0xE60E0D0C)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE SEASONAL EDIT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.champagne,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Refresh your\nlook this season',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.ivory,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Explore services',
                      variant: AppButtonVariant.accent,
                      expand: false,
                      onPressed: () => context.go(AppRoutes.explore),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
