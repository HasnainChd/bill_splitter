import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/settings_provider.dart';
import '../../providers/profile_provider.dart';

final currencySearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final currencySearchControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class DefaultCurrencyScreen extends ConsumerWidget {
  const DefaultCurrencyScreen({super.key});

  final List<Map<String, String>> _currencies = const [
    {'code': 'USD (\$)', 'name': 'US Dollar', 'flag': '🇺🇸'},
    {'code': 'EUR (€)', 'name': 'Euro', 'flag': '🇪🇺'},
    {'code': 'GBP (£)', 'name': 'British Pound', 'flag': '🇬🇧'},
    {'code': 'INR (₹)', 'name': 'Indian Rupee', 'flag': '🇮🇳'},
    {'code': 'PKR (Rs)', 'name': 'Pakistani Rupee', 'flag': '🇵🇰'},
    {'code': 'JPY (¥)', 'name': 'Japanese Yen', 'flag': '🇯🇵'},
    {'code': 'AUD (A\$)', 'name': 'Australian Dollar', 'flag': '🇦🇺'},
    {'code': 'CAD (C\$)', 'name': 'Canadian Dollar', 'flag': '🇨🇦'},
    {'code': 'CHF (CHF)', 'name': 'Swiss Franc', 'flag': '🇨🇭'},
    {'code': 'CNY (¥)', 'name': 'Chinese Yuan', 'flag': '🇨🇳'},
    {'code': 'SGD (S\$)', 'name': 'Singapore Dollar', 'flag': '🇸🇬'},
    {'code': 'NZD (NZ\$)', 'name': 'New Zealand Dollar', 'flag': '🇳🇿'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCurrency = ref.watch(defaultCurrencyProvider);
    final searchQuery = ref.watch(currencySearchQueryProvider);
    final controller = ref.watch(currencySearchControllerProvider);

    final filtered = _currencies.where((c) {
      final query = searchQuery.toLowerCase();
      return c['name']!.toLowerCase().contains(query) ||
          c['code']!.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 30.h),
            // Header Row
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
                    'Default Currency',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: (val) {
                    ref.read(currencySearchQueryProvider.notifier).state = val;
                  },
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Search currencies...',
                    hintStyle: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.35),
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.white.withValues(alpha: 0.35),
                      size: 20.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Currency List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final cur = filtered[index];
                  final isSelected = activeCurrency == cur['code'];

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: GestureDetector(
                      onTap: () async {
                        final selectedCurrency = cur['code']!;
                        ref.read(defaultCurrencyProvider.notifier).state = selectedCurrency;
                        
                        // Async update to Supabase profile
                        final profile = ref.read(profileProvider).profile;
                        if (profile != null) {
                          await ref.read(profileProvider.notifier).updateProfile(
                            fullName: profile.fullName,
                            username: profile.username,
                            phone: profile.phone,
                            bio: profile.bio,
                            currency: selectedCurrency,
                            context: context,
                          );
                        }
                      },
                      child: AppCard(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.onboardingViolet.withValues(alpha: 0.4),
                                width: 1.5,
                              )
                            : Border.all(
                                color: AppColors.white.withValues(alpha: 0.03),
                                width: 1,
                              ),
                        child: Row(
                          children: [
                            Container(
                              width: 38.w,
                              height: 38.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1C38),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                cur['flag']!,
                                style: TextStyle(fontSize: 18.sp),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    cur['code']!,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                  SizedBox(height: 2.h),
                                  AppText(
                                    cur['name']!,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.white.withValues(alpha: 0.45),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.onboardingViolet,
                                size: 22.sp,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: AppColors.white.withValues(alpha: 0.15),
                                size: 22.sp,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
