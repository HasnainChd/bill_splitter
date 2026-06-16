import 'package:flutter/material.dart';

class AppColors {
  // Primary — Deep Navy (Legacy - kept for compatibility)
  static const Color primary = Color(0xFF0A1628);
  static const Color primaryDark = Color(0xFF060D1A);
  static const Color primaryMid = Color(0xFF112240);
  static const Color primaryLight = Color(0xFFE8EDF5);
  static const Color primaryAccent = Color(0xFF1A3A6B);

  // Primary — Purple (New Theme)
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPurpleLight = Color(0xFFA78BFA);
  static const Color primaryPurpleDark = Color(0xFF7C3AED);
  static const Color primaryPurpleDarker = Color(0xFF6D28D9);

  // Accent — Gold (Legacy - kept for compatibility)
  static const Color accent = Color(0xFFD4AF37);
  static const Color accentLight = Color(0xFFFFF8E1);
  static const Color accentDark = Color(0xFFB8960C);

  // Status
  static const Color success = Color(0xFF00C896);
  static const Color successLight = Color(0xFFE0FAF4);
  static const Color error = Color(0xFFFF4757);
  static const Color errorLight = Color(0xFFFFECEE);
  static const Color warning = Color(0xFFFFB300);
  static const Color warningLight = Color(0xFFFFF8E1);

  // Group indicator colors
  static const Color orange = Color(0xFFFF9F43);
  static const Color pink = Color(0xFFFF6B9D);
  static const Color green = Color(0xFF00C896);

  // Onboarding & Theme Specific Colors
  static const Color onboardingViolet = Color(0xFF7F77FE);
  static const Color onboardingVioletDark = Color(0xFF5348FF);
  static const Color onboardingCyan = Color(0xFF1EA6E9);
  static const Color onboardingGreen = Color(0xFF109E68);
  static const Color mintGreen = Color(0xFF00FFC2);
  static const Color coralRed = Color(0xFFFF6B6B);

  // Onboarding Avatar Colors
  static const Color avatarRose = Color(0xFFF43F5E);
  static const Color avatarAmber = Color(0xFFF59E0B);
  static const Color avatarEmerald = Color(0xFF10B981);

  // Dashboard / Balance Colors
  static const Color balanceOwed = Color(0xFFFFA8A8); // "You owe" pinkish text
  static const Color balanceOwedTo =
      Color(0xFF83F8C5); // "Owed to you" mint green text
  static const Color successDark =
      Color(0xFF00B084); // Settle All button gradient end

  // Group Card Gradient Colors
  static const Color groupBlue = Color(0xFF0EA5E9);
  static const Color groupBlueDark = Color(0xFF0284C7);
  static const Color groupOrange = Color(0xFFF97316);
  static const Color groupOrangeDark = Color(0xFFEA580C);

  // Premium Card Gradient Colors
  static const Color gradIndigoStart = Color(0xFF818CF8);
  static const Color gradIndigoEnd = Color(0xFF6366F1);
  static const Color gradCyanStart = Color(0xFF38BDF8);
  static const Color gradCyanEnd = Color(0xFF0EA5E9);
  static const Color gradPinkStart = Color(0xFFF472B6);
  static const Color gradPinkEnd = Color(0xFFEC4899);
  static const Color gradEmeraldStart = Color(0xFF34D399);
  static const Color gradEmeraldEnd = Color(0xFF059669);
  static const Color gradAmberStart = Color(0xFFFBBF24);
  static const Color gradAmberEnd = Color(0xFFD97706);
  static const Color gradPurpleStart = Color(0xFFA78BFA);
  static const Color gradPurpleEnd = Color(0xFF7C3AED);

  static const List<List<Color>> cardGradients = [
    [gradIndigoStart, gradIndigoEnd],
    [gradCyanStart, gradCyanEnd],
    [gradPinkStart, gradPinkEnd],
    [gradEmeraldStart, gradEmeraldEnd],
    [gradAmberStart, gradAmberEnd],
    [gradPurpleStart, gradPurpleEnd],
  ];

  // Navigation
  static const Color navBarDark =
      Color(0xFF131318); // Bottom nav bar background

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFF0F4F8);
  static const Color backgroundDark = Color(0xFF0F0F13);
  static const Color backgroundGradientStart = Color(0xFF1A1A2E);
  static const Color backgroundGradientEnd = Color(0xFF16213E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color cardDark = Color(0xFF1A1A1F);
  static const Color cardDarkSecondary = Color(0xFF252535);
  static const Color cardBorder = Color(0xFF3A3A4A);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Text
  static const Color textPrimary = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF0A1628);
  static const Color transparent = Colors.transparent;

  // Avatar colors
  static const List<Color> avatarColors = [
    Color(0xFF0A1628),
    Color(0xFF1A3A6B),
    Color(0xFF00C896),
    Color(0xFFD4AF37),
    Color(0xFF6C5CE7),
    Color(0xFFFF4757),
    Color(0xFF00B4D8),
    Color(0xFFFF6B35),
  ];

  // Group Create Theme Colors
  static const List<Color> groupThemeColors = [
    Color(0xFF818CF8), // violet
    Color(0xFF38BDF8), // cyan
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // purple
    Color(0xFFF97316), // orange
  ];
}
