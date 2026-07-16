/// Fields accepted by `PATCH /api/v1/profile` (`user` object).
library;

class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.name,
    this.email,
    this.goal,
    this.learningLanguage,
    this.nativeLanguage,
    this.locale,
    this.avatarSignedId,
  });

  final String? name;
  final String? email;
  final int? goal;
  final String? learningLanguage;
  final String? nativeLanguage;
  final String? locale;

  /// Active Storage `signed_id` from `POST /api/v1/direct_uploads`.
  /// Pass an empty string to clear the avatar on the server.
  final String? avatarSignedId;

  Map<String, dynamic> toUserJson() {
    final m = <String, dynamic>{};
    if (name != null) m['name'] = name;
    if (email != null) m['email'] = email;
    if (goal != null) m['goal'] = goal;
    if (learningLanguage != null) m['learningLanguage'] = learningLanguage;
    if (nativeLanguage != null) m['nativeLanguage'] = nativeLanguage;
    if (locale != null) m['locale'] = locale;
    if (avatarSignedId != null) m['avatar'] = avatarSignedId;
    return m;
  }
}
