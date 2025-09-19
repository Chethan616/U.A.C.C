// lib/models/device.dart
class Device {
  final String deviceId;
  final String fcmToken;
  final String platform;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final DateTime lastSeen;
  final bool isActive;

  Device({
    required this.deviceId,
    required this.fcmToken,
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.lastSeen,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'fcmToken': fcmToken,
      'platform': platform,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map, String documentId) {
    return Device(
      deviceId: documentId,
      fcmToken: map['fcmToken'] ?? '',
      platform: map['platform'] ?? 'android',
      deviceModel: map['deviceModel'] ?? '',
      osVersion: map['osVersion'] ?? '',
      appVersion: map['appVersion'] ?? '',
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] ?? 0),
      isActive: map['isActive'] ?? true,
    );
  }

  Device copyWith({
    String? fcmToken,
    DateTime? lastSeen,
    bool? isActive,
  }) {
    return Device(
      deviceId: deviceId,
      fcmToken: fcmToken ?? this.fcmToken,
      platform: platform,
      deviceModel: deviceModel,
      osVersion: osVersion,
      appVersion: appVersion,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
    );
  }
}
