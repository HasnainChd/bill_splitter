import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/router/app_router.dart';
import '../../providers/create_group_provider.dart';
import '../providers/screen_providers.dart';

class CreateGroupScreen extends ConsumerWidget {
  const CreateGroupScreen({super.key});

  static const List<IconData> _icons = [
    Icons.flight_takeoff_rounded,
    Icons.home_rounded,
    Icons.local_pizza_rounded,
    Icons.theater_comedy_rounded,
    Icons.bolt_rounded,
    Icons.shopping_cart_rounded,
    Icons.celebration_rounded,
    Icons.landscape_rounded,
    Icons.directions_boat_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.favorite_rounded,
  ];

  static const List<Color> _colors = [
    Color(0xFF818CF8), // violet
    Color(0xFF38BDF8), // cyan
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // purple
    Color(0xFFF97316), // orange
  ];

  // Mock available contacts
  static const List<Map<String, String>> _contacts = [
    {'initials': 'SC', 'name': 'Sarah Chen', 'handle': '@sarah', 'color': '0xFFEC4899'},
    {'initials': 'MT', 'name': 'Marcus T.', 'handle': '@marcus', 'color': '0xFFF59E0B'},
    {'initials': 'PP', 'name': 'Priya Patel', 'handle': '@priya', 'color': '0xFF10B981'},
    {'initials': 'KW', 'name': 'Kai Wilson', 'handle': '@kai', 'color': '0xFF38BDF8'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = ref.watch(cgNameControllerProvider);
    final searchCtrl = ref.watch(cgSearchControllerProvider);
    final iconIndex = ref.watch(cgIconIndexProvider);
    final colorIndex = ref.watch(cgColorIndexProvider);
    final selectedMembers = ref.watch(cgSelectedMembersProvider);
    final searchQuery = ref.watch(cgMemberSearchProvider);
    final groupState = ref.watch(createGroupProvider);

    final groupName = nameCtrl.text.isEmpty ? 'New Group' : nameCtrl.text;
    final selectedColor = _colors[colorIndex];

    final filteredContacts = _contacts
        .where((c) =>
            c['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
            c['handle']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),

                    // ── Icon Preview ──
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  selectedColor,
                                  selectedColor.withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: selectedColor.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              _icons[iconIndex],
                              color: AppColors.white,
                              size: 40.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          AppText(
                            groupName,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // ── GROUP NAME ──
                    AppTextField(
                      label: 'Group Name',
                      hint: 'e.g. NYC Getaway',
                      controller: nameCtrl,
                    ),
                    SizedBox(height: 24.h),

                    // ── ICON ──
                    _label('ICON'),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: List.generate(_icons.length, (i) {
                        final isSelected = i == iconIndex;
                        return GestureDetector(
                          onTap: () => ref
                              .read(cgIconIndexProvider.notifier)
                              .state = i,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.onboardingViolet
                                    : AppColors.white.withValues(alpha: 0.08),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              _icons[i],
                              color: isSelected
                                  ? AppColors.onboardingViolet
                                  : AppColors.white.withValues(alpha: 0.7),
                              size: 22.sp,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 24.h),

                    // ── COLOR ──
                    _label('COLOR'),
                    SizedBox(height: 12.h),
                    Row(
                      children: List.generate(_colors.length, (i) {
                        final isSelected = i == colorIndex;
                        return Padding(
                          padding: EdgeInsets.only(right: 10.w),
                          child: GestureDetector(
                            onTap: () => ref
                                .read(cgColorIndexProvider.notifier)
                                .state = i,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 30.w,
                              height: 30.w,
                              decoration: BoxDecoration(
                                color: _colors[i],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.white
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _colors[i]
                                              .withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 28.h),

                    // ── ADD MEMBERS ──
                    AppTextField(
                      label: 'Add Members',
                      hint: 'Search by name or @username...',
                      controller: searchCtrl,
                      onChanged: (val) => ref
                          .read(cgMemberSearchProvider.notifier)
                          .state = val,
                      prefix: Icon(
                        Icons.search_rounded,
                        color: AppColors.white.withValues(alpha: 0.3),
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Members list
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: List.generate(filteredContacts.length, (i) {
                          final contact = filteredContacts[i];
                          final isSelected =
                              selectedMembers.contains(contact['initials']);
                          final color =
                              Color(int.parse(contact['color']!));
                          final isLast = i == filteredContacts.length - 1;

                          return Column(
                            children: [
                              _buildMemberTile(
                                ref: ref,
                                contact: contact,
                                avatarColor: color,
                                isSelected: isSelected,
                                selectedMembers: selectedMembers,
                              ),
                              if (!isLast)
                                Divider(
                                  color:
                                      AppColors.white.withValues(alpha: 0.04),
                                  height: 1,
                                  indent: 60.w,
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Invite link
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            'Or share invite link → ',
                            fontSize: 13,
                            color: AppColors.white.withValues(alpha: 0.4),
                          ),
                          const AppText(
                            'Copy link',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onboardingViolet,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ── Create Group Button (scrollable) ──
                    GestureDetector(
                      onTap: groupState.isLoading
                          ? null
                          : () => _createGroup(context, ref, nameCtrl, selectedMembers),
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
                        child: groupState.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: AppColors.white, strokeWidth: 2),
                              )
                            : AppText(
                                'Create Group with ${selectedMembers.length} member${selectedMembers.length == 1 ? '' : 's'}',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(AppRouter.home),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  color: AppColors.white, size: 20.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'New Group',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              AppText(
                'Step 1 of 2',
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
          const Spacer(),
          // Progress indicator
          Row(
            children: [
              Container(
                width: 32.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.onboardingViolet,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                width: 32.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile({
    required WidgetRef ref,
    required Map<String, String> contact,
    required Color avatarColor,
    required bool isSelected,
    required Set<String> selectedMembers,
  }) {
    return GestureDetector(
      onTap: () {
        final current = Set<String>.from(selectedMembers);
        final id = contact['initials']!;
        if (current.contains(id)) {
          current.remove(id);
        } else {
          current.add(id);
        }
        ref.read(cgSelectedMembersProvider.notifier).state = current;
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(12.r)),
              alignment: Alignment.center,
              child: AppText(contact['initials']!, fontSize: 13,
                  fontWeight: FontWeight.w800, color: AppColors.white),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(contact['name']!, fontSize: 15,
                      fontWeight: FontWeight.w600, color: AppColors.white),
                  AppText(contact['handle']!, fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.4)),
                ],
              ),
            ),
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.onboardingViolet
                    : AppColors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8.r),
                border: isSelected
                    ? null
                    : Border.all(
                        color: AppColors.white.withValues(alpha: 0.1)),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded,
                      color: AppColors.white, size: 16.sp)
                  : Icon(Icons.add_rounded,
                      color: AppColors.white.withValues(alpha: 0.4),
                      size: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return AppText(
      text,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.white.withValues(alpha: 0.4),
      letterSpacing: 1.2,
    );
  }

  void _createGroup(
    BuildContext context,
    WidgetRef ref,
    TextEditingController nameCtrl,
    Set<String> selectedMembers,
  ) {
    final notifier = ref.read(createGroupProvider.notifier);
    notifier.createGroup(
      nameCtrl.text.trim(),
      selectedMembers.toList(),
      ref,
      context,
    );
  }
}
