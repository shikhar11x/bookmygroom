import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  const AppUser({required this.id, required this.email, this.name});
  final String id;
  final String email;
  final String? name;

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name!.trim() : email;
}

final authStateProvider = StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);

/// null means signed out. Tests override this provider directly.
final currentUserProvider = Provider<AppUser?>((ref) {
  ref.watch(authStateProvider);
  final u = Supabase.instance.client.auth.currentUser;
  if (u == null) return null;
  return AppUser(
    id: u.id,
    email: u.email ?? '',
    name: u.userMetadata?['full_name'] as String?,
  );
});

class AuthRepository {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  /// Returns true if the user is signed in immediately.
  /// False means email confirmation is still required.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
    return res.session != null;
  }

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
