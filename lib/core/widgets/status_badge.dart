import 'package:flutter/material.dart';

import '../../data/models/appointment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AppointmentStatus status;

  (String, Color) get _style {
    switch (status) {
      case AppointmentStatus.pendingPayment:
        return ('Awaiting payment', AppColors.warning);
      case AppointmentStatus.confirmed:
        return ('Confirmed', AppColors.success);
      case AppointmentStatus.checkedIn:
        return ('Checked in', AppColors.champagneDark);
      case AppointmentStatus.inService:
        return ('In service', AppColors.champagneDark);
      case AppointmentStatus.completed:
        return ('Completed', AppColors.taupe);
      case AppointmentStatus.cancelled:
        return ('Cancelled', AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
