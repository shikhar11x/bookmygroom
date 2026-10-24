import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/star_rating.dart';
import '../../auth/application/auth_providers.dart';
import '../../booking/application/checkout_providers.dart';
import '../data/reviews_repository.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _comment = TextEditingController();
  int _service = 0;
  int _stylist = 0;
  File? _photo;
  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (x != null && mounted) setState(() => _photo = File(x.path));
    } catch (_) {
      _snack('Could not open your photos.');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _submitting) return;
    setState(() => _submitting = true);
    final repo = ref.read(reviewsRepositoryProvider);
    try {
      String? photoPath;
      if (_photo != null) {
        photoPath = await repo.uploadPhoto(_photo!, user.id);
      }
      await repo.submit(
        appointmentId: widget.appointmentId,
        serviceRating: _service,
        stylistRating: _stylist,
        comment: _comment.text,
        photoPath: photoPath,
      );
      ref.invalidate(reviewedProvider(widget.appointmentId));
      ref.invalidate(stylistRatingsProvider);
      if (mounted) setState(() => _done = true);
    } on ReviewException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not send your review. Check your connection.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appt = ref.watch(appointmentByIdProvider(widget.appointmentId));

    if (_done) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.screenInsets,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: MediaQuery.of(context).disableAnimations ? 1 : 0,
                    end: 1,
                  ),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppColors.champagne,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('THANK YOU', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text('Review sent', style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your feedback helps us and other guests.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: 'Done', onPressed: () => context.pop()),
              ],
            ),
          ),
        ),
      );
    }

    final canSubmit = _service > 0 && _stylist > 0 && !_submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Rate your visit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          if (appt != null)
            Text(
              appt.serviceNames.join(', '),
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('How was the service?', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          StarRating(
            value: _service,
            label: 'Service rating',
            onChanged: (v) => setState(() => _service = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            appt == null || appt.stylistName.isEmpty
                ? 'How was your stylist?'
                : 'How was ${appt.stylistName}?',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          StarRating(
            value: _stylist,
            label: 'Stylist rating',
            onChanged: (v) => setState(() => _stylist = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Tell us more (optional)',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_photo != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.file(
                    _photo!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    tooltip: 'Remove photo',
                    onPressed: () => setState(() => _photo = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            )
          else
            AppButton(
              label: 'Add a photo (optional)',
              icon: Icons.add_photo_alternate_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: _pickPhoto,
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Submit review',
            isLoading: _submitting,
            onPressed: canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
