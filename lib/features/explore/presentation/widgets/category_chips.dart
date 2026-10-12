import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/mock/mock_data.dart';
import '../../application/explore_providers.dart';

class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(exploreCategoryProvider);
    final entries = <(String?, String)>[
      (null, 'All'),
      for (final c in MockData.categories) (c.id, c.name),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenInsets,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final (id, label) = entries[i];
          final active = id == selected;
          return Semantics(
            button: true,
            selected: active,
            label: label,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(exploreCategoryProvider.notifier).select(id);
              },
              child: AnimatedContainer(
                duration: AppSpacing.fast,
                curve: Curves.easeOut,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: active ? AppColors.ink : AppColors.beige,
                  ),
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: active ? AppColors.ivory : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
