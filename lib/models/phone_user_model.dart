/// Represents the user node stored at `users/{phoneKey}` in Firebase
/// Realtime Database after a successful phone OTP login.
class PhoneUserModel {
  const PhoneUserModel({
    required this.phone,
    required this.uid,
    required this.deviceId,
    required this.appVersion,
    this.createdAt,
    this.lastLogin,
    this.status = 'active',
  });

  /// E.164 phone number, e.g. "+919876543210".
  final String phone;

  /// Firebase Authentication UID.
  final String uid;

  /// Android device ID obtained via [device_info_plus].
  final String deviceId;

  /// App version string, e.g. "1.0.0".
  final String appVersion;

  /// Server timestamp (milliseconds since epoch) when the record was created.
  /// May be null when freshly constructed before the DB write completes.
  final int? createdAt;

  /// Server timestamp (milliseconds since epoch) of the last login.
  final int? lastLogin;

  /// Account status — "active" by default, "inactive" after logout.
  final String status;

  // ---------------------------------------------------------------------------
  // Factory — from RTDB map
  // ---------------------------------------------------------------------------

  factory PhoneUserModel.fromMap(Map<String, dynamic> map) {
    return PhoneUserModel(
      phone: (map['phone'] as String?) ?? '',
      uid: (map['uid'] as String?) ?? '',
      deviceId: (map['deviceId'] as String?) ?? '',
      appVersion: (map['appVersion'] as String?) ?? '',
      createdAt: (map['createdAt'] as num?)?.toInt(),
      lastLogin: (map['lastLogin'] as num?)?.toInt(),
      status: (map['status'] as String?) ?? 'active',
    );
  }

  // ---------------------------------------------------------------------------
  // toMap — for writing to RTDB
  // ---------------------------------------------------------------------------

  Map<String, Object?> toMap() => {
        'phone': phone,
        'uid': uid,
        'deviceId': deviceId,
        'appVersion': appVersion,
        'createdAt': createdAt,
        'lastLogin': lastLogin,
        'status': status,
      };

  @override
  String toString() =>
      'PhoneUserModel(phone: $phone, uid: $uid, deviceId: $deviceId, '
      'appVersion: $appVersion, status: $status)';
}
