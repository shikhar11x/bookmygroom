import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/qr_repository.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/appointment.dart';
import '../data/appointments_repository.dart';
import '../../booking/application/checkout_providers.dart';
import '../application/live_providers.dart';
import '../../reviews/data/reviews_repository.dart';

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
                          child: Consumer(
                            builder: (context, ref, _) {
                              if (a.status != AppointmentStatus.confirmed) {
                                return const SizedBox(
                                  width: 190,
                                  height: 190,
                                  child: Center(
                                    child: Text(
                                      'QR is shown only for\nconfirmed bookings',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
                              final token = ref.watch(qrTokenProvider(a.id));
                              return token.when(
                                loading: () => const SizedBox(
                                  width: 190,
                                  height: 190,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (e, _) => SizedBox(
                                  width: 190,
                                  height: 190,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        e.toString(),
                                        textAlign: TextAlign.center,
                                      ),
                                      TextButton(
                                        onPressed: () => ref.invalidate(
                                          qrTokenProvider(a.id),
                                        ),
                                        child: const Text('Try again'),
                                      ),
                                    ],
                                  ),
                                ),
                                data: (t) => GestureDetector(
                                  // Debug only: copy the code to test manual entry.
                                  onLongPress: kDebugMode
                                      ? () => Clipboard.setData(
                                          ClipboardData(text: t),
                                        )
                                      : null,
                                  child: QrImageView(
                                    data: t,
                                    size: 190,
                                    version: QrVersions.auto,
                                  ),
                                ),
                              );
                            },
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
                _LiveStatus(a),
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
                  'Show this QR at reception. Check-in opens 1 hour before your appointment.',
                  style: theme.textTheme.bodySmall,
                ),
                if (a.status == AppointmentStatus.completed) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Consumer(
                    builder: (context, ref, _) {
                      final reviewed = ref.watch(reviewedProvider(a.id));
                      return reviewed.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (done) => done
                            ? Text(
                                'Thanks for your review.',
                                style: theme.textTheme.titleSmall,
                              )
                            : AppButton(
                                label: 'Rate your visit',
                                onPressed: () =>
                                    context.push(AppRoutes.reviewPath(a.id)),
                              ),
                      );
                    },
                  ),
                ],
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

class _LiveStatus extends ConsumerWidget {
  const _LiveStatus(this.a);
  final Appointment a;

  static const _steps = [
    (AppointmentStatus.confirmed, 'Confirmed'),
    (AppointmentStatus.checkedIn, 'Checked in'),
    (AppointmentStatus.inService, 'In service'),
    (AppointmentStatus.completed, 'Completed'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (a.status == AppointmentStatus.cancelled ||
        a.status == AppointmentStatus.pendingPayment) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final current = _steps.indexWhere((s) => s.$1 == a.status);

    String? queueText;
    if (a.status == AppointmentStatus.checkedIn) {
      final ahead = ref.watch(queueAheadProvider(a.id)).value;
      if (ahead != null) {
        queueText = ahead == 0
            ? "You're next. Please stay nearby."
            : '$ahead ${ahead == 1 ? 'guest is' : 'guests are'} ahead of you.';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _steps.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= current ? AppColors.ink : AppColors.beige,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _steps[i].$2,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: i == current ? AppColors.ink : AppColors.taupe,
                        fontWeight: i == current
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (queueText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(queueText, style: theme.textTheme.titleSmall),
        ],
      ],
    );
  }
}
