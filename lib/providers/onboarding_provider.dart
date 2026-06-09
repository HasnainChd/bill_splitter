import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingPageIndexProvider = StateProvider<int>((ref) => 0);

final onboardingPageControllerProvider = Provider<PageController>((ref) {
  final controller = PageController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});
