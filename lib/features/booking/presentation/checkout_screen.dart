import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/appointment.dart';
import '../../appointments/data/appointments_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../explore/application/explore_providers.dart';
import '../../home/application/home_providers.dart';
import '../application/booking_providers.dart';
import '../application/checkout_providers.dart';
import '../data/payment_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _couponCtrl = TextEditingController();
  String? _couponError;
  bool _confirming = false;
  bool _payOnline = false;
  late final Razorpay _razorpay;
  String? _payingAppointmentId;
  String? _payingOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _razorpay.clear();
    _couponCtrl.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final err = ref
        .read(appliedCouponProvider.notifier)
        .apply(_couponCtrl.text);
    setState(() => _couponError = err);
    if (err == null) {
      HapticFeedback.lightImpact();
      _couponCtrl.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    final id = _payingAppointmentId;
    final orderId = _payingOrderId;
    if (id == null ||
        orderId == null ||
        r.paymentId == null ||
        r.signature == null) {
      return _fail('Payment response was incomplete. Check your appointments.');
    }
    try {
      await ref
          .read(paymentRepositoryProvider)
          .verify(
            appointmentId: id,
            orderId: orderId,
            paymentId: r.paymentId!,
            signature: r.signature!,
          );
      ref.invalidate(appointmentsProvider);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.go(AppRoutes.confirmedPath(id));
      _resetBooking();
    } on PaymentException catch (e) {
      ref.invalidate(appointmentsProvider);
      _fail(e.message);
    } catch (_) {
      ref.invalidate(appointmentsProvider);
      _fail('Could not confirm payment. Check your appointments shortly.');
    }
  }

  void _onPaymentError(PaymentFailureResponse r) {
    ref.invalidate(appointmentsProvider);
    _fail('Payment was not completed. Your slot is held for a few minutes.');
  }

  void _resetBooking() {
    ref.read(selectedServicesProvider.notifier).clear();
    ref.read(bookingStylistProvider.notifier).select(null);
    ref.read(appliedCouponProvider.notifier).remove();
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final summary = ref.read(bookingSummaryProvider);
    final slot = ref.read(bookingSlotProvider);
    if (slot == null || summary.isEmpty) {
      setState(() => _confirming = false);
      return;
    }
    final price = ref.read(priceProvider);
    final coupon = ref.read(appliedCouponProvider);
    final stylistId = ref.read(bookingStylistProvider);

    final draft = Appointment(
      id: 'BMG-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      branchName: ref.read(selectedBranchProvider).name,
      stylistName: '',
      serviceNames: [for (final s in summary.services) s.name],
      start: slot,
      durationMin: summary.totalDuration,
      subtotal: price.subtotal,
      discount: price.discount,
      tax: price.tax,
      total: price.total,
      paymentMethod: _payOnline ? 'Online' : 'Pay at salon',
      couponCode: coupon?.code,
    );

    try {
      final saved = await ref
          .read(appointmentsProvider.notifier)
          .book(
            draft,
            stylistId: stylistId,
            serviceIds: [for (final s in summary.services) s.id],
          );
      if (!mounted) return;

      if (!_payOnline) {
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.confirmedPath(saved.id));
        _resetBooking();
        return;
      }

      final order = await ref
          .read(paymentRepositoryProvider)
          .createOrder(saved.id);
      _payingAppointmentId = saved.id;
      _payingOrderId = order.orderId;
      _razorpay.open({
        'key': order.keyId,
        'order_id': order.orderId,
        'amount': order.amount,
        'currency': 'INR',
        'name': 'BookMyGroom',
        'description': 'Appointment ${saved.id}',
        'prefill': {'email': ref.read(currentUserProvider)?.email ?? ''},
        'theme': {'color': '#C9A96E'},
      });
      if (mounted) setState(() => _confirming = false);
    } on BookingException catch (e) {
      _fail(e.message);
    } on PaymentException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Could not book. Check your connection and try again.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _confirming = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ref.watch(bookingSummaryProvider);
    final slot = ref.watch(bookingSlotProvider);
    final price = ref.watch(priceProvider);
    final coupon = ref.watch(appliedCouponProvider);

    if (summary.isEmpty || slot == null) {
      return Scaffold(appBar: AppBar(title: const Text('Checkout')));
    }

    Widget row(String label, String value, {bool bold = false, Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: bold
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              value,
              style:
                  (bold
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(color: color ?? AppColors.ink),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          120,
        ),
        children: [
          Text(
            DateFormat('EEEE, d MMMM  ·  h:mm a').format(slot),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            ref.watch(selectedBranchProvider).name,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Order summary', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final s in summary.services) row(s.name, formatPrice(s.price)),
          const Divider(height: 28),
          row('Subtotal', formatPrice(price.subtotal)),
          if (price.discount > 0)
            row(
              'Discount (${coupon?.code})',
              '- ${formatPrice(price.discount)}',
              color: AppColors.success,
            ),
          row('GST (18%)', formatPrice(price.tax)),
          const Divider(height: 28),
          row('Total', formatPrice(price.total), bold: true),
          const SizedBox(height: AppSpacing.lg),
          Text('Coupon', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          if (coupon != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${coupon.code}: ${coupon.label}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(appliedCouponProvider.notifier).remove(),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            )
          else
            TextField(
              controller: _couponCtrl,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _applyCoupon(),
              decoration: InputDecoration(
                hintText: 'Enter code',
                errorText: _couponError,
                suffixIcon: TextButton(
                  onPressed: _applyCoupon,
                  child: const Text('Apply'),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('Payment', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          _PayOption(
            icon: Icons.storefront_outlined,
            title: 'Pay at salon',
            subtitle: 'Pay after your service',
            selected: !_payOnline,
            onTap: () => setState(() => _payOnline = false),
          ),
          const SizedBox(height: AppSpacing.xs),
          _PayOption(
            icon: Icons.credit_card_outlined,
            title: 'Pay online',
            subtitle: 'UPI, cards and netbanking. Slot held for 10 minutes.',
            selected: _payOnline,
            onTap: () => setState(() => _payOnline = true),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Free cancellation up to 4 hours before your appointment (demo policy). Prices shown are estimates until server-side pricing is added.',
            style: theme.textTheme.bodySmall,
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
            label: _payOnline
                ? 'Pay  ·  ${formatPrice(price.total)}'
                : 'Confirm booking  ·  ${formatPrice(price.total)}',
            isLoading: _confirming,
            onPressed: _confirm,
          ),
        ),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.champagne : AppColors.beige,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.champagneDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
