import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/appointment.dart';
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

const _appointmentsKey = 'appointments';

class AppointmentsNotifier extends Notifier<List<Appointment>> {
  @override
  List<Appointment> build() {
    final raw = ref
        .watch(sharedPreferencesProvider)
        .getString(_appointmentsKey);
    if (raw == null) return [];
    try {
      return Appointment.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> _save() => ref
      .read(sharedPreferencesProvider)
      .setString(_appointmentsKey, Appointment.encodeList(state));

  /// Local check only. Real stylist double-booking checks happen on the server.
  bool hasConflict(DateTime start, int durationMin) {
    final end = start.add(Duration(minutes: durationMin));
    return state.any(
      (a) =>
          a.status == AppointmentStatus.confirmed &&
          start.isBefore(a.end) &&
          end.isAfter(a.start),
    );
  }

  Future<Appointment?> add(Appointment a) async {
    if (hasConflict(a.start, a.durationMin)) return null;
    state = [...state, a];
    await _save();
    return a;
  }

  Future<void> cancel(String id) async {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(status: AppointmentStatus.cancelled) else a,
    ];
    await _save();
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, List<Appointment>>(
      AppointmentsNotifier.new,
    );

final appointmentByIdProvider = Provider.family<Appointment?, String>((
  ref,
  id,
) {
  for (final a in ref.watch(appointmentsProvider)) {
    if (a.id == id) return a;
  }
  return null;
});
