import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String adminId;
  final String fName;
  final String lName;
  final String email;
  final String? hotelId; // null for ministry, specific hotelId for hotel admins
  final String? hotelName; // for hotel admins
  final String? hotelCity; // for hotel admins
  final String? hotelState; // for hotel admins
  final String? hotelAddress; // for hotel admins
  final bool active;
  final String? fcmToken; // FCM token for push notifications
  final String role; // 'ministry admin' or 'hotel admin'
  final DateTime createdAt;
  final DateTime updatedAt;
  final AdminSettings? settings;

  Admin({
    required this.adminId,
    required this.fName,
    required this.lName,
    required this.email,
    this.hotelId,
    this.hotelName,
    this.hotelCity,
    this.hotelState,
    this.hotelAddress,
    required this.active,
    this.fcmToken,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      adminId: map['adminId'] ?? '',
      fName: map['fName'] ?? '',
      lName: map['lName'] ?? '',
      email: map['email'] ?? '',
      hotelId: map['hotelId'] as String?,
      hotelName: map['hotelName'],
      hotelCity: map['hotelCity'],
      hotelState: map['hotelState'],
      hotelAddress: map['hotelAddress'],
      active: map['active'] ?? true,
      fcmToken: map['fcmToken'],
      role: map['role'] ?? 'ministry admin',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      settings: map['settings'] != null
          ? AdminSettings.fromMap(map['settings'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'fName': fName,
      'lName': lName,
      'email': email,
      'hotelId': hotelId,
      'hotelName': hotelName,
      'hotelCity': hotelCity,
      'hotelState': hotelState,
      'hotelAddress': hotelAddress,
      'active': active,
      'fcmToken': fcmToken,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'settings': settings?.toMap(),
    };
  }
}

class AdminSettings {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final DateTime updatedAt;

  AdminSettings({
    this.emailNotifications = false,
    this.pushNotifications = false,
    this.smsNotifications = false,
    required this.updatedAt,
  });

  factory AdminSettings.fromMap(Map<String, dynamic> map) {
    return AdminSettings(
      emailNotifications: map['emailNotifications'] ?? false,
      pushNotifications: map['pushNotifications'] ?? false,
      smsNotifications: map['smsNotifications'] ?? false,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
