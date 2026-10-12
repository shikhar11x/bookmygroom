import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return Padding(
      padding: AppSpacing.screenInsets,
      child: AnimatedContainer(
        duration: AppSpacing.medium,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: focused ? AppColors.ivory : AppColors.cream,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: focused ? AppColors.champagne : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: AppColors.champagne.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: TextField(
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            _focus.unfocus();
            // Query is passed to Explore in Phase 3.
            context.go(AppRoutes.explore);
          },
          decoration: const InputDecoration(
            hintText: 'Search haircuts, facials, stylists',
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.taupe),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
