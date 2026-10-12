import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../data/mock/mock_data.dart';

class TreatmentRail extends StatelessWidget {
  const TreatmentRail({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = MockData.popularTreatments;
    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenInsets,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final t = items[i];
          return PressableScale(
            onTap: () => context.go(AppRoutes.explore),
            child: SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 240,
                    child: AppNetworkImage(
                      url: t.imageUrl,
                      radius: AppSpacing.radiusLg,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${t.price}  ·  ${t.durationMin} min',
                    style: theme.textTheme.bodySmall,
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
