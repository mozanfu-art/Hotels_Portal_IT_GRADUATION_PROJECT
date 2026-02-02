import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String type; // e.g., 'New User', 'New Booking', 'Status Update'
  final String description;
  final String? actorId; // The user who performed the action
  final String? actorName;
  final String?
  entityId; // The ID of the affected entity (e.g., hotelId, userId)
  final String? entityType; // e.g., 'Hotel', 'User', 'Booking'
  final Timestamp timestamp;

  Activity({
    required this.id,
    required this.type,
    required this.description,
    this.actorId,
    this.actorName,
    this.entityId,
    this.entityType,
    required this.timestamp,
  });

  factory Activity.fromMap(Map<String, dynamic> map, String documentId) {
    return Activity(
      id: documentId,
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      actorId: map['actorId'],
      actorName: map['actorName'],
      entityId: map['entityId'],
      entityType: map['entityType'],
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'actorId': actorId,
      'actorName': actorName,
      'entityId': entityId,
      'entityType': entityType,
      'timestamp': timestamp,
    };
  }
}
