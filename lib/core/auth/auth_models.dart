import 'dart:convert';

enum AuthProblem {
  credentials,
  validation,
  rate,
  unavailable,
  network,
  expired,
  storage,
  protocol,
  conflict,
  permission,
}

class AuthFailure implements Exception {
  final AuthProblem problem;
  const AuthFailure(this.problem);
  @override
  String toString() => 'Authentication request failed (${problem.name})';
}

class TokenPair {
  final String accessToken;
  final String refreshToken;
  TokenPair(this.accessToken, this.refreshToken);
  factory TokenPair.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        !RegExp(r'^[a-f0-9]{128}$').hasMatch(refresh)) {
      throw const AuthFailure(AuthProblem.protocol);
    }
    return TokenPair(access, refresh);
  }
}

class Account {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String visibility;
  final int revision;
  final AstrologyDetails? astrology;
  final int completed;

  Account({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.visibility = 'PRIVATE',
    this.revision = 0,
    this.astrology,
    this.completed = 0,
  });
  factory Account.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['email'] is! String ||
        json['username'] is! String) {
      throw const AuthFailure(AuthProblem.protocol);
    }
    final profile = json['profile'];
    return Account(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: profile is Map ? profile['displayName'] as String? : null,
      avatarUrl: profile is Map ? profile['avatarUrl'] as String? : null,
      visibility: profile is Map
          ? profile['visibility'] as String? ?? 'PRIVATE'
          : 'PRIVATE',
      revision: profile is Map ? profile['revision'] as int? ?? 0 : 0,
      completed: json['completeness'] is Map
          ? (json['completeness'] as Map)['completed'] as int? ?? 0
          : 0,
      astrology: json['astrologyProfile'] is Map<String, dynamic>
          ? AstrologyDetails.fromJson(
              json['astrologyProfile'] as Map<String, dynamic>,
            )
          : null,
      bio: profile is Map ? profile['bio'] as String? : null,
    );
  }
}

class Registration {
  final String email, username, displayName, password;
  Registration({
    required this.email,
    required this.username,
    required this.displayName,
    required this.password,
  });
  Map<String, String> toJson() => {
    'email': email.trim().toLowerCase(),
    'username': username,
    'displayName': displayName,
    'password': password,
  };
}

bool validEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', unicode: true).hasMatch(value.trim());
bool validPassword(String value, {int minimum = 15}) =>
    value.runes.length >= minimum && utf8.encode(value).length <= 72;

class AstrologyDetails {
  final String birthDate;
  final bool known;
  final int? minutes;
  final String? place, timezone, consentAt;
  final int revision;
  AstrologyDetails({
    required this.birthDate,
    required this.known,
    this.minutes,
    this.place,
    this.timezone,
    this.consentAt,
    required this.revision,
  });
  factory AstrologyDetails.fromJson(Map<String, dynamic> json) =>
      AstrologyDetails(
        birthDate: json['birthDate'] as String,
        known: json['birthTimeKnown'] as bool,
        minutes: json['birthTimeMinutes'] as int?,
        place: json['birthPlace'] as String?,
        timezone: json['timezone'] as String?,
        consentAt: json['consentAt'] as String?,
        revision: json['revision'] as int? ?? 0,
      );
}

class ProfilePatch {
  final String displayName, bio, visibility;
  final int revision;
  ProfilePatch(this.displayName, this.bio, this.visibility, this.revision);
  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'bio': bio,
    'visibility': visibility,
    'expectedRevision': revision,
  };
}

class AstrologyPatch {
  final String date, place, timezone;
  final bool known, consent, adult;
  final int? minutes;
  final int revision;
  AstrologyPatch({
    required this.date,
    required this.known,
    this.minutes,
    required this.place,
    required this.timezone,
    required this.consent,
    required this.adult,
    required this.revision,
  });
  Map<String, dynamic> toJson() => {
    'birthDate': date,
    'birthTimeKnown': known,
    if (known) 'birthTimeMinutes': minutes,
    'birthPlace': place,
    'timezone': timezone,
    'consent': consent,
    'adultConfirmed': adult,
    'visibility': 'PRIVATE',
    'expectedRevision': revision,
  };
}
