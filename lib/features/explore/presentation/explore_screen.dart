import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    eyebrow: 'Explore',
    title: 'Discover services',
    message: 'Service discovery arrives in Phase 3.',
    icon: Icons.search,
  );
}
