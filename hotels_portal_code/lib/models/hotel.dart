import 'package:cloud_firestore/cloud_firestore.dart';

class Hotel {
  final String hotelId;
  final String hotelName;
  final String hotelState;
  final String hotelCity;
  final String hotelAddress;
  final String? hotelEmail;
  final String? hotelPhone;
  final String hotelDescription;
  final String? licenseNumber;
  final int starRate;
  final bool approved;
  final String? adminId; // ID of the hotel admin
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images; // CHANGED
  final List<String> amenities;
  final List<Map<String, dynamic>>
  restaurants; // List of maps with 'name' and 'location'
  final int conferenceRoomsCount;

  Hotel({
    required this.hotelId,
    required this.hotelName,
    required this.hotelState,
    required this.hotelCity,
    required this.hotelAddress,
    required this.hotelEmail,
    this.hotelPhone,
    this.licenseNumber,
    required this.hotelDescription,
    required this.starRate,
    required this.approved,
    this.adminId,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [], // CHANGED
    this.amenities = const [],
    this.restaurants = const [],
    this.conferenceRoomsCount = 0,
  });

  factory Hotel.fromMap(Map<String, dynamic> map) {
    // Validation
    if (map['hotelId'] == null || map['hotelId'].toString().isEmpty) {
      throw ArgumentError('Hotel ID is required');
    }
    if (map['hotelName'] == null || map['hotelName'].toString().isEmpty) {
      throw ArgumentError('Hotel name is required');
    }
    if (map['hotelEmail'] != null &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(map['hotelEmail'])) {
      throw ArgumentError('Valid hotel email is required');
    }
    if (map['starRate'] == null || map['starRate'] < 1 || map['starRate'] > 5) {
      throw ArgumentError('Star rate must be between 1 and 5');
    }

    // Handle both old map format and new list format for images for robustness
    List<String> parsedImages = [];
    if (map['images'] is List) {
      parsedImages = List<String>.from(map['images']);
    } else if (map['images'] is Map) {
      // Logic to flatten the old map structure
      final Map<String, dynamic> imagesMap = map['images'];
      imagesMap.forEach((key, value) {
        if (value is List) {
          parsedImages.addAll(List<String>.from(value));
        }
      });
    }

    return Hotel(
      hotelId: map['hotelId'],
      hotelName: map['hotelName'],
      hotelState: map['hotelState'],
      hotelCity: map['hotelCity'],
      hotelAddress: map['hotelAddress'],
      hotelEmail: map['hotelEmail'],
      hotelPhone: map['hotelPhone'],
      hotelDescription: map['hotelDescription'],
      starRate: map['starRate'],
      approved: map['approved'] ?? false,
      adminId: map['adminId'],
      licenseNumber: map['licenseNumber'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      images: parsedImages, // CHANGED
      amenities: List<String>.from(map['amenities'] ?? []),
      restaurants: List<Map<String, dynamic>>.from(map['restaurants'] ?? []),
      conferenceRoomsCount: map['conferenceRoomsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hotelId': hotelId,
      'hotelName': hotelName,
      'hotelState': hotelState,
      'hotelCity': hotelCity,
      'hotelAddress': hotelAddress,
      'hotelEmail': hotelEmail,
      'hotelPhone': hotelPhone,
      'hotelDescription': hotelDescription,
      'licenseNumber': licenseNumber,
      'starRate': starRate,
      'approved': approved,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'images': images, // CHANGED
      'amenities': amenities,
      'restaurants': restaurants,
      'conferenceRoomsCount': conferenceRoomsCount,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'hotelId': hotelId,
      'hotelName': hotelName,
      'hotelState': hotelState,
      'hotelCity': hotelCity,
      'hotelAddress': hotelAddress,
      'hotelEmail': hotelEmail,
      'hotelPhone': hotelPhone,
      'hotelDescription': hotelDescription,
      'licenseNumber': licenseNumber,
      'starRate': starRate,
      'approved': approved,
      'adminId': adminId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'images': images, // CHANGED
      'amenities': amenities,
      'restaurants': restaurants,
      'conferenceRoomsCount': conferenceRoomsCount,
    };
  }

  factory Hotel.fromJson(Map<String, dynamic> json) {
    // Handle both old map format and new list format
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = List<String>.from(json['images']);
    } else if (json['images'] is Map) {
      final Map<String, dynamic> imagesMap = json['images'];
      imagesMap.forEach((key, value) {
        if (value is List) {
          parsedImages.addAll(List<String>.from(value));
        }
      });
    }

    return Hotel(
      hotelId: json['hotelId'],
      hotelName: json['hotelName'],
      hotelState: json['hotelState'],
      hotelCity: json['hotelCity'],
      hotelAddress: json['hotelAddress'],
      hotelEmail: json['hotelEmail'],
      hotelPhone: json['hotelPhone'],
      hotelDescription: json['hotelDescription'],
      starRate: json['starRate'],
      approved: json['approved'] ?? false,
      adminId: json['adminId'],
      licenseNumber: json['licenseNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      images: parsedImages, // CHANGED
      amenities: List<String>.from(json['amenities'] ?? []),
      restaurants: List<Map<String, dynamic>>.from(json['restaurants'] ?? []),
      conferenceRoomsCount: json['conferenceRoomsCount'] ?? 0,
    );
  }

  // Getters for compatibility with screens
  String get description => hotelDescription;
  List<String> get imageURLs => images; // CHANGED
  List<String> get allImages => images; // CHANGED
}
