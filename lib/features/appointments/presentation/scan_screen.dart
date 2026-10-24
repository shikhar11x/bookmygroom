import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../data/qr_repository.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _busy = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _handle(String token) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(qrRepositoryProvider).checkIn(token.trim());
      HapticFeedback.mediumImpact();
      if (mounted) await _showResult(success: true, result: r);
    } on QrException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) await _showResult(success: false, message: e.message);
    } catch (_) {
      if (mounted) {
        await _showResult(
          success: false,
          message: 'Network error. Try scanning again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showResult({
    required bool success,
    CheckInResult? result,
    String? message,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (ctx) => SafeArea(
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
              Row(
                children: [
                  Icon(
                    success ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: success ? AppColors.success : AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    success ? 'Checked in' : 'Check-in failed',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (success && result != null) ...[
                Text(result.customer, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE, d MMM  ·  h:mm a').format(result.start),
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Stylist: ${result.stylist}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  result.services.join(', '),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.dueAtSalon
                      ? 'Collect ${formatPrice(result.total)} at the salon'
                      : 'Paid online',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: result.dueAtSalon
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ] else
                Text(message ?? '', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Scan next',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _manualEntry() async {
    final ctrl = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter pass code'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Paste code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Check in'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (token != null && token.trim().isNotEmpty) _handle(token);
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(isStaffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reception check-in')),
      body: isStaff.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not verify access.')),
        data: (ok) {
          if (!ok) {
            return const Center(child: Text('Staff access only.'));
          }
          return Stack(
            children: [
              MobileScanner(
                controller: _scanner,
                onDetect: (capture) {
                  final value = capture.barcodes.isEmpty
                      ? null
                      : capture.barcodes.first.rawValue;
                  if (value != null) _handle(value);
                },
              ),
              Positioned(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: 24,
                child: SafeArea(
                  child: AppButton(
                    label: 'Enter code manually',
                    variant: AppButtonVariant.accent,
                    isLoading: _busy,
                    onPressed: _manualEntry,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
