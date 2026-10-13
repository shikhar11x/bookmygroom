import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/appointment.dart';
import '../data/appointments_repository.dart';
import '../../booking/application/checkout_providers.dart';

class PassScreen extends ConsumerWidget {
  const PassScreen({super.key, required this.appointmentId});

  final String appointmentId;

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    Appointment a,
  ) async {
    if (a.start.difference(DateTime.now()) < const Duration(hours: 4)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Free cancellation closes 4 hours before the appointment.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(appointmentsProvider.notifier).cancel(a.id);
      } on BookingException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final a = ref.watch(appointmentByIdProvider(appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment pass'),
        leading: BackButton(
          onPressed: () => context.go(AppRoutes.appointments),
        ),
      ),
      body: a == null
          ? const Center(child: Text('Appointment not found'))
          : ListView(
              padding: AppSpacing.screenInsets,
              children: [
                Container(
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
                              'BOOKMYGROOM',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.champagne,
                              ),
                            ),
                          ),
                          StatusBadge(status: a.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        DateFormat('EEEE, d MMMM').format(a.start),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.ivory,
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(a.start),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.champagne,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: QrImageView(
                            data: 'bmg:${a.id}',
                            size: 190,
                            version: QrVersions.auto,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Text(
                          a.id,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.ivory,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Line('Studio', a.branchName),
                _Line('Stylist', a.stylistName),
                _Line('Duration', formatDuration(a.durationMin)),
                _Line(
                  'Payment',
                  '${a.paymentMethod}  ·  ${formatPrice(a.total)}',
                ),
                const Divider(height: 28),
                Text('Services', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                for (final n in a.serviceNames)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(n, style: theme.textTheme.bodyMedium),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Show this QR at reception. Secure check-in validation arrives with the backend.',
                  style: theme.textTheme.bodySmall,
                ),
                if (a.status == AppointmentStatus.confirmed &&
                    a.end.isAfter(DateTime.now())) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Cancel appointment',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _cancel(context, ref, a),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: theme.textTheme.titleSmall)),
        ],
      ),
    );
  }
}
