import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_providers.dart';
import '../../booking/application/checkout_providers.dart';

class LoyaltyEntry {
  const LoyaltyEntry(this.points, this.reason, this.createdAt);
  final int points;
  final String reason;
  final DateTime createdAt;
}

class Tier {
  const Tier(this.name, this.minPoints);
  final String name;
  final int minPoints;
}

const tiers = [Tier('Member', 0), Tier('Silver', 100), Tier('Gold', 300)];

class LoyaltyStatus {
  const LoyaltyStatus(this.entries);
  final List<LoyaltyEntry> entries;

  int get balance => entries.fold(0, (s, e) => s + e.points);
  int get lifetime =>
      entries.where((e) => e.points > 0).fold(0, (s, e) => s + e.points);

  Tier get tier => tiers.lastWhere((t) => lifetime >= t.minPoints);
  Tier? get nextTier {
    final i = tiers.indexOf(tier);
    return i + 1 < tiers.length ? tiers[i + 1] : null;
  }
}

final loyaltyProvider = FutureProvider.autoDispose<LoyaltyStatus>((ref) async {
  ref.watch(currentUserProvider);
  // Reload whenever bookings change (e.g. a visit gets completed).
  ref.watch(appointmentsProvider);
  final rows = await Supabase.instance.client
      .from('loyalty_ledger')
      .select('points,reason,created_at')
      .order('created_at', ascending: false);
  return LoyaltyStatus([
    for (final r in rows)
      LoyaltyEntry(
        r['points'] as int,
        r['reason'] as String,
        DateTime.parse(r['created_at'] as String).toLocal(),
      ),
  ]);
});
