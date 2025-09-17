// lib/models/user.dart
class User {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final UserSettings settings;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  User({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.settings,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'settings': settings.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map, String documentId) {
    return User(
      uid: documentId,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'],
      settings: UserSettings.fromMap(map['settings'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'] ?? 0),
    );
  }

  User copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    UserSettings? settings,
    DateTime? lastLoginAt,
  }) {
    return User(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class UserSettings {
  final bool notificationsEnabled;
  final bool callRecordingEnabled;
  final bool autoSummarize;
  final bool darkModeEnabled;
  final bool biometricEnabled;
  final String language;
  final String voiceQuality;
  final double summarizationLevel;
  final List<String> excludedApps;
  final QuietHours? quietHours;
  final bool shareAnalytics;

  UserSettings({
    this.notificationsEnabled = true,
    this.callRecordingEnabled = true,
    this.autoSummarize = true,
    this.darkModeEnabled = false,
    this.biometricEnabled = false,
    this.language = 'English',
    this.voiceQuality = 'High',
    this.summarizationLevel = 2.0,
    this.excludedApps = const [],
    this.quietHours,
    this.shareAnalytics = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'callRecordingEnabled': callRecordingEnabled,
      'autoSummarize': autoSummarize,
      'darkModeEnabled': darkModeEnabled,
      'biometricEnabled': biometricEnabled,
      'language': language,
      'voiceQuality': voiceQuality,
      'summarizationLevel': summarizationLevel,
      'excludedApps': excludedApps,
      'quietHours': quietHours?.toMap(),
      'shareAnalytics': shareAnalytics,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      callRecordingEnabled: map['callRecordingEnabled'] ?? true,
      autoSummarize: map['autoSummarize'] ?? true,
      darkModeEnabled: map['darkModeEnabled'] ?? false,
      biometricEnabled: map['biometricEnabled'] ?? false,
      language: map['language'] ?? 'English',
      voiceQuality: map['voiceQuality'] ?? 'High',
      summarizationLevel: (map['summarizationLevel'] ?? 2.0).toDouble(),
      excludedApps: List<String>.from(map['excludedApps'] ?? []),
      quietHours: map['quietHours'] != null
          ? QuietHours.fromMap(map['quietHours'])
          : null,
      shareAnalytics: map['shareAnalytics'] ?? false,
    );
  }
}

class QuietHours {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final List<int> activeDays; // 1-7, Monday to Sunday

  QuietHours({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.activeDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'activeDays': activeDays,
    };
  }

  factory QuietHours.fromMap(Map<String, dynamic> map) {
    return QuietHours(
      startHour: map['startHour'] ?? 22,
      startMinute: map['startMinute'] ?? 0,
      endHour: map['endHour'] ?? 7,
      endMinute: map['endMinute'] ?? 0,
      activeDays: List<int>.from(map['activeDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
    );
  }
}
