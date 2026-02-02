import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/activity.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/models/room.dart';
import 'package:hotel_booking_app/services/activity_service.dart';
import 'package:hotel_booking_app/services/notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final ActivityService _activityService = ActivityService();

  Future<Map<String, int>> getAvailableRoomCounts(
    String hotelId,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    try {
      // 1. Fetch all rooms for the hotel that are marked as 'available'.
      final roomsFuture = _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: hotelId)
          .where('available', isEqualTo: true)
          .get();

      // 2. Fetch all potentially conflicting bookings for the hotel.
      // A booking conflicts if its start date is before our end date AND its end date is after our start date.
      // Firestore can only handle one range filter, so we'll do the first half here and filter the rest on the client.
      final hotelRef = _firestore.collection('hotels').doc(hotelId);
      final bookingsFuture = _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: hotelRef)
          .where('bookingStatus', whereIn: ['confirmed', 'checked_in'])
          .where('checkInDate', isLessThan: Timestamp.fromDate(checkOut))
          .get();

      // Await both futures to run in parallel for efficiency.
      final results = await Future.wait([roomsFuture, bookingsFuture]);
      final roomsSnapshot = results[0] as QuerySnapshot;
      final bookingsSnapshot = results[1] as QuerySnapshot;

      // Further filter bookings on the client to find true overlaps.
      final conflictingBookings = bookingsSnapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .where((booking) => booking.checkOutDate.isAfter(checkIn))
          .toList();

      // 3. Count the total number of rooms for each room type.
      final Map<String, int> totalRoomsPerType = {};
      for (var doc in roomsSnapshot.docs) {
        final room = Room.fromMap(doc.data() as Map<String, dynamic>);
        totalRoomsPerType[room.roomType] =
            (totalRoomsPerType[room.roomType] ?? 0) + 1;
      }

      // 4. Count the number of booked rooms for each room type from the conflicting bookings.
      final Map<String, int> bookedRoomsPerType = {};
      for (var booking in conflictingBookings) {
        bookedRoomsPerType[booking.roomType] =
            (bookedRoomsPerType[booking.roomType] ?? 0) + 1;
      }

      // 5. Calculate the final number of available rooms for each type.
      final Map<String, int> availableRoomsPerType = {};
      totalRoomsPerType.forEach((roomType, totalCount) {
        final bookedCount = bookedRoomsPerType[roomType] ?? 0;
        availableRoomsPerType[roomType] = totalCount - bookedCount;
      });

      return availableRoomsPerType;
    } catch (e) {
      print('Error getting available room counts: $e');
      throw Exception('Failed to calculate room availability: $e');
    }
  }

  // Room Availability
  Future<List<Booking>> getBookingsForRoom(
    String hotelId,
    String roomType,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    try {
      final hotelRef = _firestore.collection('hotels').doc(hotelId);
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: hotelRef)
          .where('roomType', isEqualTo: roomType)
          .where('bookingStatus', whereIn: ['confirmed', 'checked_in'])
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .where(
            (booking) =>
                (booking.checkInDate.isBefore(checkOut) &&
                booking.checkOutDate.isAfter(checkIn)),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get room bookings: $e');
    }
  }

  Future<int> getAvailableRooms(
    String hotelId,
    String roomType,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    try {
      // 1. Get the total count of rooms of this type that are marked as 'available'
      final roomsSnapshot = await _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: hotelId)
          .where('roomType', isEqualTo: roomType)
          .where(
            'available',
            isEqualTo: true,
          ) // Exclude rooms marked as unavailable
          .get();
      final totalAvailableRooms = roomsSnapshot.docs.length;

      if (totalAvailableRooms == 0) {
        return 0;
      }

      // 2. Get bookings that conflict with the requested dates and status
      List<Booking> conflictingBookings = await getBookingsForRoom(
        hotelId,
        roomType,
        checkIn,
        checkOut,
      );

      // 3. The number of available rooms is the total minus the conflicting ones
      return totalAvailableRooms - conflictingBookings.length;
    } catch (e) {
      throw Exception('Failed to get available rooms: $e');
    }
  }

  // Booking CRUD Operations
  Future<Booking?> getBooking(String bookingId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      if (doc.exists) {
        return Booking.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  Future<List<Booking>> getAllBookings() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookings: $e');
    }
  }

  Future<List<Booking>> getBookingsByHotelId(String hotelId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where(
            'hotelId',
            isEqualTo: _firestore.collection('hotels').doc(hotelId),
          )
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      print(s);
      throw Exception('Failed to get bookings: $e');
    }
  }

  Future<String> createBooking(
    Booking booking,
    String guestId,
    String guestName,
  ) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(booking.bookingId)
          .set(booking.toMap());
      // --- Send Notifications ---
      // 1. Notify Guest that their booking request has been received
      await _notificationService.sendBookingPendingNotification(
        booking.guestId.id,
        booking.bookingId,
        booking.hotelId.id,
      );

      await _notificationService.sendBookingConfirmationNotification(
        booking.guestId.id,
        booking.bookingId,
        booking.hotelId.id,
      );

      // 2. Notify the relevant Hotel Admin of the new booking request
      final hotelDoc = await booking.hotelId.get();
      if (hotelDoc.exists) {
        final hotel = Hotel.fromMap(hotelDoc.data() as Map<String, dynamic>);
        if (hotel.adminId != null) {
          await _notificationService.sendNewBookingNotificationToAdmin(
            hotel.adminId!,
            hotel.hotelId,
            booking.bookingId,
            booking.guestName,
            booking.guestId.id,
          );
        }
      }

      // Log activity
      await _activityService.createActivity(
        Activity(
          id: '',
          type: 'New Booking',
          description:
              'A new booking has been made by "${booking.guestName}" for the hotel "${booking.hotelName}".',
          entityId: booking.bookingId,
          entityType: 'Booking',
          actorId: guestId,
          actorName: guestName,
          timestamp: Timestamp.now(),
        ),
      );
      return booking.bookingId;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Private helper to send notifications based on status changes.
  Future<void> _sendGuestNotificationForStatusChange(
    String bookingId,
    String status,
  ) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking != null) {
        final guestId = booking.guestId.id;
        switch (status.toLowerCase()) {
          case 'confirmed':
            await _notificationService.sendBookingConfirmationNotification(
              guestId,
              bookingId,
              booking.hotelId.id,
            );
            break;
          case 'cancelled':
            await _notificationService.sendBookingCancellationNotification(
              guestId,
              bookingId,
              booking.hotelId.id,
            );
            break;
          case 'checked_in':
            await _notificationService.sendCheckInNotification(
              guestId,
              bookingId,
              booking.hotelId.id,
            );
            break;
          case 'completed':
            await _notificationService.sendCheckOutNotification(
              guestId,
              bookingId,
              booking.hotelId.id,
            );
            break;
        }
      }
    } catch (e, s) {
      print(s);
      // Log the error but don't let it crash the booking update process
      print(
        "Failed to send notification for booking $bookingId status change: $e",
      );
    }
  }

  Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });

      if (updates.containsKey('bookingStatus')) {
        await _sendGuestNotificationForStatusChange(
          bookingId,
          updates['bookingStatus'],
        );
      }
    } catch (e) {
      throw Exception('Failed to update booking: $e');
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      throw Exception('Failed to delete booking: $e');
    }
  }

  Future<void> confirmBooking(String bookingId) async {
    try {
      await updateBooking(bookingId, {'bookingStatus': 'confirmed'});
    } catch (e) {
      throw Exception('Failed to confirm booking: $e');
    }
  }

  Future<void> cancelBooking(
    String bookingId,
    String guestId,
    String guestName,
  ) async {
    try {
      await updateBooking(bookingId, {'bookingStatus': 'cancelled'});
      final booking = await getBooking(bookingId);
      final hotelDoc = await booking!.hotelId.get();
      final hotel = hotelDoc.exists
          ? Hotel.fromMap(hotelDoc.data() as Map<String, dynamic>)
          : null;
      final adminId = hotel?.adminId;
      await _notificationService.sendBookingCancellationNotificationToAdmin(
        adminId!,
        booking.hotelId.id,
        bookingId,
        booking.guestName,
        booking.guestId.id,
      );

      await _activityService.createActivity(
        Activity(
          id: '',
          type: 'Booking Cancellation',
          description:
              'Booking request ${booking.bookingId} has been cancelled by ${booking.guestName}.',
          entityId: booking.bookingId,
          entityType: 'Booking',
          actorId: guestId,
          actorName: guestName,
          timestamp: Timestamp.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  Future<void> checkInBooking(String bookingId) async {
    try {
      await updateBooking(bookingId, {'bookingStatus': 'checked_in'});
    } catch (e) {
      throw Exception('Failed to check in booking: $e');
    }
  }

  Future<void> checkOutBooking(String bookingId) async {
    try {
      await updateBooking(bookingId, {'bookingStatus': 'completed'});
    } catch (e) {
      throw Exception('Failed to check out booking: $e');
    }
  }

  // Booking Queries
  Future<List<Booking>> getBookingsByGuest(String guestId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where(
            'guestId',
            isEqualTo: _firestore.collection('guests').doc(guestId),
          )
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get guest bookings: $e');
    }
  }

  Future<List<Booking>> getBookingsByHotel(String hotelId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where(
            'hotelId',
            isEqualTo: _firestore.collection('hotels').doc(hotelId),
          )
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get hotel bookings: $e');
    }
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('bookingStatus', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookings by status: $e');
    }
  }

  Future<List<Booking>> getBookingsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where(
            'checkInDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'checkInDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('checkInDate')
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookings by date range: $e');
    }
  }

  // Revenue and Analytics
  Future<double> getTotalRevenue(
    String hotelId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: hotelId)
          .where('bookingStatus', isEqualTo: 'completed')
          .where(
            'checkOutDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'checkOutDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .get();

      double totalRevenue = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalRevenue += data['totalAmount'] ?? 0;
      }

      return totalRevenue;
    } catch (e) {
      throw Exception('Failed to get total revenue: $e');
    }
  }

  Future<Map<String, int>> getBookingStats(
    String hotelId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: hotelId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      Map<String, int> stats = {
        'total': snapshot.docs.length,
        'confirmed': 0,
        'cancelled': 0,
        'completed': 0,
        'pending': 0,
      };

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['bookingStatus'] ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get booking stats: $e');
    }
  }

  // Stream for real-time updates
  Stream<List<Booking>> getBookingsStream(String? hotelId, String? guestId) {
    Query query = _firestore.collection('bookings');

    if (hotelId != null) {
      query = query.where('hotelId', isEqualTo: hotelId);
    }

    if (guestId != null) {
      query = query.where(
        'guestId',
        isEqualTo: _firestore.collection('guests').doc(guestId),
      );
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Real-time availability stream
  Stream<int> getAvailableRoomsStream(
    String hotelId,
    String roomType,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    return _firestore
        .collection('bookings')
        .where('hotelId', isEqualTo: hotelId)
        .where('roomType', isEqualTo: roomType)
        .where('bookingStatus', whereIn: ['confirmed', 'checked_in'])
        .snapshots()
        .asyncMap((snapshot) async {
          // Get total rooms of this type from hotel data
          DocumentSnapshot hotelDoc = await _firestore
              .collection('hotels')
              .doc(hotelId)
              .get();
          if (!hotelDoc.exists) return 0;

          Map<String, dynamic> hotelData =
              hotelDoc.data() as Map<String, dynamic>;
          List<dynamic> rooms = hotelData['rooms'] ?? [];
          int totalRooms = rooms
              .where((room) => room['roomType'] == roomType)
              .length;

          // Get conflicting bookings
          List<Booking> conflictingBookings = snapshot.docs
              .map((doc) => Booking.fromMap(doc.data()))
              .where(
                (booking) =>
                    (booking.checkInDate.isBefore(checkOut) &&
                    booking.checkOutDate.isAfter(checkIn)),
              )
              .toList();

          return totalRooms - conflictingBookings.length;
        });
  }
}
