import 'package:flutter/foundation.dart';

/// Parse a datetime string from Supabase.
/// Ensures it is always parsed as UTC if it doesn't specify a timezone.
DateTime parseUtcDateTime(String dateStr) {
  try {
    // If it doesn't end with 'Z' and doesn't contain a timezone offset ('+' or '-' after the 'T'),
    // we append 'Z' to make sure DateTime.parse() treats it as UTC instead of local time.
    if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains('-')) {
      return DateTime.parse('${dateStr}Z');
    }
    return DateTime.parse(dateStr);
  } catch (e) {
    debugPrint('Error parsing date "$dateStr": $e. Returning DateTime.now().');
    return DateTime.now();
  }
}
