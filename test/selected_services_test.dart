import 'package:bookmygroom/data/mock/mock_data.dart';
import 'package:bookmygroom/data/models/catalog_models.dart';
import 'package:bookmygroom/features/explore/application/explore_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Service _byId(String id) => MockData.services.firstWhere((s) => s.id == id);

void main() {
  test('totals add up and exclusive services are replaced', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectedServicesProvider.notifier);

    notifier.toggle(_byId('sv_cut'));
    notifier.toggle(_byId('sv_beard'));
    var summary = container.read(bookingSummaryProvider);
    expect(summary.totalPrice, 899 + 599);
    expect(summary.totalDuration, 45 + 30);

    // Same exclusive group ('beard') replaces the earlier pick.
    final replaced = notifier.toggle(_byId('sv_shave'));
    expect(replaced, 'Beard Sculpt & Shave');
    summary = container.read(bookingSummaryProvider);
    expect(summary.services.length, 2);
    expect(summary.totalPrice, 899 + 449);

    // Toggling again deselects.
    notifier.toggle(_byId('sv_shave'));
    expect(container.read(selectedServicesProvider).length, 1);
  });
}
