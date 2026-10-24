import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../application/rewards_providers.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(loyaltyProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load rewards',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Try again',
                  expand: false,
                  onPressed: () => ref.invalidate(loyaltyProvider),
                ),
              ],
            ),
          ),
          data: (s) {
            final next = s.nextTier;
            final progress = next == null
                ? 1.0
                : ((s.lifetime - s.tier.minPoints) /
                          (next.minPoints - s.tier.minPoints))
                      .clamp(0.0, 1.0);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              children: [
                Text('REWARDS', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text('Your loyalty', style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.tier.name.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.champagne,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${s.balance}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: AppColors.ivory,
                        ),
                      ),
                      Text(
                        'points',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.taupeLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.charcoalSoft,
                          color: AppColors.champagne,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        next == null
                            ? 'You have reached our top tier.'
                            : '${next.minPoints - s.lifetime} more points to ${next.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.taupeLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('How it works', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Earn 1 point for every ₹100 you spend on a completed visit (before tax). Tiers are based on points earned over time. Redeeming points for discounts is coming soon.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('History', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                if (s.entries.isEmpty)
                  Text(
                    'Complete a visit to start earning points.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  for (final e in s.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.reason, style: theme.textTheme.titleSmall),
                      subtitle: Text(
                        DateFormat('d MMM yyyy').format(e.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Text(
                        '${e.points > 0 ? '+' : ''}${e.points}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: e.points > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
