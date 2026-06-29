import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/models/group.dart';
import '../../core/models/expense.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/app_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../core/router/app_router.dart';
import '../../providers/profile_provider.dart';
import '../providers/screen_providers.dart';
import '../../core/utils/group_icon_helper.dart';
import '../../core/utils/financial_calculator.dart';
import '../widgets/add_expense_form_elements.dart';

class AddExpenseScreen extends ConsumerWidget {
  final Group group;
  final Expense? expenseToEdit;
  final String? scannedAmount;
  final String? scannedTitle;
  final String? scannedImagePath;
  const AddExpenseScreen({
    super.key,
    required this.group,
    this.expenseToEdit,
    this.scannedAmount,
    this.scannedTitle,
    this.scannedImagePath,
  });

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Food', 'icon': Icons.restaurant_rounded},
    {'label': 'Travel', 'icon': Icons.flight_takeoff_rounded},
    {'label': 'Rent', 'icon': Icons.home_rounded},
    {'label': 'Shopping', 'icon': Icons.shopping_cart_rounded},
    {'label': 'Bills', 'icon': Icons.bolt_rounded},
    {'label': 'Fun', 'icon': Icons.theater_comedy_rounded},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountCtrl = ref.watch(aeAmountControllerProvider);
    final titleCtrl = ref.watch(aeTitleControllerProvider);
    final category = ref.watch(aeCategoryProvider);
    final groupCurrency = group.currency;
    final currencyCode =
        groupCurrency.length >= 3 ? groupCurrency.substring(0, 3) : 'PKR';
    final currencySymbol = (() {
      final openParen = groupCurrency.indexOf('(');
      final closeParen = groupCurrency.indexOf(')');
      if (openParen != -1 && closeParen != -1 && closeParen > openParen) {
        return groupCurrency.substring(openParen + 1, closeParen);
      }
      return currencyCode;
    })();
    final splitType = ref.watch(aeSplitTypeProvider);
    final selectedMembers = ref.watch(aeSelectedMembersProvider);
    final membersAsync = ref.watch(groupMembersProvider(group.groupId));
    final members = membersAsync.value ?? [];
    final currentUserId = ref.watch(supabaseUserProvider)?.id;
    final expenseState = ref.watch(expenseProvider);
    final paidBy = ref.watch(aePaidByProvider) ?? currentUserId;
    final groupColor = AppColors.groupThemeColors[
        group.groupId.hashCode.abs() % AppColors.groupThemeColors.length];

    // Init from expenseToEdit once or default initialization
    if (expenseToEdit != null &&
        selectedMembers.isEmpty &&
        members.isNotEmpty) {
      Future.microtask(() {
        amountCtrl.text = expenseToEdit!.amount.toStringAsFixed(0);
        ref.read(aeAmountValueProvider.notifier).state = expenseToEdit!.amount;
        titleCtrl.text = expenseToEdit!.title;
        ref.read(aePaidByProvider.notifier).state = expenseToEdit!.paidBy;
        ref.read(aeDateProvider.notifier).state = expenseToEdit!.date;
        ref.read(aeNotesControllerProvider).text = expenseToEdit!.notes ?? '';
        ref.read(aeReceiptUrlProvider.notifier).state =
            expenseToEdit!.receiptUrl;
        ref.read(aeReceiptFileProvider.notifier).state = null;

        // Map category
        String initialCat = 'Food';
        for (final cat in _categories) {
          final icon = cat['icon'] as IconData;
          if (icon.codePoint == expenseToEdit!.categoryIconCodePoint) {
            initialCat = cat['label'] as String;
            break;
          }
        }
        ref.read(aeCategoryProvider.notifier).state = initialCat;

        // Set split type directly from database or fallback to dynamic calculation
        String initialSplitType = expenseToEdit!.splitType;
        if (initialSplitType == 'Equal' &&
            expenseToEdit!.splitAmong.isNotEmpty) {
          final splits = expenseToEdit!.splitAmong.values.toList();
          bool isEqual = true;
          if (expenseToEdit!.splitAmong.length != members.length) {
            isEqual = false;
          } else {
            final first = splits.first;
            for (final s in splits) {
              if ((s - first).abs() > 0.05) {
                isEqual = false;
                break;
              }
            }
          }
          if (!isEqual) {
            initialSplitType = 'Custom';
          }
        }

        final bool isEqual = initialSplitType == 'Equal';
        ref.read(aeSplitTypeProvider.notifier).state = initialSplitType;
        ref.read(aeSelectedMembersProvider.notifier).state =
            expenseToEdit!.splitAmong.keys.toSet();
        if (!isEqual) {
          if (initialSplitType == 'Custom') {
            ref.read(aeCustomSplitsProvider.notifier).state =
                Map<String, double>.from(expenseToEdit!.splitAmong);
            ref.read(aePercentSplitsProvider.notifier).state = {};
          } else if (initialSplitType == '%') {
            ref.read(aeCustomSplitsProvider.notifier).state = {};
            final Map<String, double> percentMap = {};
            final totalAmt = expenseToEdit!.amount;
            if (totalAmt > 0) {
              expenseToEdit!.splitAmong.forEach((userId, amt) {
                percentMap[userId] =
                    double.parse(((amt / totalAmt) * 100.0).toStringAsFixed(0));
              });
            }
            ref.read(aePercentSplitsProvider.notifier).state = percentMap;
          }
        } else {
          ref.read(aeCustomSplitsProvider.notifier).state = {};
          ref.read(aePercentSplitsProvider.notifier).state = {};
        }
      });
    } else if (expenseToEdit == null &&
        selectedMembers.isEmpty &&
        members.isNotEmpty) {
      Future.microtask(() {
        ref.read(aePaidByProvider.notifier).state = currentUserId;
        ref.read(aeSelectedMembersProvider.notifier).state =
            members.map((m) => m.id).toSet();
        ref.read(aeCustomSplitsProvider.notifier).state = {};
        ref.read(aePercentSplitsProvider.notifier).state = {};
        if (scannedAmount != null) {
          amountCtrl.text = scannedAmount!;
          ref.read(aeAmountValueProvider.notifier).state =
              double.tryParse(scannedAmount!) ?? 0.0;
        } else {
          ref.read(aeAmountValueProvider.notifier).state = 0.0;
        }
        if (scannedTitle != null) {
          titleCtrl.text = scannedTitle!;
        }
        if (scannedImagePath != null) {
          ref.read(aeReceiptFileProvider.notifier).state =
              File(scannedImagePath!);
        }
        ref.read(aeDateProvider.notifier).state = DateTime.now();
        ref.read(aeNotesControllerProvider).clear();
        ref.read(aeReceiptUrlProvider.notifier).state = null;
        if (scannedImagePath == null) {
          ref.read(aeReceiptFileProvider.notifier).state = null;
        }
      });
    }

    final amountValue = ref.watch(aeAmountValueProvider);
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
        title: AppText(
          expenseToEdit != null ? 'Edit  Expense' : 'Add  Expense',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
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
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 40.w,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                '$currencySymbol ',
                                fontSize: 52.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              IntrinsicWidth(
                                child: TextField(
                                  controller: amountCtrl,
                                  onChanged: (val) {
                                    ref.read(aeAmountValueProvider.notifier).state =
                                        double.tryParse(val) ?? 0.0;
                                  },
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: TextStyle(
                                      fontSize: 52.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.white,
                                      letterSpacing: -1),
                                  cursorColor: AppColors.onboardingViolet,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: '0',
                                    hintStyle: TextStyle(color: Colors.white24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Center(
                      child: AppText(
                        '${GroupIconHelper.getCleanGroupName(group.name)} · ${splitType.toLowerCase()} split',
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
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.backgroundDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20.r)),
                          ),
                          builder: (context) {
                            final groups = ref.read(groupProvider).groups;
                            return SafeArea(
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AppText(
                                      'Select Group',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                    SizedBox(height: 16.h),
                                    if (groups.isEmpty)
                                      const Center(
                                          child: AppText('No groups found',
                                              color: Colors.white54))
                                    else
                                      Flexible(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: groups.length,
                                          itemBuilder: (context, index) {
                                            final g = groups[index];
                                            final iconColor =
                                                AppColors.groupThemeColors[
                                                    g.groupId.hashCode.abs() %
                                                        AppColors
                                                            .groupThemeColors
                                                            .length];
                                            return ListTile(
                                              leading: Container(
                                                width: 32.w,
                                                height: 32.w,
                                                decoration: BoxDecoration(
                                                  color: iconColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.r),
                                                ),
                                                child: Icon(
                                                    GroupIconHelper
                                                        .getIconForGroup(g),
                                                    color: AppColors.white,
                                                    size: 16.sp),
                                              ),
                                              title: AppText(g.name,
                                                  color: AppColors.white),
                                              onTap: () {
                                                Navigator.pop(context);
                                                context.replace(
                                                  '${AppRouter.addExpense}?groupId=${g.groupId}',
                                                  extra: g,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
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
                                color: groupColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                  GroupIconHelper.getIconForGroup(group),
                                  color: groupColor,
                                  size: 16.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppText(
                                GroupIconHelper.getCleanGroupName(group.name),
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
                    ),
                    SizedBox(height: 24.h),

                    // ── PAID BY ──
                    _sectionLabel('PAID BY'),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 80.h,
                      child: membersAsync.when(
                        loading: () => ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 4,
                          itemBuilder: (context, index) => Container(
                            margin: EdgeInsets.only(right: 16.w),
                            child: Column(
                              children: [
                                Container(
                                  width: 46.w,
                                  height: 46.w,
                                  decoration: const BoxDecoration(
                                    color: AppColors.cardDark,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Container(
                                  width: 40.w,
                                  height: 10.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardDark,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        error: (err, __) => Center(
                          child: AppText(
                            'Error loading payers: $err',
                            fontSize: 12,
                            color: AppColors.coralRed,
                          ),
                        ),
                        data: (_) {
                          final displayMembers = members.isNotEmpty
                              ? members
                              : (ref.watch(profileProvider).profile != null
                                  ? [ref.watch(profileProvider).profile!]
                                  : []);
                          if (displayMembers.isEmpty) {
                            return const Center(
                              child: AppText(
                                'No members available',
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: displayMembers.length,
                            itemBuilder: (context, index) {
                              final member = displayMembers[index];
                              final isPayer = member.id == paidBy;
                              final isMe = member.id == currentUserId;

                              final nameParts =
                                  member.fullName.trim().split(' ');
                              final displayName = isMe
                                  ? 'You'
                                  : (nameParts.isNotEmpty
                                      ? nameParts[0]
                                      : 'User');
                              final initials = nameParts.length >= 2
                                  ? '${nameParts[0][0]}${nameParts[1][0]}'
                                  : nameParts.isNotEmpty &&
                                          nameParts[0].isNotEmpty
                                      ? nameParts[0][0]
                                      : 'U';

                              final avatarColor = AppColors.avatarColors[
                                  member.id.hashCode.abs() %
                                      AppColors.avatarColors.length];

                              return GestureDetector(
                                onTap: () {
                                  ref.read(aePaidByProvider.notifier).state =
                                      member.id;
                                },
                                child: Container(
                                  margin: EdgeInsets.only(right: 16.w),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 180),
                                            width: 46.w,
                                            height: 46.w,
                                            decoration: BoxDecoration(
                                              color: avatarColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isPayer
                                                    ? AppColors.onboardingViolet
                                                    : Colors.transparent,
                                                width: 2.5.w,
                                              ),
                                              image: member.avatarUrl.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                          member.avatarUrl),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: member.avatarUrl.isEmpty
                                                ? AppText(
                                                    initials.toUpperCase(),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.white,
                                                  )
                                                : null,
                                          ),
                                          if (isPayer)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding: EdgeInsets.all(2.w),
                                                decoration: const BoxDecoration(
                                                  color: AppColors
                                                      .onboardingViolet,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  color: AppColors.white,
                                                  size: 10.sp,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 6.h),
                                      AppText(
                                        displayName,
                                        fontSize: 12,
                                        fontWeight: isPayer
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isPayer
                                            ? AppColors.white
                                            : AppColors.white
                                                .withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ── DATE ──
                    _sectionLabel('DATE'),
                    SizedBox(height: 12.h),
                    const DatePickerField(),
                    SizedBox(height: 24.h),

                    // ── NOTES ──
                    _sectionLabel('NOTES'),
                    SizedBox(height: 12.h),
                    const NotesField(),
                    SizedBox(height: 24.h),

                    // ── RECEIPT ──
                    _sectionLabel('RECEIPT'),
                    SizedBox(height: 12.h),
                    const ReceiptAttachmentPicker(),
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
                      child: membersAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(
                                color: AppColors.onboardingViolet),
                          ),
                        ),
                        error: (err, stack) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: AppText('Failed to load group members: $err',
                              color: AppColors.white),
                        ),
                        data: (_) {
                          if (members.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: AppText('No members in group',
                                  color: Colors.white54),
                            );
                          }
                          return Column(
                            children: List.generate(members.length, (i) {
                              final member = members[i];
                              final isMe = member.id == currentUserId;

                              final isSelected =
                                  selectedMembers.contains(member.id);
                              final avatarColor = AppColors.avatarColors[
                                  member.id.hashCode.abs() %
                                      AppColors.avatarColors.length];
                              final isLast = i == members.length - 1;

                              return Column(
                                children: [
                                  MemberSplitRow(
                                    member: member,
                                    isMe: isMe,
                                    isSelected: isSelected,
                                    avatarColor: avatarColor,
                                    currency: currencySymbol,
                                    splitType: splitType,
                                    equalAmount: isSelected ? perPerson : 0.0,
                                  ),
                                  if (!isLast)
                                    Divider(
                                      color: AppColors.white
                                          .withValues(alpha: 0.04),
                                      height: 1,
                                      indent: 68.w,
                                    ),
                                ],
                              );
                            }),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // ── Add/Update Expense Button (scrollable) ──
                    GestureDetector(
                      onTap: expenseState.isLoading
                          ? null
                          : () {
                              _saveExpense(
                                  context,
                                  ref,
                                  amountCtrl,
                                  titleCtrl,
                                  selectedMembers,
                                  currentUserId);
                            },
                      child: Container(
                        width: double.infinity,
                        height: 54.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: expenseState.isLoading
                                ? [
                                    AppColors.onboardingViolet
                                        .withValues(alpha: 0.5),
                                    AppColors.primaryPurpleDarker
                                        .withValues(alpha: 0.5),
                                  ]
                                : [
                                    AppColors.onboardingViolet,
                                    AppColors.primaryPurpleDarker,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(28.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.onboardingViolet.withValues(
                                  alpha: expenseState.isLoading ? 0.15 : 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: expenseState.isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                        color: AppColors.white, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12.w),
                                  AppText(
                                    expenseToEdit != null
                                        ? 'Updating...'
                                        : 'Saving...',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ],
                              )
                            : AppText(
                                expenseToEdit != null
                                    ? 'Update Expense · $currencySymbol ${amountValue.toStringAsFixed(2)}'
                                    : 'Add Expense · $currencySymbol ${amountValue.toStringAsFixed(2)}',
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
    String? currentUserId,
  ) async {
    final title = titleCtrl.text.trim();
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    final splitType = ref.read(aeSplitTypeProvider);
    final groupCurrency = group.currency;
    final currencyCode =
        groupCurrency.length >= 3 ? groupCurrency.substring(0, 3) : 'PKR';

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
    if (currentUserId == null) {
      AppSnackBar.showError(context, 'No user logged in');
      return;
    }

    Map<String, double> splitAmong = {};

    if (splitType == 'Equal') {
      splitAmong = FinancialCalculator.generateEqualSplits(
          amount, selectedMembers.toList());
    } else if (splitType == 'Custom') {
      final customMap = ref.read(aeCustomSplitsProvider);
      final totalCustom =
          selectedMembers.fold(0.0, (sum, m) => sum + (customMap[m] ?? 0.0));
      if ((totalCustom - amount).abs() > 0.05) {
        final totalCustomStr = totalCustom % 1 == 0
            ? totalCustom.toStringAsFixed(0)
            : totalCustom.toStringAsFixed(2);
        final amountStr = amount % 1 == 0
            ? amount.toStringAsFixed(0)
            : amount.toStringAsFixed(2);
        AppSnackBar.showError(context,
            'The sum of custom splits ($currencyCode $totalCustomStr) must equal the total amount ($currencyCode $amountStr)');
        return;
      }
      splitAmong = {
        for (final m in selectedMembers) m: customMap[m] ?? 0.0,
      };
    } else if (splitType == '%') {
      final percentMap = ref.read(aePercentSplitsProvider);
      final totalPercent =
          selectedMembers.fold(0.0, (sum, m) => sum + (percentMap[m] ?? 0.0));
      if ((totalPercent - 100.0).abs() > 0.05) {
        final totalPercentStr = totalPercent % 1 == 0
            ? totalPercent.toStringAsFixed(0)
            : totalPercent.toStringAsFixed(2);
        AppSnackBar.showError(context,
            'The sum of percentages ($totalPercentStr%) must equal 100%');
        return;
      }
      final Map<String, double> pctSplits = {};
      final memberList = selectedMembers.toList();
      for (final m in memberList) {
        final pct = percentMap[m] ?? 0.0;
        pctSplits[m] = double.parse(((pct / 100.0) * amount).toStringAsFixed(2));
      }
      if (memberList.isNotEmpty) {
        final firstMember = memberList.first;
        double sum = 0.0;
        pctSplits.forEach((key, val) {
          if (key != firstMember) {
            sum += val;
          }
        });
        pctSplits[firstMember] = double.parse((amount - sum).toStringAsFixed(2));
      }
      splitAmong = pctSplits;
    }

    final selectedCatLabel = ref.read(aeCategoryProvider);
    final catMap = _categories.firstWhere((c) => c['label'] == selectedCatLabel,
        orElse: () => _categories.first);
    final iconData = catMap['icon'] as IconData;
    final categoryIconCodePoint = iconData.codePoint;

    try {
      final paidBy = ref.read(aePaidByProvider) ?? currentUserId;
      final date = ref.read(aeDateProvider);
      final notes = ref.read(aeNotesControllerProvider).text.trim();
      final notesOrNull = notes.isEmpty ? null : notes;

      String? finalReceiptUrl = ref.read(aeReceiptUrlProvider);
      final file = ref.read(aeReceiptFileProvider);

      if (file != null) {
        finalReceiptUrl =
            await ref.read(expenseProvider.notifier).uploadReceipt(file);
      }

      if (expenseToEdit != null) {
        final updatedExpense = Expense(
          expenseId: expenseToEdit!.expenseId,
          title: title,
          amount: amount,
          currency: currencyCode,
          paidBy: paidBy,
          splitAmong: splitAmong,
          date: date,
          notes: notesOrNull,
          receiptUrl: finalReceiptUrl,
          groupId: expenseToEdit!.groupId,
          categoryIconCodePoint: categoryIconCodePoint,
          splitType: splitType,
          createdAt: expenseToEdit!.createdAt,
          updatedAt: expenseToEdit!.updatedAt,
        );
        await ref.read(expenseProvider.notifier).updateExpense(updatedExpense);
        if (context.mounted) {
          AppSnackBar.showSuccess(context, 'Expense updated!');
          context.pop();
        }
      } else {
        await ref.read(expenseProvider.notifier).addExpense(
              groupId: group.groupId,
              title: title,
              amount: amount,
              currency: currencyCode,
              paidBy: paidBy,
              splitAmong: splitAmong,
              categoryIconCodePoint: categoryIconCodePoint,
              splitType: splitType,
              date: date,
              notes: notesOrNull,
              receiptUrl: finalReceiptUrl,
            );
        if (context.mounted) {
          AppSnackBar.showSuccess(context, 'Expense added!');
          context.pop();
        }
      }
    } catch (e) {
      if (context.mounted) {
        if (expenseToEdit != null) {
          await AppDialog.showInfo(
            context,
            title: 'Update Failed',
            message:
                'Failed to save expense changes. The local cache has been reverted to prevent mismatch.\n\nError: $e',
            buttonText: 'OK',
          );
        } else {
          AppSnackBar.showError(context, 'Failed to save expense: $e');
        }
      }
    }
  }
}

class MemberSplitRow extends ConsumerStatefulWidget {
  final UserProfile member;
  final bool isMe;
  final bool isSelected;
  final Color avatarColor;
  final String currency;
  final String splitType;
  final double equalAmount;

  const MemberSplitRow({
    super.key,
    required this.member,
    required this.isMe,
    required this.isSelected,
    required this.avatarColor,
    required this.currency,
    required this.splitType,
    required this.equalAmount,
  });

  @override
  ConsumerState<MemberSplitRow> createState() => _MemberSplitRowState();
}

class _MemberSplitRowState extends ConsumerState<MemberSplitRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _updateText();
  }

  @override
  void didUpdateWidget(MemberSplitRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.splitType != oldWidget.splitType ||
        widget.equalAmount != oldWidget.equalAmount) {
      _updateText();
    }
  }

  void _updateText() {
    if (widget.splitType == 'Equal') {
      _controller.text = widget.equalAmount.toStringAsFixed(0);
    } else if (widget.splitType == 'Custom') {
      final customMap = ref.read(aeCustomSplitsProvider);
      final currentVal = customMap[widget.member.id] ?? 0.0;
      _controller.text = currentVal > 0 ? currentVal.toStringAsFixed(0) : '';
    } else if (widget.splitType == '%') {
      final percentMap = ref.read(aePercentSplitsProvider);
      final currentVal = percentMap[widget.member.id] ?? 0.0;
      _controller.text = currentVal > 0 ? currentVal.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameParts = widget.member.fullName.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : nameParts.isNotEmpty && nameParts[0].isNotEmpty
            ? nameParts[0][0]
            : 'U';

    final isSelected = widget.isSelected;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Checkbox toggle
          GestureDetector(
            onTap: () {
              final selected =
                  Set<String>.from(ref.read(aeSelectedMembersProvider));
              if (selected.contains(widget.member.id)) {
                selected.remove(widget.member.id);
              } else {
                selected.add(widget.member.id);
              }
              ref.read(aeSelectedMembersProvider.notifier).state = selected;
            },
            child: Container(
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
          ),
          SizedBox(width: 12.w),
          // Avatar
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: widget.avatarColor,
              borderRadius: BorderRadius.circular(10.r),
              image: widget.member.avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.member.avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: widget.member.avatarUrl.isEmpty
                ? AppText(
                    initials.toUpperCase(),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          // Name
          Expanded(
            child: AppText(
              widget.isMe ? 'You' : widget.member.fullName,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          // Input or Display
          if (widget.splitType == 'Equal')
            AppText(
              '${widget.currency} ${widget.equalAmount.toStringAsFixed(0)}',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: 0.25),
            )
          else if (widget.splitType == 'Custom')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  '${widget.currency} ',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white.withValues(alpha: 0.4),
                ),
                SizedBox(
                  width: 70.w,
                  height: 36.h,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                      filled: true,
                      fillColor: AppColors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      final customMap = Map<String, double>.from(
                          ref.read(aeCustomSplitsProvider));
                      customMap[widget.member.id] = parsed;
                      ref.read(aeCustomSplitsProvider.notifier).state =
                          customMap;
                    },
                  ),
                ),
              ],
            )
          else if (widget.splitType == '%')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60.w,
                  height: 36.h,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                      filled: true,
                      fillColor: AppColors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      final percentMap = Map<String, double>.from(
                          ref.read(aePercentSplitsProvider));
                      percentMap[widget.member.id] = parsed;
                      ref.read(aePercentSplitsProvider.notifier).state =
                          percentMap;
                    },
                  ),
                ),
                SizedBox(width: 4.w),
                AppText(
                  '%',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
