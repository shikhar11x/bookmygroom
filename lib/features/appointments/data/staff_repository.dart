import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffException implements Exception {
  const StaffException(this.message);
  final String message;

  @override
  String toString() => message;
}

class StaffRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<void> setStatus(String id, String status) async {
    try {
      await _db.rpc(
        'set_appointment_status',
        params: {'p_id': id, 'p_status': status},
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('bad_transition')) {
        throw const StaffException(
          'Status already changed. The list has been refreshed.',
        );
      }
      if (e.message.contains('not_staff')) {
        throw const StaffException('Staff access only.');
      }
      throw const StaffException('Could not update. Try again.');
    }
  }
}

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepository(),
);
