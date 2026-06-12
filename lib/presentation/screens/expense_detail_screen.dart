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
import '../../providers/firebase_group_provider.dart';
import '../../providers/firebase_expense_provider.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  static const Map<String, Color> _avatarColors = {
    'AJ': AppColors.onboardingViolet,
    'SC': Color(0xFFEC4899),
    'MT': Color(0xFFF59E0B),
    'PP': Color(0xFF10B981),
    'KW': Color(0xFF8B5CF6),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(firebaseGroupProvider);
    final group = groupState.groups.firstWhere(
      (g) => g.groupId == expense.groupId,
      orElse: () => Group(
        groupId: expense.groupId,
        name: 'Friday Dinner Crew',
        members: expense.splitAmong.keys.toList().isNotEmpty
            ? expense.splitAmong.keys.toList()
            : const ['You', 'Sarah', 'Marcus', 'Priya'],
        currency: expense.currency,
        createdAt: DateTime.now(),
      ),
    );

    final dateStr = DateFormat('MMMM d, yyyy').format(expense.date);
    final shortDateStr = DateFormat('MMM d').format(expense.date);

    // Dynamic split calculation
    final totalAmount = expense.amount;
    final splitCount =
        expense.splitAmong.isNotEmpty ? expense.splitAmong.length : 1;
    final share = totalAmount / splitCount;

    final emoji = _getEmoji(expense.title, expense.categoryIconCodePoint);
    final categoryLabel = _getCategoryLabel(expense.title, expense.categoryIconCodePoint);

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          children: [
            // Decorative background circle in the top right
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
            
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // ── Custom Header (In Scroll View) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (no border, dark background card)
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
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            AppText(
                              'Expense',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                            AppText(
                              'Detail',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                      // Actions Row (no border)
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
                                Icons.edit_outlined,
                                color: const Color(0xFFFBBF24), // Yellow/Orange pencil icon
                                size: 18.sp,
                              ),
                              onPressed: () {
                                AppSnackBar.showSuccess(
                                    context, 'Edit functionality coming soon');
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
                                color: AppColors.white.withValues(alpha: 0.7), // Grey/White delete icon
                                size: 18.sp,
                              ),
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(firebaseExpenseProvider.notifier)
                                      .deleteExpense(
                                          expense.groupId, expense.expenseId);
                                  if (context.mounted) {
                                    AppSnackBar.showSuccess(
                                        context, 'Expense deleted');
                                    context.pop();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppSnackBar.showError(
                                        context, 'Failed to delete expense');
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // Centered Large Icon & Info
                  Center(
                    child: Column(
                      children: [
                        // Large stand-alone emoji directly on background (no container card)
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
                          '${group.name} · $dateStr',
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.4),
                        ),
                        SizedBox(height: 20.h),
                        AppText(
                          '\$${totalAmount.toStringAsFixed(2)}',
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
                              color: AppColors.white.withValues(alpha: 0.4),
                            ),
                            AppText(
                              expense.paidBy == 'You' ||
                                      (group.members.isNotEmpty &&
                                          expense.paidBy == group.members.first)
                                  ? 'You'
                                  : expense.paidBy,
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

                  // Info Cards Row (vertical cards Category, Split, Date using AppCard)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard(
                        label: 'Category',
                        content: categoryLabel,
                      ),
                      _buildInfoCard(
                        label: 'Split',
                        content: '⚖️ Equal',
                      ),
                      _buildInfoCard(
                        label: 'Date',
                        content: '📅 $shortDateStr',
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // Split Breakdown Card
                  _sectionLabel('SPLIT BREAKDOWN'),
                  SizedBox(height: 12.h),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: List.generate(group.members.length, (index) {
                        final memberName = group.members[index];
                        final isPayer = memberName == expense.paidBy ||
                            (memberName == 'You' &&
                                expense.paidBy == group.members.first);

                        final initials = memberName.length >= 2
                            ? memberName.substring(0, 2).toUpperCase()
                            : memberName.toUpperCase();

                        final avatarColor = _avatarColors[initials] ??
                            _avatarColors.values
                                .elementAt(index % _avatarColors.length);

                        // Calculate balance
                        final double displayBal =
                            isPayer ? (totalAmount - share) : share;
                        final isLast = index == group.members.length - 1;

                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 14.h),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 40.w,
                                    height: 40.w,
                                    decoration: BoxDecoration(
                                      color: avatarColor,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    alignment: Alignment.center,
                                    child: AppText(
                                      initials,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),

                                  // Name & Subtitle & Status
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            AppText(
                                              memberName == group.members.first
                                                  ? 'You'
                                                  : memberName,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.white,
                                            ),
                                            SizedBox(width: 8.w),
                                            _buildStatusBadge(isPayer),
                                          ],
                                        ),
                                        SizedBox(height: 4.h),
                                        AppText(
                                          isPayer
                                              ? 'Paid \$${totalAmount.toStringAsFixed(0)}'
                                              : 'Owes \$${share.toStringAsFixed(0)}',
                                          fontSize: 11,
                                          color: AppColors.white
                                              .withValues(alpha: 0.4),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Net Balance
                                  AppText(
                                    '${isPayer ? '+' : '-'}\$${displayBal.toStringAsFixed(0)}',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isPayer
                                        ? const Color(0xFF00C896)
                                        : AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                color: Colors.white.withValues(alpha: 0.04),
                                height: 1,
                                indent: 68.w,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Receipt Box
                  _sectionLabel('RECEIPT'),
                  SizedBox(height: 12.h),
                  AppCard(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: AppColors.coralRed.withValues(alpha: 0.12),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                'receipt_thai_restaurant.pdf',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                              SizedBox(height: 2.h),
                              AppText(
                                '2.4 MB',
                                fontSize: 12,
                                color: AppColors.white.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.download_rounded,
                          color: AppColors.white.withValues(alpha: 0.4),
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Notes Box
                  if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                    _sectionLabel('NOTES'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.all(16.w),
                      child: AppText(
                        expense.notes!,
                        fontSize: 13,
                        color: AppColors.white.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],

                  // ── Reminder Button (Full Width via AppButton) ──
                  AppButton(
                    label: 'Remind members · \$${(totalAmount - share).toStringAsFixed(0)}',
                    color: AppColors.onboardingViolet,
                    textColor: AppColors.white,
                    onTap: () {
                      AppSnackBar.showSuccess(
                          context, 'Reminder sent to members!');
                    },
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String label, required String content}) {
    return AppCard(
      borderRadius: 16.r,
      padding: EdgeInsets.zero,
      child: Container(
        width: 108.w,
        height: 64.h,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              label,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.4),
            ),
            SizedBox(height: 6.h),
            AppText(
              content,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }

  String _getEmoji(String title, int codePoint) {
    final t = title.toLowerCase();
    if (t.contains('airbnb') || t.contains('hotel') || t.contains('accommodation') || t.contains('stay') || t.contains('hostel')) {
      return '🏨';
    }
    if (t.contains('food') || t.contains('restaurant') || t.contains('dinner') || t.contains('lunch') || t.contains('thai') || t.contains('pizza') || t.contains('burger')) {
      return '🍕';
    }
    if (codePoint == Icons.restaurant_rounded.codePoint || codePoint == Icons.restaurant.codePoint || codePoint == 0xe567) {
      return '🍕';
    } else if (codePoint == Icons.flight_takeoff_rounded.codePoint || codePoint == Icons.flight.codePoint) {
      return '✈️';
    } else if (codePoint == Icons.home_rounded.codePoint || codePoint == Icons.home.codePoint) {
      return '🏠';
    } else if (codePoint == Icons.shopping_cart_rounded.codePoint || codePoint == Icons.shopping_cart.codePoint) {
      return '🛍️';
    } else if (codePoint == Icons.bolt_rounded.codePoint || codePoint == Icons.bolt.codePoint) {
      return '⚡';
    } else if (codePoint == Icons.theater_comedy_rounded.codePoint || codePoint == Icons.theater_comedy.codePoint) {
      return '🎭';
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
    return '🍕 Food';
  }

  Widget _buildStatusBadge(bool isPayer) {
    final color = isPayer ? const Color(0xFF00C896) : const Color(0xFFFFA500);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPayer ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 10.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          AppText(
            isPayer ? 'Settled' : 'Pending',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ],
      ),
    );
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
}
