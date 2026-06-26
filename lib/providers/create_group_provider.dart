import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_snackbar.dart';
import 'group_provider.dart';
import 'settings_provider.dart';

// Create Group State
class CreateGroupState {
  final List<String> members;
  final bool isLoading;
  final String? error;

  const CreateGroupState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  CreateGroupState copyWith({
    List<String>? members,
    bool? isLoading,
    String? error,
  }) {
    return CreateGroupState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Create Group Notifier
class CreateGroupNotifier extends StateNotifier<CreateGroupState> {
  CreateGroupNotifier() : super(const CreateGroupState());

  void addMember(String member) {
    if (member.isNotEmpty && !state.members.contains(member)) {
      state = state.copyWith(members: [...state.members, member]);
    }
  }

  void removeMember(String member) {
    state = state.copyWith(
        members: state.members.where((m) => m != member).toList());
  }

  Future<void> createGroup({
    required String name,
    required List<String> members,
    required int iconCodePoint,
    required String iconFontFamily,
    required WidgetRef ref,
    required BuildContext context,
    String? currency,
  }) async {
    if (name.trim().isEmpty) {
      AppSnackBar.showError(context, 'Please enter a group name');
      return;
    }

    if (members.isEmpty) {
      AppSnackBar.showError(context, 'Please add at least one member');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final String chosenCurrency =
          currency ?? ref.read(defaultCurrencyProvider) ?? 'USD (\$)';
      final String currencyCode = chosenCurrency.length >= 3
          ? chosenCurrency.substring(
              0, chosenCurrency.contains(' ') ? chosenCurrency.indexOf(' ') : 3)
          : chosenCurrency;

      await ref.read(groupProvider.notifier).addGroup(
            name: name.trim(),
            members: members,
            iconCodePoint: iconCodePoint,
            iconFontFamily: iconFontFamily,
            currency: currencyCode,
          );
      if (context.mounted) {
        AppSnackBar.showSuccess(context, 'Group created successfully');
        context.pop();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to create group: $e');
      if (context.mounted) {
        AppSnackBar.showError(context, 'Failed to create group: $e');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Create Group Provider
final createGroupProvider =
    StateNotifierProvider<CreateGroupNotifier, CreateGroupState>((ref) {
  return CreateGroupNotifier();
});

// Form Controllers Provider
class CreateGroupFormControllers {
  final TextEditingController groupName;
  final TextEditingController description;
  final TextEditingController member;

  CreateGroupFormControllers({
    required this.groupName,
    required this.description,
    required this.member,
  });

  void dispose() {
    groupName.dispose();
    description.dispose();
    member.dispose();
  }
}

final createGroupFormControllersProvider =
    Provider<CreateGroupFormControllers>((ref) {
  final controllers = CreateGroupFormControllers(
    groupName: TextEditingController(),
    description: TextEditingController(),
    member: TextEditingController(),
  );
  ref.onDispose(() {
    controllers.dispose();
  });
  return controllers;
});
