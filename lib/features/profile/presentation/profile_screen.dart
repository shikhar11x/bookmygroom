import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../appointments/data/qr_repository.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/application/auth_providers.dart';
import '../../booking/application/checkout_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not sign out. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStaff = ref.watch(isStaffProvider).value ?? false;
    final user = ref.watch(currentUserProvider);
    final bookings = ref.watch(appointmentsProvider).value?.length ?? 0;
    final initial = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName[0].toUpperCase()
        : '?';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            Text('PROFILE', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text('Your account', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.champagne,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('My appointments'),
              subtitle: Text('$bookings total'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go(AppRoutes.appointments),
            ),
            const Divider(),
            if (isStaff) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.qr_code_scanner_rounded),
                title: const Text('Reception check-in'),
                subtitle: const Text('Scan guest passes'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.scan),
              ),
              const Divider(),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Sign out',
              variant: AppButtonVariant.secondary,
              isLoading: _signingOut,
              onPressed: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
