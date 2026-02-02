import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hotel_booking_app/models/activity.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'dart:typed_data';

import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/models/review.dart';
import 'package:hotel_booking_app/models/room.dart';
import 'package:hotel_booking_app/services/activity_service.dart';

class HotelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ActivityService _activityService = ActivityService();

  // Hotel CRUD Operations
  Future<Hotel?> getHotel(String hotelId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('hotels')
          .doc(hotelId)
          .get();
      if (doc.exists) {
        return Hotel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get hotel: $e');
    }
  }

  Future<Map<String, dynamic>> getAllHotels({
    int limit = 20,
    DocumentSnapshot? startAfter,
    bool approvedOnly = false,
  }) async {
    try {
      Query query = _firestore
          .collection('hotels')
          .where('email', isNotEqualTo: null);

      if (approvedOnly) {
        query = query.where('approved', isEqualTo: true);
      }

      query = query.orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      QuerySnapshot snapshot = await query.get();
      List<Hotel> hotels = [];

      for (var doc in snapshot.docs) {
        try {
          Hotel hotel = Hotel.fromMap(doc.data() as Map<String, dynamic>);
          hotels.add(hotel);
        } catch (e) {
          // Skip invalid hotel documents
          print('Skipping invalid hotel ${doc.id}: $e');
          continue;
        }
      }

      return {
        'hotels': hotels,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
    } catch (e) {
      throw Exception('Failed to get hotels: $e');
    }
  }

  Future<String> createHotel(
    Hotel hotel,
    String adminId,
    String adminName,
  ) async {
    try {
      await _firestore
          .collection('hotels')
          .doc(hotel.hotelId)
          .set(hotel.toMap());

      await _activityService.createActivity(
        Activity(
          id: '',
          type: 'New Hotel Registration',
          description: 'A new hotel "${hotel.hotelName}" has been registered.',
          entityId: hotel.hotelId,
          entityType: 'Hotel',
          actorId: adminId,
          actorName: adminName,
          timestamp: Timestamp.now(),
        ),
      );
      return hotel.hotelId;
    } catch (e) {
      throw Exception('Failed to create hotel: $e');
    }
  }

  Future<void> updateHotel(String hotelId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('hotels').doc(hotelId).update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update hotel: $e');
    }
  }

  Future<void> deleteHotel(String hotelId) async {
    try {
      await _firestore.collection('hotels').doc(hotelId).delete();
    } catch (e) {
      throw Exception('Failed to delete hotel: $e');
    }
  }

  // Hotel Rooms
  Future<List<Room>> getHotelRooms(String hotelId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: hotelId)
          .get();
      return snapshot.docs
          .map((doc) => Room.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get hotel rooms: $e');
    }
  }

  Future<String> addHotelRoom(String hotelId, Room room) async {
    try {
      await _firestore.collection('rooms').doc(room.roomId).set(room.toMap());
      return room.roomId;
    } catch (e) {
      throw Exception('Failed to add hotel room: $e');
    }
  }

  Future<void> updateHotelRoom(
    String roomId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update hotel room: $e');
    }
  }

  Future<List<Booking>> getHotelBookings(String hotelId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where(
            'hotelId',
            isEqualTo: _firestore.collection('hotels').doc(hotelId),
          )
          .get();
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get hotel bookings: $e');
    }
  }

  // Reviews
  Future<List<Review>> getHotelReviews(String hotelId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('hotelId', isEqualTo: hotelId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get hotel reviews: $e');
    }
  }

  Future<String> uploadHotelImage(
    String hotelId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      Reference storageRef = _storage.ref().child(
        'hotels/$hotelId/images/$uniqueFileName', // CHANGED path
      );
      UploadTask uploadTask = storageRef.putData(imageBytes);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteHotelImage(String imageUrl) async {
    try {
      if (imageUrl.startsWith('http')) {
        Reference storageRef = _storage.refFromURL(imageUrl);
        await storageRef.delete();
      }
    } catch (e) {
      // It's safe to ignore "object-not-found" errors.
      print('Could not delete image, it may have been removed already: $e');
    }
  }

  // NEW: Method for uploading room-specific images
  Future<String> uploadRoomImage(
    String hotelId,
    String roomId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      Reference storageRef = _storage.ref().child(
        'hotels/$hotelId/rooms/$roomId/$uniqueFileName',
      );
      UploadTask uploadTask = storageRef.putData(imageBytes);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload room image: $e');
    }
  }

  Future<List<Hotel>> getTopRatedHotels({int limit = 5}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('hotels')
          .where('approved', isEqualTo: true)
          .orderBy('starRate', descending: true)
          .limit(limit)
          .get();

      List<Hotel> hotels = [];
      for (var doc in snapshot.docs) {
        try {
          Hotel hotel = Hotel.fromMap(doc.data() as Map<String, dynamic>);
          hotels.add(hotel);
        } catch (e) {
          print('Skipping invalid hotel ${doc.id}: $e');
          continue;
        }
      }
      return hotels;
    } catch (e) {
      throw Exception('Failed to get top rated hotels: $e');
    }
  }
}
