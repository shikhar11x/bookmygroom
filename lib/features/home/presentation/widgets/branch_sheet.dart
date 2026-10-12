import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/mock/mock_data.dart';
import '../../application/home_providers.dart';

Future<void> showBranchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _BranchSheet(),
  );
}

class _BranchSheet extends ConsumerWidget {
  const _BranchSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedBranchProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your studio', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final b in MockData.branches)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(b.name, style: theme.textTheme.titleMedium),
                subtitle: Text(b.area, style: theme.textTheme.bodySmall),
                trailing: b.id == selected.id
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.champagneDark,
                      )
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(selectedBranchProvider.notifier).select(b);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
