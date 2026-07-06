import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_provider.dart';
import 'settings_provider.dart';
import 'group_provider.dart';
import '../core/utils/app_snackbar.dart';
import '../presentation/providers/screen_providers.dart';

class EditProfileFormState {
  final TextEditingController nameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController bioCtrl;
  final String selectedCurrency;
  final String? selectedImagePath;
  final bool isRemovingAvatar;
  final bool isSaving;

  EditProfileFormState({
    required this.nameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.bioCtrl,
    required this.selectedCurrency,
    this.selectedImagePath,
    required this.isRemovingAvatar,
    required this.isSaving,
  });

  EditProfileFormState copyWith({
    String? selectedCurrency,
    String? selectedImagePath,
    bool? isRemovingAvatar,
    bool? isSaving,
  }) {
    return EditProfileFormState(
      nameCtrl: nameCtrl,
      usernameCtrl: usernameCtrl,
      emailCtrl: emailCtrl,
      phoneCtrl: phoneCtrl,
      bioCtrl: bioCtrl,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      selectedImagePath: selectedImagePath ?? this.selectedImagePath,
      isRemovingAvatar: isRemovingAvatar ?? this.isRemovingAvatar,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class EditProfileFormNotifier extends StateNotifier<EditProfileFormState> {
  final Ref ref;

  EditProfileFormNotifier({
    required TextEditingController nameCtrl,
    required TextEditingController usernameCtrl,
    required TextEditingController emailCtrl,
    required TextEditingController phoneCtrl,
    required TextEditingController bioCtrl,
    required String currency,
    required this.ref,
  }) : super(EditProfileFormState(
          nameCtrl: nameCtrl,
          usernameCtrl: usernameCtrl,
          emailCtrl: emailCtrl,
          phoneCtrl: phoneCtrl,
          bioCtrl: bioCtrl,
          selectedCurrency: currency,
          isRemovingAvatar: false,
          isSaving: false,
        ));

  String get selectedCurrency => state.selectedCurrency;

  void updateSelectedCurrency(String currency) {
    state = state.copyWith(selectedCurrency: currency);
  }

  void updateSelectedImagePath(String? path) {
    state = EditProfileFormState(
      nameCtrl: state.nameCtrl,
      usernameCtrl: state.usernameCtrl,
      emailCtrl: state.emailCtrl,
      phoneCtrl: state.phoneCtrl,
      bioCtrl: state.bioCtrl,
      selectedCurrency: state.selectedCurrency,
      selectedImagePath: path,
      isRemovingAvatar: false,
      isSaving: state.isSaving,
    );
  }

  void setRemovingAvatar(bool val) {
    state = EditProfileFormState(
      nameCtrl: state.nameCtrl,
      usernameCtrl: state.usernameCtrl,
      emailCtrl: state.emailCtrl,
      phoneCtrl: state.phoneCtrl,
      bioCtrl: state.bioCtrl,
      selectedCurrency: state.selectedCurrency,
      selectedImagePath: val ? null : state.selectedImagePath,
      isRemovingAvatar: val,
      isSaving: state.isSaving,
    );
  }

  Future<bool> save(BuildContext context) async {
    final name = state.nameCtrl.text.trim();
    final username = state.usernameCtrl.text.trim();
    final phone = state.phoneCtrl.text.trim();
    final bio = state.bioCtrl.text.trim();

    // Reset error states
    ref.read(epNameErrorProvider.notifier).state = null;
    ref.read(epUsernameErrorProvider.notifier).state = null;
    ref.read(epPhoneErrorProvider.notifier).state = null;
    ref.read(epBioErrorProvider.notifier).state = null;

    bool hasError = false;

    // 1. Full Name Validation
    if (name.isEmpty) {
      ref.read(epNameErrorProvider.notifier).state = 'Please enter your full name';
      hasError = true;
    } else if (name.length > 50) {
      ref.read(epNameErrorProvider.notifier).state = 'Name is too long (max 50 chars)';
      hasError = true;
    }

    // 2. Username Validation
    if (username.isEmpty) {
      ref.read(epUsernameErrorProvider.notifier).state = 'Please enter a username';
      hasError = true;
    } else if (username.length < 3) {
      ref.read(epUsernameErrorProvider.notifier).state = 'Username must be at least 3 characters';
      hasError = true;
    } else if (username.length > 20) {
      ref.read(epUsernameErrorProvider.notifier).state = 'Username must be at most 20 characters';
      hasError = true;
    } else if (!RegExp(r'^[a-zA-Z0-9_\.]+$').hasMatch(username)) {
      ref.read(epUsernameErrorProvider.notifier).state = 'Username can only contain letters, numbers, underscores, and periods';
      hasError = true;
    }

    // 3. Phone Validation
    if (phone.isNotEmpty) {
      if (phone.length > 15) {
        ref.read(epPhoneErrorProvider.notifier).state = 'Phone number is too long (max 15 digits)';
        hasError = true;
      } else if (!RegExp(r'^\+?[0-9\-\s\(\)]+$').hasMatch(phone)) {
        ref.read(epPhoneErrorProvider.notifier).state = 'Please enter a valid phone number';
        hasError = true;
      }
    }

    // 4. Bio Validation
    if (bio.length > 150) {
      ref.read(epBioErrorProvider.notifier).state = 'Bio is too long (max 150 chars)';
      hasError = true;
    }

    if (hasError) {
      AppSnackBar.showError(context, 'Please fix the errors above before continuing');
      return false;
    }

    state = state.copyWith(isSaving: true);
    try {
      final success = await ref.read(profileProvider.notifier).updateProfile(
            fullName: name,
            username: username,
            phone: phone,
            bio: bio,
            currency: state.selectedCurrency,
            avatarFilePath: state.isRemovingAvatar ? '' : state.selectedImagePath,
            context: context,
          );
      if (success) {
        ref.read(defaultCurrencyProvider.notifier).state = state.selectedCurrency;
        ref.invalidate(groupMembersProvider);
      }
      return success;
    } finally {
      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }
}

final editProfileFormProvider =
    StateNotifierProvider.autoDispose<EditProfileFormNotifier, EditProfileFormState>((ref) {
  final profile = ref.read(profileProvider).profile;

  final nameCtrl = TextEditingController(text: profile?.fullName ?? '');
  final usernameCtrl = TextEditingController(text: (profile?.username ?? '').replaceAll(' ', ''));
  final emailCtrl = TextEditingController(text: profile?.email ?? '');
  final phoneCtrl = TextEditingController(text: profile?.phone ?? '');
  final bioCtrl = TextEditingController(text: profile?.bio ?? '');
  final currency = profile?.currency ?? 'USD (\$)';

  void listener() {
    ref.notifyListeners();
  }
  nameCtrl.addListener(listener);
  usernameCtrl.addListener(listener);

  ref.onDispose(() {
    nameCtrl.dispose();
    usernameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    bioCtrl.dispose();
  });

  final notifier = EditProfileFormNotifier(
    nameCtrl: nameCtrl,
    usernameCtrl: usernameCtrl,
    emailCtrl: emailCtrl,
    phoneCtrl: phoneCtrl,
    bioCtrl: bioCtrl,
    currency: currency,
    ref: ref,
  );

  // Sync with profile provider updates if the form fields are empty (e.g. after async profile fetch completes)
  ref.listen<ProfileState>(profileProvider, (previous, next) {
    final p = next.profile;
    if (p != null) {
      if (nameCtrl.text.isEmpty) nameCtrl.text = p.fullName;
      if (usernameCtrl.text.isEmpty) usernameCtrl.text = p.username.replaceAll(' ', '');
      if (emailCtrl.text.isEmpty) emailCtrl.text = p.email;
      if (phoneCtrl.text.isEmpty) phoneCtrl.text = p.phone;
      if (bioCtrl.text.isEmpty) bioCtrl.text = p.bio;
      if (notifier.selectedCurrency == 'USD (\$)' || notifier.selectedCurrency.isEmpty) {
        notifier.updateSelectedCurrency(p.currency);
      }
    }
  });

  return notifier;
});
