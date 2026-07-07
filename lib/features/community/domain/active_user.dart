/// Active learners payload from `GET /api/v1/users/active` (camelCase JSON).
library;

import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/core/utils/avatar_url.dart';

int? _intFromJson(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString());
}

class ActiveUser {
  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: rasterAvatarUrl(json['avatarUrl'] as String?),
    );
  }
  const ActiveUser({required this.id, required this.name, this.avatarUrl});

  final String id;
  final String name;
  final String? avatarUrl;
}

class ActiveUsersResponse {
  factory ActiveUsersResponse.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'];
    final users = <ActiveUser>[];
    if (rawUsers is List) {
      for (final e in rawUsers) {
        final m = castJsonObjectOrNull(e);
        if (m != null) {
          users.add(ActiveUser.fromJson(m));
        }
      }
    }
    return ActiveUsersResponse(
      users: users,
      count: _intFromJson(json['count']) ?? users.length,
      recordingsCountToday: _intFromJson(json['recordingsCountToday']),
      recordingsDurationToday: _intFromJson(json['recordingsDurationToday']),
    );
  }
  const ActiveUsersResponse({
    required this.users,
    required this.count,
    this.recordingsCountToday,
    this.recordingsDurationToday,
  });

  final List<ActiveUser> users;
  final int count;
  final int? recordingsCountToday;

  /// Total practice duration for the community today, milliseconds.
  final int? recordingsDurationToday;
}
