import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';

final faqExpandedIndexProvider =
    StateProvider.autoDispose<int?>((ref) => 0); // Index 0 expanded by default
final faqSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final faqSelectedTopicProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final helpSearchControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  static const List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I split a bill unequally?',
      'answer':
          'Tap "Add Expense" → select "Custom Split" → enter the exact amount for each person. You can also split by percentage.',
      'topic': 'Splitting & Expenses',
    },
    {
      'question': 'Can I add expenses in other currencies?',
      'answer':
          'Yes, Equaly supports multiple currencies. When creating a group, you can specify its primary currency. All transactions inside that group will use that currency.',
      'topic': 'Splitting & Expenses',
    },
    {
      'question': 'How do I settle my balances?',
      'answer':
          'Open your group, tap "Settle Up", select the member you want to pay, and choose your payment method to log the settlement.',
      'topic': 'Payments',
    },
    {
      'question': 'What happens if someone leaves a group?',
      'answer':
          'Any outstanding balances must be settled before a member can leave a group. Once settled, they can be removed by the group admin or leave via group settings.',
      'topic': 'Groups',
    },
    {
      'question': 'How is my personal data secured?',
      'answer':
          'We secure your transactions and details using industrial-grade database encryption. You can request your data copy or delete your account permanently in the Privacy settings.',
      'topic': 'Privacy & Security',
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
    {'label': 'Privacy & Security', 'emoji': '🔒', 'color': AppColors.coralRed},
  ];

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedIndex = ref.watch(faqExpandedIndexProvider);
    final searchQuery = ref.watch(faqSearchQueryProvider);
    final selectedTopic = ref.watch(faqSelectedTopicProvider);
    final searchController = ref.watch(helpSearchControllerProvider);

    // Filter FAQs based on query and topic
    final filteredFaqs = _faqs.where((faq) {
      final matchesSearch = searchQuery.isEmpty ||
          faq['question']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesTopic =
          selectedTopic == null || faq['topic'] == selectedTopic;
      return matchesSearch && matchesTopic;
    }).toList();

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
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.cardDark,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r)),
                                title: const AppText('Live Chat Offline',
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                                content: const AppText(
                                  'All support agents are currently assisting other users. Please email us at devcodeinnovations@gmail.com for support.',
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const AppText('OK',
                                        color: AppColors.onboardingViolet),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 10.w),
                        _buildContactCard(
                          icon: Icons.email_rounded,
                          iconColor: AppColors.onboardingCyan,
                          title: 'Email Us',
                          subtitle: 'Reply in 24h',
                          onTap: () => _launchUrl(
                              'mailto:devcodeinnovations@gmail.com?subject=Equaly%20Support%20Request'),
                        ),
                        SizedBox(width: 10.w),
                        _buildContactCard(
                          icon: Icons.phone_rounded,
                          iconColor: AppColors.orange,
                          title: 'Call Us',
                          subtitle: 'Pro only',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.cardDark,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r)),
                                title: const AppText('Premium Support',
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                                content: const AppText(
                                  'Phone support is exclusive to Equaly Pro subscribers. Standard users can contact us 24/7 via Email.',
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const AppText('OK',
                                        color: AppColors.onboardingViolet),
                                  ),
                                ],
                              ),
                            );
                          },
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
                      children: [
                        // Clear Filter pill if a topic is selected
                        if (selectedTopic != null)
                          GestureDetector(
                            onTap: () => ref
                                .read(faqSelectedTopicProvider.notifier)
                                .state = null,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.close_rounded,
                                      size: 14, color: AppColors.white),
                                  const SizedBox(width: 4.0),
                                  const AppText(
                                    'Clear Filter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ..._topics.map((topic) {
                          final label = topic['label'] as String;
                          final isSelected = selectedTopic == label;
                          final color = topic['color'] as Color;
                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(faqSelectedTopicProvider.notifier)
                                  .state = isSelected ? null : label;
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.2)
                                    : color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : color.withValues(alpha: 0.2),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppText(topic['emoji'] as String,
                                      fontSize: 13),
                                  SizedBox(width: 6.w),
                                  AppText(
                                    label,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: 28.h),

                    // FREQUENTLY ASKED Section
                    _sectionLabel('FREQUENTLY ASKED'),
                    SizedBox(height: 12.h),
                    filteredFaqs.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.h),
                            child: const Center(
                              child: AppText(
                                'No matching FAQs found.',
                                fontSize: 14,
                                color: AppColors.textGrey,
                              ),
                            ),
                          )
                        : Column(
                            children:
                                List.generate(filteredFaqs.length, (index) {
                              final faq = filteredFaqs[index];
                              // Find actual index in static _faqs for expanded state tracking
                              final actualIndex = _faqs.indexOf(faq);
                              final isExpanded = expandedIndex == actualIndex;
                              return Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(faqExpandedIndexProvider.notifier)
                                        .state = isExpanded ? null : actualIndex;
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
                                            : AppColors.white
                                                .withValues(alpha: 0.04),
                                        width: 1.2.w,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                        .withValues(
                                                            alpha: 0.05),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isExpanded
                                                    ? Icons
                                                        .keyboard_arrow_up_rounded
                                                    : Icons
                                                        .keyboard_arrow_down_rounded,
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
                                            color: AppColors.white
                                                .withValues(alpha: 0.6),
                                            height: 1.4,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                    SizedBox(height: 32.h),

                    // Footer
                    Center(
                      child: Column(
                        children: [
                          AppText(
                            'Equaly v1.0.0 · Production Ready',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: 0.25),
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: () =>
                                _launchUrl('https://play.google.com/store'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 14.sp),
                                SizedBox(width: 4.w),
                                const AppText(
                                  'Rate Equaly on the Play Store',
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
