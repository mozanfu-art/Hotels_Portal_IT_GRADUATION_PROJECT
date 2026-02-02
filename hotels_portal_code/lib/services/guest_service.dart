import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/models/guest.dart';
import 'package:hotel_booking_app/models/guest_settings.dart';
import 'package:hotel_booking_app/models/notification.dart';
import 'package:hotel_booking_app/models/review.dart';
import 'package:hotel_booking_app/services/notification_service.dart';

class GuestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Guest CRUD Operations
  Future<Guest?> getGuest(String guestId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('guests')
          .doc(guestId)
          .get();
      if (doc.exists) {
        return Guest.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get guest: $e');
    }
  }

  Future<void> toggleFavoriteHotel(String guestId, String hotelId) async {
    try {
      final guestRef = _firestore.collection('guests').doc(guestId);
      final guestDoc = await guestRef.get();

      if (guestDoc.exists) {
        final guestData = guestDoc.data() as Map<String, dynamic>;
        final currentFavorites = List<String>.from(
          guestData['favoriteHotelIds'] ?? [],
        );

        if (currentFavorites.contains(hotelId)) {
          // Remove from favorites
          await guestRef.update({
            'favoriteHotelIds': FieldValue.arrayRemove([hotelId]),
          });
        } else {
          // Add to favorites
          await guestRef.update({
            'favoriteHotelIds': FieldValue.arrayUnion([hotelId]),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update favorites: $e');
    }
  }

  Future<List<Guest>> getAllGuests() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('guests').get();
      return snapshot.docs
          .map((doc) => Guest.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get guests: $e');
    }
  }

  // New Method: Get guests with their booking history for a specific hotel
  Future<List<Map<String, dynamic>>> getGuestsForHotel(String hotelId) async {
    try {
      // 1. Get all bookings for the specified hotel
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where(
            'hotelId',
            isEqualTo: _firestore.collection('hotels').doc(hotelId),
          )
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        return [];
      }

      // 2. Group bookings by guestId and extract metadata
      final Map<String, Map<String, dynamic>> guestBookingInfo = {};
      for (var doc in bookingsSnapshot.docs) {
        final booking = Booking.fromMap(doc.data());
        final guestRef = booking.guestId;
        final guestId = guestRef.id;

        if (guestBookingInfo.containsKey(guestId)) {
          // Increment booking count
          guestBookingInfo[guestId]!['bookingCount']++;
          // Update last visit if this booking is more recent
          if (booking.checkInDate.isAfter(
            guestBookingInfo[guestId]!['lastVisit'],
          )) {
            guestBookingInfo[guestId]!['lastVisit'] = booking.checkInDate;
          }
        } else {
          guestBookingInfo[guestId] = {
            'guestRef': guestRef,
            'bookingCount': 1,
            'lastVisit': booking.checkInDate,
          };
        }
      }

      // 3. Fetch guest details for each unique guest
      final List<Map<String, dynamic>> guestsWithHistory = [];
      for (var entry in guestBookingInfo.entries) {
        final info = entry.value;

        final guestDoc = await (info['guestRef'] as DocumentReference).get();

        if (guestDoc.exists) {
          final guest = Guest.fromMap(guestDoc.data() as Map<String, dynamic>);
          guestsWithHistory.add({
            'guest': guest,
            'bookingCount': info['bookingCount'],
            'lastVisit': info['lastVisit'],
          });
        }
      }

      // Sort by last visit date, most recent first
      guestsWithHistory.sort(
        (a, b) =>
            (b['lastVisit'] as DateTime).compareTo(a['lastVisit'] as DateTime),
      );

      return guestsWithHistory;
    } catch (e, s) {
      print('Error getting guests for hotel: $e');
      print(s);
      throw Exception('Failed to get guests for hotel: $e');
    }
  }

  Future<String> createGuest(Guest guest) async {
    try {
      await _firestore
          .collection('guests')
          .doc(guest.guestId)
          .set(guest.toMap());
      return guest.guestId;
    } catch (e) {
      throw Exception('Failed to create guest: $e');
    }
  }

  Future<void> updateGuest(String guestId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('guests').doc(guestId).update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update guest: $e');
    }
  }

  Future<void> deleteGuest(String guestId) async {
    try {
      await _firestore.collection('guests').doc(guestId).delete();
    } catch (e) {
      throw Exception('Failed to delete guest: $e');
    }
  }

  // Guest Settings
  Future<GuestSettings> getGuestSettings(String guestId) async {
    try {
      final doc = await _firestore.collection('guests').doc(guestId).get();
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('settings')) {
        return GuestSettings.fromMap(
          doc.data()!['settings'] as Map<String, dynamic>,
        );
      }
      return GuestSettings(); // Return default settings if not found
    } catch (e) {
      print('Failed to get guest settings: $e');
      return GuestSettings(); // Return default on error
    }
  }

  Future<void> updateGuestSettings(
    String guestId,
    Map<String, dynamic> settingsData,
  ) async {
    try {
      await _firestore.collection('guests').doc(guestId).update({
        'settings': settingsData,
      });
    } catch (e) {
      throw Exception('Failed to update guest settings: $e');
    }
  }

  // Authentication
  Future<Guest?> signIn(String email, String password) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('guests')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Guest.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('guests')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check email: $e');
    }
  }

  // Guest Bookings
  Future<List<Booking>> getGuestBookingHistory(String guestId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where(
            'guestId',
            isEqualTo: _firestore.collection('guests').doc(guestId),
          )
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Booking.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get booking history: $e');
    }
  }

  // Guest Notifications
  Future<List<Notification>> getGuestNotifications(String guestId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('guests')
          .doc(guestId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => Notification.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(
    String guestId,
    String notificationId,
  ) async {
    try {
      await _firestore
          .collection('guests')
          .doc(guestId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true, 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Guest Reviews
  Future<List<Review>> getGuestReviews(String guestId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('guestId', isEqualTo: guestId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }

  // Hotel Reviews
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

  Future<String> addReview(Review review) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(review.reviewId)
          .set(review.toMap());

      await _notificationService.sendNewReviewNotificationToAdmin(
        review.guestId,
        review.hotelId,
        review.bookingId,
        review.guestName,
        review.guestId,
      );

      await _notificationService.sendNewReviewNotificationToGuest(
        review.guestId,
        review.hotelId,
        review.bookingId,
        review.guestName,
      );
      return review.reviewId;
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Stream for real-time updates
  Stream<List<Notification>> getGuestNotificationsStream(String guestId) {
    return _firestore
        .collection('guests')
        .doc(guestId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Notification.fromMap(doc.data()))
              .toList(),
        );
  }
}
