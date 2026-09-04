import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/error_handler.dart';

class RequestItem {
  final String id;
  final String groupId;
  final String userId;
  final String? targetUserId;
  final double? amount;
  final String? currency;
  final String? note;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  RequestItem({
    required this.id,
    required this.groupId,
    required this.userId,
    this.targetUserId,
    this.amount,
    this.currency,
    this.note,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory RequestItem.fromMap(Map<String, dynamic> data) {
    return RequestItem(
      id: data['id'],
      groupId: data['group_id'],
      userId: data['user_id'],
      targetUserId: data['target_user_id'],
      amount: data['amount'] != null ? (data['amount'] as num).toDouble() : null,
      currency: data['currency'],
      note: data['note'],
      status: data['status'] ?? 'pending',
      createdAt: DateTime.parse(data['created_at']).toLocal(),
      respondedAt: data['responded_at'] != null
          ? DateTime.parse(data['responded_at']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'target_user_id': targetUserId,
      'amount': amount,
      'currency': currency,
      'note': note,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }
}

class RequestsState {
  final bool isLoading;
  final List<RequestItem> requests;
  final String? error;

  const RequestsState({
    this.isLoading = false,
    this.requests = const [],
    this.error,
  });

  RequestsState copyWith({
    bool? isLoading,
    List<RequestItem>? requests,
    String? error,
  }) {
    return RequestsState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      error: error,
    );
  }
}

class RequestsNotifier extends StateNotifier<RequestsState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _requestsSubscription;

  RequestsNotifier() : super(const RequestsState()) {
    fetchRequests();
  }

  void fetchRequests() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    
    _requestsSubscription?.cancel();
    _requestsSubscription = _supabase
        .from('requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
      (data) {
        final List<RequestItem> requestsList = data
            .map((row) => RequestItem.fromMap(row))
            .toList();

        if (mounted) {
          state = state.copyWith(requests: requestsList, isLoading: false);
        }
      },
      onError: (e) {
        debugPrint('Error loading requests stream: $e');
        if (mounted) {
          state = state.copyWith(
              error: ErrorHandler.getUserFriendlyMessage(e), isLoading: false);
        }
      },
    );
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }
}

final requestsProvider = StateNotifierProvider<RequestsNotifier, RequestsState>((ref) {
  return RequestsNotifier();
});
