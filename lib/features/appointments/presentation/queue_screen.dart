import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/appointment.dart';
import '../application/live_providers.dart';
import '../data/qr_repository.dart';
import '../data/staff_repository.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaff = ref.watch(isStaffProvider);
    final queue = ref.watch(staffQueueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's queue")),
      body: isStaff.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not verify access.')),
        data: (ok) {
          if (!ok) return const Center(child: Text('Staff access only.'));
          return queue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: AppButton(
                label: 'Try again',
                expand: false,
                onPressed: () => ref.invalidate(staffQueueProvider),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No appointments today.'));
              }
              return ListView.separated(
                padding: AppSpacing.screenInsets,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _QueueTile(items[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _QueueTile extends ConsumerStatefulWidget {
  const _QueueTile(this.a);
  final Appointment a;

  @override
  ConsumerState<_QueueTile> createState() => _QueueTileState();
}

class _QueueTileState extends ConsumerState<_QueueTile> {
  bool _busy = false;

  Future<void> _move(String status) async {
    setState(() => _busy = true);
    try {
      await ref.read(staffRepositoryProvider).setStatus(widget.a.id, status);
      HapticFeedback.mediumImpact();
    } on StaffException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.a;
    final action = switch (a.status) {
      AppointmentStatus.checkedIn => ('Start service', 'in_service'),
      AppointmentStatus.inService => ('Complete', 'completed'),
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.beige),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('h:mm a').format(a.start),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              StatusBadge(status: a.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(a.serviceNames.join(', '), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(
            '${a.stylistName}  ·  ${a.id}',
            style: theme.textTheme.bodySmall,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: action.$1,
              isLoading: _busy,
              onPressed: () => _move(action.$2),
            ),
          ],
        ],
      ),
    );
  }
}
