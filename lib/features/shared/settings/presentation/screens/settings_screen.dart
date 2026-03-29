import 'dart:async';

import 'package:bloody/core/theme/app_colors.dart';
import 'package:bloody/core/theme/app_theme.dart';
import 'package:bloody/core/widgets/app_confirm_dialog.dart';
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:bloody/features/shared/auth/presentation/providers/auth_provider.dart';
import 'package:bloody/features/shared/settings/domain/entities/notification_settings_entity.dart';
import 'package:bloody/features/donor/dashboard/presentation/providers/donor_profile_provider.dart';
import 'package:bloody/features/receiver/map_finder/presentation/providers/receiver_map_provider.dart';
import 'package:bloody/features/shared/settings/presentation/providers/availability_provider.dart';
import 'package:bloody/features/shared/settings/presentation/providers/profile_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/screens/login_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../providers/notification_settings_provider.dart';
import '../widgets/availability_toggle.dart';
import '../widgets/eligibility_timer.dart';
import '../widgets/profile_card.dart';
import 'donation_history_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Timer? _countdownTimer;
  String _remainingTime = '';
  bool _isDeferred = false;
  bool _isRequestingPriority = false;
  DateTime? _nextEligibleDate;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await ref.read(profileProvider.notifier).loadProfile(_userId);
    if (!mounted) return;
    final profile = ref.read(profileProvider).value;
    if (!mounted) return;
    if (profile != null) {
      ref.read(availabilityProvider.notifier).setValue(profile.isAvailable);
      if (profile.lastDonationDate != null) {
        _startEligibilityTimer(profile.lastDonationDate!);
      }
    }
  }

  void _startEligibilityTimer(DateTime lastDonation) {
    final nextEligible = lastDonation.add(const Duration(days: 90));
    if (DateTime.now().isBefore(nextEligible)) {
      setState(() {
        _isDeferred = true;
        _nextEligibleDate = nextEligible;
      });
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        final remaining = nextEligible.difference(DateTime.now());
        if (remaining.isNegative) {
          t.cancel();
          if (mounted) setState(() => _isDeferred = false);
        } else if (mounted) {
          setState(() {
            _remainingTime = _formatDuration(remaining);
          });
        }
      });
    }
  }

  String _formatDuration(Duration d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.inDays}${'days_short'.tr()} ${pad(d.inHours.remainder(24))}${'hours_short'.tr()} ${pad(d.inMinutes.remainder(60))}${'minutes_short'.tr()}';
  }

  double _calculateProgress() {
    if (_nextEligibleDate == null) return 0;
    final lastDonation = _nextEligibleDate!.subtract(const Duration(days: 90));
    final total = _nextEligibleDate!.difference(lastDonation).inSeconds;
    final elapsed = DateTime.now().difference(lastDonation).inSeconds;
    return total <= 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);
  }

  Future<void> _handleAvailabilityToggle(bool newValue) async {
    final success =
        await ref.read(availabilityProvider.notifier).toggle(_userId, newValue);
    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('availability_update_error'.tr()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'log_out'.tr(),
      content: 'logout_confirm'.tr(),
      confirmLabel: 'log_out'.tr(),
    );
    if (confirmed == true) {
      ref.invalidate(receiverMapProvider);
      ref.invalidate(donorProfileProvider);
      ref.invalidate(profileProvider);
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider);
    final availabilityState = ref.watch(availabilityProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final isDonor = profileAsync.value?.isDonor ?? true;
    final priorityStatus = profileAsync.value?.priorityStatus ?? 'none';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(isDark, isDonor),
      body: profileAsync.isLoading
          ? const AppLoadingCenter()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: User Information
                  _buildSectionHeader('my_info'.tr()),
                  const SizedBox(height: 12),
                  _buildUserInfoSection(profileAsync.value, availabilityState,
                      isDonor, priorityStatus, isDark),
                  const SizedBox(height: 24),

                  // Section 2: Notification Settings
                  _buildSectionHeader('notification_preferences'.tr()),
                  const SizedBox(height: 12),
                  _buildNotificationToggles(isDark, notificationSettings),
                  const SizedBox(height: 24),

                  // Section 3: App Settings
                  _buildSectionHeader('app_settings'.tr()),
                  const SizedBox(height: 12),
                  _buildPreferencesCard(isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, bool isDonor) {
    return AppBar(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 78,
      flexibleSpace: Container(
        height: 110,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentDark, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'settings'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDonor)
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DonationHistoryScreen(userId: _userId)),
                          ),
                          icon: const Icon(Icons.volunteer_activism_rounded,
                              color: Colors.white, size: 20),
                          tooltip: 'donation_history'.tr(),
                        ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        ),
                        icon: const Icon(Icons.notifications,
                            color: Colors.white, size: 20),
                      ),
                      IconButton(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 20),
                        tooltip: 'log_out'.tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(
      userProfile, availabilityState, isDonor, priorityStatus, isDark) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Profile item
          ProfileCard(
            username: userProfile?.username ?? 'User',
            email: userProfile?.email,
            bloodType: userProfile?.bloodType,
            city: userProfile?.city,
            onEditTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    username: userProfile?.username ?? '',
                    phone: userProfile?.phone ?? '',
                    bloodType: userProfile?.bloodType,
                    city: userProfile?.city,
                    birthDate: userProfile?.birthDate,
                    bloodRequestReason: userProfile?.bloodRequestReason,
                  ),
                ),
              );
              _loadData();
            },
          ),
          // Eligibility item (if donor)
          if (isDonor) ...[
            Divider(height: 1, color: colors.outline.withOpacity(0.1)),
            EligibilityTimer(
              isEligible: !_isDeferred,
              remainingTime: _remainingTime,
              progress: _calculateProgress(),
            ),
          ],
          // Availability toggle
          Divider(height: 1, color: colors.outline.withOpacity(0.1)),
          AvailabilityToggle(
            isAvailable: availabilityState.value ?? true,
            isLoading: availabilityState.isLoading,
            onChanged: _handleAvailabilityToggle,
          ),
          // Priority card (if receiver)
          if (!isDonor) ...[
            Divider(height: 1, color: colors.outline.withOpacity(0.1)),
            _buildPriorityRow(isDark, priorityStatus),
          ],
        ],
      ),
    );
  }

  Future<void> _requestPriority() async {
    if (_isRequestingPriority) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // If reason not yet filled, collect it and submit the request directly.
    final profile = ref.read(profileProvider).value;
    if (profile?.bloodRequestReason == null ||
        profile!.bloodRequestReason!.trim().isEmpty) {
      _showReasonDialog(submitPriorityAfterSave: true);
      return;
    }

    setState(() => _isRequestingPriority = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'priority_status': 'pending'}).eq('id', userId);

      if (!mounted) return;
      await ref.read(profileProvider.notifier).loadProfile(userId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('error_loading'.tr()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) {
        setState(() => _isRequestingPriority = false);
      }
    }
  }

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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('priority_reason_required'.tr()),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                              ));
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
                              if (userId.isNotEmpty) {
                                await ref
                                    .read(profileProvider.notifier)
                                    .loadProfile(userId);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted && submitPriorityAfterSave) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('priority_pending'.tr()),
                                  backgroundColor: AppColors.accent,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                ));
                              }
                            } catch (_) {
                              setDialogState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('error_loading'.tr()),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                ));
                              }
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
                                strokeWidth: 2, color: Colors.white),
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

  Widget _buildPriorityRow(bool isDark, String priorityStatus) {
    final isPending = priorityStatus == 'pending';
    final isApproved = priorityStatus == 'high';
    final isRejected = priorityStatus == 'rejected';

    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    if (isApproved) {
      color = AppTheme.primaryRed;
      icon = Icons.star_rounded;
      title = 'priority_approved'.tr();
      subtitle = 'priority_approved_desc'.tr();
    } else if (isPending) {
      color = const Color(0xFFE65100);
      icon = Icons.hourglass_top_rounded;
      title = 'priority_pending'.tr();
      subtitle = 'priority_pending_desc'.tr();
    } else if (isRejected) {
      color = const Color(0xFF616161);
      icon = Icons.cancel_outlined;
      title = 'priority_rejected'.tr();
      subtitle = 'priority_rejected_desc'.tr();
    } else {
      color = Colors.blue.shade700;
      icon = Icons.shield_outlined;
      title = 'priority_none'.tr();
      subtitle = 'priority_none_desc'.tr();
    }

    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          if (!isPending && !isApproved)
            ElevatedButton(
              onPressed: _isRequestingPriority ? null : _requestPriority,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isRequestingPriority
                  ? const AppLoadingIndicator(
                      size: 16,
                      strokeWidth: 2,
                      color: Colors.white,
                    )
                  : Text('request_high_priority'.tr()),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggles(bool isDark, AsyncValue settingsAsync) {
    return settingsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: const AppLoadingCenter(),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Text('error_loading_preferences'.tr()),
      ),
      data: (settings) {
        final entity = settings as NotificationSettingsEntity;
        final colors = Theme.of(context).colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              _buildToggleRow(
                isDark: isDark,
                icon: Icons.bloodtype_rounded,
                iconColor: const Color(0xFFE53935),
                label: 'low_stock_alerts'.tr(),
                subtitle: 'low_stock_alerts_desc'.tr(),
                value: entity.receiveLowStockAlerts,
                onChanged: (val) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .toggleLowStockAlerts(val);
                },
              ),
              Divider(height: 1, color: colors.outline.withOpacity(0.1)),
              _buildToggleRow(
                isDark: isDark,
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF1976D2),
                label: 'system_notifications'.tr(),
                subtitle: 'system_notifications_desc'.tr(),
                value: entity.receiveSystemNotifications,
                onChanged: (val) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .toggleSystemNotifications(val);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleRow({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF4CAF50),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(bool isDark) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            isDark: isDark,
            icon:
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: const Color(0xFF1976D2),
            label: 'dark_mode'.tr(),
            subtitle:
                isDarkMode ? 'theme_dark_desc'.tr() : 'theme_light_desc'.tr(),
            value: isDarkMode,
            onChanged: (val) {
              AppTheme.saveTheme(val ? ThemeMode.dark : ThemeMode.light);
              setState(() {});
            },
          ),
          Divider(height: 1, color: colors.outline.withOpacity(0.1)),
          _buildToggleRow(
            isDark: isDark,
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF1976D2),
            label: 'arabic_lang'.tr(),
            subtitle: context.locale.languageCode == 'ar'
                ? 'العربية مفعّلة'
                : 'English enabled',
            value: context.locale.languageCode == 'ar',
            onChanged: (val) async {
              await context
                  .setLocale(val ? const Locale('ar') : const Locale('en'));
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
