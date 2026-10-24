import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/explore_providers.dart';

Future<void> showReviewSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ReviewSheet(),
  );
}

class _ReviewSheet extends ConsumerWidget {
  const _ReviewSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(bookingSummaryProvider);

    // Close automatically once everything has been removed.
    if (summary.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your selection',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(selectedServicesProvider.notifier).clear(),
                    child: Text('Clear all', style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final s in summary.services)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.name, style: theme.textTheme.titleMedium),
                        subtitle: Text(
                          '${formatPrice(s.price)}  ·  ${formatDuration(s.durationMin)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove ${s.name}',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => ref
                              .read(selectedServicesProvider.notifier)
                              .remove(s.id),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Estimated total', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    '${formatPrice(summary.totalPrice)}  ·  ${formatDuration(summary.totalDuration)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Final price and taxes are confirmed at checkout.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Done',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
