import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/appointment.dart';
import '../../booking/application/checkout_providers.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final all = ref.watch(appointmentsProvider);
    final now = DateTime.now();

    final upcoming =
        all
            .where(
              (a) =>
                  a.status == AppointmentStatus.confirmed && a.end.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final past = all.where((a) => !upcoming.contains(a)).toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    return Scaffold(
      body: SafeArea(
        child: all.isEmpty
            ? Center(
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
                          Icons.calendar_today_outlined,
                          color: AppColors.champagneDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No appointments yet',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your bookings will appear here.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Book a service',
                        expand: false,
                        onPressed: () => context.go(AppRoutes.explore),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                ),
                children: [
                  Text('APPOINTMENTS', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text('Your bookings', style: theme.textTheme.headlineMedium),
                  if (upcoming.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('Upcoming', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    for (final a in upcoming) _Tile(a),
                  ],
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Past and cancelled',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final a in past) _Tile(a),
                  ],
                ],
              ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.a);
  final Appointment a;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(AppRoutes.passPath(a.id)),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.beige),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEE, d MMM  ·  h:mm a').format(a.start),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(status: a.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                a.serviceNames.join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '${a.branchName}  ·  ${formatPrice(a.total)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
