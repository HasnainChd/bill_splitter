import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/expense.dart';
import '../../core/models/group.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/expense_provider.dart';
import '../../core/utils/app_dialog.dart';
import '../../providers/profile_provider.dart';
import '../../core/router/app_router.dart';
import '../../providers/settings_provider.dart';
import '../../core/utils/group_icon_helper.dart';
import '../../core/utils/app_date_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/screen_providers.dart';

final expenseReminderLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class ExpenseDetailScreen extends ConsumerWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load latest remote details for this expense fresh on mount
    final loadedExpenses = ref.watch(loadedSingleExpensesProvider);
    if (!loadedExpenses.contains(this.expense.expenseId)) {
      Future.microtask(() {
        ref
            .read(loadedSingleExpensesProvider.notifier)
            .update((state) => {...state, this.expense.expenseId});
        ref.read(expenseProvider.notifier).loadExpense(this.expense.expenseId);
      });
    }

    final isReminding = ref.watch(expenseReminderLoadingProvider);
    final groupState = ref.watch(groupProvider);
    final expenseState = ref.watch(expenseProvider);
    final currentUserId = ref.watch(supabaseUserProvider)?.id;
    final membersAsync = ref.watch(groupMembersProvider(this.expense.groupId));
    final members = membersAsync.value ?? [];

    // Watch list of expenses reactively to handle live updates from edit screen
    final groupExpenses =
        ref.watch(expensesForGroupProvider(this.expense.groupId));
    final resolvedExpense = groupExpenses.firstWhere(
      (e) => e.expenseId == this.expense.expenseId,
      orElse: () => this.expense,
    );
    final expense = resolvedExpense;

    final group = groupState.groups.firstWhere(
      (g) => g.groupId == expense.groupId,
      orElse: () => Group(
        groupId: expense.groupId,
        name: 'Group Detail',
        members: const [],
        currency: expense.currency,
        createdAt: DateTime.now(),
      ),
    );

    final currencyCode = expense.currency.isNotEmpty
        ? expense.currency
        : (group.currency.length >= 3 ? group.currency.substring(0, 3) : 'PKR');

    final activeDateFormat = ref.watch(dateFormatProvider);
    final dateStr = AppDateFormatter.format(expense.date, activeDateFormat);

    final totalAmount = expense.amount;
    final emoji = _getEmoji(expense.title, expense.categoryIconCodePoint);
    final categoryLabel =
        _getCategoryLabel(expense.title, expense.categoryIconCodePoint);

    final isUserPayer = expense.paidBy == currentUserId;
    final myOwedAmt = currentUserId != null
        ? (expense.splitAmong[currentUserId] ?? 0.0)
        : 0.0;

    final payerProfile = members.firstWhere(
      (m) => m.id == expense.paidBy,
      orElse: () => UserProfile(
        id: expense.paidBy,
        fullName: 'Another Member',
        username: '',
        email: '',
        phone: '',
        bio: '',
        currency: expense.currency,
        avatarUrl: '',
      ),
    );
    final payerName =
        currentUserId == expense.paidBy ? 'You' : payerProfile.fullName;

    final displaySplitType = (() {
      if (expense.splitType == '%') return 'Percentage';
      if (expense.splitType == 'Custom') return 'Exact Amount';

      // Dynamic fallback for legacy data:
      final splits = expense.splitAmong.values.toList();
      if (splits.isEmpty) return 'Equal';
      if (members.isNotEmpty && expense.splitAmong.length != members.length) {
        return 'Exact Amount';
      }
      final first = splits.first;
      for (final s in splits) {
        if ((s - first).abs() > 0.05) {
          return 'Exact Amount';
        }
      }
      return 'Equal';
    })();

    final balances = ref.watch(balancesForGroupProvider(group.groupId));

    final memberMap = {
      for (final m in members) m.id: m.fullName,
    };

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          children: [
            Positioned(
              top: -60.h,
              right: -60.w,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1C38),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Custom Header (Fixed) ──
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        AppText(
                          'Expense Detail',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                                  Icons.refresh_rounded,
                                  color: AppColors.white.withValues(alpha: 0.8),
                                  size: 18.sp,
                                ),
                                onPressed: () async {
                                  AppSnackBar.showInfo(context, 'Refreshing expense details...');
                                  await ref
                                      .read(expenseProvider.notifier)
                                      .loadExpense(expense.expenseId);
                                  if (context.mounted) {
                                    AppSnackBar.showSuccess(context, 'Expense details refreshed!');
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 8.w),
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
                                  Icons.edit_outlined,
                                  color: const Color(0xFFFBBF24),
                                  size: 18.sp,
                                ),
                                onPressed: () {
                                  context.push(
                                    AppRouter.addExpense,
                                    extra: {
                                      'group': group,
                                      'expense': expense,
                                    },
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 8.w),
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
                                  Icons.delete_outline_rounded,
                                  color: AppColors.white.withValues(alpha: 0.7),
                                  size: 18.sp,
                                ),
                                onPressed: () async {
                                  final confirm = await AppDialog.showConfirm(
                                    context,
                                    title: 'Delete Expense',
                                    message:
                                        'Are you sure you want to delete this expense?',
                                    confirmText: 'Delete',
                                    cancelText: 'Cancel',
                                    isDanger: true,
                                  );
                                  if (confirm != true) return;
                                  try {
                                    await ref
                                        .read(expenseProvider.notifier)
                                        .deleteExpense(
                                            expense.groupId, expense.expenseId);
                                    if (context.mounted) {
                                      AppSnackBar.showSuccess(
                                          context, 'Expense deleted');
                                      context.pop();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      await AppDialog.showInfo(
                                        context,
                                        title: 'Delete Failed',
                                        message:
                                            'Failed to delete expense. The action has been reverted.\n\nError: $e',
                                        buttonText: 'OK',
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable Body ──
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Centered Large Icon & Info
                          Center(
                            child: Column(
                              children: [
                                AppText(
                                  emoji,
                                  fontSize: 56,
                                ),
                                SizedBox(height: 16.h),
                                AppText(
                                  expense.title,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  align: TextAlign.center,
                                ),
                                SizedBox(height: 6.h),
                                AppText(
                                  '${GroupIconHelper.getCleanGroupName(group.name)} · $dateStr',
                                  fontSize: 13,
                                  color: AppColors.white.withValues(alpha: 0.4),
                                ),
                                SizedBox(height: 20.h),
                                AppText(
                                  '$currencyCode ${totalAmount.toStringAsFixed(2)}',
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AppText(
                                      'Paid by ',
                                      fontSize: 13,
                                      color: AppColors.white
                                          .withValues(alpha: 0.4),
                                    ),
                                    AppText(
                                      payerName,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onboardingViolet,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 28.h),

                          // Summary Details Card
                          AppCard(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 10.h),
                            child: Column(
                              children: [
                                _buildDetailRow('Paid by', payerName),
                                _buildDivider(),
                                _buildDetailRow('Split Type', displaySplitType),
                                _buildDivider(),
                                _buildDetailRow(
                                    'Group',
                                    GroupIconHelper.getCleanGroupName(
                                        group.name)),
                                _buildDivider(),
                                _buildDetailRow('Category', categoryLabel),
                                _buildDivider(),
                                _buildDetailRow('Date', dateStr),
                                if (expense.createdAt != null) ...[
                                  _buildDivider(),
                                  _buildDetailRow(
                                    'Added On',
                                    '${AppDateFormatter.format(expense.createdAt!, activeDateFormat)} ${DateFormat('h:mm a').format(expense.createdAt!)}',
                                  ),
                                ],
                                if (expense.updatedAt != null) ...[
                                  _buildDivider(),
                                  _buildDetailRow(
                                    'Updated On',
                                    '${AppDateFormatter.format(expense.updatedAt!, activeDateFormat)} ${DateFormat('h:mm a').format(expense.updatedAt!)}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: 32.h),

                          // Split Breakdown Card
                          _sectionLabel('SPLIT BREAKDOWN'),
                          SizedBox(height: 12.h),
                          AppCard(
                            padding: EdgeInsets.zero,
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
                                child: AppText(
                                    'Failed to load split breakdown: $err',
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

                                // Pre-calculate displayed amounts for all members to ensure exact sum matching the total expense amount
                                final Map<String, double> displayedSplitAmounts = {};
                                {
                                  String? lastParticipatingMemberId;
                                  for (int i = members.length - 1; i >= 0; i--) {
                                    final m = members[i];
                                    final owed = expense.splitAmong[m.id] ?? 0.0;
                                    if (owed.abs() > 0.0001) {
                                      lastParticipatingMemberId = m.id;
                                      break;
                                    }
                                  }

                                  double sumOfOthers = 0.0;
                                  for (final m in members) {
                                    final rawAmt = expense.splitAmong[m.id] ?? 0.0;
                                    if (m.id == lastParticipatingMemberId) {
                                      continue;
                                    }
                                    final rounded = double.parse(rawAmt.toStringAsFixed(2));
                                    displayedSplitAmounts[m.id] = rounded;
                                    if (rawAmt.abs() > 0.0001) {
                                      sumOfOthers += rounded;
                                    }
                                  }

                                  if (lastParticipatingMemberId != null) {
                                    displayedSplitAmounts[lastParticipatingMemberId] = double.parse((expense.amount - sumOfOthers).toStringAsFixed(2));
                                  }
                                }

                                return Column(
                                  children:
                                      List.generate(members.length, (index) {
                                    final m = members[index];
                                    final isMe = m.id == currentUserId;
                                    final isPayer = m.id == expense.paidBy;

                                    final nameParts =
                                        m.fullName.trim().split(' ');
                                    final initials = nameParts.length >= 2
                                        ? '${nameParts[0][0]}${nameParts[1][0]}'
                                            .toUpperCase()
                                        : nameParts.isNotEmpty &&
                                                nameParts[0].isNotEmpty
                                            ? nameParts[0][0].toUpperCase()
                                            : 'U';

                                    final avatarColor = AppColors.avatarColors[
                                        m.id.hashCode.abs() %
                                            AppColors.avatarColors.length];

                                    // Calculations
                                    final double owedAmt =
                                        displayedSplitAmounts[m.id] ?? 0.0;

                                    final isLast = index == members.length - 1;

                                    return Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.w, vertical: 14.h),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40.w,
                                                height: 40.w,
                                                decoration: BoxDecoration(
                                                  color: avatarColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r),
                                                  image: m.avatarUrl.isNotEmpty
                                                      ? DecorationImage(
                                                          image: NetworkImage(
                                                              m.avatarUrl),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                alignment: Alignment.center,
                                                child: m.avatarUrl.isEmpty
                                                    ? AppText(
                                                        initials,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors.white,
                                                      )
                                                    : null,
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: AppText(
                                                            isMe
                                                                ? 'You'
                                                                : m.fullName,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AppColors.white,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    AppText(
                                                      (() {
                                                        final memberBalance =
                                                            balances[m.id] ??
                                                                0.0;
                                                        final balanceSign =
                                                            memberBalance > 0
                                                                ? '+'
                                                                : (memberBalance <
                                                                        0
                                                                    ? '-'
                                                                    : '');
                                                        final base = isPayer
                                                            ? 'Paid $currencyCode ${totalAmount.toStringAsFixed(2)} · '
                                                            : '';
                                                        return "$base${isMe ? 'Your' : "${m.fullName}'s"} group balance: $balanceSign$currencyCode${memberBalance.abs().toStringAsFixed(2)}";
                                                      })(),
                                                      fontSize: 11,
                                                      color: AppColors.white
                                                          .withValues(
                                                              alpha: 0.4),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              AppText(
                                                '$currencyCode ${owedAmt.toStringAsFixed(2)}',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isLast)
                                          Divider(
                                            color: Colors.white
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

                          // Receipt Box
                          if (expense.receiptUrl != null &&
                              expense.receiptUrl!.isNotEmpty) ...[
                            _sectionLabel('RECEIPT'),
                            SizedBox(height: 12.h),
                            AppCard(
                              padding: EdgeInsets.zero,
                              onTap: () {
                                // Open full screen image
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: EdgeInsets.all(16.w),
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        InteractiveViewer(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16.r),
                                            child: Image.network(
                                              expense.receiptUrl!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.white, size: 30),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24.r),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    expense.receiptUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 28.h),
                          ] else ...[
                            _sectionLabel('RECEIPT'),
                            SizedBox(height: 12.h),
                            AppCard(
                              padding: EdgeInsets.all(16.w),
                              onTap: () {
                                _showDigitalReceipt(
                                  context,
                                  expense,
                                  memberMap,
                                  currentUserId ?? '',
                                  payerName,
                                  currencyCode,
                                  activeDateFormat,
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 44.w,
                                    height: 44.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.coralRed
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: AppColors.coralRed,
                                      size: 24.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          'receipt_${expense.title.toLowerCase().replaceAll(' ', '_')}.pdf',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.white,
                                        ),
                                        SizedBox(height: 2.h),
                                        AppText(
                                          'Generated Digital Receipt',
                                          fontSize: 12,
                                          color: AppColors.white
                                              .withValues(alpha: 0.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.download_rounded,
                                    color:
                                        AppColors.white.withValues(alpha: 0.4),
                                    size: 20.sp,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 28.h),
                          ],

                          // Notes Box
                          if (expense.notes != null &&
                              expense.notes!.isNotEmpty) ...[
                            _sectionLabel('NOTES'),
                            SizedBox(height: 12.h),
                            AppCard(
                              padding: EdgeInsets.all(16.w),
                              child: SizedBox(
                                width: double.infinity,
                                child: AppText(
                                  expense.notes!,
                                  fontSize: 14,
                                  color: AppColors.white.withValues(alpha: 0.8),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 28.h),
                          ],

                          // Reminder Button (only show for non-settlements)
                          if (expense.title != 'Settle Payment' &&
                              expense.categoryIconCodePoint !=
                                  Icons.handshake_rounded.codePoint) ...[
                            if (isUserPayer) ...[
                              if (totalAmount - myOwedAmt > 0 &&
                                  (balances[currentUserId] ?? 0.0) > 0.01 &&
                                  expense.splitAmong.keys.any((id) =>
                                      id != currentUserId &&
                                      (balances[id] ?? 0.0) < -0.01))
                                AppButton(
                                  label:
                                      'Remind members · $currencyCode ${(totalAmount - myOwedAmt).toStringAsFixed(0)}',
                                  color: AppColors.onboardingViolet,
                                  textColor: AppColors.white,
                                  isLoading: isReminding,
                                  onTap: () async {
                                    final targetIds = expense.splitAmong.keys
                                        .where((id) =>
                                            id != currentUserId &&
                                            (balances[id] ?? 0.0) < -0.01)
                                        .toList();

                                    if (targetIds.isEmpty) {
                                      AppSnackBar.showError(context,
                                          'All members in this expense are already settled!');
                                      return;
                                    }

                                    final confirm = await AppDialog.showConfirm(
                                      context,
                                      title: 'Send Reminder',
                                      message:
                                          'Are you sure you want to send a payment reminder to other members?',
                                      confirmText: 'Send',
                                      cancelText: 'Cancel',
                                    );
                                    if (confirm == true) {
                                      ref
                                          .read(expenseReminderLoadingProvider
                                              .notifier)
                                          .state = true;
                                      try {
                                        final response = await Supabase
                                            .instance.client.functions
                                            .invoke(
                                          'send-notification',
                                          body: {
                                            'table': 'payment_reminders',
                                            'new_record': {
                                              'group_id': expense.groupId,
                                              'sender_id': currentUserId,
                                              'target_user_ids': targetIds,
                                              'amount': totalAmount - myOwedAmt,
                                              'currency': currencyCode,
                                            },
                                          },
                                        );

                                        if (response.status != 200 &&
                                            response.status != 204) {
                                          throw Exception(
                                              'Server returned status code ${response.status}');
                                        }

                                        if (context.mounted) {
                                          AppSnackBar.showSuccess(context,
                                              'Reminder sent to members!');
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          AppSnackBar.showError(context,
                                              'Failed to send reminder: $e');
                                        }
                                      } finally {
                                        ref
                                            .read(expenseReminderLoadingProvider
                                                .notifier)
                                            .state = false;
                                      }
                                    }
                                  },
                                ),
                            ],
                          ],
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (expenseState.isLoading)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: AppColors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.onboardingViolet,
                            ),
                            SizedBox(height: 16.h),
                            const AppText(
                              'Deleting...',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getEmoji(String title, int codePoint) {
    if (codePoint == Icons.restaurant_rounded.codePoint ||
        codePoint == Icons.restaurant.codePoint ||
        codePoint == 0xe567) {
      return '🍕';
    } else if (codePoint == Icons.flight_takeoff_rounded.codePoint ||
        codePoint == Icons.flight.codePoint) {
      return '✈️';
    } else if (codePoint == Icons.home_rounded.codePoint ||
        codePoint == Icons.home.codePoint) {
      return '🏠';
    } else if (codePoint == Icons.shopping_cart_rounded.codePoint ||
        codePoint == Icons.shopping_cart.codePoint) {
      return '🛍️';
    } else if (codePoint == Icons.bolt_rounded.codePoint ||
        codePoint == Icons.bolt.codePoint) {
      return '⚡';
    } else if (codePoint == Icons.theater_comedy_rounded.codePoint ||
        codePoint == Icons.theater_comedy.codePoint) {
      return '🎭';
    } else if (codePoint == Icons.handshake_rounded.codePoint ||
        codePoint == Icons.handshake.codePoint) {
      return '🤝';
    }

    final t = title.toLowerCase();
    if (t.contains('airbnb') ||
        t.contains('hotel') ||
        t.contains('accommodation') ||
        t.contains('stay') ||
        t.contains('hostel')) {
      return '🏨';
    }
    if (t.contains('food') ||
        t.contains('restaurant') ||
        t.contains('dinner') ||
        t.contains('lunch') ||
        t.contains('thai') ||
        t.contains('pizza') ||
        t.contains('burger')) {
      return '🍕';
    }
    if (t.contains('settle')) {
      return '🤝';
    }
    return '🍕';
  }

  String _getCategoryLabel(String title, int codePoint) {
    final emoji = _getEmoji(title, codePoint);
    if (emoji == '🏨') return '🏨 Accom.';
    if (emoji == '🍕') return '🍕 Food';
    if (emoji == '✈️') return '✈️ Travel';
    if (emoji == '🏠') return '🏠 Rent';
    if (emoji == '🛍️') return '🛍️ Shop';
    if (emoji == '⚡') return '⚡ Bills';
    if (emoji == '🎭') return '🎭 Fun';
    if (emoji == '🤝') return '🤝 Settle';
    return '🍕 Food';
  }

  Widget _sectionLabel(String text) {
    return AppText(
      text,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.white.withValues(alpha: 0.4),
      letterSpacing: 1.0,
    );
  }

  void _showDigitalReceipt(
    BuildContext context,
    Expense expense,
    Map<String, String> memberMap,
    String currentUserId,
    String payerName,
    String currencyCode,
    String activeDateFormat,
  ) {
    // Pre-calculate displayed amounts for all members to ensure exact sum matching the total expense amount
    final Map<String, double> displayedSplitAmounts = {};
    {
      final keys = expense.splitAmong.keys.toList();
      String? lastParticipatingMemberId;
      for (int i = keys.length - 1; i >= 0; i--) {
        final key = keys[i];
        final owed = expense.splitAmong[key] ?? 0.0;
        if (owed.abs() > 0.0001) {
          lastParticipatingMemberId = key;
          break;
        }
      }

      double sumOfOthers = 0.0;
      for (final key in keys) {
        final rawAmt = expense.splitAmong[key] ?? 0.0;
        if (key == lastParticipatingMemberId) {
          continue;
        }
        final rounded = double.parse(rawAmt.toStringAsFixed(2));
        displayedSplitAmounts[key] = rounded;
        if (rawAmt.abs() > 0.0001) {
          sumOfOthers += rounded;
        }
      }

      if (lastParticipatingMemberId != null) {
        displayedSplitAmounts[lastParticipatingMemberId] = double.parse((expense.amount - sumOfOthers).toStringAsFixed(2));
      }
    }

    bool isDownloading = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B3A),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.onboardingViolet,
                      size: 40.sp,
                    ),
                    SizedBox(height: 12.h),
                    const AppText(
                      'DIGITAL RECEIPT',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textGrey,
                      letterSpacing: 1.5,
                    ),
                    SizedBox(height: 16.h),
                    AppText(
                      expense.title,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      align: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      '${AppDateFormatter.format(expense.date, activeDateFormat)} · ${DateFormat('hh:mm a').format(expense.date)}',
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0
                                ? Colors.transparent
                                : AppColors.textGrey.withValues(alpha: 0.3),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppText('Paid By',
                            fontSize: 13, color: AppColors.textGrey),
                        AppText(payerName,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        'SPLIT DETAILS',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...expense.splitAmong.entries.map((entry) {
                      final name = entry.key == currentUserId
                          ? 'You'
                          : (memberMap[entry.key] ?? 'Member');
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(name,
                                fontSize: 13,
                                color: AppColors.white.withValues(alpha: 0.7)),
                            AppText(
                                '$currencyCode ${(displayedSplitAmounts[entry.key] ?? entry.value).toStringAsFixed(2)}',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 16.h),
                    Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0
                                ? Colors.transparent
                                : AppColors.textGrey.withValues(alpha: 0.3),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppText('Total Amount',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white),
                        AppText(
                            '$currencyCode ${expense.amount.toStringAsFixed(2)}',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Container(
                      height: 40.h,
                      width: 180.w,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          25,
                          (i) => Container(
                            width: (i % 3 == 0)
                                ? 2.w
                                : (i % 5 == 0)
                                    ? 4.w
                                    : 1.w,
                            color: i % 2 == 0
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.transparent,
                            margin: EdgeInsets.symmetric(horizontal: 1.w),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    AppText(
                      'TXN-${expense.expenseId.hashCode.abs().toString().padLeft(8, '0')}',
                      fontSize: 10,
                      color: AppColors.textGrey,
                      letterSpacing: 2.0,
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const AppText('Close',
                                fontSize: 13, color: AppColors.white),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.onboardingViolet,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            onPressed: isDownloading
                                ? null
                                : () async {
                                    setState(() {
                                      isDownloading = true;
                                    });
                                    await Future.delayed(
                                        const Duration(milliseconds: 1500));
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      AppSnackBar.showSuccess(
                                        context,
                                        'PDF Receipt Download: Feature coming soon!',
                                      );
                                    }
                                  },
                            child: isDownloading
                                ? SizedBox(
                                    height: 16.w,
                                    width: 16.w,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const AppText('Download PDF',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            fontSize: 13,
            color: AppColors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.w500,
          ),
          AppText(
            value,
            fontSize: 13,
            color: valueColor ?? AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.white.withValues(alpha: 0.04),
      height: 1,
    );
  }
}
