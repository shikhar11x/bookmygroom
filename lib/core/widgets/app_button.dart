import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, accent, text }

/// Tactile button with press-scale feedback, haptics and a loading state.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.haptic = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expand;
  final bool haptic;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  Color get _background {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.ink;
      case AppButtonVariant.accent:
        return AppColors.champagne;
      case AppButtonVariant.secondary:
        return Colors.transparent;
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color get _foreground {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.ivory;
      case AppButtonVariant.accent:
        return AppColors.ink;
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
        return AppColors.ink;
    }
  }

  void _handleTap() {
    if (!_enabled) return;
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foreground,
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: _foreground),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: _foreground,
              ),
            ),
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed && !reduceMotion ? 0.97 : 1,
          duration: AppSpacing.fast,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _enabled || widget.isLoading ? 1 : 0.45,
            duration: AppSpacing.fast,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: widget.variant == AppButtonVariant.secondary
                    ? Border.all(color: AppColors.ink, width: 1.2)
                    : null,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
