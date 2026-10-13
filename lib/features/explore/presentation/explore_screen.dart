import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/fade_in_up.dart';
import '../application/explore_providers.dart';
import 'widgets/booking_summary_bar.dart';
import 'widgets/category_chips.dart';
import 'widgets/service_tile.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final services = ref.watch(filteredServicesProvider);
    final hasSelection = ref.watch(
      selectedServicesProvider.select((s) => s.isNotEmpty),
    );

    // Keep the field in sync when Home sets the query from outside.
    ref.listen<String>(searchQueryProvider, (_, next) {
      if (_controller.text != next) _controller.text = next;
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EXPLORE', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Discover services',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: AppSpacing.screenInsets,
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) =>
                        ref.read(searchQueryProvider.notifier).set(v),
                    decoration: InputDecoration(
                      hintText: 'Search services',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.taupe,
                      ),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _controller.clear();
                                ref.read(searchQueryProvider.notifier).set('');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const CategoryChips(),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: services.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            4,
                            AppSpacing.screenPadding,
                            hasSelection ? 110 : AppSpacing.xl,
                          ),
                          itemCount: services.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) => FadeInUp(
                            key: ValueKey(services[i].id),
                            delay: Duration(milliseconds: 40 * (i % 6)),
                            child: ServiceTile(service: services[i]),
                          ),
                        ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BookingSummaryBar(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screenInsets,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.champagneDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No services found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Try a different search or category.',
              style: theme.textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).set('');
                ref.read(exploreCategoryProvider.notifier).select(null);
              },
              child: Text('Reset filters', style: theme.textTheme.titleSmall),
            ),
          ],
        ),
      ),
    );
  }
}
