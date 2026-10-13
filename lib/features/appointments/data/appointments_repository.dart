import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/appointment.dart';

class BookingException implements Exception {
  const BookingException(this.message);
  final String message;

  @override
  String toString() => message;
}

String _friendly(String raw) {
  if (raw.contains('slot_taken')) {
    return 'That time was just taken. Please pick another slot.';
  }
  if (raw.contains('user_overlap')) {
    return 'You already have an appointment at this time.';
  }
  if (raw.contains('in_past')) return 'Please choose a future time.';
  if (raw.contains('bad_coupon')) {
    return 'This coupon is not valid for your selection.';
  }
  if (raw.contains('bad_services')) {
    return 'Some selected services are not available together.';
  }
  if (raw.contains('bad_payment')) {
    return 'This payment method is not available yet.';
  }
  if (raw.contains('cancel_window')) {
    return 'Free cancellation closes 4 hours before the appointment.';
  }
  if (raw.contains('not_cancellable')) {
    return 'This appointment can no longer be cancelled.';
  }
  return 'Something went wrong. Please try again.';
}

class AppointmentsRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Appointment>> fetchMine() async {
    final rows = await _db
        .from('appointments')
        .select()
        .order('start_at', ascending: false);
    return rows.map<Appointment>(Appointment.fromRow).toList();
  }

  Future<Appointment> book(
    Appointment a, {
    required String? stylistId,
    required List<String> serviceIds,
  }) async {
    try {
      final row = await _db.rpc(
        'book_appointment',
        params: {
          'p_id': a.id,
          'p_branch_name': a.branchName,
          'p_stylist_id': stylistId,
          'p_service_ids': serviceIds,
          'p_start': a.start.toUtc().toIso8601String(),
          'p_coupon': a.couponCode,
          'p_payment_method': a.paymentMethod,
        },
      );
      return Appointment.fromRow(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // Same id sent twice (retry): return the booking that already exists.
      if (e.code == '23505') {
        final existing = await _db
            .from('appointments')
            .select()
            .eq('id', a.id)
            .single();
        return Appointment.fromRow(existing);
      }
      throw BookingException(_friendly(e.message));
    }
  }

  Future<Appointment> cancel(String id) async {
    try {
      final row = await _db.rpc('cancel_appointment', params: {'p_id': id});
      return Appointment.fromRow(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw BookingException(_friendly(e.message));
    }
  }
}

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>(
  (ref) => AppointmentsRepository(),
);
