import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send notification to guest
  Future<void> sendGuestNotification(
    String guestId,
    String title,
    String message, {
    String? hotelId,
    String? type,
    String? bookingId,
  }) async {
    try {
      Notification notification = Notification(
        notificationId: _firestore.collection('temp').doc().id, // Generate ID
        title: title,
        message: message,
        type: type ?? 'general',
        guestId: guestId, // Associate with guest
        bookingId: bookingId, // Associate with booking
        hotelId: hotelId,
        read: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save notification to the guest's subcollection
      await _firestore
          .collection('guests')
          .doc(guestId)
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to send guest notification: $e');
    }
  }

  // Base method to send a notification to an admin
  Future<void> sendAdminNotification(
    String adminId,
    String title,
    String guestId,
    String message, {
    String? type,
    String? bookingId,
    String? hotelId,
  }) async {
    try {
      Notification notification = Notification(
        notificationId: _firestore.collection('temp').doc().id,
        title: title,
        message: message,
        type: type ?? 'general',
        hotelId: hotelId,
        bookingId: bookingId,
        guestId: guestId,
        read: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to send admin notification: $e');
    }
  }

  // --- Specific Booking Notifications ---

  Future<void> sendBookingPendingNotification(
    String guestId,
    String bookingId,
    String hotelId,
  ) async {
    await sendGuestNotification(
      guestId,
      'Booking Received',
      'Your booking request $bookingId is pending confirmation from the hotel.',
      type: 'booking',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  Future<void> sendNewReviewNotificationToAdmin(
    String adminId,
    String hotelId,
    String bookingId,
    String guestName,
    String guestId,
  ) async {
    await sendAdminNotification(
      adminId,
      'New Review Received',
      'You have a new review from $guestName.',
      guestId,
      type: 'review',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  Future<void> sendNewReviewNotificationToGuest(
    String guestId,
    String hotelId,
    String bookingId,
    String guestName,
  ) async {
    await sendGuestNotification(
      guestId,
      'Your Review Received',
      'Your review has been received thanks for your feedback.',
      type: 'review',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  Future<void> sendBookingCancellationNotificationToAdmin(
    String adminId,
    String hotelId,
    String bookingId,
    String guestName,
    String guestId,
  ) async {
    await sendAdminNotification(
      adminId,
      'Booking Cancelled',
      'Your booking request $bookingId has been cancelled by $guestName.',
      guestId,
      type: 'booking',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  Future<void> sendNewBookingNotificationToAdmin(
    String adminId,
    String hotelId,
    String bookingId,
    String guestName,
    String guestId,
  ) async {
    await sendAdminNotification(
      adminId,
      'New Booking Received',
      'You have a new booking request ($bookingId) from $guestName.',
      guestId,
      type: 'booking',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  Future<void> sendBookingConfirmationNotification(
    String guestId,
    String bookingId,
    String hotelId,
  ) async {
    await sendGuestNotification(
      guestId,
      'Booking Confirmed',
      'Your booking $bookingId has been confirmed. Remember to pay at check-in, check your email for details.',
      type: 'booking',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  Future<void> sendBookingCancellationNotification(
    String guestId,
    String bookingId,
    String hotelId,
  ) async {
    await sendGuestNotification(
      guestId,
      'Booking Cancelled',
      'Your booking $bookingId has been cancelled.',
      type: 'booking',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  Future<void> sendCheckInNotification(
    String guestId,
    String bookingId,
    String hotelId,
  ) async {
    await sendGuestNotification(
      guestId,
      'Welcome!',
      'You have successfully checked in for booking $bookingId. Enjoy your stay!',
      type: 'booking',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  Future<void> sendCheckOutNotification(
    String guestId,
    String bookingId,
    String hotelId,
  ) async {
    await sendGuestNotification(
      guestId,
      'Thank You!',
      'Your booking $bookingId is complete. We hope you enjoyed your stay and invite you to leave a review!',
      type: 'booking',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  // Stream for real-time admin notifications
  Stream<List<Notification>> getAdminNotificationsStream(String adminId) {
    return _firestore
        .collection('admins')
        .doc(adminId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Notification.fromMap(doc.data()))
              .toList(),
        );
  }

  // Mark an admin's notification as read
  Future<void> markAdminNotificationAsRead(
    String adminId,
    String notificationId,
  ) async {
    try {
      await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true, 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Failed to mark admin notification as read: $e');
    }
  }
}
