import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A queued request for offline sync
class QueuedRequest {
  const QueuedRequest({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    this.queryParams,
    required this.createdAt,
  });

  final String id;
  final String method;
  final String path;
  final dynamic data;
  final Map<String, dynamic>? queryParams;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'data': data,
        'queryParams': queryParams,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
        id: json['id'] as String,
        method: json['method'] as String,
        path: json['path'] as String,
        data: json['data'],
        queryParams: json['queryParams'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Manager for offline request queue
class OfflineQueueManager {
  OfflineQueueManager({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  static const _queueKey = 'offline_queue';

  /// In-memory cache of pending requests
  List<QueuedRequest>? _cache;

  /// Add a request to the queue
  Future<void> addRequest(QueuedRequest request) async {
    final requests = await getPendingRequests();
    requests.add(request);
    await _saveQueue(requests);
  }

  /// Get all pending requests in order
  Future<List<QueuedRequest>> getPendingRequests() async {
    // Always read from storage to ensure consistency
    final data = await _secureStorage.read(key: _queueKey);
    if (data == null || data.isEmpty) {
      _cache = [];
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      _cache = jsonList
          .map((e) => QueuedRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      // Sort by creation time to preserve order
      _cache!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return List.from(_cache!);
    } catch (e) {
      // Corrupted data, clear queue
      await clearQueue();
      return [];
    }
  }

  /// Remove a request from the queue
  Future<void> removeRequest(String id) async {
    final requests = await getPendingRequests();
    requests.removeWhere((r) => r.id == id);
    await _saveQueue(requests);
  }

  /// Clear all pending requests
  Future<void> clearQueue() async {
    _cache = [];
    await _secureStorage.delete(key: _queueKey);
  }

  /// Get the count of pending requests
  Future<int> getPendingCount() async {
    final requests = await getPendingRequests();
    return requests.length;
  }

  /// Check if there are pending requests
  Future<bool> hasPendingRequests() async {
    final count = await getPendingCount();
    return count > 0;
  }

  Future<void> _saveQueue(List<QueuedRequest> requests) async {
    _cache = requests;
    final jsonList = requests.map((r) => r.toJson()).toList();
    await _secureStorage.write(key: _queueKey, value: jsonEncode(jsonList));
  }
}
