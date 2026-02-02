import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/guest_settings.dart';

class Guest {
  final String guestId;
  final String fName;
  final String lName;
  final String email;
  final DateTime? birthDate;
  final String? phone;
  final String? fcmToken; // FCM token for push notifications
  final String role; // 'guest'
  final bool active; // To enable/disable the account
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> favoriteHotelIds;
  final GuestSettings? settings;

  Guest({
    required this.guestId,
    required this.fName,
    required this.lName,
    required this.email,
    this.birthDate,
    this.phone,
    this.fcmToken,
    required this.role,
    this.active = true, // Default to active
    required this.createdAt,
    required this.updatedAt,
    this.favoriteHotelIds = const [],
    this.settings,
  });

  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      guestId: map['guestId'],
      fName: map['FName'],
      lName: map['LName'],
      email: map['email'],
      birthDate: map['birthDate'] != null
          ? (map['birthDate'] as Timestamp).toDate()
          : null,
      phone: map['phone'],
      fcmToken: map['fcmToken'],
      role: map['role'] ?? 'guest',
      active: map['active'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String),
      favoriteHotelIds: List<String>.from(map['favoriteHotelIds'] ?? []),
      settings: map['settings'] != null
          ? GuestSettings.fromMap(map['settings'])
          : GuestSettings(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guestId': guestId,
      'FName': fName,
      'LName': lName,
      'email': email,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'phone': phone,
      'fcmToken': fcmToken,
      'role': role,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'favoriteHotelIds': favoriteHotelIds,
      'settings': settings?.toMap(),
    };
  }

  Guest copyWith({
    String? guestId,
    String? fName,
    String? lName,
    String? email,
    DateTime? birthDate,
    String? phone,
    String? fcmToken,
    String? role,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? favoriteHotelIds,
    GuestSettings? settings,
  }) {
    return Guest(
      guestId: guestId ?? this.guestId,
      fName: fName ?? this.fName,
      lName: lName ?? this.lName,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      fcmToken: fcmToken ?? this.fcmToken,
      role: role ?? this.role,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favoriteHotelIds: favoriteHotelIds ?? this.favoriteHotelIds,
      settings: settings ?? this.settings,
    );
  }
}
