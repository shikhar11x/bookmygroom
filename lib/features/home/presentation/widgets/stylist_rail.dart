import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../reviews/data/reviews_repository.dart';
import '../../application/home_providers.dart';

class StylistRail extends ConsumerWidget {
  const StylistRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favourites = ref.watch(favouriteStylistsProvider);
    final ratings = ref.watch(stylistRatingsProvider).value ?? const {};
    final items = MockData.stylists;
    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenInsets,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final s = items[i];
          final isFav = favourites.contains(s.id);
          final r = ratings[s.id];
          final ratingLabel = r == null
              ? 'New  ·  ${s.experienceYears} yrs'
              : '${r.average.toStringAsFixed(1)} (${r.count})  ·  ${s.experienceYears} yrs';
          return SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 190,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        url: s.imageUrl,
                        radius: AppSpacing.radiusMd,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Semantics(
                          button: true,
                          label: isFav
                              ? 'Remove ${s.name} from favourites'
                              : 'Add ${s.name} to favourites',
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(favouriteStylistsProvider.notifier)
                                  .toggle(s.id);
                            },
                            child: AnimatedContainer(
                              duration: AppSpacing.fast,
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.ivory.withValues(alpha: 0.92),
                              ),
                              child: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: isFav ? AppColors.error : AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  s.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.champagneDark,
                    ),
                    const SizedBox(width: 4),
                    Text(ratingLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
