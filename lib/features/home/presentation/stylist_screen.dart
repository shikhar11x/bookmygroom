import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/mock/mock_data.dart';
import '../../booking/application/booking_providers.dart';
import '../../explore/application/explore_providers.dart';
import '../../reviews/data/reviews_repository.dart';

class StylistScreen extends ConsumerWidget {
  const StylistScreen({super.key, required this.stylistId});

  final String stylistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final found = MockData.stylists.where((s) => s.id == stylistId);
    if (found.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Stylist not found')),
      );
    }
    final s = found.first;
    final rating = ref.watch(stylistRatingsProvider).value?[s.id];
    final hasServices = ref.watch(
      selectedServicesProvider.select((l) => l.isNotEmpty),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
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
                  const SizedBox(height: 2),
                  Text(s.role, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: AppColors.champagneDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating == null
                            ? 'New  ·  ${s.experienceYears} years experience'
                            : '${rating.average.toStringAsFixed(1)} (${rating.count} verified)  ·  ${s.experienceYears} years',
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  if (s.bio.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(s.bio, style: theme.textTheme.bodyLarge),
                  ],
                  if (s.specialties.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('Specialties', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final t in s.specialties)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                              border: Border.all(color: AppColors.beige),
                            ),
                            child: Text(t, style: theme.textTheme.titleSmall),
                          ),
                      ],
                    ),
                  ],
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
          child: AppButton(
            label: hasServices
                ? 'Book with ${s.name.split(' ').first}'
                : 'Choose services first',
            onPressed: () {
              if (hasServices) {
                ref.read(bookingStylistProvider.notifier).select(s.id);
                context.push(AppRoutes.booking);
              } else {
                context.go(AppRoutes.explore);
              }
            },
          ),
        ),
      ),
    );
  }
}
