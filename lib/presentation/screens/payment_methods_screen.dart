import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';

final currentDefaultPaymentProvider =
    StateProvider.autoDispose<String>((ref) => 'Apple Pay');

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultMethod = ref.watch(currentDefaultPaymentProvider);

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
                  const AppText(
                    'Payment Methods',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // ── Scrollable Body ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large Default Method Top Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.onboardingViolet,
                            AppColors.primaryPurpleDarker,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onboardingViolet
                                .withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'DEFAULT METHOD',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white.withValues(alpha: 0.5),
                                letterSpacing: 1.2,
                              ),
                              SizedBox(height: 12.h),
                              AppText(
                                defaultMethod,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              SizedBox(height: 16.h),
                              AppText(
                                defaultMethod == 'Apple Pay'
                                    ? 'Instant transfers · No fees'
                                    : defaultMethod == 'Venmo'
                                        ? 'Connected · @alexj'
                                        : defaultMethod == 'PayPal'
                                            ? 'Connected · alex@email.com'
                                            : 'Default account for settlement',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                          // Stylized circle overlapping background design
                          Positioned(
                            right: 0,
                            top: 0,
                            child: defaultMethod == 'Apple Pay'
                                ? Container(
                                    width: 38.w,
                                    height: 38.w,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const AppText('🍎', fontSize: 18),
                                  )
                                : defaultMethod == 'Venmo'
                                    ? Container(
                                        width: 38.w,
                                        height: 38.w,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child:
                                            const AppText('💙', fontSize: 18),
                                      )
                                    : Container(
                                        width: 38.w,
                                        height: 38.w,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(Icons.credit_card,
                                            color: AppColors.white,
                                            size: 20.sp),
                                      ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // YOUR METHODS Section
                    _sectionLabel('YOUR METHODS'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildMethodRow(
                            ref: ref,
                            title: 'Apple Pay',
                            subtitle: 'Instant · No fees',
                            emojiOrIcon: '🍎',
                            isDefault: defaultMethod == 'Apple Pay',
                          ),
                          _buildDivider(),
                          _buildMethodRow(
                            ref: ref,
                            title: 'Venmo',
                            subtitle: 'Connected · @alexj',
                            emojiOrIcon: '💙',
                            isDefault: defaultMethod == 'Venmo',
                          ),
                          _buildDivider(),
                          _buildMethodRow(
                            ref: ref,
                            title: 'PayPal',
                            subtitle: 'alex@email.com',
                            emojiOrIcon: const Color(0xFF0284C7),
                            isDefault: defaultMethod == 'PayPal',
                          ),
                          _buildDivider(),
                          _buildMethodRow(
                            ref: ref,
                            title: 'Visa •••• 4829',
                            subtitle: 'Expires 09/27',
                            emojiOrIcon: Icons.credit_card_rounded,
                            isDefault: defaultMethod == 'Visa •••• 4829',
                          ),
                          _buildDivider(),
                          _buildMethodRow(
                            ref: ref,
                            title: 'Chase •••• 2847',
                            subtitle: 'Checking account',
                            emojiOrIcon: Icons.apartment_rounded,
                            isDefault: defaultMethod == 'Chase •••• 2847',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ADD NEW Section
                    _sectionLabel('ADD NEW'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildAddOptionRow(
                            icon: Icons.credit_card_rounded,
                            iconColor: AppColors.orange,
                            title: 'Add Debit / Credit Card',
                          ),
                          _buildDivider(),
                          _buildAddOptionRow(
                            icon: Icons.apartment_rounded,
                            iconColor: AppColors.onboardingCyan,
                            title: 'Connect Bank Account',
                          ),
                          _buildDivider(),
                          _buildAddOptionRow(
                            icon: Icons.monetization_on_outlined,
                            iconColor: const Color(0xFF10B981),
                            title: 'Connect Cash App',
                          ),
                          _buildDivider(),
                          _buildAddOptionRow(
                            icon: Icons.bolt_rounded,
                            iconColor: AppColors.onboardingViolet,
                            title: 'Connect Zelle',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Footer Encryption Notice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            color: Colors.amber, size: 14.sp),
                        SizedBox(width: 6.w),
                        AppText(
                          'Your payment info is encrypted and never stored on Equally\'s servers.',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.25),
                        ),
                      ],
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

  Widget _buildMethodRow({
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required dynamic emojiOrIcon, // String (emoji) or IconData or Color
    required bool isDefault,
  }) {
    Widget leadingWidget;
    if (emojiOrIcon is String) {
      leadingWidget = Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C38),
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: AppText(emojiOrIcon, fontSize: 16),
      );
    } else if (emojiOrIcon is IconData) {
      leadingWidget = Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C38),
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Icon(emojiOrIcon, color: AppColors.orange, size: 18.sp),
      );
    } else {
      // Color represented for PayPal blue circle
      leadingWidget = Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C38),
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 16.w,
          height: 16.w,
          decoration: BoxDecoration(
            color: emojiOrIcon as Color,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return ListTile(
      leading: leadingWidget,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            title,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
          if (isDefault) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: const AppText(
                'DEFAULT',
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ],
      ),
      subtitle: AppText(
        subtitle,
        fontSize: 11,
        color: AppColors.white.withValues(alpha: 0.35),
      ),
      trailing: isDefault
          ? Icon(
              Icons.chevron_right_rounded,
              color: AppColors.white.withValues(alpha: 0.2),
              size: 20.sp,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(currentDefaultPaymentProvider.notifier).state =
                        title;
                  },
                  child: const AppText(
                    'Set default',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onboardingViolet,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.white.withValues(alpha: 0.2),
                  size: 20.sp,
                ),
              ],
            ),
      onTap: () {},
    );
  }

  Widget _buildAddOptionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return ListTile(
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C38),
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 18.sp),
      ),
      title: AppText(
        title,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.white.withValues(alpha: 0.2),
        size: 20.sp,
      ),
      onTap: () {},
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
      indent: 68.w,
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
