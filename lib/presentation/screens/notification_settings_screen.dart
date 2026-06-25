import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  NotificationSettingsNotifier() : super(_defaultSettings) {
    _loadSettings();
  }

  static const Map<String, bool> _defaultSettings = {
    'muteAll': false,
    'push': true,
    'email': true,
    'sms': false,
    'newExpense': true,
    'expenseEdited': false,
    'addedToGroup': true,
    'someoneLeaves': false,
    'paymentReceived': true,
    'paymentReminder': true,
    'autoRemind': false,
    'unsettledBalances': true,
    'monthlyRecap': true,
    'streakReminders': false,
    'productUpdates': false,
    'tipsTricks': false,
  };

  void _loadSettings() {
    final box = Hive.box('settings');
    final saved = box.get('notification_settings');
    if (saved != null) {
      if (saved is Map) {
        final Map<String, bool> casted = {};
        saved.forEach((key, value) {
          if (key is String && value is bool) {
            casted[key] = value;
          }
        });
        state = {
          ..._defaultSettings,
          ...casted,
        };
      }
    }
  }

  void toggleSetting(String key) {
    final nextValue = !state[key]!;
    state = {
      ...state,
      key: nextValue,
    };
    final box = Hive.box('settings');
    box.put('notification_settings', state);
  }
}

final notificationSettingsStateProvider =
    StateNotifierProvider.autoDispose<NotificationSettingsNotifier, Map<String, bool>>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsStateProvider);

    void toggleSetting(String key) {
      ref.read(notificationSettingsStateProvider.notifier).toggleSetting(key);
    }

    final isMuted = settings['muteAll']!;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 30.h),
            // ── Header ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1C38),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.white,
                        size: 24.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          'Notifications',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                        SizedBox(height: 2.h),
                        AppText(
                          'Control what Equaly tells you',
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // ── Scrollable settings list ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mute All Card
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                        leading: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1C38),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.notifications_off_rounded,
                            color: AppColors.coralRed,
                            size: 18.sp,
                          ),
                        ),
                        title: const AppText(
                          'Mute All Notifications',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                        subtitle: AppText(
                          'Pause everything temporarily',
                          fontSize: 11,
                          color: AppColors.white.withValues(alpha: 0.35),
                        ),
                        trailing: Switch(
                          value: isMuted,
                          onChanged: (_) => toggleSetting('muteAll'),
                          activeColor: AppColors.onboardingViolet,
                          activeTrackColor: AppColors.onboardingViolet.withValues(alpha: 0.3),
                          inactiveThumbColor: AppColors.white.withValues(alpha: 0.6),
                          inactiveTrackColor: const Color(0xFF1E1C38),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // DELIVERY Section
                    _sectionLabel('DELIVERY'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            label: 'Push Notifications',
                            sublabel: 'Banner and lock screen alerts',
                            value: isMuted ? false : settings['push']!,
                            onChanged: isMuted ? null : () => toggleSetting('push'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'Email Notifications',
                            sublabel: 'alex@email.com',
                            value: isMuted ? false : settings['email']!,
                            onChanged: isMuted ? null : () => toggleSetting('email'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'SMS Notifications',
                            sublabel: '+1 (555) 234-5678',
                            value: isMuted ? false : settings['sms']!,
                            onChanged: isMuted ? null : () => toggleSetting('sms'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ACTIVITY Section
                    _sectionLabel('ACTIVITY'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            label: 'New Expense Added',
                            sublabel: 'When someone adds an expense to your group',
                            value: isMuted ? false : settings['newExpense']!,
                            onChanged: isMuted ? null : () => toggleSetting('newExpense'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'Expense Edited',
                            sublabel: 'When an expense is modified',
                            value: isMuted ? false : settings['expenseEdited']!,
                            onChanged: isMuted ? null : () => toggleSetting('expenseEdited'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'You Are Added to Group',
                            sublabel: 'Group invitations',
                            value: isMuted ? false : settings['addedToGroup']!,
                            onChanged: isMuted ? null : () => toggleSetting('addedToGroup'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'Someone Leaves Group',
                            sublabel: 'Member activity',
                            value: isMuted ? false : settings['someoneLeaves']!,
                            onChanged: isMuted ? null : () => toggleSetting('someoneLeaves'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // PAYMENTS Section
                    _sectionLabel('PAYMENTS'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            label: 'Payment Received',
                            sublabel: 'When someone settles with you',
                            value: isMuted ? false : settings['paymentReceived']!,
                            onChanged: isMuted ? null : () => toggleSetting('paymentReceived'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'Payment Reminder',
                            sublabel: 'When someone reminds you to pay',
                            value: isMuted ? false : settings['paymentReminder']!,
                            onChanged: isMuted ? null : () => toggleSetting('paymentReminder'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'Auto-remind Others',
                            sublabel: 'Weekly reminders to people who owe you',
                            value: isMuted ? false : settings['autoRemind']!,
                            onChanged: isMuted ? null : () => toggleSetting('autoRemind'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // REMINDERS Section
                    _sectionLabel('REMINDERS'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            label: 'Unsettled Balances',
                            sublabel: 'Weekly summary of what you owe',
                            value: isMuted ? false : settings['unsettledBalances']!,
                            onChanged: isMuted ? null : () => toggleSetting('unsettledBalances'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'Monthly Recap',
                            sublabel: 'Spending summary at month end',
                            value: isMuted ? false : settings['monthlyRecap']!,
                            onChanged: isMuted ? null : () => toggleSetting('monthlyRecap'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'Streak Reminders',
                            sublabel: 'Motivate regular expense tracking',
                            value: isMuted ? false : settings['streakReminders']!,
                            onChanged: isMuted ? null : () => toggleSetting('streakReminders'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // MARKETING Section
                    _sectionLabel('MARKETING'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            label: 'Product Updates',
                            sublabel: 'New features and improvements',
                            value: isMuted ? false : settings['productUpdates']!,
                            onChanged: isMuted ? null : () => toggleSetting('productUpdates'),
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            label: 'Equaly Tips & Tricks',
                            sublabel: 'How to get more from the app',
                            value: isMuted ? false : settings['tipsTricks']!,
                            onChanged: isMuted ? null : () => toggleSetting('tipsTricks'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 48.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required String sublabel,
    required bool value,
    required VoidCallback? onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      title: AppText(
        label,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      subtitle: AppText(
        sublabel,
        fontSize: 11,
        color: AppColors.white.withValues(alpha: 0.35),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged == null ? null : (_) => onChanged(),
        activeColor: AppColors.onboardingViolet,
        activeTrackColor: AppColors.onboardingViolet.withValues(alpha: 0.3),
        inactiveThumbColor: AppColors.white.withValues(alpha: 0.6),
        inactiveTrackColor: const Color(0xFF1E1C38),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
      indent: 14.w,
    );
  }

  Widget _sectionLabel(String text) {
    return AppText(
      text,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: AppColors.white.withValues(alpha: 0.4),
      letterSpacing: 1.2,
    );
  }
}
