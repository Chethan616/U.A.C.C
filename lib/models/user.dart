// lib/models/user.dart
class User {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? photoURL;
  final DateTime? lastPhotoUpdate;
  final UserSettings settings;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool profileCompleted;
  final bool isGoogleUser;

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.photoURL,
    this.lastPhotoUpdate,
    required this.settings,
    required this.createdAt,
    required this.lastLoginAt,
    this.profileCompleted = false,
    this.isGoogleUser = false,
  });

  String get displayName => '$firstName $lastName'.trim();

  bool get canUpdatePhoto {
    if (lastPhotoUpdate == null) return true;
    final daysSinceLastUpdate =
        DateTime.now().difference(lastPhotoUpdate!).inDays;
    return daysSinceLastUpdate >= 45;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'photoURL': photoURL,
      'lastPhotoUpdate': lastPhotoUpdate?.millisecondsSinceEpoch,
      'settings': settings.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
      'profileCompleted': profileCompleted,
      'isGoogleUser': isGoogleUser,
    };
  }

  factory User.fromMap(Map<String, dynamic> map, String documentId) {
    return User(
      uid: documentId,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'])
          : null,
      photoURL: map['photoURL'],
      lastPhotoUpdate: map['lastPhotoUpdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPhotoUpdate'])
          : null,
      settings: UserSettings.fromMap(map['settings'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'] ?? 0),
      profileCompleted: map['profileCompleted'] ?? false,
      isGoogleUser: map['isGoogleUser'] ?? false,
    );
  }

  User copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? photoURL,
    DateTime? lastPhotoUpdate,
    UserSettings? settings,
    DateTime? lastLoginAt,
    bool? profileCompleted,
    bool? isGoogleUser,
  }) {
    return User(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoURL: photoURL ?? this.photoURL,
      lastPhotoUpdate: lastPhotoUpdate ?? this.lastPhotoUpdate,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
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
