import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';

final faqExpandedIndexProvider =
    StateProvider.autoDispose<int?>((ref) => 0); // Index 0 expanded by default
final faqSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  static const List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I split a bill unequally?',
      'answer':
          'Tap "Add Expense" → select "Custom Split" → enter the exact amount for each person. You can also split by percentage.',
    },
    {
      'question': 'Can I add expenses in other currencies?',
      'answer':
          'Yes, Divvy supports multiple currencies. When creating a group, you can specify its primary currency, and you can also add individual expenses with custom exchange rates.',
    },
    {
      'question': 'How do I connect my Venmo?',
      'answer':
          'Go to Settings → Payment Methods, tap "Connect Venmo", and authenticate with your Venmo credentials to enable seamless settled payments.',
    },
    {
      'question': 'What happens if someone leaves a group?',
      'answer':
          'Any outstanding balances must be settled before a member can leave a group. Once settled, they can be removed by the group admin or leave via group settings.',
    },
    {
      'question': 'How do I export my expense history?',
      'answer':
          'Navigate to your Group Detail page, tap the options menu in the top right, and choose "Export to CSV". A spreadsheet file will be generated for download.',
    },
  ];

  static const List<Map<String, dynamic>> _topics = [
    {
      'label': 'Getting Started',
      'emoji': '🚀',
      'color': AppColors.onboardingViolet
    },
    {'label': 'Groups', 'emoji': '👥', 'color': AppColors.onboardingCyan},
    {
      'label': 'Splitting & Expenses',
      'emoji': '💸',
      'color': Color(0xFF10B981)
    },
    {'label': 'Payments', 'emoji': '💳', 'color': AppColors.orange},
    {'label': 'Divvy Pro', 'emoji': '⚡', 'color': Colors.amber},
    {'label': 'Privacy & Security', 'emoji': '🔒', 'color': AppColors.coralRed},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedIndex = ref.watch(faqExpandedIndexProvider);
    final searchController = TextEditingController();

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
                    'Help & Support',
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
                    // Search Bar
                    AppTextField(
                      hint: 'Search help articles...',
                      controller: searchController,
                      prefixIcon: Icons.search_rounded,
                      onChanged: (val) {
                        ref.read(faqSearchQueryProvider.notifier).state = val;
                      },
                    ),
                    SizedBox(height: 20.h),

                    // Quick Contact Card Grid (3 Columns)
                    Row(
                      children: [
                        _buildContactCard(
                          icon: Icons.chat_bubble_rounded,
                          iconColor: AppColors.onboardingViolet,
                          title: 'Live Chat',
                          subtitle: '~2 min wait',
                          onTap: () {},
                        ),
                        SizedBox(width: 10.w),
                        _buildContactCard(
                          icon: Icons.email_rounded,
                          iconColor: AppColors.onboardingCyan,
                          title: 'Email Us',
                          subtitle: 'Reply in 24h',
                          onTap: () {},
                        ),
                        SizedBox(width: 10.w),
                        _buildContactCard(
                          icon: Icons.phone_rounded,
                          iconColor: AppColors.orange,
                          title: 'Call Us',
                          subtitle: 'Pro only',
                          onTap: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),

                    // BROWSE TOPICS Section
                    _sectionLabel('BROWSE TOPICS'),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _topics.map((topic) {
                        final color = topic['color'] as Color;
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(topic['emoji'] as String, fontSize: 13),
                              SizedBox(width: 6.w),
                              AppText(
                                topic['label'] as String,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 28.h),

                    // FREQUENTLY ASKED Section
                    _sectionLabel('FREQUENTLY ASKED'),
                    SizedBox(height: 12.h),
                    ...List.generate(_faqs.length, (index) {
                      final isExpanded = expandedIndex == index;
                      final faq = _faqs[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(faqExpandedIndexProvider.notifier).state =
                                isExpanded ? null : index;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? const Color(0xFF171530)
                                  : AppColors.cardDark,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isExpanded
                                    ? AppColors.onboardingViolet
                                    : AppColors.white.withValues(alpha: 0.04),
                                width: 1.2.w,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        faq['question'] as String,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isExpanded
                                            ? AppColors.onboardingViolet
                                            : AppColors.white,
                                      ),
                                    ),
                                    Container(
                                      width: 24.w,
                                      height: 24.w,
                                      decoration: BoxDecoration(
                                        color: isExpanded
                                            ? AppColors.onboardingViolet
                                                .withValues(alpha: 0.12)
                                            : AppColors.white
                                                .withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: isExpanded
                                            ? AppColors.onboardingViolet
                                            : AppColors.white
                                                .withValues(alpha: 0.4),
                                        size: 16.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isExpanded) ...[
                                  SizedBox(height: 12.h),
                                  AppText(
                                    faq['answer'] as String,
                                    fontSize: 13,
                                    color:
                                        AppColors.white.withValues(alpha: 0.6),
                                    height: 1.4,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 32.h),

                    // Footer
                    Center(
                      child: Column(
                        children: [
                          AppText(
                            'Divvy v2.4.1 · Built with ♥ in NYC',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: 0.25),
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 14.sp),
                                SizedBox(width: 4.w),
                                const AppText(
                                  'Rate Divvy on the App Store',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onboardingViolet,
                                ),
                              ],
                            ),
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

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.04),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 24.sp),
              SizedBox(height: 12.h),
              AppText(
                title,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
              SizedBox(height: 4.h),
              AppText(
                subtitle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
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
