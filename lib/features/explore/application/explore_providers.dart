import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_data.dart';
import '../../../data/models/catalog_models.dart';

class ExploreCategory extends Notifier<String?> {
  @override
  String? build() => null; // null means "All"

  void select(String? id) => state = id;
}

final exploreCategoryProvider = NotifierProvider<ExploreCategory, String?>(
  ExploreCategory.new,
);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

final filteredServicesProvider = Provider<List<Service>>((ref) {
  final category = ref.watch(exploreCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  return MockData.services.where((s) {
    if (category != null && s.categoryId != category) return false;
    if (query.isEmpty) return true;
    return s.name.toLowerCase().contains(query) ||
        s.description.toLowerCase().contains(query);
  }).toList();
});

/// Selected service ids, in the order they were picked.
class SelectedServices extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  /// Toggles a service. If it conflicts with an already-selected service
  /// in the same exclusive group, that one is replaced and its name returned.
  String? toggle(Service service) {
    if (state.contains(service.id)) {
      state = state.where((id) => id != service.id).toList();
      return null;
    }
    String? replacedName;
    var next = [...state];
    final group = service.exclusiveGroup;
    if (group != null) {
      final clash = MockData.services.where(
        (s) => s.exclusiveGroup == group && next.contains(s.id),
      );
      for (final c in clash) {
        replacedName = c.name;
        next.remove(c.id);
      }
    }
    next.add(service.id);
    state = next;
    return replacedName;
  }

  void remove(String id) => state = state.where((e) => e != id).toList();

  void clear() => state = [];
}

final selectedServicesProvider =
    NotifierProvider<SelectedServices, List<String>>(SelectedServices.new);

class BookingSummary {
  const BookingSummary(this.services);
  final List<Service> services;

  int get totalPrice => services.fold(0, (sum, s) => sum + s.price);
  int get totalDuration => services.fold(0, (sum, s) => sum + s.durationMin);
  bool get isEmpty => services.isEmpty;
}

final bookingSummaryProvider = Provider<BookingSummary>((ref) {
  final ids = ref.watch(selectedServicesProvider);
  final services = [
    for (final id in ids) MockData.services.firstWhere((s) => s.id == id),
  ];
  return BookingSummary(services);
});
