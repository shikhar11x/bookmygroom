import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    eyebrow: 'Profile',
    title: 'Your account',
    message: 'Profile, receipts and preferences arrive in a later phase.',
    icon: Icons.person_outline,
  );
}
