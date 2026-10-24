import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

/// True once the user has finished the intro screens in this app session.
/// Memory only, so the intro shows again on every fresh app start while
/// signed out. Signed-in users never see it (the router checks that).
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;

  void reset() => state = false;
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
