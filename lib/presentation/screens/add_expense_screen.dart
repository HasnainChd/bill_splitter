import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/models/group.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/firebase_expense_provider.dart';
import '../providers/screen_providers.dart';

class AddExpenseScreen extends ConsumerWidget {
  final Group group;
  const AddExpenseScreen({super.key, required this.group});

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Food', 'icon': Icons.restaurant_rounded},
    {'label': 'Travel', 'icon': Icons.flight_takeoff_rounded},
    {'label': 'Rent', 'icon': Icons.home_rounded},
    {'label': 'Shopping', 'icon': Icons.shopping_cart_rounded},
    {'label': 'Bills', 'icon': Icons.bolt_rounded},
    {'label': 'Fun', 'icon': Icons.theater_comedy_rounded},
  ];

  static const Map<String, Color> _avatarColors = {
    'AJ': AppColors.onboardingViolet,
    'SC': Color(0xFFEC4899),
    'MT': Color(0xFFF59E0B),
    'PP': Color(0xFF10B981),
    'KW': Color(0xFF8B5CF6),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountCtrl = ref.watch(aeAmountControllerProvider);
    final titleCtrl = ref.watch(aeTitleControllerProvider);
    final category = ref.watch(aeCategoryProvider);
    final splitType = ref.watch(aeSplitTypeProvider);
    final selectedMembers = ref.watch(aeSelectedMembersProvider);

    // Init selected members once (all members selected by default)
    if (selectedMembers.isEmpty && group.members.isNotEmpty) {
      Future.microtask(() => ref
          .read(aeSelectedMembersProvider.notifier)
          .state = group.members.toSet());
    }

    final amountValue = double.tryParse(amountCtrl.text) ?? 0;
    final perPerson =
        selectedMembers.isNotEmpty ? amountValue / selectedMembers.length : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 70.h,
        leadingWidth: 70.w,
        centerTitle: true,
        leading: Center(
          child: Container(
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
        ),
        title: Column(
          children: [
            const AppText(
              'Add',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
            AppText(
              'Expense',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // ── Large Amount Display ──
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            '\$',
                            fontSize: 52.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                          IntrinsicWidth(
                            child: TextField(
                              controller: amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: TextStyle(
                                fontSize: 52.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                                letterSpacing: -1,
                              ),
                              cursorColor: AppColors.onboardingViolet,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: Colors.white24,
                                ),
                              ),
                              onChanged: (_) {},
                            ),
                          ),
                        ],
                      ),
                    ),

                    Center(
                      child: AppText(
                        '${group.name} · ${splitType.toLowerCase()} split',
                        fontSize: 13,
                        color: AppColors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // ── DESCRIPTION ──
                    AppTextField(
                      label: 'Description',
                      hint: 'e.g. Thai restaurant',
                      controller: titleCtrl,
                      prefix: Icon(
                        Icons.format_list_bulleted_rounded,
                        color: AppColors.onboardingViolet,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ── CATEGORY ──
                    _sectionLabel('CATEGORY'),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _categories.map((cat) {
                        final isSelected = category == cat['label'];
                        return GestureDetector(
                          onTap: () => ref
                              .read(aeCategoryProvider.notifier)
                              .state = cat['label'] as String,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 9.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.onboardingViolet
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat['icon'] as IconData,
                                    size: 15.sp,
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.white
                                            .withValues(alpha: 0.6)),
                                SizedBox(width: 6.w),
                                AppText(
                                  cat['label'] as String,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.white.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24.h),

                    // ── GROUP ──
                    _sectionLabel('GROUP'),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              color: AppColors.groupOrange,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(Icons.local_pizza_rounded,
                                color: AppColors.white, size: 16.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: AppText(
                              group.name,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.white.withValues(alpha: 0.4),
                              size: 20.sp),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ── SPLIT ──
                    _sectionLabel('SPLIT'),
                    SizedBox(height: 12.h),
                    _buildSplitToggle(ref, splitType),
                    SizedBox(height: 16.h),

                    // ── Members ──
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: List.generate(group.members.length, (i) {
                          final member = group.members[i];
                          final initials = member.length >= 2
                              ? member.substring(0, 2).toUpperCase()
                              : member.toUpperCase();
                          final isSelected = selectedMembers.contains(member);
                          final avatarColor = _avatarColors[initials] ??
                              _avatarColors.values
                                  .elementAt(i % _avatarColors.length);
                          final isLast = i == group.members.length - 1;

                          return Column(
                            children: [
                              _buildMemberRow(
                                ref: ref,
                                member: member,
                                displayName: member == group.members.first
                                    ? 'You'
                                    : member,
                                initials: initials,
                                avatarColor: avatarColor,
                                isSelected: isSelected,
                                amount: isSelected ? perPerson : 0.0,
                                selectedMembers: selectedMembers,
                              ),
                              if (!isLast)
                                Divider(
                                  color:
                                      AppColors.white.withValues(alpha: 0.04),
                                  height: 1,
                                  indent: 68.w,
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // ── Add Expense Button (scrollable) ──
                    GestureDetector(
                      onTap: () => _saveExpense(context, ref, amountCtrl,
                          titleCtrl, selectedMembers, perPerson),
                      child: Container(
                        width: double.infinity,
                        height: 54.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.onboardingViolet,
                              AppColors.primaryPurpleDarker,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.onboardingViolet
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: AppText(
                          'Add Expense · \$${amountValue.toStringAsFixed(2)}',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitToggle(WidgetRef ref, String splitType) {
    const options = ['Equal', 'Custom', '%'];
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = splitType == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(aeSplitTypeProvider.notifier).state = opt,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF1E1B3A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: AppText(
                  opt,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.white
                      : AppColors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMemberRow({
    required WidgetRef ref,
    required String member,
    required String displayName,
    required String initials,
    required Color avatarColor,
    required bool isSelected,
    required double amount,
    required Set<String> selectedMembers,
  }) {
    return GestureDetector(
      onTap: () {
        final current = Set<String>.from(selectedMembers);
        if (current.contains(member)) {
          current.remove(member);
        } else {
          current.add(member);
        }
        ref.read(aeSelectedMembersProvider.notifier).state = current;
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(
                    10.r), // Match premium rounded corners
              ),
              alignment: Alignment.center,
              child: AppText(initials,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppText(displayName,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white),
            ),
            // Checkbox
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.onboardingViolet
                    : AppColors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded,
                      color: AppColors.white, size: 16.sp)
                  : null,
            ),
            SizedBox(width: 16.w),
            AppText(
              '\$${amount.toStringAsFixed(0)}',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return AppText(
      label,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.white.withValues(alpha: 0.4),
      letterSpacing: 1.2,
    );
  }

  Future<void> _saveExpense(
    BuildContext context,
    WidgetRef ref,
    TextEditingController amountCtrl,
    TextEditingController titleCtrl,
    Set<String> selectedMembers,
    double perPerson,
  ) async {
    final title = titleCtrl.text.trim();
    final amount = double.tryParse(amountCtrl.text) ?? 0;

    if (title.isEmpty) {
      AppSnackBar.showError(context, 'Please enter a description');
      return;
    }
    if (amount <= 0) {
      AppSnackBar.showError(context, 'Please enter a valid amount');
      return;
    }
    if (selectedMembers.isEmpty) {
      AppSnackBar.showError(context, 'Select at least one member');
      return;
    }

    final splitAmong = {
      for (final m in selectedMembers) m: perPerson,
    };

    final selectedCatLabel = ref.read(aeCategoryProvider);
    final catMap = _categories.firstWhere((c) => c['label'] == selectedCatLabel,
        orElse: () => _categories.first);
    final iconData = catMap['icon'] as IconData;
    final categoryIconCodePoint = iconData.codePoint;

    await ref.read(firebaseExpenseProvider.notifier).addExpense(
          groupId: group.groupId,
          title: title,
          amount: amount,
          currency: group.currency,
          paidBy: group.members.isNotEmpty ? group.members.first : 'You',
          splitAmong: splitAmong,
          categoryIconCodePoint: categoryIconCodePoint,
        );

    if (context.mounted) {
      AppSnackBar.showSuccess(context, 'Expense added!');
      context.pop();
    }
  }
}
