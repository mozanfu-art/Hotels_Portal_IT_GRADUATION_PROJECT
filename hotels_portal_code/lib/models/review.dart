import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String reviewId;
  final String guestId;
  final String hotelId;
  final String bookingId;
  final String hotelName; // Added to store the hotel's name
  final String guestName;
  final double starRate;
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.reviewId,
    required this.guestId,
    required this.hotelId,
    required this.bookingId,
    required this.hotelName,
    required this.guestName,
    required this.starRate,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      reviewId: map['reviewId'],
      guestId: map['guestId'],
      hotelId: map['hotelId'],
      bookingId: map['bookingId'] ?? '',
      hotelName: map['hotelName'] ?? 'Unknown Hotel', // Handle old data
      guestName: map['guestName'],
      starRate: (map['starRate'] as num).toDouble(),
      review: map['review'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'guestId': guestId,
      'hotelId': hotelId,
      'bookingId': bookingId,
      'hotelName': hotelName,
      'guestName': guestName,
      'starRate': starRate,
      'review': review,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
