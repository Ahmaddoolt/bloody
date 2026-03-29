// file: lib/actors/receiver/map_finder/presentation/screens/receiver_map_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../../core/widgets/custom_loader.dart';
import '../../../../../../core/widgets/map_toggle_fab.dart';
import '../../../../shared/settings/presentation/providers/profile_provider.dart';
import '../../../../shared/settings/presentation/widgets/priority_request_card.dart';
import '../providers/receiver_map_provider.dart';
import '../widgets/receiver_blood_type_selector.dart';
import '../widgets/receiver_donor_list.dart';
import '../widgets/receiver_donor_map.dart';
import '../widgets/receiver_donor_sheet.dart';
import '../widgets/receiver_home_app_bar.dart';
import '../widgets/receiver_home_states.dart';

class ReceiverHomeScreen extends ConsumerStatefulWidget {
  const ReceiverHomeScreen({super.key});

  @override
  ConsumerState<ReceiverHomeScreen> createState() => _ReceiverHomeScreenState();
}

class _ReceiverHomeScreenState extends ConsumerState<ReceiverHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasShownReasonDialog = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiverMapProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(receiverMapProvider);
    if (state.isMapView || state.isLoadingMore || !state.hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(receiverMapProvider.notifier).loadMore();
    }
  }

  Future<void> _confirmDonation(String donorId, String donorName) async {
    final shouldConfirm = await AppConfirmDialog.show(
      context: context,
      title: 'confirm_donation'.tr(),
      content: 'confirm_donation_body'.tr(args: [donorName]),
      confirmLabel: 'yes_confirm'.tr(),
      confirmColor: Colors.green,
    );

    if (shouldConfirm != true) return;

    final success =
        await ref.read(receiverMapProvider.notifier).confirmDonation(donorId);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      _showSnack('donation_confirmed'.tr(args: [donorName]), Colors.green);
    } else {
      _showSnack('error_updating_donor'.tr(), Colors.red);
    }
  }

  void _showDonorModal(Map<String, dynamic> user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(receiverMapProvider);

          return ReceiverDonorSheet(
            user: user,
            isDark: isDark,
            isConfirmingDonation: state.isConfirmingDonation,
            onCall: () => _callUser(user['phone'] as String?),
            onConfirmDonation: () => _confirmDonation(
              user['id'] as String,
              (user['username']?.toString().isNotEmpty == true
                      ? user['username']
                      : null) ??
                  'donor'.tr(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _callUser(String? phone) async {
    if (phone == null) return;

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showBloodRequestDialog() {
    final reasonController = TextEditingController();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bloodtype_rounded,
                    color: AppColors.accent, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'why_need_blood_title'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'why_need_blood_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'blood_request_reason_label'.tr(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('skip'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final reason = reasonController.text.trim();
                        try {
                          if (reason.isNotEmpty) {
                            await Supabase.instance.client
                                .from('profiles')
                                .update({'blood_request_reason': reason}).eq(
                                    'id', userId);
                          }
                        } on PostgrestException catch (error) {
                          if (error.code != '42703') {
                            _showSnack('error_loading'.tr(), Colors.red);
                            return;
                          }
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text('save'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPrioritySheet() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    // Always fetch fresh profile so admin status changes are reflected immediately.
    if (userId.isNotEmpty) {
      await ref.read(profileProvider.notifier).loadProfile(userId);
    }

    if (!mounted) return;

    final profileAsync = ref.read(profileProvider);
    final profile = profileAsync.value;
    final priorityStatus = profile?.priorityStatus ?? 'none';

    // For pending/approved states show the status sheet.
    // For everything else (none, rejected) always show the reason dialog first.
    if (priorityStatus != 'pending' && priorityStatus != 'high') {
      _showReasonDialog(submitPriorityAfterSave: true);
      return;
    }

    bool isRequesting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              PriorityRequestCard(
                priorityStatus: priorityStatus,
                isRequesting: isRequesting,
                onRequest: () async {
                  setSheetState(() => isRequesting = true);
                  try {
                    await Supabase.instance.client.from('profiles').update(
                        {'priority_status': 'pending'}).eq('id', userId);
                    if (userId.isNotEmpty) {
                      await ref
                          .read(profileProvider.notifier)
                          .loadProfile(userId);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (_) {
                    if (ctx.mounted) {
                      setSheetState(() => isRequesting = false);
                    }
                    _showSnack('error_loading'.tr(), Colors.red);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a dialog for the user to enter their blood request reason.
  void _showReasonDialog({bool submitPriorityAfterSave = false}) {
    final currentReason =
        ref.read(profileProvider).value?.bloodRequestReason ?? '';
    final controller = TextEditingController(text: currentReason);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                'situation_dialog_title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'situation_dialog_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 300,
                autofocus: true,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'situation_hint'.tr(),
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            Theme.of(ctx).colorScheme.outline.withOpacity(0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            Theme.of(ctx).colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Theme.of(ctx)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.4),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
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
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) {
                              _showSnack(
                                  'priority_reason_required'.tr(), Colors.red);
                              return;
                            }
                            setDialogState(() => isSaving = true);
                            try {
                              final payload = <String, dynamic>{
                                'blood_request_reason': text,
                              };
                              if (submitPriorityAfterSave) {
                                payload['priority_status'] = 'pending';
                              }
                              try {
                                await Supabase.instance.client
                                    .from('profiles')
                                    .update(payload)
                                    .eq('id', userId);
                              } on PostgrestException catch (error) {
                                if (error.code != '42703' ||
                                    !submitPriorityAfterSave) {
                                  rethrow;
                                }
                                await Supabase.instance.client
                                    .from('profiles')
                                    .update({'priority_status': 'pending'}).eq(
                                        'id', userId);
                              }
                              // Refresh the local profile cache
                              if (userId.isNotEmpty) {
                                await ref
                                    .read(profileProvider.notifier)
                                    .loadProfile(userId);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (submitPriorityAfterSave) {
                                _showSnack(
                                    'priority_pending'.tr(), AppColors.accent);
                              }
                            } catch (_) {
                              setDialogState(() => isSaving = false);
                              _showSnack('error_loading'.tr(), Colors.red);
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('situation_submit'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(receiverMapProvider);
    final donorMarkerIcon = ref.watch(donorMarkerIconProvider).value;

    // Show blood request reason dialog once after profile loads
    ref.listen<ReceiverMapState>(receiverMapProvider, (prev, curr) {
      if ((prev?.isInitialLoading ?? true) && !curr.isInitialLoading) {
        if (curr.city != null &&
            (curr.bloodRequestReason?.trim().isEmpty ?? true) &&
            !_hasShownReasonDialog) {
          _hasShownReasonDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showBloodRequestDialog();
          });
        }
      }
    });

    return Scaffold(
      appBar: ReceiverHomeAppBar(
        state: state,
        onPriorityTap: _showPrioritySheet,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                _horizontalPaddingFor(constraints.maxWidth);

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    0,
                  ),
                  child: ReceiverBloodTypeSelector(
                    isDark: isDark,
                    state: state,
                    onSelect: (bloodType) => ref
                        .read(receiverMapProvider.notifier)
                        .selectBloodType(bloodType),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildContent(
                      isDark: isDark,
                      state: state,
                      donorMarkerIcon: donorMarkerIcon,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: MapToggleFab(
        heroTag: 'receiver_map_fab',
        isMapView: state.isMapView,
        onToggle: () => ref.read(receiverMapProvider.notifier).toggleMapView(),
      ),
    );
  }

  double _horizontalPaddingFor(double width) {
    if (width >= 1200) return 32;
    if (width >= 900) return 24;
    return 16;
  }

  Widget _buildContent({
    required bool isDark,
    required ReceiverMapState state,
    required BitmapDescriptor? donorMarkerIcon,
    required double horizontalPadding,
  }) {
    if (state.isInitialLoading) {
      return const Center(child: CustomLoader());
    }

    if (state.hasError && state.donors.isEmpty) {
      return ReceiverErrorState(
        horizontalPadding: horizontalPadding,
        onRetry: () => ref.read(receiverMapProvider.notifier).refresh(),
      );
    }

    if (state.neededBloodType == null) {
      return ReceiverMissingBloodTypeState(
        horizontalPadding: horizontalPadding,
      );
    }

    if (state.isMapView) {
      return ReceiverDonorMap(
        state: state,
        donorMarkerIcon: donorMarkerIcon,
        horizontalPadding: horizontalPadding,
        onRetryLocation: () =>
            ref.read(receiverMapProvider.notifier).retryLocation(),
        onOpenDonor: _showDonorModal,
      );
    }

    if (state.donors.isEmpty) {
      return ReceiverEmptyState(
        state: state,
        horizontalPadding: horizontalPadding,
        onRefresh: () => ref.read(receiverMapProvider.notifier).refresh(),
      );
    }

    return ReceiverDonorList(
      isDark: isDark,
      state: state,
      horizontalPadding: horizontalPadding,
      scrollController: _scrollController,
      onRefresh: () => ref.read(receiverMapProvider.notifier).refresh(),
      onOpenDonor: _showDonorModal,
      onCall: _callUser,
    );
  }
}
