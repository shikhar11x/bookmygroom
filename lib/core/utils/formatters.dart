import 'package:intl/intl.dart';

String formatPrice(int price) =>
    '₹${NumberFormat.decimalPattern('en_IN').format(price)}';

String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h hr';
  return '$h hr $m min';
}
