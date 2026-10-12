import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    eyebrow: 'Appointments',
    title: 'Your bookings',
    message: 'Upcoming and past appointments arrive with the booking phase.',
    icon: Icons.calendar_today_outlined,
  );
}
