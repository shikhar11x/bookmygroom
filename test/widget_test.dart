import 'package:bookmygroom/app.dart';
import 'package:bookmygroom/core/providers/app_providers.dart';
import 'package:bookmygroom/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Shell shows five navigation destinations', (tester) async {
    // Turn on reduced motion so entrance animations create no timers.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    // Mock storage, otherwise getInstance() waits forever in tests.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWithValue(
            const AppUser(id: 'test', email: 'test@example.com', name: 'Test'),
          ),
        ],
        child: const BookMyGroomApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    await tester.tap(find.text('Explore'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Discover services'), findsOneWidget);
  });
}
