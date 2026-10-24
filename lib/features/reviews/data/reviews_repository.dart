import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_providers.dart';

class ReviewException implements Exception {
  const ReviewException(this.message);
  final String message;

  @override
  String toString() => message;
}

class StylistRating {
  const StylistRating(this.average, this.count);
  final double average;
  final int count;
}

String _friendly(String raw) {
  if (raw.contains('already_reviewed')) {
    return 'You have already reviewed this appointment.';
  }
  if (raw.contains('not_completed')) {
    return 'You can review once the service is completed.';
  }
  if (raw.contains('not_found')) return 'Appointment not found.';
  return 'Could not send your review. Please try again.';
}

class ReviewsRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<String> uploadPhoto(File file, String userId) async {
    final isPng = file.path.toLowerCase().endsWith('.png');
    final ext = isPng ? 'png' : 'jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage
        .from('review-photos')
        .upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: isPng ? 'image/png' : 'image/jpeg',
          ),
        );
    return path;
  }

  Future<void> submit({
    required String appointmentId,
    required int serviceRating,
    required int stylistRating,
    String? comment,
    String? photoPath,
  }) async {
    try {
      await _db.rpc(
        'submit_review',
        params: {
          'p_appointment_id': appointmentId,
          'p_service_rating': serviceRating,
          'p_stylist_rating': stylistRating,
          'p_comment': comment,
          'p_photo_path': photoPath,
        },
      );
    } on PostgrestException catch (e) {
      throw ReviewException(_friendly(e.message));
    }
  }

  Future<bool> hasReviewed(String appointmentId) async {
    final row = await _db
        .from('reviews')
        .select('id')
        .eq('appointment_id', appointmentId)
        .maybeSingle();
    return row != null;
  }

  Future<Map<String, StylistRating>> stylistRatings() async {
    final rows = await _db.rpc('stylist_ratings') as List;
    return {
      for (final r in rows)
        r['stylist_id'] as String: StylistRating(
          (r['average'] as num).toDouble(),
          r['review_count'] as int,
        ),
    };
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(),
);

final reviewedProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  id,
) {
  ref.watch(currentUserProvider);
  return ref.read(reviewsRepositoryProvider).hasReviewed(id);
});

final stylistRatingsProvider = FutureProvider<Map<String, StylistRating>>((
  ref,
) {
  ref.watch(currentUserProvider);
  return ref.read(reviewsRepositoryProvider).stylistRatings();
});
