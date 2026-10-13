import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../application/checkout_providers.dart';

class ConfirmationScreen extends ConsumerWidget {
  const ConfirmationScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final a = ref.watch(appointmentByIdProvider(appointmentId));
    final reduce = MediaQuery.of(context).disableAnimations;

    if (a == null) {
      return Scaffold(
        body: Center(
          child: AppButton(
            label: 'Go home',
            expand: false,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenInsets,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: reduce ? 1 : 0, end: 1),
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.champagne,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('BOOKING CONFIRMED', style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text("You're all set", style: theme.textTheme.displayMedium),
              const SizedBox(height: AppSpacing.lg),
              Text(
                DateFormat('EEEE, d MMMM  ·  h:mm a').format(a.start),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${a.branchName}  ·  ${a.stylistName}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text('Reference ${a.id}', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${a.paymentMethod}  ·  ${formatPrice(a.total)} due',
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              AppButton(
                label: 'View appointment pass',
                onPressed: () =>
                    context.pushReplacement(AppRoutes.passPath(a.id)),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Back to home',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.home),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
