import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_spacing.dart';

/// Gentle entrance animation. Skipped entirely when reduced motion is on.
class FadeInUp extends StatelessWidget {
  const FadeInUp({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppSpacing.slow, curve: Curves.easeOut)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: AppSpacing.slow,
          curve: Curves.easeOut,
        );
  }
}
