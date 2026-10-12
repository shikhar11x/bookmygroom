import 'package:bookmygroom/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shell shows five navigation destinations', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BookMyGroomApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Discover services'), findsOneWidget);
  });
}
