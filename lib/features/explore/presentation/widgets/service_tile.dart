import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../data/models/catalog_models.dart';
import '../../application/explore_providers.dart';

class ServiceTile extends ConsumerWidget {
  const ServiceTile({super.key, required this.service});

  final Service service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(
      selectedServicesProvider.select((ids) => ids.contains(service.id)),
    );

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${service.name}, ${formatPrice(service.price)}, ${formatDuration(service.durationMin)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          final replaced = ref
              .read(selectedServicesProvider.notifier)
              .toggle(service);
          if (replaced != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Replaced $replaced with ${service.name}'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
          }
        },
        child: AnimatedContainer(
          duration: AppSpacing.fast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 4),
            border: Border.all(
              color: selected ? AppColors.champagne : AppColors.beige,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: AppNetworkImage(
                  url: service.imageUrl,
                  radius: AppSpacing.radiusSm + 2,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatPrice(service.price)}  ·  ${formatDuration(service.durationMin)}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedContainer(
                duration: AppSpacing.fast,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.ink : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.ink : AppColors.taupeLight,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: AppSpacing.fast,
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.add_rounded,
                    key: ValueKey(selected),
                    size: 18,
                    color: selected ? AppColors.ivory : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
