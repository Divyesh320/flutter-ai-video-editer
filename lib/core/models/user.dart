import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Authentication provider types
enum AuthProvider {
  @JsonValue('email')
  email,
  @JsonValue('google')
  google,
  @JsonValue('facebook')
  facebook,
}

/// User model representing an authenticated user
@JsonSerializable()
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    required this.provider,
    required this.createdAt,
  });

  /// Unique user identifier
  final String id;

  /// User's email address
  final String email;

  /// User's display name (optional)
  final String? name;

  /// URL to user's avatar image (optional)
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// Authentication provider used
  final AuthProvider provider;

  /// Account creation timestamp
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Creates a User from JSON map
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Converts User to JSON map
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Creates a copy of User with optional field overrides
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    AuthProvider? provider,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, email, name, avatarUrl, provider, createdAt];
}
