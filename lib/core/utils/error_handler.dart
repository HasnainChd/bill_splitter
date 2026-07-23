class ErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'Something went wrong. Please try again.';
    
    final errorStr = error.toString().toLowerCase();
    
    // Network/connectivity errors
    if (errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('errno = 7') ||
        errorStr.contains('no address associated')) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    // Timeout errors
    if (errorStr.contains('timeout') ||
        errorStr.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }
    
    // Auth errors
    if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    
    if (errorStr.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    
    if (errorStr.contains('user already registered') ||
        errorStr.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    
    if (errorStr.contains('jwt expired') ||
        errorStr.contains('session_not_found') ||
        errorStr.contains('refresh_token')) {
      return 'Your session has expired. Please sign in again.';
    }
    
    // Permission/RLS errors
    if (errorStr.contains('permission denied') ||
        errorStr.contains('rls') ||
        errorStr.contains('row level security')) {
      return 'You don\'t have permission to perform this action.';
    }
    
    // Server errors
    if (errorStr.contains('500') ||
        errorStr.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }
    
    if (errorStr.contains('503') ||
        errorStr.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    }
    
    // Supabase specific
    if (errorStr.contains('authretryable') ||
        errorStr.contains('clientexception')) {
      return 'Connection failed. Please check your internet and try again.';
    }
    
    // Generic fallback
    return 'Something went wrong. Please try again.';
  }
}
