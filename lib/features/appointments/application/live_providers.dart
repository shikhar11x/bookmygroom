import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/appointment.dart';
import '../../booking/application/checkout_providers.dart';

/// Guests checked in ahead of this one. Null when not currently checked in.
final queueAheadProvider = FutureProvider.autoDispose.family<int?, String>((
  ref,
  id,
) async {
  // Re-runs whenever this appointment's own status changes.
  ref.watch(appointmentByIdProvider(id));
  final r = await Supabase.instance.client.rpc(
    'queue_ahead',
    params: {'p_id': id},
  );
  return r as int?;
});

/// Today's live queue for staff (RLS returns all rows only to staff).
final staffQueueProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  return Supabase.instance.client
      .from('appointments')
      .stream(primaryKey: ['id'])
      .order('start_at')
      .map((rows) {
        final now = DateTime.now();
        const live = {
          AppointmentStatus.confirmed,
          AppointmentStatus.checkedIn,
          AppointmentStatus.inService,
        };
        return rows
            .map(Appointment.fromRow)
            .where(
              (a) =>
                  live.contains(a.status) &&
                  a.start.year == now.year &&
                  a.start.month == now.month &&
                  a.start.day == now.day,
            )
            .toList();
      });
});
