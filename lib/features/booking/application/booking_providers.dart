import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../explore/application/explore_providers.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// null means "Any available stylist".
class BookingStylist extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) {
    state = id;
    ref.read(bookingSlotProvider.notifier).clear();
  }
}

final bookingStylistProvider = NotifierProvider<BookingStylist, String?>(
  BookingStylist.new,
);

class BookingDate extends Notifier<DateTime> {
  @override
  DateTime build() => _day(DateTime.now());

  void select(DateTime d) {
    state = _day(d);
    ref.read(bookingSlotProvider.notifier).clear();
  }
}

final bookingDateProvider = NotifierProvider<BookingDate, DateTime>(
  BookingDate.new,
);

class BookingSlot extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime t) => state = t;
  void clear() => state = null;
}

final bookingSlotProvider = NotifierProvider<BookingSlot, DateTime?>(
  BookingSlot.new,
);

class Slot {
  const Slot(this.time, this.available);
  final DateTime time;
  final bool available;
}

/// MOCK availability. Replaced by server-side availability and
/// conflict checks in the backend phase.
final slotsProvider = Provider<List<Slot>>((ref) {
  final date = ref.watch(bookingDateProvider);
  final stylist = ref.watch(bookingStylistProvider) ?? 'any';
  final duration = ref.watch(bookingSummaryProvider).totalDuration;
  final now = DateTime.now();
  final close = DateTime(date.year, date.month, date.day, 21);
  final stylistSeed = stylist.codeUnits.fold<int>(0, (a, b) => a + b);

  final slots = <Slot>[];
  for (
    var t = DateTime(date.year, date.month, date.day, 10);
    t.isBefore(close);
    t = t.add(const Duration(minutes: 30))
  ) {
    final fits = !t.add(Duration(minutes: duration)).isAfter(close);
    final isFuture = t.isAfter(now.add(const Duration(minutes: 30)));
    final seed =
        date.day * 31 + t.hour * 7 + (t.minute ~/ 30) * 13 + stylistSeed;
    final booked = seed % (stylist == 'any' ? 6 : 4) == 0;
    slots.add(Slot(t, fits && isFuture && !booked));
  }
  return slots;
});
