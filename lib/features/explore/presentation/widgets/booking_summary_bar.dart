import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/explore_providers.dart';
import 'review_sheet.dart';

/// Floating summary shown only while services are selected.
class BookingSummaryBar extends ConsumerWidget {
  const BookingSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(bookingSummaryProvider);
    final visible = !summary.isEmpty;
    final reduce = MediaQuery.of(context).disableAnimations;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.6),
        duration: reduce ? Duration.zero : AppSpacing.medium,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: reduce ? Duration.zero : AppSpacing.fast,
          child: Container(
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 12),
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${summary.services.length} ${summary.services.length == 1 ? 'service' : 'services'}  ·  ${formatDuration(summary.totalDuration)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.taupeLight),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatPrice(summary.totalPrice),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: AppColors.ivory),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Review',
                  variant: AppButtonVariant.accent,
                  expand: false,
                  onPressed: () => showReviewSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}