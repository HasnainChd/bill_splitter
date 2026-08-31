import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 1. onboarding_started - when Onboarding screen loads
  static Future<void> logOnboardingStarted() async {
    try {
      await _analytics.logEvent(name: 'onboarding_started');
    } catch (e) {
      debugPrint('Analytics logOnboardingStarted error: $e');
    }
  }

  /// 2. onboarding_completed - when user finishes/skips the Walkthrough
  static Future<void> logOnboardingCompleted() async {
    try {
      await _analytics.logEvent(name: 'onboarding_completed');
    } catch (e) {
      debugPrint('Analytics logOnboardingCompleted error: $e');
    }
  }

  /// 3. sign_up - successful registration (params: method - email/google)
  static Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logEvent(
        name: 'sign_up',
        parameters: {'method': method},
      );
      await setSignupMethod(method);
    } catch (e) {
      debugPrint('Analytics logSignUp error: $e');
    }
  }

  /// 4. login - successful login (params: method - email/google)
  static Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logEvent(
        name: 'login',
        parameters: {'method': method},
      );
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  /// 5. login_failed - failed login attempt (params: error_reason, no PII)
  static Future<void> logLoginFailed({required String errorReason}) async {
    try {
      await _analytics.logEvent(
        name: 'login_failed',
        parameters: {'error_reason': errorReason},
      );
    } catch (e) {
      debugPrint('Analytics logLoginFailed error: $e');
    }
  }

  /// 6. group_created - new group created (params: currency)
  static Future<void> logGroupCreated({required String currency}) async {
    try {
      await _analytics.logEvent(
        name: 'group_created',
        parameters: {'currency': currency},
      );
    } catch (e) {
      debugPrint('Analytics logGroupCreated error: $e');
    }
  }

  /// 7. group_joined - joined via invite code or link (params: join_method - code/qr/link)
  static Future<void> logGroupJoined({required String joinMethod}) async {
    try {
      await _analytics.logEvent(
        name: 'group_joined',
        parameters: {'join_method': joinMethod},
      );
    } catch (e) {
      debugPrint('Analytics logGroupJoined error: $e');
    }
  }

  /// 8 & 9. expense_added & first_expense_added
  static Future<void> logExpenseAdded({
    required String splitType,
    required String category,
    required bool hasReceipt,
    String? userId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'expense_added',
        parameters: {
          'split_type': splitType,
          'category': category,
          'has_receipt': hasReceipt ? 1 : 0,
        },
      );

      if (userId != null && userId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'has_logged_first_expense_$userId';
        final alreadyLogged = prefs.getBool(key) ?? false;
        if (!alreadyLogged) {
          await _analytics.logEvent(
            name: 'first_expense_added',
            parameters: {
              'split_type': splitType,
              'category': category,
              'has_receipt': hasReceipt ? 1 : 0,
            },
          );
          await prefs.setBool(key, true);
        }
      }
    } catch (e) {
      debugPrint('Analytics logExpenseAdded error: $e');
    }
  }

  /// 10. settle_up_completed - full settlement completed
  static Future<void> logSettleUpCompleted({
    String? currency,
    double? amount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'settle_up_completed',
        parameters: {
          if (currency != null) 'currency': currency,
          if (amount != null) 'amount': amount,
        },
      );
    } catch (e) {
      debugPrint('Analytics logSettleUpCompleted error: $e');
    }
  }

  /// 11. remind_to_settle_sent - group nudge or person reminder sent (param: reminder_type - group/person)
  static Future<void> logRemindToSettleSent({required String reminderType}) async {
    try {
      await _analytics.logEvent(
        name: 'remind_to_settle_sent',
        parameters: {'reminder_type': reminderType},
      );
    } catch (e) {
      debugPrint('Analytics logRemindToSettleSent error: $e');
    }
  }

  /// 12. receipt_scanned - receipt photo attached to an expense or scanned
  static Future<void> logReceiptScanned() async {
    try {
      await _analytics.logEvent(name: 'receipt_scanned');
    } catch (e) {
      debugPrint('Analytics logReceiptScanned error: $e');
    }
  }

  /// 13. pdf_downloaded - expense PDF exported
  static Future<void> logPdfDownloaded() async {
    try {
      await _analytics.logEvent(name: 'pdf_downloaded');
    } catch (e) {
      debugPrint('Analytics logPdfDownloaded error: $e');
    }
  }

  /// 14. member_removed - group creator removes a member
  static Future<void> logMemberRemoved() async {
    try {
      await _analytics.logEvent(name: 'member_removed');
    } catch (e) {
      debugPrint('Analytics logMemberRemoved error: $e');
    }
  }

  /// 15. member_left - self-leave
  static Future<void> logMemberLeft() async {
    try {
      await _analytics.logEvent(name: 'member_left');
    } catch (e) {
      debugPrint('Analytics logMemberLeft error: $e');
    }
  }

  /// User Properties
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics setUserProperty ($name) error: $e');
    }
  }

  static Future<void> setDefaultCurrency(String currency) async {
    await setUserProperty(name: 'default_currency', value: currency);
  }

  static Future<void> setSignupMethod(String method) async {
    await setUserProperty(name: 'signup_method', value: method);
  }

  static Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserId error: $e');
    }
  }
}
