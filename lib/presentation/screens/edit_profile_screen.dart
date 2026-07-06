import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/profile_provider.dart';
import '../../providers/edit_profile_provider.dart';
import '../providers/screen_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  static const List<String> _currencies = [
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
    'JPY (¥)',
    'AUD (A\$)',
    'PKR (Rs)',
  ];

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        ref
            .read(editProfileFormProvider.notifier)
            .updateSelectedImagePath(pickedFile.path);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppColors.coralRed.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.coralRed.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.coralRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.coralRed,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              const AppText(
                'Delete Account?',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              SizedBox(height: 12.h),
              const AppText(
                'Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.',
                fontSize: 14,
                color: AppColors.textGrey,
                align: TextAlign.center,
                height: 1.4,
              ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        alignment: Alignment.center,
                        child: const AppText(
                          'Cancel',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: AppColors.coralRed,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.coralRed.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const AppText(
                          'Delete',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: AppColors.coralRed,
          ),
        ),
      );

      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          // Delete from public.users (relies on RLS allowing delete for own user)
          await supabase.from('users').delete().eq('id', user.id);
          await supabase.auth.signOut();
          
          if (context.mounted) {
            Navigator.pop(context); // pop loading dialog
            context.go('/login');
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // pop loading dialog
          AppSnackBar.showError(context, 'Failed to delete account: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.onboardingViolet),
        ),
      );
    }

    final formState = ref.watch(editProfileFormProvider);
    final initials = _getInitials(formState.nameCtrl.text.isNotEmpty
        ? formState.nameCtrl.text
        : profile.fullName);

    // Determine the avatar image provider
    ImageProvider? avatarImage;
    if (!formState.isRemovingAvatar) {
      if (formState.selectedImagePath != null) {
        avatarImage = FileImage(File(formState.selectedImagePath!));
      } else if (profile.avatarUrl.isNotEmpty) {
        avatarImage = NetworkImage(profile.avatarUrl);
      }
    }

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 30.h),
                // ── Custom Header ──
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button (No border card)
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
                      const AppText(
                        'Edit Profile',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                      // Save Button
                      TextButton(
                        onPressed: formState.isSaving
                            ? null
                            : () async {
                                final success = await ref
                                    .read(editProfileFormProvider.notifier)
                                    .save(context);
                                if (success && context.mounted) {
                                  AppSnackBar.showSuccess(
                                      context, 'Profile changes saved!');
                                  context.pop();
                                }
                              },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                        ),
                        child: AppText(
                          'Save',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: formState.isSaving
                              ? AppColors.white.withValues(alpha: 0.3)
                              : AppColors.onboardingViolet,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // ── Scrollable Edit Form ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar center setup
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 96.w,
                                    height: 96.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.onboardingViolet,
                                      borderRadius: BorderRadius.circular(24.r),
                                      image: avatarImage != null
                                          ? DecorationImage(
                                              image: avatarImage,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: avatarImage == null
                                        ? AppText(
                                            initials,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.white,
                                          )
                                        : null,
                                  ),
                                  // Edit circle badge
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _pickImage(context, ref),
                                      child: Container(
                                        width: 28.w,
                                        height: 28.w,
                                        decoration: BoxDecoration(
                                          color: AppColors.onboardingViolet,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.backgroundDark,
                                            width: 2.w,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.white,
                                          size: 14.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              // Upload & Remove pills
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickImage(context, ref),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1C38),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      child: const AppText(
                                        'Upload photo',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(
                                              editProfileFormProvider.notifier)
                                          .setRemovingAvatar(true);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.coralRed
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      child: const AppText(
                                        'Remove',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.coralRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28.h),

                        // FULL NAME Field
                        AppTextField(
                          hint: 'Enter your full name',
                          controller: formState.nameCtrl,
                          label: 'Full Name',
                          prefixIcon: Icons.person_outline_rounded,
                          maxLength: 50,
                          errorText: ref.watch(epNameErrorProvider),
                          onChanged: (val) {
                            if (ref.read(epNameErrorProvider) != null) {
                              ref.read(epNameErrorProvider.notifier).state = null;
                            }
                          },
                        ),
                        SizedBox(height: 20.h),

                        // USERNAME Field
                        AppTextField(
                          hint: 'Enter username',
                          controller: formState.usernameCtrl,
                          label: 'Username',
                          maxLength: 20,
                          errorText: ref.watch(epUsernameErrorProvider),
                          onChanged: (val) {
                            if (ref.read(epUsernameErrorProvider) != null) {
                              ref.read(epUsernameErrorProvider.notifier).state = null;
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
                          prefix: Container(
                            width: 38.w,
                            alignment: Alignment.center,
                            child: const AppText(
                              '@',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onboardingViolet,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: AppText(
                            '✓ equaly.app/${(formState.usernameCtrl.text.isNotEmpty ? formState.usernameCtrl.text : "username").replaceAll(" ", "")}',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // EMAIL Field
                        AppTextField(
                          hint: 'Enter your email address',
                          controller: formState.emailCtrl,
                          label: 'Email',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                        ),
                        SizedBox(height: 20.h),

                        // PHONE Field
                        AppTextField(
                          hint: 'Enter phone number',
                          controller: formState.phoneCtrl,
                          label: 'Phone',
                          prefixIcon: Icons.smartphone_rounded,
                          keyboardType: TextInputType.phone,
                          maxLength: 15,
                          errorText: ref.watch(epPhoneErrorProvider),
                          onChanged: (val) {
                            if (ref.read(epPhoneErrorProvider) != null) {
                              ref.read(epPhoneErrorProvider.notifier).state = null;
                            }
                          },
                        ),
                        SizedBox(height: 20.h),

                        // BIO Field
                        AppTextField(
                          hint: 'Tell us about yourself',
                          controller: formState.bioCtrl,
                          label: 'Bio',
                          prefixIcon: Icons.chat_bubble_outline_rounded,
                          maxLines: 2,
                          maxLength: 150,
                          errorText: ref.watch(epBioErrorProvider),
                          onChanged: (val) {
                            if (ref.read(epBioErrorProvider) != null) {
                              ref.read(epBioErrorProvider.notifier).state = null;
                            }
                          },
                        ),
                        SizedBox(height: 24.h),

                        // DEFAULT CURRENCY Title & Chips
                        _sectionLabel('DEFAULT CURRENCY'),
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _currencies.map((currency) {
                            final isSelected =
                                formState.selectedCurrency == currency;
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(editProfileFormProvider.notifier)
                                    .updateSelectedCurrency(currency);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.onboardingViolet
                                          .withValues(alpha: 0.12)
                                      : AppColors.transparent,
                                  borderRadius: BorderRadius.circular(18.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.onboardingViolet
                                        : AppColors.white.withValues(alpha: 0.08),
                                    width: 1.2,
                                  ),
                                ),
                                child: AppText(
                                  currency,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 28.h),

                        // DANGER ZONE Title & Card
                        _sectionLabel('DANGER ZONE'),
                        SizedBox(height: 12.h),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _buildDangerZoneRow(
                                title: 'Delete Account',
                                onTap: () => _showDeleteAccountDialog(context, ref),
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
            if (formState.isSaving)
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
                              'Saving Profile...',
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

  Widget _buildDangerZoneRow({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: AppText(
        title,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.coralRed,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.coralRed.withValues(alpha: 0.5),
        size: 20.sp,
      ),
      onTap: onTap,
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
