import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_data.dart';
import '../../../data/models/catalog_models.dart';

class SelectedBranch extends Notifier<SalonBranch> {
  @override
  SalonBranch build() => MockData.branches.first;

  void select(SalonBranch branch) => state = branch;
}

final selectedBranchProvider = NotifierProvider<SelectedBranch, SalonBranch>(
  SelectedBranch.new,
);

/// In-memory for now. Persisted to Supabase in the backend phase.
class FavouriteStylists extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
  }
}

final favouriteStylistsProvider =
    NotifierProvider<FavouriteStylists, Set<String>>(FavouriteStylists.new);
