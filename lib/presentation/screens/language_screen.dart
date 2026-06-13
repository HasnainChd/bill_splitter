import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/settings_provider.dart';

final languageSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final languageSearchControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  final List<Map<String, String>> _languages = const [
    {'code': 'English (US)', 'native': 'English', 'flag': '🇺🇸'},
    {'code': 'English (UK)', 'native': 'English', 'flag': '🇬🇧'},
    {'code': 'Urdu (PK)', 'native': 'اردو', 'flag': '🇵🇰'},
    {'code': 'Spanish', 'native': 'Español', 'flag': '🇪🇸'},
    {'code': 'French', 'native': 'Français', 'flag': '🇫🇷'},
    {'code': 'German', 'native': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'Italian', 'native': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'Portuguese', 'native': 'Português', 'flag': '🇵🇹'},
    {'code': 'Chinese', 'native': '中文', 'flag': '🇨🇳'},
    {'code': 'Japanese', 'native': '日本語', 'flag': '🇯🇵'},
    {'code': 'Korean', 'native': '한국어', 'flag': '🇰🇷'},
    {'code': 'Arabic', 'native': 'العربية', 'flag': '🇸🇦'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLanguage = ref.watch(languageProvider);
    final searchQuery = ref.watch(languageSearchQueryProvider);
    final controller = ref.watch(languageSearchControllerProvider);

    final filtered = _languages.where((l) {
      final query = searchQuery.toLowerCase();
      return l['code']!.toLowerCase().contains(query) ||
          l['native']!.toLowerCase().contains(query);
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
                    'Language',
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
                    ref.read(languageSearchQueryProvider.notifier).state = val;
                  },
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Search languages...',
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

            // Language List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final lang = filtered[index];
                  final isSelected = activeLanguage == lang['code'];

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(languageProvider.notifier).state = lang['code']!;
                      },
                      child: AppCard(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.onboardingCyan.withValues(alpha: 0.4),
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
                                lang['flag']!,
                                style: TextStyle(fontSize: 18.sp),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    lang['code']!,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                  SizedBox(height: 2.h),
                                  AppText(
                                    lang['native']!,
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
                                color: AppColors.onboardingCyan,
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
