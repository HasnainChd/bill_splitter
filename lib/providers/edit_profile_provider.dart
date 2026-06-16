import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_provider.dart';
import 'settings_provider.dart';

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
    state = state.copyWith(isSaving: true);
    try {
      final success = await ref.read(profileProvider.notifier).updateProfile(
            fullName: state.nameCtrl.text.trim(),
            username: state.usernameCtrl.text.trim(),
            phone: state.phoneCtrl.text.trim(),
            bio: state.bioCtrl.text.trim(),
            currency: state.selectedCurrency,
            avatarFilePath: state.isRemovingAvatar ? '' : state.selectedImagePath,
            context: context,
          );
      if (success) {
        ref.read(defaultCurrencyProvider.notifier).state = state.selectedCurrency;
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
  final usernameCtrl = TextEditingController(text: profile?.username ?? '');
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

  return EditProfileFormNotifier(
    nameCtrl: nameCtrl,
    usernameCtrl: usernameCtrl,
    emailCtrl: emailCtrl,
    phoneCtrl: phoneCtrl,
    bioCtrl: bioCtrl,
    currency: currency,
    ref: ref,
  );
});
