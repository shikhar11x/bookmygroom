import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_network_image.dart';

class _OnboardingPage {
  const _OnboardingPage(this.imageUrl, this.eyebrow, this.title, this.body);
  final String imageUrl;
  final String eyebrow;
  final String title;
  final String body;
}

const _pages = <_OnboardingPage>[
  _OnboardingPage(
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=1200&q=75',
    'Welcome',
    'Where every visit\nfeels considered',
    'Discover a salon experience designed around you.',
  ),
  _OnboardingPage(
    'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=1200&q=75',
    'Our artists',
    'Crafted by\nmaster stylists',
    'Choose your stylist or let us match you with the best available.',
  ),
  _OnboardingPage(
    'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=1200&q=75',
    'Effortless',
    'Book in\nunder a minute',
    'Pick services, a time that suits you, and walk right in.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await ref.read(onboardingProvider.notifier).complete();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: AppSpacing.medium,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final page = _pages[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(url: page.imageUrl, radius: 0),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.3, 1],
                          colors: [Colors.transparent, Color(0xEB0E0D0C)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        0,
                        AppSpacing.screenPadding,
                        190,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            page.eyebrow.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.champagne,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            page.title,
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: AppColors.ivory,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            page.body,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.ivory.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: AppSpacing.screenInsets,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: AppSpacing.fast,
                        child: TextButton(
                          onPressed: _isLast ? null : _finish,
                          child: Text(
                            'Skip',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.ivory,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        for (var i = 0; i < _pages.length; i++)
                          AnimatedContainer(
                            duration: AppSpacing.medium,
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(right: 6),
                            height: 6,
                            width: i == _index ? 28 : 6,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? AppColors.champagne
                                  : AppColors.ivory.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: _isLast ? 'Get started' : 'Continue',
                      variant: AppButtonVariant.accent,
                      isLoading: _finishing,
                      onPressed: _next,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
