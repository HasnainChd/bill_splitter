import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Stream provider that listens to connectivity changes
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((result) {
        // Modern connectivity_plus returns List<ConnectivityResult>
        return result.isNotEmpty && !result.contains(ConnectivityResult.none);
      });
});

// Check initial state immediately on app start
final isOnlineProvider = FutureProvider<bool>((ref) async {
  final result = await Connectivity().checkConnectivity();
  return result.isNotEmpty && !result.contains(ConnectivityResult.none);
});
