import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/fade_in_up.dart';
import '../../../core/widgets/section_header.dart';
import 'widgets/category_row.dart';
import 'widgets/hero_banner.dart';
import 'widgets/home_header.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/offers_rail.dart';
import 'widgets/stylist_rail.dart';
import 'widgets/treatment_rail.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void toExplore() => context.go(AppRoutes.explore);
    const gap = SizedBox(height: 36);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            const FadeInUp(child: HomeHeader()),
            const SizedBox(height: 20),
            const FadeInUp(
              delay: Duration(milliseconds: 80),
              child: HomeSearchBar(),
            ),
            const SizedBox(height: 24),
            const FadeInUp(
              delay: Duration(milliseconds: 160),
              child: HeroBanner(),
            ),
            gap,
            SectionHeader(
              eyebrow: 'Services',
              title: 'Browse by category',
              actionLabel: 'See all',
              onAction: toExplore,
            ),
            const SizedBox(height: AppSpacing.md),
            const CategoryRow(),
            gap,
            SectionHeader(
              eyebrow: 'Most loved',
              title: 'Popular treatments',
              actionLabel: 'See all',
              onAction: toExplore,
            ),
            const SizedBox(height: AppSpacing.md),
            const TreatmentRail(),
            gap,
            SectionHeader(
              eyebrow: 'Our artists',
              title: 'Featured stylists',
              actionLabel: 'See all',
              onAction: toExplore,
            ),
            const SizedBox(height: AppSpacing.md),
            const StylistRail(),
            gap,
            const SectionHeader(eyebrow: 'For you', title: 'Exclusive offers'),
            const SizedBox(height: AppSpacing.md),
            const OffersRail(),
          ],
        ),
      ),
    );
  }
}
