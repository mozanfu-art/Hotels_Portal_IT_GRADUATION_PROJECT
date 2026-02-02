import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String bookingId;
  final DocumentReference guestId;
  final DocumentReference hotelId;
  final DocumentReference roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int adultsGuests;
  final int? childrenGuests;
  final String roomType;
  final int roomsQuantity;
  final double totalAmount;
  final String bookingStatus;
  final String? specialRequests;
  final String confirmationCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Denormalized fields
  final String guestName;
  final String hotelName;
  final String hotelCity;
  final String hotelState;

  Booking({
    required this.bookingId,
    required this.guestId,
    required this.hotelId,
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adultsGuests,
    this.childrenGuests,
    required this.roomType,
    required this.roomsQuantity,
    required this.totalAmount,
    required this.bookingStatus,
    this.specialRequests,
    required this.confirmationCode,
    required this.createdAt,
    required this.updatedAt,
    required this.guestName,
    required this.hotelName,
    required this.hotelCity,
    required this.hotelState,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      bookingId: map['bookingId'],
      guestId: map['guestId'],
      hotelId: map['hotelId'],
      roomId: map['roomId'],
      checkInDate: (map['checkInDate'] as Timestamp).toDate(),
      checkOutDate: (map['checkOutDate'] as Timestamp).toDate(),
      adultsGuests: map['adultsGuests'],
      childrenGuests: map['childrenGuests'],
      roomType: map['roomType'],
      roomsQuantity: map['roomsQuantity'],
      totalAmount: (map['totalAmount'] as num).toDouble(),
      bookingStatus: map['bookingStatus'],
      specialRequests: map['specialRequests'],
      confirmationCode: map['confirmationCode'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      guestName: map['guestName'] ?? '',
      hotelName: map['hotelName'] ?? '',
      hotelCity: map['hotelCity'] ?? '',
      hotelState: map['hotelState'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'guestId': guestId,
      'hotelId': hotelId,
      'roomId': roomId,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'adultsGuests': adultsGuests,
      'childrenGuests': childrenGuests,
      'roomType': roomType,
      'roomsQuantity': roomsQuantity,
      'totalAmount': totalAmount,
      'bookingStatus': bookingStatus,
      'specialRequests': specialRequests,
      'confirmationCode': confirmationCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'guestName': guestName,
      'hotelName': hotelName,
      'hotelCity': hotelCity,
      'hotelState': hotelState,
    };
  }
}
