import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../data/models/appointment.dart';
import '../../../booking/application/booking_providers.dart';
import '../../../booking/application/checkout_providers.dart';
import '../../../explore/application/explore_providers.dart';

/// "Book again" for the most recent completed visit. Hidden when none exists.
class RebookSection extends ConsumerWidget {
  const RebookSection({super.key});

  void _rebook(BuildContext context, WidgetRef ref, Appointment a) {
    final services = [
      for (final name in a.serviceNames)
        ...MockData.services.where((s) => s.name == name),
    ];
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Those services are no longer available.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final picked = ref.read(selectedServicesProvider.notifier)..clear();
    for (final s in services) {
      picked.toggle(s);
    }
    final stylist = MockData.stylists
        .where((s) => s.name == a.stylistName)
        .firstOrNull;
    ref.read(bookingStylistProvider.notifier).select(stylist?.id);
    context.push(AppRoutes.booking);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(appointmentsProvider).value ?? const <Appointment>[];
    final done =
        list.where((a) => a.status == AppointmentStatus.completed).toList()
          ..sort((a, b) => b.start.compareTo(a.start));
    if (done.isEmpty) return const SizedBox.shrink();

    final a = done.first;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(eyebrow: 'Last visit', title: 'Book again'),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: AppSpacing.screenInsets,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.beige),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.serviceNames.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${a.stylistName}  ·  ${formatPrice(a.total)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Book again',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _rebook(context, ref, a),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
