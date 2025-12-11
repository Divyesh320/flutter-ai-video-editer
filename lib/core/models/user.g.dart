// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  provider: $enumDecode(_$AuthProviderEnumMap, json['provider']),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  if (instance.name case final value?) 'name': value,
  if (instance.avatarUrl case final value?) 'avatar_url': value,
  'provider': _$AuthProviderEnumMap[instance.provider]!,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$AuthProviderEnumMap = {
  AuthProvider.email: 'email',
  AuthProvider.google: 'google',
};
