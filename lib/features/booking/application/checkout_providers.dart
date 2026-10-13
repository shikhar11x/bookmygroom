import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/appointment.dart';
import '../../appointments/data/appointments_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../explore/application/explore_providers.dart';

/// MOCK coupon rules. Real validation moves to the server later.
class Coupon {
  const Coupon({
    required this.code,
    required this.label,
    required this.percent,
    required this.maxDiscount,
    this.categoryId,
    this.appliesTo,
  });
  final String code;
  final String label;
  final int percent;
  final int maxDiscount;
  final String? categoryId;
  final String? appliesTo;
}

const _coupons = <Coupon>[
  Coupon(
    code: 'WELCOME20',
    label: '20% off, up to ₹500',
    percent: 20,
    maxDiscount: 500,
  ),
  Coupon(
    code: 'GLOW15',
    label: '15% off facials, up to ₹400',
    percent: 15,
    maxDiscount: 400,
    categoryId: 'facial',
    appliesTo: 'facial services',
  ),
];

class AppliedCoupon extends Notifier<Coupon?> {
  @override
  Coupon? build() => null;

  /// Returns an error message, or null on success.
  String? apply(String raw) {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return 'Enter a coupon code';
    final match = _coupons.where((c) => c.code == code);
    if (match.isEmpty) return 'This code is not valid';
    final c = match.first;
    if (c.categoryId != null) {
      final ok = ref
          .read(bookingSummaryProvider)
          .services
          .any((s) => s.categoryId == c.categoryId);
      if (!ok) return '$code applies only to ${c.appliesTo}';
    }
    state = c;
    return null;
  }

  void remove() => state = null;
}

final appliedCouponProvider = NotifierProvider<AppliedCoupon, Coupon?>(
  AppliedCoupon.new,
);

class PriceBreakdown {
  const PriceBreakdown(this.subtotal, this.discount, this.tax);
  final int subtotal;
  final int discount;
  final int tax;
  int get total => subtotal - discount + tax;
}

const _gstPercent = 18;

final priceProvider = Provider<PriceBreakdown>((ref) {
  final summary = ref.watch(bookingSummaryProvider);
  final coupon = ref.watch(appliedCouponProvider);
  final subtotal = summary.totalPrice;
  var discount = 0;
  if (coupon != null) {
    final eligible = coupon.categoryId == null
        ? subtotal
        : summary.services
              .where((s) => s.categoryId == coupon.categoryId)
              .fold(0, (sum, s) => sum + s.price);
    discount = math.min(
      (eligible * coupon.percent / 100).round(),
      coupon.maxDiscount,
    );
  }
  final tax = ((subtotal - discount) * _gstPercent / 100).round();
  return PriceBreakdown(subtotal, discount, tax);
});

class AppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
  AppointmentsRepository get _repo => ref.read(appointmentsRepositoryProvider);

  @override
  Future<List<Appointment>> build() async {
    // Re-runs when the signed-in user changes, so lists never leak across users.
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    return _repo.fetchMine();
  }

  Future<Appointment> book(
    Appointment draft, {
    required String? stylistId,
    required List<String> serviceIds,
  }) async {
    final saved = await _repo.book(
      draft,
      stylistId: stylistId,
      serviceIds: serviceIds,
    );
    final current = state.value ?? const <Appointment>[];
    state = AsyncData([saved, ...current.where((a) => a.id != saved.id)]);
    return saved;
  }

  Future<void> cancel(String id) async {
    final updated = await _repo.cancel(id);
    final current = state.value ?? const <Appointment>[];
    state = AsyncData([for (final a in current) a.id == id ? updated : a]);
  }
}

final appointmentsProvider =
    AsyncNotifierProvider<AppointmentsNotifier, List<Appointment>>(
      AppointmentsNotifier.new,
    );

final appointmentByIdProvider = Provider.family<Appointment?, String>((
  ref,
  id,
) {
  final list = ref.watch(appointmentsProvider).value ?? const <Appointment>[];
  for (final a in list) {
    if (a.id == id) return a;
  }
  return null;
});
