import 'package:equatable/equatable.dart';

/// Authentication provider types
enum AuthProvider {
  local,
  google,
  facebook,
}

/// User model representing an authenticated user
/// Compatible with backend response format
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    required this.provider,
    this.isActive = true,
    this.quota,
    this.createdAt,
    this.lastLogin,
  });

  /// Unique user identifier
  final String id;

  /// User's email address
  final String email;

  /// User's display name (optional)
  final String? name;

  /// URL to user's avatar image (optional)
  final String? avatar;

  /// Authentication provider used
  final AuthProvider provider;

  /// Whether user account is active
  final bool isActive;

  /// User quota information
  final UserQuota? quota;

  /// Account creation timestamp
  final DateTime? createdAt;

  /// Last login timestamp
  final DateTime? lastLogin;

  /// Creates a User from JSON map (backend format)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      provider: _parseProvider(json['provider'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      quota: json['quota'] != null 
          ? UserQuota.fromJson(json['quota'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.tryParse(json['lastLogin'] as String)
          : null,
    );
  }

  static AuthProvider _parseProvider(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'google':
        return AuthProvider.google;
      case 'facebook':
        return AuthProvider.facebook;
      case 'local':
      default:
        return AuthProvider.local;
    }
  }

  /// Converts User to JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (name != null) 'name': name,
    if (avatar != null) 'avatar': avatar,
    'provider': provider.name,
    'isActive': isActive,
    if (quota != null) 'quota': quota!.toJson(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (lastLogin != null) 'lastLogin': lastLogin!.toIso8601String(),
  };

  /// Creates a copy of User with optional field overrides
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    AuthProvider? provider,
    bool? isActive,
    UserQuota? quota,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      provider: provider ?? this.provider,
      isActive: isActive ?? this.isActive,
      quota: quota ?? this.quota,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  List<Object?> get props => [id, email, name, avatar, provider, isActive, quota, createdAt, lastLogin];
}

/// User quota information
class UserQuota extends Equatable {
  const UserQuota({
    required this.limit,
    required this.used,
    this.resetDate,
  });

  final int limit;
  final int used;
  final DateTime? resetDate;

  factory UserQuota.fromJson(Map<String, dynamic> json) {
    return UserQuota(
      limit: json['limit'] as int? ?? 100,
      used: json['used'] as int? ?? 0,
      resetDate: json['resetDate'] != null 
          ? DateTime.tryParse(json['resetDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'limit': limit,
    'used': used,
    if (resetDate != null) 'resetDate': resetDate!.toIso8601String(),
  };

  int get remaining => limit - used;
  bool get hasRemaining => remaining > 0;

  @override
  List<Object?> get props => [limit, used, resetDate];
}
