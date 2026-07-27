import 'package:bill_splitter/core/utils/app_snackbar.dart';
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
import '../../core/utils/group_icon_helper.dart';

class CreateGroupScreen extends ConsumerWidget {
  const CreateGroupScreen({super.key});

  static const List<Map<String, String>> _currencies = [
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
    final nameCtrl = ref.watch(cgNameControllerProvider);
    final searchCtrl = ref.watch(cgSearchControllerProvider);
    final selectedIconCodePoint = ref.watch(cgSelectedIconCodePointProvider);
    final colorIndex = ref.watch(cgColorIndexProvider);
    final selectedMembers = ref.watch(cgSelectedMembersProvider);
    final searchQuery = ref.watch(cgMemberSearchProvider);
    final groupState = ref.watch(createGroupProvider);
    final selectedCurrency = ref.watch(cgSelectedCurrencyProvider);

    final groupName = nameCtrl.text.isEmpty ? 'New Group' : nameCtrl.text;
    final selectedColor = AppColors.groupThemeColors[colorIndex];

    final isQueryLongEnough =
        searchQuery.trim().replaceAll('@', '').length >= 2;

    final usersAsync = isQueryLongEnough
        ? ref.watch(searchedUsersProvider(searchQuery))
        : ref.watch(allUsersProvider);

    final usersList = usersAsync.value ?? [];
    final cleanQuery = searchQuery.trim().startsWith('@')
        ? searchQuery.trim().substring(1)
        : searchQuery.trim();
    final filteredUsers = isQueryLongEnough
        ? usersList
        : usersList
            .where((u) =>
                u.fullName.toLowerCase().contains(cleanQuery.toLowerCase()) ||
                u.username.toLowerCase().contains(cleanQuery.toLowerCase()))
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
                              GroupIconHelper.getIconFromCodePoint(
                                  selectedIconCodePoint),
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
                      maxLength: 50,
                      errorText: ref.watch(cgNameErrorProvider),
                      onChanged: (val) {
                        if (ref.read(cgNameErrorProvider) != null) {
                          ref.read(cgNameErrorProvider.notifier).state = null;
                        }
                      },
                    ),
                    SizedBox(height: 24.h),

                    // ── ICON ──
                    _label('ICON'),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Quick select icons
                        ...GroupIconHelper.quickSelectIcons.map((item) {
                          final isSelected =
                              item.icon.codePoint == selectedIconCodePoint;
                          return GestureDetector(
                            onTap: () => ref
                                .read(cgSelectedIconCodePointProvider.notifier)
                                .state = item.icon.codePoint,
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
                                item.icon,
                                color: isSelected
                                    ? AppColors.onboardingViolet
                                    : AppColors.white.withValues(alpha: 0.7),
                                size: 22.sp,
                              ),
                            ),
                          );
                        }),

                        // "More" button
                        GestureDetector(
                          onTap: () => _showAllIconsDialog(context, ref),
                          child: Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: !GroupIconHelper.quickSelectIcons.any(
                                        (item) =>
                                            item.icon.codePoint ==
                                            selectedIconCodePoint)
                                    ? AppColors.onboardingViolet
                                    : AppColors.white.withValues(alpha: 0.08),
                                width: !GroupIconHelper.quickSelectIcons.any(
                                        (item) =>
                                            item.icon.codePoint ==
                                            selectedIconCodePoint)
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              color: !GroupIconHelper.quickSelectIcons.any(
                                      (item) =>
                                          item.icon.codePoint ==
                                          selectedIconCodePoint)
                                  ? AppColors.onboardingViolet
                                  : AppColors.white.withValues(alpha: 0.7),
                              size: 22.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // ── COLOR ──
                    _label('COLOR'),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children:
                          List.generate(AppColors.groupThemeColors.length, (i) {
                        final isSelected = i == colorIndex;
                        return GestureDetector(
                          onTap: () =>
                              ref.read(cgColorIndexProvider.notifier).state = i,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 30.w,
                            height: 30.w,
                            decoration: BoxDecoration(
                              color: AppColors.groupThemeColors[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.groupThemeColors[i]
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 28.h),

                    // ── CURRENCY ──
                    _label('CURRENCY'),
                    SizedBox(height: 12.h),
                    GestureDetector(
                      onTap: () => _showCurrencyPickerSheet(context, ref),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1C38),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getFlagForCurrency(selectedCurrency),
                                style: TextStyle(fontSize: 16.sp),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppText(
                                selectedCurrency,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.white.withValues(alpha: 0.4),
                              size: 20.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // ── ADD MEMBERS ──
                    AppTextField(
                      label: 'Add Members',
                      hint: 'Search by name or @username...',
                      controller: searchCtrl,
                      onChanged: (val) =>
                          ref.read(cgMemberSearchProvider.notifier).state = val,
                      prefix: Icon(
                        Icons.search_rounded,
                        color: AppColors.white.withValues(alpha: 0.3),
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Members list
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05)),
                      ),
                      child: usersAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(
                              color: AppColors.onboardingViolet,
                            ),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: AppText(
                              'Failed to load users: $err',
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        data: (_) {
                          if (filteredUsers.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: AppText(
                                  'No registered users found',
                                  color: Colors.white54,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: List.generate(filteredUsers.length, (i) {
                              final contact = filteredUsers[i];
                              final isSelected =
                                  selectedMembers.contains(contact.id);

                              // Compute initials
                              final nameParts =
                                  contact.fullName.trim().split(' ');
                              final initials = nameParts.length >= 2
                                  ? '${nameParts[0][0]}${nameParts[1][0]}'
                                      .toUpperCase()
                                  : nameParts.isNotEmpty &&
                                          nameParts[0].isNotEmpty
                                      ? nameParts[0][0].toUpperCase()
                                      : 'U';

                              // Compute color based on ID hash
                              final color = AppColors.avatarColors[
                                  contact.id.hashCode.abs() %
                                      AppColors.avatarColors.length];
                              final isLast = i == filteredUsers.length - 1;

                              return Column(
                                children: [
                                  _buildMemberTile(
                                    ref: ref,
                                    contactId: contact.id,
                                    name: contact.fullName,
                                    handle: '@${contact.username}',
                                    initials: initials,
                                    avatarColor: color,
                                    isSelected: isSelected,
                                    selectedMembers: selectedMembers,
                                    avatarUrl: contact.avatarUrl,
                                  ),
                                  if (!isLast)
                                    Divider(
                                      color: AppColors.white
                                          .withValues(alpha: 0.04),
                                      height: 1,
                                      indent: 60.w,
                                    ),
                                ],
                              );
                            }),
                          );
                        },
                      ),
                    ),
                    if (ref.watch(cgMembersErrorProvider) != null) ...[
                      SizedBox(height: 8.h),
                      AppText(
                        ref.watch(cgMembersErrorProvider)!,
                        color: AppColors.coralRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                    SizedBox(height: 16.h),

                    // ── Create Group Button (scrollable) ──
                    GestureDetector(
                      onTap: groupState.isLoading
                          ? null
                          : () => _createGroup(context, ref, nameCtrl,
                              selectedMembers, selectedIconCodePoint),
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
                                  const AppText(
                                    'Creating...',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ],
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
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1C38),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.white,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMemberTile({
    required WidgetRef ref,
    required String contactId,
    required String name,
    required String handle,
    required String initials,
    required Color avatarColor,
    required bool isSelected,
    required Set<String> selectedMembers,
    String? avatarUrl,
  }) {
    return GestureDetector(
      onTap: () {
        final current = Set<String>.from(selectedMembers);
        if (current.contains(contactId)) {
          current.remove(contactId);
        } else {
          current.add(contactId);
        }
        ref.read(cgSelectedMembersProvider.notifier).state = current;
        if (ref.read(cgMembersErrorProvider) != null) {
          ref.read(cgMembersErrorProvider.notifier).state = null;
        }
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
                borderRadius: BorderRadius.circular(12.r),
                image: avatarUrl != null && avatarUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? AppText(initials,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(name,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white),
                  AppText(handle,
                      fontSize: 12,
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
                    : Border.all(color: AppColors.white.withValues(alpha: 0.1)),
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
    int selectedIconCodePoint,
  ) {
    final name = nameCtrl.text.trim();

    // Reset errors
    ref.read(cgNameErrorProvider.notifier).state = null;
    ref.read(cgMembersErrorProvider.notifier).state = null;

    bool hasError = false;

    if (name.isEmpty) {
      ref.read(cgNameErrorProvider.notifier).state =
          'Please enter a group name';
      hasError = true;
    }

    if (selectedMembers.isEmpty) {
      ref.read(cgMembersErrorProvider.notifier).state =
          'Please select at least one member to add to the group';
      hasError = true;
    }

    if (hasError) {
      AppSnackBar.showError(
          context, 'Please fix the errors above before continuing');
      return;
    }

    final selectedCurrency = ref.read(cgSelectedCurrencyProvider);
    final notifier = ref.read(createGroupProvider.notifier);
    notifier.createGroup(
      name: name,
      members: selectedMembers.toList(),
      iconCodePoint: selectedIconCodePoint,
      iconFontFamily: 'MaterialIcons',
      ref: ref,
      context: context,
      currency: selectedCurrency,
    );
  }

  String _getFlagForCurrency(String currencyCode) {
    final found = _currencies.firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {'flag': '🏳️'},
    );
    return found['flag']!;
  }

  void _showCurrencyPickerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Select Group Currency',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
                SizedBox(height: 16.h),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _currencies.length,
                    itemBuilder: (context, index) {
                      final cur = _currencies[index];
                      final isSelected =
                          ref.read(cgSelectedCurrencyProvider) == cur['code'];
                      return ListTile(
                        leading: Text(cur['flag']!,
                            style: TextStyle(fontSize: 20.sp)),
                        title: AppText(cur['code']!,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold),
                        subtitle: AppText(cur['name']!,
                            color: Colors.white54, fontSize: 12),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.onboardingViolet)
                            : null,
                        onTap: () {
                          ref.read(cgSelectedCurrencyProvider.notifier).state =
                              cur['code']!;
                          Navigator.pop(context);
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
  }

  void _showAllIconsDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _IconPickerSheet(
                ref: ref, scrollController: scrollController);
          },
        );
      },
    );
  }
}

class _IconPickerSheet extends StatefulWidget {
  final WidgetRef ref;
  final ScrollController scrollController;
  const _IconPickerSheet({required this.ref, required this.scrollController});

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIconCodePoint =
        widget.ref.watch(cgSelectedIconCodePointProvider);
    final filtered = GroupIconHelper.allIcons.where((item) {
      return item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.category.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    // Group by category
    final Map<String, List<GroupIconItem>> grouped = {};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 8.h, bottom: 16.h),
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Select Group Icon',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.white),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: AppTextField(
            hint: 'Search icons...',
            controller: _searchController,
            prefix: Icon(Icons.search_rounded,
                color: AppColors.white.withValues(alpha: 0.3), size: 18.sp),
            onChanged: (val) {
              setState(() {
                _query = val;
              });
            },
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final category = grouped.keys.elementAt(index);
              final items = grouped[category]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: AppText(
                      category.toUpperCase(),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white.withValues(alpha: 0.4),
                      letterSpacing: 1.2,
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final isSelected =
                          selectedIconCodePoint == item.icon.codePoint;
                      return GestureDetector(
                        onTap: () {
                          widget.ref
                              .read(cgSelectedIconCodePointProvider.notifier)
                              .state = item.icon.codePoint;
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.onboardingViolet
                                    .withValues(alpha: 0.15)
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.onboardingViolet
                                  : AppColors.white.withValues(alpha: 0.05),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            color: isSelected
                                ? AppColors.onboardingViolet
                                : AppColors.white,
                            size: 22.sp,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
