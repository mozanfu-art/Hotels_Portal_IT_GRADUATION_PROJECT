import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String notificationId;
  final String title;
  final String message;
  final String type;
  final String? hotelId;
  final String? guestId;
  final String? bookingId;
  final bool read;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    this.hotelId,
    this.guestId,
    this.bookingId,
    required this.read,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      notificationId: map['notificationId'],
      title: map['title'],
      message: map['message'],
      type: map['type'],
      hotelId: map['hotelId'],
      guestId: map['guestId'],
      bookingId: map['bookingId'],
      read: map['read'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'type': type,
      'hotelId': hotelId,
      'guestId': guestId,
      'bookingId': bookingId,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
