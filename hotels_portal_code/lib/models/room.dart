import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String roomId;
  final String hotelId;
  final String roomType;
  final String roomDescription;
  final int maxChildren;
  final int maxAdults;
  final double pricePerNight;
  final List<String> amenities;
  final List<String> images;
  final bool available;
  final DateTime createdAt;
  final DateTime updatedAt;

  Room({
    required this.roomId,
    required this.hotelId,
    required this.roomType,
    required this.roomDescription,
    required this.pricePerNight,
    required this.amenities,
    required this.images,
    required this.maxChildren,
    required this.maxAdults,
    required this.available,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      roomId: map['roomId'],
      hotelId: map['hotelId'],
      roomType: map['roomType'],
      roomDescription: map['roomDescription'],
      maxAdults: map['maxAdults'],
      maxChildren: map['maxChildren'],
      pricePerNight: (map['pricePerNight'] as num).toDouble(),
      amenities: List<String>.from(map['amenities'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      available: map['available'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'hotelId': hotelId,
      'roomType': roomType,
      'roomDescription': roomDescription,
      'maxAdults': maxAdults,
      'maxChildren': maxChildren,
      'pricePerNight': pricePerNight,
      'amenities': amenities,
      'images': images,
      'available': available,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
