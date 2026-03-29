import 'package:bloody/core/theme/app_colors.dart';
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// State & Notifier
// ---------------------------------------------------------------------------

class _DonorRewardsState {
  final List<Map<String, dynamic>> donors;
  final bool isLoading;
  final String? error;
  final Set<String> rewardingIds;

  const _DonorRewardsState({
    this.donors = const [],
    this.isLoading = false,
    this.error,
    this.rewardingIds = const {},
  });

  _DonorRewardsState copyWith({
    List<Map<String, dynamic>>? donors,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Set<String>? rewardingIds,
  }) {
    return _DonorRewardsState(
      donors: donors ?? this.donors,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      rewardingIds: rewardingIds ?? this.rewardingIds,
    );
  }
}

class _DonorRewardsNotifier extends StateNotifier<_DonorRewardsState> {
  _DonorRewardsNotifier() : super(const _DonorRewardsState()) {
    fetch();
  }

  final _supabase = Supabase.instance.client;

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _supabase
          .from('profiles')
          .select('id, username, blood_type, city, points, phone, fcm_token')
          .eq('user_type', 'donor')
          .gt('points', 0)
          .order('points', ascending: false);
      state = state.copyWith(
        isLoading: false,
        donors: List<Map<String, dynamic>>.from(data as List),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> rewardDonor(Map<String, dynamic> donor) async {
    final id = donor['id']?.toString() ?? '';
    state = state.copyWith(rewardingIds: {...state.rewardingIds, id});
    try {
      await _supabase.from('profiles').update({'points': 0}).eq('id', id);

      final token = donor['fcm_token']?.toString();
      final name = donor['username']?.toString() ?? 'donor'.tr();
      if (token != null && token.isNotEmpty) {
        try {
          await _supabase.functions.invoke('send-fcm', body: {
            'token': token,
            'title': 'reward_notif_title'.tr(),
            'body': 'reward_notif_body'.tr(namedArgs: {'name': name}),
          });
        } catch (_) {}
      }

      try {
        await _supabase.from('notifications').insert({
          'user_id': id,
          'title': 'reward_notif_title'.tr(),
          'body': 'reward_notif_body'.tr(namedArgs: {'name': name}),
          'type': 'reward',
          'is_read': false,
        });
      } catch (_) {}

      state = state.copyWith(
        rewardingIds: state.rewardingIds.difference({id}),
        donors: state.donors.where((d) => d['id'] != id).toList(),
      );
      return true;
    } catch (_) {
      state = state.copyWith(rewardingIds: state.rewardingIds.difference({id}));
      return false;
    }
  }
}

final _donorRewardsProvider = StateNotifierProvider.autoDispose<
    _DonorRewardsNotifier, _DonorRewardsState>(
  (_) => _DonorRewardsNotifier(),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AdminDonorRewardsScreen extends ConsumerWidget {
  const AdminDonorRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_donorRewardsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('reward_donors'.tr()),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(_donorRewardsProvider.notifier).fetch(),
          ),
        ],
      ),
      body: state.isLoading
          ? const AppLoadingCenter()
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 56, color: colorScheme.error.withOpacity(0.6)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text('retry'.tr()),
                        onPressed: () =>
                            ref.read(_donorRewardsProvider.notifier).fetch(),
                      ),
                    ],
                  ),
                )
              : state.donors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_outlined,
                              size: 72,
                              color: colorScheme.onSurface.withOpacity(0.25)),
                          const SizedBox(height: 16),
                          Text(
                            'no_donors_found'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _DonorList(state: state, ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Donor list
// ---------------------------------------------------------------------------

class _DonorList extends StatelessWidget {
  final _DonorRewardsState state;
  final WidgetRef ref;

  const _DonorList({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: state.donors.length,
      itemBuilder: (context, index) {
        final donor = state.donors[index];
        final id = donor['id']?.toString() ?? '';
        return _DonorRewardCard(
          rank: index + 1,
          donor: donor,
          isRewarding: state.rewardingIds.contains(id),
          onReward: () => _confirmAndReward(context, ref, donor),
          onCall: () {
            final phone = donor['phone']?.toString();
            if (phone != null && phone.isNotEmpty) {
              launchUrl(Uri.parse('tel:$phone'));
            }
          },
        );
      },
    );
  }

  Future<void> _confirmAndReward(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> donor,
  ) async {
    final name = (donor['username']?.toString().isNotEmpty == true)
        ? donor['username'].toString()
        : 'donor'.tr();
    final points = (donor['points'] as num?)?.toInt() ?? 0;
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy gradient icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'reward_donor_title'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Donor summary card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.accent.withOpacity(0.15),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  size: 14, color: Color(0xFFFFB300)),
                              const SizedBox(width: 3),
                              Text(
                                '$points ${'points_label'.tr()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFFFB300),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'reward_donor_body'.tr(namedArgs: {'name': name}),
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.emoji_events_rounded, size: 18),
                      label: Text('reward'.tr()),
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8F00),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await ref.read(_donorRewardsProvider.notifier).rewardDonor(donor);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(success ? 'reward_confirmed'.tr() : 'reward_failed'.tr()),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

class _DonorRewardCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> donor;
  final bool isRewarding;
  final VoidCallback onReward;
  final VoidCallback onCall;

  const _DonorRewardCard({
    required this.rank,
    required this.donor,
    required this.isRewarding,
    required this.onReward,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = (donor['username']?.toString().isNotEmpty == true)
        ? donor['username'].toString()
        : 'donor'.tr();
    final bloodType = donor['blood_type']?.toString();
    final city = donor['city']?.toString();
    final points = (donor['points'] as num?)?.toInt() ?? 0;
    final phone = donor['phone']?.toString();
    final hasPhone = phone != null && phone.isNotEmpty;

    final medalColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: medalColor != null
            ? Border.all(color: medalColor.withOpacity(0.5), width: 1.5)
            : Border.all(color: colorScheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Rank / medal
            SizedBox(
              width: 36,
              child: Center(
                child: medalColor != null
                    ? Icon(Icons.emoji_events_rounded,
                        color: medalColor, size: 28)
                    : Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            // Name + chips
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (bloodType != null)
                        _MiniChip(
                            icon: Icons.bloodtype_rounded,
                            label: bloodType,
                            color: AppColors.accent),
                      if (city != null)
                        _MiniChip(
                            icon: Icons.location_on_rounded,
                            label: city.tr(),
                            color: Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Points + actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Points badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 14, color: Color(0xFFFFB300)),
                      const SizedBox(width: 3),
                      Text(
                        '$points',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFFB300),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Action buttons row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPhone)
                      _ActionIconButton(
                        icon: Icons.phone_rounded,
                        color: Colors.green,
                        onPressed: onCall,
                      ),
                    if (hasPhone) const SizedBox(width: 6),
                    _ActionIconButton(
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFFF8F00),
                      onPressed: isRewarding ? null : onReward,
                      isLoading: isRewarding,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isLoading
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(icon, size: 18, color: color),
              onPressed: onPressed,
            ),
    );
  }
}
