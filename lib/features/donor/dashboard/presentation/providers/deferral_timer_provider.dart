import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for deferral countdown timer
final deferralTimerProvider =
    StateNotifierProvider<DeferralTimerNotifier, DeferralTimerState>((ref) {
  return DeferralTimerNotifier();
});

class DeferralTimerState {
  final bool isDeferred;
  final String remainingTime;
  final DateTime? lastDonationDate;
  final DateTime? nextEligibleDate;
  final double progress;

  const DeferralTimerState({
    this.isDeferred = false,
    this.remainingTime = '',
    this.lastDonationDate,
    this.nextEligibleDate,
    this.progress = 0.0,
  });

  DeferralTimerState copyWith({
    bool? isDeferred,
    String? remainingTime,
    DateTime? lastDonationDate,
    DateTime? nextEligibleDate,
    double? progress,
  }) {
    return DeferralTimerState(
      isDeferred: isDeferred ?? this.isDeferred,
      remainingTime: remainingTime ?? this.remainingTime,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      nextEligibleDate: nextEligibleDate ?? this.nextEligibleDate,
      progress: progress ?? this.progress,
    );
  }
}

class DeferralTimerNotifier extends StateNotifier<DeferralTimerState> {
  Timer? _timer;

  DeferralTimerNotifier() : super(const DeferralTimerState());

  void startDeferralPeriod(DateTime lastDonationDate) {
    final nextEligibleDate = lastDonationDate.add(const Duration(days: 90));

    state = state.copyWith(
      isDeferred: true,
      lastDonationDate: lastDonationDate,
      nextEligibleDate: nextEligibleDate,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    if (state.nextEligibleDate == null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Check if notifier is still active
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (state.nextEligibleDate == null) {
        timer.cancel();
        return;
      }

      final remaining = state.nextEligibleDate!.difference(DateTime.now());

      if (remaining.isNegative) {
        // Deferral period is over
        timer.cancel();
        if (mounted) {
          state = state.copyWith(
            isDeferred: false,
            remainingTime: '',
            progress: 1.0,
          );
        }
      } else {
        // Update countdown
        if (mounted) {
          state = state.copyWith(
            remainingTime: _formatDuration(remaining),
            progress: _calculateProgress(),
          );
        }
      }
    });
  }

  void clearDeferral() {
    _timer?.cancel();
    state = const DeferralTimerState();
  }

  double _calculateProgress() {
    if (state.lastDonationDate == null || state.nextEligibleDate == null) {
      return 0;
    }

    final total =
        state.nextEligibleDate!.difference(state.lastDonationDate!).inSeconds;
    final elapsed =
        DateTime.now().difference(state.lastDonationDate!).inSeconds;

    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);

    // Format with translated time units - NO SECONDS
    final parts = <String>[];

    if (days > 0) {
      parts.add('$days${'days_short'.tr()}');
    }
    if (hours > 0 || days > 0) {
      parts.add('${hours.toString().padLeft(2, '0')}${'hours_short'.tr()}');
    }
    parts.add('${minutes.toString().padLeft(2, '0')}${'minutes_short'.tr()}');

    return parts.join('  ');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
