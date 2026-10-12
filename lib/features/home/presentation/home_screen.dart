import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    eyebrow: 'BookMyGroom',
    title: 'Good to see you',
    message: 'The editorial home experience arrives in Phase 2.',
    icon: Icons.home_outlined,
  );
}
