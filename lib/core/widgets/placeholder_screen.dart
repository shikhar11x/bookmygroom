import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Temporary elegant screen used until each feature is built in later phases.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenInsets,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.champagneDark),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(eyebrow.toUpperCase(), style: theme.textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(title, style: theme.textTheme.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
