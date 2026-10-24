import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_providers.dart';

class QrException implements Exception {
  const QrException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CheckInResult {
  const CheckInResult({
    required this.id,
    required this.customer,
    required this.stylist,
    required this.services,
    required this.start,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
  });

  final String id;
  final String customer;
  final String stylist;
  final List<String> services;
  final DateTime start;
  final String paymentMethod;
  final String paymentStatus;
  final int total;

  bool get dueAtSalon => paymentStatus != 'paid';
}

String _friendly(String? code) {
  switch (code) {
    case 'invalid_qr':
      return 'This QR code is not valid.';
    case 'expired':
      return 'This appointment has already ended.';
    case 'already_used':
      return 'Already checked in. This pass was used before.';
    case 'not_confirmed':
      return 'This appointment is not confirmed (cancelled or unpaid).';
    case 'too_early':
      return 'Too early. Check-in opens 1 hour before the appointment.';
    case 'not_staff':
      return 'Your account is not allowed to check guests in.';
    default:
      return 'Could not complete the request. Try again.';
  }
}

String? _codeOf(FunctionException e) =>
    e.details is Map ? (e.details as Map)['error'] as String? : null;

class QrRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<String> issueToken(String appointmentId) async {
    try {
      final res = await _db.functions
          .invoke('issue-qr-token', body: {'appointment_id': appointmentId});
      return (res.data as Map<String, dynamic>)['token'] as String;
    } on FunctionException catch (e) {
      throw QrException(_friendly(_codeOf(e)));
    }
  }

  Future<CheckInResult> checkIn(String token) async {
    try {
      final res = await _db.functions.invoke('check-in', body: {'token': token});
      final d = res.data as Map<String, dynamic>;
      return CheckInResult(
        id: d['id'] as String,
        customer: d['customer'] as String,
        stylist: d['stylist'] as String,
        services: List<String>.from(d['services'] as List),
        start: DateTime.parse(d['start_at'] as String).toLocal(),
        paymentMethod: d['payment_method'] as String,
        paymentStatus: d['payment_status'] as String,
        total: d['total'] as int,
      );
    } on FunctionException catch (e) {
      throw QrException(_friendly(_codeOf(e)));
    }
  }
}

final qrRepositoryProvider = Provider<QrRepository>((ref) => QrRepository());

final qrTokenProvider =
    FutureProvider.autoDispose.family<String, String>(
        (ref, id) => ref.read(qrRepositoryProvider).issueToken(id));

/// True only for accounts listed in the staff table.
final isStaffProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final row = await Supabase.instance.client
      .from('staff')
      .select('user_id')
      .maybeSingle();
  return row != null;
});