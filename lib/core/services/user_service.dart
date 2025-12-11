import 'dart:io';

import 'api_service.dart';
import 'api_exceptions.dart';

/// User quota information
class UserQuota {
  const UserQuota({
    required this.limit,
    required this.used,
    this.resetDate,
  });

  factory UserQuota.fromJson(Map<String, dynamic> json) {
    return UserQuota(
      limit: json['limit'] as int? ?? 100,
      used: json['used'] as int? ?? 0,
      resetDate: json['resetDate'] != null
          ? DateTime.parse(json['resetDate'] as String)
          : null,
    );
  }

  final int limit;
  final int used;
  final DateTime? resetDate;

  int get remaining => limit - used;
  double get usagePercent => limit > 0 ? used / limit : 0.0;
  bool get isExhausted => used >= limit;
}

/// User profile information
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.quota,
    this.isActive,
    this.createdAt,
    this.lastLogin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar'] as String? ?? json['avatarUrl'] as String?,
      quota: json['quota'] != null
          ? UserQuota.fromJson(json['quota'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final UserQuota? quota;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;
}

/// Usage statistics
class UsageStats {
  const UsageStats({
    this.totalChats,
    this.totalTranscriptions,
    this.totalTTS,
    this.totalVisionAnalysis,
    this.totalVideosProcessed,
    this.totalEmbeddings,
    this.tokensUsed,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      totalChats: json['totalChats'] as int?,
      totalTranscriptions: json['totalTranscriptions'] as int?,
      totalTTS: json['totalTTS'] as int?,
      totalVisionAnalysis: json['totalVisionAnalysis'] as int?,
      totalVideosProcessed: json['totalVideosProcessed'] as int?,
      totalEmbeddings: json['totalEmbeddings'] as int?,
      tokensUsed: json['tokensUsed'] as int?,
    );
  }

  final int? totalChats;
  final int? totalTranscriptions;
  final int? totalTTS;
  final int? totalVisionAnalysis;
  final int? totalVideosProcessed;
  final int? totalEmbeddings;
  final int? tokensUsed;
}

/// User Service for profile and account management
class UserService {
  UserService({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  /// Get user profile
  Future<UserProfile> getProfile() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/user/profile',
      );

      if (response.data == null) {
        throw ApiException('Failed to get profile');
      }

      final data = response.data!['data'] ?? response.data!;
      return UserProfile.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get profile: $e');
    }
  }

  /// Update user profile
  Future<UserProfile> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/user/profile',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
        },
      );

      if (response.data == null) {
        throw ApiException('Failed to update profile');
      }

      final data = response.data!['data'] ?? response.data!;
      return UserProfile.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update profile: $e');
    }
  }

  /// Upload avatar image
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/user/avatar',
        imageFile.path,
        fieldName: 'avatar',
      );

      if (response.data == null) {
        throw ApiException('Failed to upload avatar');
      }

      final data = response.data!['data'] ?? response.data!;
      return data['avatarUrl'] as String? ?? data['avatar'] as String? ?? '';
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to upload avatar: $e');
    }
  }

  /// Delete avatar
  Future<void> deleteAvatar() async {
    try {
      await _apiService.delete<void>('/user/avatar');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete avatar: $e');
    }
  }

  /// Get quota information
  Future<UserQuota> getQuota() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/user/quota',
      );

      if (response.data == null) {
        throw ApiException('Failed to get quota');
      }

      final data = response.data!['data'] ?? response.data!;
      return UserQuota.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get quota: $e');
    }
  }

  /// Get usage statistics
  Future<UsageStats> getUsageStats() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/user/usage-stats',
      );

      if (response.data == null) {
        throw ApiException('Failed to get usage stats');
      }

      final data = response.data!['data'] ?? response.data!;
      return UsageStats.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get usage stats: $e');
    }
  }

  /// Deactivate account
  Future<void> deactivateAccount() async {
    try {
      await _apiService.post<void>('/user/deactivate');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to deactivate account: $e');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.post<void>(
        '/user/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to change password: $e');
    }
  }
}
