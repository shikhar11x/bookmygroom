import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/appointment.dart';
import '../../../booking/application/checkout_providers.dart';

/// Shows the next active booking. Renders nothing when there is none.
class UpcomingCard extends ConsumerWidget {
  const UpcomingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(appointmentsProvider).value ?? const <Appointment>[];
    final now = DateTime.now();
    const live = {
      AppointmentStatus.pendingPayment,
      AppointmentStatus.confirmed,
      AppointmentStatus.checkedIn,
      AppointmentStatus.inService,
    };
    final upcoming =
        list
            .where((a) => live.contains(a.status) && a.end.isAfter(now))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final a = upcoming.first;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: AppSpacing.screenInsets,
        child: PressableScale(
          onTap: () => context.push(AppRoutes.passPath(a.id)),
          child: Semantics(
            button: true,
            label:
                'Next appointment, ${DateFormat('EEEE d MMMM h:mm a').format(a.start)}',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'YOUR NEXT VISIT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.champagne,
                          ),
                        ),
                      ),
                      StatusBadge(status: a.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    DateFormat('EEEE, d MMMM').format(a.start),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.ivory,
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(a.start),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.champagne,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    a.serviceNames.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.taupeLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${a.branchName}  ·  ${a.stylistName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.taupeLight,
                          ),
                        ),
                      ),
                      Text(
                        'View pass',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.champagne,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.champagne,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
