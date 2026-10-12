import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    eyebrow: 'Rewards',
    title: 'Loyalty & offers',
    message: 'Points, memberships and offers arrive in a later phase.',
    icon: Icons.workspace_premium_outlined,
  );
}
