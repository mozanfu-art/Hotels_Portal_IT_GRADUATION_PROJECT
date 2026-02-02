import 'package:cloud_firestore/cloud_firestore.dart';

class GuestSettings {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;

  GuestSettings({
    this.emailNotifications = false,
    this.pushNotifications = false,
    this.smsNotifications = false,
  });

  factory GuestSettings.fromMap(Map<String, dynamic> map) {
    return GuestSettings(
      emailNotifications: map['emailNotifications'] ?? false,
      pushNotifications: map['pushNotifications'] ?? false,
      smsNotifications: map['smsNotifications'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
