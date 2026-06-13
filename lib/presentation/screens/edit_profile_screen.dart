import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/utils/app_snackbar.dart';

// Riverpod providers for local edit profile states
final epNameProvider =
    Provider.autoDispose((ref) => TextEditingController(text: 'Alex Johnson'));
final epUsernameProvider =
    Provider.autoDispose((ref) => TextEditingController(text: 'alexj'));
final epEmailProvider = Provider.autoDispose(
    (ref) => TextEditingController(text: 'alex@email.com'));
final epPhoneProvider = Provider.autoDispose(
    (ref) => TextEditingController(text: '+1 (555) 234-5678'));
final epBioProvider = Provider.autoDispose(
    (ref) => TextEditingController(text: 'Loves travel, hates IOUs 😂'));
final epCurrencyProvider =
    StateProvider.autoDispose<String>((ref) => 'USD (\$)');

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  static const List<String> _currencies = [
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
    'JPY (¥)',
    'AUD (A\$)',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = ref.watch(epNameProvider);
    final usernameCtrl = ref.watch(epUsernameProvider);
    final emailCtrl = ref.watch(epEmailProvider);
    final phoneCtrl = ref.watch(epPhoneProvider);
    final bioCtrl = ref.watch(epBioProvider);
    final selectedCurrency = ref.watch(epCurrencyProvider);

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 30.h),
            // ── Custom Header ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (No border card)
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
                  // Title
                  const AppText(
                    'Edit Profile',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                  // Save Button (Violet text clickable)
                  TextButton(
                    onPressed: () {
                      AppSnackBar.showSuccess(
                          context, 'Profile changes saved!');
                      context.pop();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                    child: const AppText(
                      'Save',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onboardingViolet,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // ── Scrollable Edit Form ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar center setup
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 96.w,
                                height: 96.w,
                                decoration: BoxDecoration(
                                  color: AppColors.onboardingViolet,
                                  borderRadius: BorderRadius.circular(24.r),
                                ),
                                alignment: Alignment.center,
                                child: const AppText(
                                  'AJ',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                              // Edit circle badge
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28.w,
                                  height: 28.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.onboardingViolet,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.backgroundDark,
                                      width: 2.w,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.white,
                                    size: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          // Upload & Remove pills
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1C38),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: const AppText(
                                    'Upload photo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.coralRed
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: const AppText(
                                    'Remove',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.coralRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // FULL NAME Field
                    AppTextField(
                      hint: 'Enter your full name',
                      controller: nameCtrl,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    SizedBox(height: 20.h),

                    // USERNAME Field
                    AppTextField(
                      hint: 'Enter username',
                      controller: usernameCtrl,
                      label: 'Username',
                      prefix: Container(
                        width: 38.w,
                        alignment: Alignment.center,
                        child: const AppText(
                          '@',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onboardingViolet,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Padding(
                      padding: EdgeInsets.only(left: 4.w),
                      child: const AppText(
                        '✓ divvy.app/alexj',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00C896),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // EMAIL Field
                    AppTextField(
                      hint: 'Enter your email address',
                      controller: emailCtrl,
                      label: 'Email',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 20.h),

                    // PHONE Field
                    AppTextField(
                      hint: 'Enter phone number',
                      controller: phoneCtrl,
                      label: 'Phone',
                      prefixIcon: Icons.smartphone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 20.h),

                    // BIO Field
                    AppTextField(
                      hint: 'Tell us about yourself',
                      controller: bioCtrl,
                      label: 'Bio',
                      prefixIcon: Icons.chat_bubble_outline_rounded,
                      maxLines: 2,
                    ),
                    SizedBox(height: 24.h),

                    // DEFAULT CURRENCY Title & Chips
                    _sectionLabel('DEFAULT CURRENCY'),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _currencies.map((currency) {
                        final isSelected = selectedCurrency == currency;
                        return GestureDetector(
                          onTap: () {
                            ref.read(epCurrencyProvider.notifier).state =
                                currency;
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.onboardingViolet
                                      .withValues(alpha: 0.12)
                                  : AppColors.transparent,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.onboardingViolet
                                    : Colors.white.withValues(alpha: 0.08),
                                width: 1.2,
                              ),
                            ),
                            child: AppText(
                              currency,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 28.h),

                    // DANGER ZONE Title & Card
                    _sectionLabel('DANGER ZONE'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildDangerZoneRow(
                            title: 'Delete All My Data',
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildDangerZoneRow(
                            title: 'Close Account',
                            onTap: () {},
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

  Widget _buildDangerZoneRow({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: AppText(
        title,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.coralRed,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.coralRed.withValues(alpha: 0.5),
        size: 20.sp,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
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
