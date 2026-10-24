import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Tappable 1 to 5 star rating with a small pop animation.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: i == value,
            label: '$label: $i ${i == 1 ? 'star' : 'stars'}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedScale(
                  scale: i <= value && !reduce ? 1.12 : 1,
                  duration: AppSpacing.fast,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    i <= value
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 44,
                    color: i <= value
                        ? AppColors.champagne
                        : AppColors.taupeLight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
