import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/mock/mock_data.dart';
import '../application/explore_providers.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final found = MockData.services.where((s) => s.id == serviceId);
    if (found.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Service not found')),
      );
    }
    final s = found.first;
    final selected = ref.watch(
      selectedServicesProvider.select((ids) => ids.contains(s.id)),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.ivory,
            flexibleSpace: FlexibleSpaceBar(
              background: AppNetworkImage(url: s.imageUrl, radius: 0),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    '${formatPrice(s.price)}  ·  ${formatDuration(s.durationMin)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(s.description, style: theme.textTheme.bodyLarge),
                  if (s.included.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text("What's included", style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    for (final item in s.included)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.champagneDark,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (s.aftercare != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('Aftercare', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(s.aftercare!, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Prices shown are estimates. The final total is confirmed at checkout.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            8,
            AppSpacing.screenPadding,
            12,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: selected ? 'Remove' : 'Add to booking',
                  variant: selected
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  onPressed: () {
                    final replaced = ref
                        .read(selectedServicesProvider.notifier)
                        .toggle(s);
                    if (replaced != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Replaced $replaced with ${s.name}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Continue',
                    variant: AppButtonVariant.accent,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push(AppRoutes.booking);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
