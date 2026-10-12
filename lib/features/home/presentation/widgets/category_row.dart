import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../explore/application/explore_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../data/mock/mock_data.dart';

class CategoryRow extends ConsumerWidget {
  const CategoryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = MockData.categories;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenInsets,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final c = items[i];
          return PressableScale(
            onTap: () {
              ref.read(exploreCategoryProvider.notifier).select(c.id);
              context.go(AppRoutes.explore);
            },
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: ClipOval(
                      child: AppNetworkImage(url: c.imageUrl, radius: 0),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
