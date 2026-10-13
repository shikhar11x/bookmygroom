import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/mock/mock_data.dart';
import '../../explore/application/explore_providers.dart';
import '../application/booking_providers.dart';

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(bookingSummaryProvider);

    if (summary.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book appointment')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No services selected', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Choose services',
                expand: false,
                onPressed: () => context.go(AppRoutes.explore),
              ),
            ],
          ),
        ),
      );
    }

    final slot = ref.watch(bookingSlotProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          Padding(
            padding: AppSpacing.screenInsets,
            child: Text(
              '${summary.services.length} services  ·  ${formatDuration(summary.totalDuration)}  ·  ${formatPrice(summary.totalPrice)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Title('Choose your stylist', theme),
          const SizedBox(height: AppSpacing.sm),
          const _StylistPicker(),
          const SizedBox(height: AppSpacing.lg),
          _Title('Pick a date', theme),
          const SizedBox(height: AppSpacing.sm),
          const _DateStrip(),
          const SizedBox(height: AppSpacing.lg),
          _Title('Available times', theme),
          const SizedBox(height: AppSpacing.sm),
          const _SlotGrid(),
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
            label: slot == null
                ? 'Select a time'
                : 'Continue  ·  ${DateFormat('h:mm a').format(slot)}',
            onPressed: slot == null ? null : () => _showDraft(context, ref),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, this.theme);
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.screenInsets,
    child: Text(text, style: theme.textTheme.headlineSmall),
  );
}

class _StylistPicker extends ConsumerWidget {
  const _StylistPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(bookingStylistProvider);
    final entries = <(String?, String, String?)>[
      (null, 'Any available', null),
      for (final s in MockData.stylists) (s.id, s.name, s.imageUrl),
    ];
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenInsets,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final (id, name, url) = entries[i];
          final active = id == selected;
          return Semantics(
            button: true,
            selected: active,
            label: name,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(bookingStylistProvider.notifier).select(id);
              },
              child: SizedBox(
                width: 76,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: AppSpacing.fast,
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active
                              ? AppColors.champagne
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: url == null
                            ? Container(
                                color: AppColors.cream,
                                child: const Icon(
                                  Icons.auto_awesome_outlined,
                                  color: AppColors.champagneDark,
                                ),
                              )
                            : AppNetworkImage(url: url, radius: 0),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateStrip extends ConsumerWidget {
  const _DateStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(bookingDateProvider);
    final today = DateTime.now();
    final days = [
      for (var i = 0; i < 14; i++)
        DateTime(today.year, today.month, today.day + i),
    ];
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenInsets,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final d = days[i];
          final active = d == selected;
          return Semantics(
            button: true,
            selected: active,
            label: DateFormat('EEEE d MMMM').format(d),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(bookingDateProvider.notifier).select(d);
              },
              child: AnimatedContainer(
                duration: AppSpacing.fast,
                width: 56,
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: active ? AppColors.ink : AppColors.beige,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(d).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: active ? AppColors.taupeLight : AppColors.taupe,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: active ? AppColors.ivory : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlotGrid extends ConsumerWidget {
  const _SlotGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final slots = ref.watch(slotsProvider);
    final selected = ref.watch(bookingSlotProvider);

    if (!slots.any((s) => s.available)) {
      return Padding(
        padding: AppSpacing.screenInsets,
        child: Text(
          'No times left on this day. Try another date.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Padding(
      padding: AppSpacing.screenInsets,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final s in slots)
            Semantics(
              button: true,
              enabled: s.available,
              selected: s.time == selected,
              label: DateFormat('h:mm a').format(s.time),
              child: GestureDetector(
                onTap: s.available
                    ? () {
                        HapticFeedback.selectionClick();
                        ref.read(bookingSlotProvider.notifier).select(s.time);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: AppSpacing.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: s.time == selected
                        ? AppColors.ink
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: s.time == selected
                          ? AppColors.ink
                          : AppColors.beige,
                    ),
                  ),
                  child: Text(
                    DateFormat('h:mm a').format(s.time),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: s.time == selected
                          ? AppColors.ivory
                          : s.available
                          ? AppColors.ink
                          : AppColors.taupeLight,
                      decoration: s.available
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showDraft(BuildContext context, WidgetRef ref) {
  final summary = ref.read(bookingSummaryProvider);
  final slot = ref.read(bookingSlotProvider)!;
  final stylistId = ref.read(bookingStylistProvider);
  final stylist = stylistId == null
      ? 'Any available stylist'
      : MockData.stylists.firstWhere((s) => s.id == stylistId).name;
  final theme = Theme.of(context);

  showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(
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
            Text('Your appointment', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              DateFormat('EEEE, d MMMM  ·  h:mm a').format(slot),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(stylist, style: theme.textTheme.bodyMedium),
            const Divider(height: 28),
            for (final s in summary.services)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(s.name)),
                    Text(formatPrice(s.price)),
                  ],
                ),
              ),
            const Divider(height: 28),
            Row(
              children: [
                Text('Estimated total', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Text(
                  formatPrice(summary.totalPrice),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Payment and confirmation arrive in the next phase.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Close',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
