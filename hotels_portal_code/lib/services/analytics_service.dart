import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/models/generated_report.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/models/room.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveGeneratedReport({
    required String hotelId,
    required GeneratedReport report,
  }) async {
    try {
      await _firestore
          .collection('hotels')
          .doc(hotelId)
          .collection('generated_reports')
          .add(report.toFirestore());
    } catch (e) {
      print('Error saving generated report: $e');
      throw Exception('Could not save the report.');
    }
  }

  Stream<List<GeneratedReport>> getPastReportsStream(String hotelId) {
    return _firestore
        .collection('hotels')
        .doc(hotelId)
        .collection('generated_reports')
        .orderBy('createdAt', descending: true)
        .limit(20) // Limit to the last 20 reports
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GeneratedReport.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> saveMinistryReport(GeneratedReport report) async {
    try {
      await _firestore.collection('ministry_reports').add(report.toFirestore());
    } catch (e) {
      print('Error saving ministry report: $e');
      throw Exception('Could not save the ministry report.');
    }
  }

  Stream<List<GeneratedReport>> getPastMinistryReportsStream() {
    return _firestore
        .collection('ministry_reports')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GeneratedReport.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getBookingReportData({
    required String hotelId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Adjust endDate to include the entire day
    final adjustedEndDate = endDate.add(const Duration(days: 1));

    try {
      final hotelRef = _firestore.collection('hotels').doc(hotelId);
      final snapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: hotelRef)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThan: adjustedEndDate)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final booking = Booking.fromMap(doc.data());
        return {
          'Confirmation Code': booking.confirmationCode,
          'Guest Name': booking.guestName,
          'Room Type': booking.roomType,
          'Check-in Date': DateFormat('yyyy-MM-dd').format(booking.checkInDate),
          'Check-out Date': DateFormat(
            'yyyy-MM-dd',
          ).format(booking.checkOutDate),
          'Status': booking.bookingStatus,
          'Total Amount': '\$${booking.totalAmount.toStringAsFixed(2)}',
        };
      }).toList();
    } catch (e) {
      print('Error getting booking report data: $e');
      throw Exception('Failed to generate booking report.');
    }
  }

  Future<Map<String, dynamic>> getRevenueReportData({
    required String hotelId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final adjustedEndDate = endDate.add(const Duration(days: 1));

    try {
      Query query = _firestore.collection('bookings');

      // If a specific hotelId is provided, filter by it.
      // Otherwise, query all bookings.
      if (hotelId.isNotEmpty) {
        final hotelRef = _firestore.collection('hotels').doc(hotelId);
        query = query.where('hotelId', isEqualTo: hotelRef);
      }

      final snapshot = await query
          .where('bookingStatus', isEqualTo: 'completed')
          .where('updatedAt', isGreaterThanOrEqualTo: startDate)
          .where('updatedAt', isLessThan: adjustedEndDate)
          .get();

      double totalRevenue = 0;
      int totalBookings = snapshot.docs.length;
      Map<String, double> revenueByRoomType = {};

      for (var doc in snapshot.docs) {
        final booking = Booking.fromMap(doc.data() as Map<String, dynamic>);
        totalRevenue += booking.totalAmount;
        revenueByRoomType[booking.roomType] =
            (revenueByRoomType[booking.roomType] ?? 0) + booking.totalAmount;
      }

      return {
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        'totalRevenue': totalRevenue,
        'totalBookings': totalBookings,
        'averageBookingValue': totalBookings > 0
            ? totalRevenue / totalBookings
            : 0.0,
        'revenueByRoomType': revenueByRoomType,
      };
    } catch (e) {
      print('Error getting revenue report data: $e');
      throw Exception('Failed to generate revenue report.');
    }
  }

  Future<List<Map<String, dynamic>>> getHotelSummaryReportData() async {
    try {
      final snapshot = await _firestore
          .collection('hotels')
          .orderBy('hotelName')
          .get();
      return snapshot.docs.map((doc) {
        final hotel = Hotel.fromMap(doc.data());
        return {
          'Hotel Name': hotel.hotelName,
          'State': hotel.hotelState,
          'City': hotel.hotelCity,
          'Star Rate': hotel.starRate.toString(),
          'Status': hotel.approved ? 'Approved' : 'Pending',
        };
      }).toList();
    } catch (e) {
      print('Error getting hotel summary report data: $e');
      throw Exception('Failed to generate hotel summary report.');
    }
  }

  Future<List<Map<String, dynamic>>> getPlatformBookingActivityReportData({
    required DateTime startDate,
    required DateTime endDate,
    String? hotelId,
    String? bookingStatus,
  }) async {
    final adjustedEndDate = endDate.add(const Duration(days: 1));
    try {
      Query query = _firestore
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThan: adjustedEndDate);

      if (hotelId != null && hotelId.isNotEmpty) {
        query = query.where(
          'hotelId',
          isEqualTo: _firestore.collection('hotels').doc(hotelId),
        );
      }
      if (bookingStatus != null &&
          bookingStatus.isNotEmpty &&
          bookingStatus != 'All') {
        query = query.where('bookingStatus', isEqualTo: bookingStatus);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final booking = Booking.fromMap(doc.data() as Map<String, dynamic>);
        return {
          'Confirmation Code': booking.confirmationCode,
          'Hotel Name': booking.hotelName,
          'Guest Name': booking.guestName,
          'Check-in': DateFormat('yyyy-MM-dd').format(booking.checkInDate),
          'Status': booking.bookingStatus,
          'Amount': '\$${booking.totalAmount.toStringAsFixed(2)}',
        };
      }).toList();
    } catch (e) {
      print('Error getting platform booking report data: $e');
      throw Exception('Failed to generate platform booking report.');
    }
  }

  Future<List<Map<String, dynamic>>> getUserDirectoryReportData({
    String userType = 'All',
  }) async {
    try {
      final List<Map<String, dynamic>> users = [];
      List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [];

      // Determine which collections to fetch
      bool shouldFetchGuests = userType == 'All' || userType == 'Guest';
      bool shouldFetchAdmins =
          userType == 'All' ||
          userType == 'Hotel Admin' ||
          userType == 'Ministry Admin';

      if (shouldFetchGuests) {
        futures.add(_firestore.collection('guests').get());
      }
      if (shouldFetchAdmins) {
        futures.add(_firestore.collection('admins').get());
      }

      if (futures.isEmpty) {
        return []; // Should not happen with current user types, but good practice
      }

      final results = await Future.wait(futures);
      int futureIndex = 0;

      if (shouldFetchGuests) {
        final guestsSnapshot =
            results[futureIndex++];
        users.addAll(
          guestsSnapshot.docs.map((doc) {
            final guest = doc.data();
            return {
              'Name': '${guest['FName']} ${guest['LName']}',
              'Email': guest['email'],
              'Role': 'Guest',
              'Status': guest['active'] ? 'Active' : 'Inactive',
              'Created At': (guest['createdAt'] as Timestamp)
                  .toDate()
                  .toString(),
            };
          }),
        );
      }

      if (shouldFetchAdmins) {
        final adminsSnapshot =
            results[futureIndex];
        final adminUsers = adminsSnapshot.docs
            .map((doc) {
              final admin = doc.data();
              final String role = admin['role'] == 'ministry admin'
                  ? 'Ministry Admin'
                  : 'Hotel Admin';

              if (userType != 'All' && userType != role) {
                return null;
              }

              return {
                'Name': '${admin['fName']} ${admin['lName']}',
                'Email': admin['email'],
                'Role': role,
                'Status': admin['active'] ? 'Active' : 'Inactive',
                'Created At': (admin['createdAt'] as Timestamp)
                    .toDate()
                    .toString(),
              };
            })
            .where((item) => item != null)
            .cast<Map<String, dynamic>>();
        users.addAll(adminUsers);
      }

      users.sort(
        (a, b) => (a['Name'] as String).compareTo(b['Name'] as String),
      );
      return users;
    } catch (e, s) {
      print(s);
      print('Error getting user directory report data: $e');
      throw Exception('Failed to generate user directory report.');
    }
  }

  Future<List<Map<String, dynamic>>> getRoomStatusSummary(
    String hotelId,
  ) async {
    try {
      final hotelRef = _firestore.collection('hotels').doc(hotelId);
      final today = DateTime.now();

      // --- Fetch necessary data in parallel ---
      final roomsSnapshotFuture = _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: hotelId)
          .get();
      // Get all bookings that could potentially be active today
      final bookingsSnapshotFuture = _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: hotelRef)
          .where('bookingStatus', whereIn: ['confirmed', 'checked_in'])
          .get();

      final results = await Future.wait([
        roomsSnapshotFuture,
        bookingsSnapshotFuture,
      ]);

      final roomsSnapshot = results[0];
      final bookingsSnapshot = results[1];

      // --- Process Room Data ---
      final Map<String, int> totalRoomsByType = {};
      for (var doc in roomsSnapshot.docs) {
        final room = Room.fromMap(doc.data());
        totalRoomsByType[room.roomType] =
            (totalRoomsByType[room.roomType] ?? 0) + 1;
      }

      // --- Process Booking Data ---
      final Map<String, int> occupiedRoomsByType = {};
      final currentBookings = bookingsSnapshot.docs.where((doc) {
        final booking = Booking.fromMap(doc.data());
        // A room is occupied if today is on or after check-in and before check-out
        return (booking.checkInDate.isBefore(today) ||
                booking.checkInDate.isAtSameMomentAs(today)) &&
            booking.checkOutDate.isAfter(today);
      });

      for (var doc in currentBookings) {
        final booking = Booking.fromMap(doc.data());
        occupiedRoomsByType[booking.roomType] =
            (occupiedRoomsByType[booking.roomType] ?? 0) + 1;
      }

      // --- Combine Data ---
      final List<Map<String, dynamic>> summary = [];
      totalRoomsByType.forEach((type, total) {
        summary.add({
          'type': type,
          'total': total,
          'occupied': occupiedRoomsByType[type] ?? 0,
        });
      });

      // Sort alphabetically by room type
      summary.sort((a, b) => a['type'].compareTo(b['type']));

      return summary;
    } catch (e, s) {
      print(s);
      print('Error getting room status summary: $e');
      throw Exception('Failed to get room status summary: $e');
    }
  }

  Future<Map<String, dynamic>> getHotelDashboardStats(String hotelId) async {
    try {
      final hotelRef = _firestore.collection('hotels').doc(hotelId);
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final startOfWeek = startOfToday.subtract(
        Duration(days: today.weekday - 1),
      );

      // --- Fetch necessary data in parallel ---
      final hotelDocFuture = hotelRef.get();
      final roomsSnapshotFuture = _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: hotelId)
          .get();
      final bookingsSnapshotFuture = _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: hotelRef)
          .get();

      final results = await Future.wait([
        hotelDocFuture,
        roomsSnapshotFuture,
        bookingsSnapshotFuture,
      ]);

      final hotelDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final roomsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final bookingsSnapshot =
          results[2] as QuerySnapshot<Map<String, dynamic>>;

      if (!hotelDoc.exists) {
        throw Exception("Hotel not found");
      }

      // --- Process Data ---
      final hotelData = Hotel.fromMap(hotelDoc.data()!);
      final allBookings = bookingsSnapshot.docs
          .map((doc) => Booking.fromMap(doc.data()))
          .toList();
      final totalRooms = roomsSnapshot.docs.length;

      // --- Stat Calculations ---

      // 1. Occupancy Rate
      final occupiedRooms = allBookings.where((booking) {
        final status = booking.bookingStatus.toLowerCase();
        return (status == 'confirmed' || status == 'checked_in') &&
            booking.checkInDate.isBefore(today) &&
            booking.checkOutDate.isAfter(today);
      }).length;
      final double occupancyRate = totalRooms > 0
          ? (occupiedRooms / totalRooms) * 100
          : 0.0;

      // 2. Revenue Today (based on check-outs/completed today)
      final double revenueToday = allBookings
          .where(
            (booking) =>
                booking.bookingStatus.toLowerCase() == 'completed' &&
                booking.updatedAt.year == today.year &&
                booking.updatedAt.month == today.month &&
                booking.updatedAt.day == today.day,
          )
          .fold(0.0, (sum, booking) => sum + booking.totalAmount);

      // 3. New Bookings (this week)
      final newBookingsThisWeek = allBookings
          .where((booking) => booking.createdAt.isAfter(startOfWeek))
          .length;

      // 4. Average Rating
      final double averageRating = hotelData.starRate.toDouble();

      return {
        'occupancyRate': occupancyRate,
        'revenueToday': revenueToday,
        'newBookingsThisWeek': newBookingsThisWeek,
        'averageRating': averageRating,
      };
    } catch (e, s) {
      print(s);
      print('Error getting hotel dashboard stats: $e');
      throw Exception('Failed to get hotel dashboard stats: $e');
    }
  }

  // Get overall dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get booking statistics
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      final totalBookings = bookingsSnapshot.docs.length;

      // Calculate revenue
      double totalRevenue = 0.0;
      int confirmedBookings = 0;
      int completedBookings = 0;
      int cancelledBookings = 0;

      for (var doc in bookingsSnapshot.docs) {
        final booking = Booking.fromMap(doc.data());
        totalRevenue += booking.totalAmount;

        switch (booking.bookingStatus.toLowerCase()) {
          case 'confirmed':
            confirmedBookings++;
            break;
          case 'completed':
            completedBookings++;
            break;
          case 'cancelled':
            cancelledBookings++;
            break;
        }
      }

      // Get hotel statistics
      final hotelsSnapshot = await _firestore.collection('hotels').get();
      final totalHotels = hotelsSnapshot.docs.length;
      final approvedHotels = hotelsSnapshot.docs
          .where((doc) => doc.data()['approved'] == true)
          .length;
      final pendingInspections = hotelsSnapshot.docs
          .where(
            (doc) => doc.data()['status'] == 'pending_inspection',
          ) // Assuming this status
          .length;
      final complianceIssues = hotelsSnapshot.docs
          .where(
            (doc) => doc.data()['status'] == 'suspended',
          ) // Assuming this status
          .length;

      // Get guest statistics
      final guestsSnapshot = await _firestore.collection('guests').get();
      final totalGuests = guestsSnapshot.docs.length;

      // Get recent bookings (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentBookings = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'].toDate();
        return createdAt.isAfter(thirtyDaysAgo);
      }).length;

      return {
        'totalBookings': totalBookings,
        'totalRevenue': totalRevenue,
        'confirmedBookings': confirmedBookings,
        'completedBookings': completedBookings,
        'cancelledBookings': cancelledBookings,
        'totalHotels': totalHotels,
        'approvedHotels': approvedHotels,
        'totalGuests': totalGuests,
        'recentBookings': recentBookings,
        'averageBookingValue': totalBookings > 0
            ? totalRevenue / totalBookings
            : 0.0,
        'pendingInspections': pendingInspections,
        'complianceIssues': complianceIssues,
      };
    } catch (e, s) {
      print(s);
      print('Error getting dashboard stats: $e');
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  // Get revenue analytics by time period
  Future<Map<String, dynamic>> getRevenueAnalytics({
    String period = 'monthly', // 'daily', 'weekly', 'monthly', 'yearly'
    int limit = 12,
  }) async {
    try {
      final bookingsSnapshot = await _firestore.collection('bookings').get();

      Map<String, double> revenueByPeriod = {};
      Map<String, int> bookingsByPeriod = {};

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final totalPrice = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

        if (createdAt != null) {
          String periodKey;

          switch (period) {
            case 'daily':
              periodKey =
                  '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
              break;
            case 'weekly':
              final weekStart = createdAt.subtract(
                Duration(days: createdAt.weekday - 1),
              );
              periodKey =
                  '${weekStart.year}-W${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
              break;
            case 'monthly':
              periodKey =
                  '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
              break;
            case 'yearly':
              periodKey = '${createdAt.year}';
              break;
            default:
              periodKey =
                  '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          }

          revenueByPeriod[periodKey] =
              (revenueByPeriod[periodKey] ?? 0) + totalPrice;
          bookingsByPeriod[periodKey] = (bookingsByPeriod[periodKey] ?? 0) + 1;
        }
      }

      // Sort by period and limit
      final sortedEntries = revenueByPeriod.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));

      final limitedEntries = sortedEntries.take(limit).toList();

      return {
        'revenueByPeriod': Map.fromEntries(limitedEntries),
        'bookingsByPeriod': Map.fromEntries(
          bookingsByPeriod.entries.where(
            (entry) => limitedEntries.any((e) => e.key == entry.key),
          ),
        ),
        'period': period,
      };
    } catch (e) {
      print('Error getting revenue analytics: $e');
      throw Exception('Failed to get revenue analytics: $e');
    }
  }

  // Get hotel performance analytics
  Future<List<Map<String, dynamic>>> getHotelPerformance({
    int limit = 20,
  }) async {
    try {
      final hotelsSnapshot = await _firestore.collection('hotels').get();
      final bookingsSnapshot = await _firestore.collection('bookings').get();

      Map<String, Map<String, dynamic>> hotelStats = {};

      // Initialize hotel stats
      for (var hotelDoc in hotelsSnapshot.docs) {
        final hotelData = hotelDoc.data();
        hotelStats[hotelDoc.id] = {
          'hotelId': hotelDoc.id,
          'hotelName': hotelData['hotelName'] ?? 'Unknown Hotel',
          'totalBookings': 0,
          'totalRevenue': 0.0,
          'completedBookings': 0,
          'cancelledBookings': 0,
          'averageRating': hotelData['averageRating'] ?? 0.0,
          'starRate': hotelData['starRate'] ?? 0,
        };
      }

      // Calculate booking stats per hotel
      for (var bookingDoc in bookingsSnapshot.docs) {
        final bookingData = bookingDoc.data();
        final hotelId = bookingData['hotelId'] as String?;
        final totalPrice =
            (bookingData['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final status =
            (bookingData['bookingStatus'] as String?)?.toLowerCase() ?? '';

        if (hotelId != null && hotelStats.containsKey(hotelId)) {
          hotelStats[hotelId]!['totalBookings']++;
          hotelStats[hotelId]!['totalRevenue'] += totalPrice;

          if (status == 'completed') {
            hotelStats[hotelId]!['completedBookings']++;
          } else if (status == 'cancelled') {
            hotelStats[hotelId]!['cancelledBookings']++;
          }
        }
      }

      // Convert to list and sort by revenue
      final hotelList = hotelStats.values.toList();
      hotelList.sort(
        (a, b) => (b['totalRevenue'] as double).compareTo(
          a['totalRevenue'] as double,
        ),
      );

      return hotelList.take(limit).toList();
    } catch (e) {
      print('Error getting hotel performance: $e');
      throw Exception('Failed to get hotel performance: $e');
    }
  }

  // Get location-based analytics
  Future<Map<String, dynamic>> getLocationAnalytics() async {
    try {
      final hotelsSnapshot = await _firestore.collection('hotels').get();
      final bookingsSnapshot = await _firestore.collection('bookings').get();

      Map<String, Map<String, dynamic>> locationStats = {};

      // Count hotels by state
      for (var hotelDoc in hotelsSnapshot.docs) {
        final hotelData = hotelDoc.data();
        final state = hotelData['hotelState'] as String?;
        final city = hotelData['hotelCity'] as String?;

        if (state != null) {
          if (!locationStats.containsKey(state)) {
            locationStats[state] = {
              'state': state,
              'totalHotels': 0,
              'approvedHotels': 0,
              'totalBookings': 0,
              'totalRevenue': 0.0,
              'cities': <String, Map<String, dynamic>>{},
            };
          }

          locationStats[state]!['totalHotels']++;
          if (hotelData['approved'] == true) {
            locationStats[state]!['approvedHotels']++;
          }

          // City stats
          if (city != null) {
            if (!locationStats[state]!['cities'].containsKey(city)) {
              locationStats[state]!['cities'][city] = {
                'city': city,
                'totalHotels': 0,
                'approvedHotels': 0,
                'totalBookings': 0,
                'totalRevenue': 0.0,
              };
            }

            locationStats[state]!['cities'][city]['totalHotels']++;
            if (hotelData['approved'] == true) {
              locationStats[state]!['cities'][city]['approvedHotels']++;
            }
          }
        }
      }

      // Calculate booking stats by location
      for (var bookingDoc in bookingsSnapshot.docs) {
        final bookingData = bookingDoc.data();
        final hotelId = bookingData['hotelId'] as String?;
        final totalPrice =
            (bookingData['totalAmount'] as num?)?.toDouble() ?? 0.0;

        if (hotelId != null) {
          // Find hotel and update location stats
          final hotelDoc = hotelsSnapshot.docs.firstWhere(
            (doc) => doc.id == hotelId,
            orElse: () => hotelsSnapshot.docs.first,
          );

          if (hotelDoc.exists) {
            final hotelData = hotelDoc.data();
            final state = hotelData['hotelState'] as String?;
            final city = hotelData['hotelCity'] as String?;

            if (state != null && locationStats.containsKey(state)) {
              locationStats[state]!['totalBookings']++;
              locationStats[state]!['totalRevenue'] += totalPrice;

              if (city != null &&
                  locationStats[state]!['cities'].containsKey(city)) {
                locationStats[state]!['cities'][city]['totalBookings']++;
                locationStats[state]!['cities'][city]['totalRevenue'] +=
                    totalPrice;
              }
            }
          }
        }
      }

      return {'locations': locationStats.values.toList()};
    } catch (e) {
      print('Error getting location analytics: $e');
      throw Exception('Failed to get location analytics: $e');
    }
  }

  // Get occupancy rates (simplified version)
  Future<Map<String, dynamic>> getOccupancyRates() async {
    try {
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      // Get bookings for current month
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('checkInDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('checkInDate', isLessThan: Timestamp.fromDate(nextMonth))
          .get();

      Map<String, int> hotelBookings = {};
      int totalBookings = bookingsSnapshot.docs.length;

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final hotelId = data['hotelId'] as String?;
        if (hotelId != null) {
          hotelBookings[hotelId] = (hotelBookings[hotelId] ?? 0) + 1;
        }
      }

      // Calculate average occupancy (simplified)
      final hotelsSnapshot = await _firestore.collection('hotels').get();
      final totalHotels = hotelsSnapshot.docs.length;
      final averageBookingsPerHotel = totalHotels > 0
          ? totalBookings / totalHotels
          : 0.0;

      return {
        'totalBookings': totalBookings,
        'totalHotels': totalHotels,
        'averageBookingsPerHotel': averageBookingsPerHotel,
        'occupancyRate': totalHotels > 0
            ? (averageBookingsPerHotel / 30) * 100
            : 0.0,
        // Simplified daily rate
        'hotelBookings': hotelBookings,
      };
    } catch (e) {
      print('Error getting occupancy rates: $e');
      throw Exception('Failed to get occupancy rates: $e');
    }
  }

  // Get guest satisfaction scores (from reviews/ratings)
  Future<Map<String, dynamic>> getGuestSatisfaction() async {
    try {
      // Get all hotels with ratings
      final hotelsSnapshot = await _firestore.collection('hotels').get();

      double totalRating = 0.0;
      int ratedHotels = 0;
      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in hotelsSnapshot.docs) {
        final data = doc.data();
        final rating = (data['averageRating'] as num?)?.toDouble();

        if (rating != null && rating > 0) {
          totalRating += rating;
          ratedHotels++;

          // Distribution (simplified)
          int roundedRating = rating.round().clamp(1, 5);
          ratingDistribution[roundedRating] =
              (ratingDistribution[roundedRating] ?? 0) + 1;
        }
      }

      return {
        'averageRating': ratedHotels > 0 ? totalRating / ratedHotels : 0.0,
        'ratedHotels': ratedHotels,
        'totalHotels': hotelsSnapshot.docs.length,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('Error getting guest satisfaction: $e');
      throw Exception('Failed to get guest satisfaction: $e');
    }
  }

  // Get booking trends and patterns
  Future<Map<String, dynamic>> getBookingTrends() async {
    try {
      final bookingsSnapshot = await _firestore.collection('bookings').get();

      Map<String, int> bookingsByDayOfWeek = {};
      Map<String, int> bookingsByMonth = {};
      Map<int, int> bookingsByHour = {};

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        if (createdAt != null) {
          // Day of week
          final dayName = _getDayName(createdAt.weekday);
          bookingsByDayOfWeek[dayName] =
              (bookingsByDayOfWeek[dayName] ?? 0) + 1;

          // Month
          final monthName = _getMonthName(createdAt.month);
          bookingsByMonth[monthName] = (bookingsByMonth[monthName] ?? 0) + 1;

          // Hour
          bookingsByHour[createdAt.hour] =
              (bookingsByHour[createdAt.hour] ?? 0) + 1;
        }
      }

      return {
        'bookingsByDayOfWeek': bookingsByDayOfWeek,
        'bookingsByMonth': bookingsByMonth,
        'bookingsByHour': bookingsByHour,
        'totalBookings': bookingsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting booking trends: $e');
      throw Exception('Failed to get booking trends: $e');
    }
  }

  // Helper methods
  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // Cache analytics data (simplified in-memory cache)
  final Map<String, dynamic> _cache = {};
  DateTime? _cacheTimestamp;

  Future<Map<String, dynamic>> getCachedAnalytics(
    String key,
    Duration cacheDuration,
  ) async {
    final now = DateTime.now();

    if (_cacheTimestamp != null &&
        now.difference(_cacheTimestamp!) < cacheDuration &&
        _cache.containsKey(key)) {
      return _cache[key]!;
    }

    // Cache miss - fetch fresh data
    dynamic data;
    switch (key) {
      case 'dashboard':
        data = await getDashboardStats();
        break;
      case 'revenue':
        data = await getRevenueAnalytics();
        break;
      case 'hotel_performance':
        data = await getHotelPerformance();
        break;
      case 'location':
        data = await getLocationAnalytics();
        break;
      case 'occupancy':
        data = await getOccupancyRates();
        break;
      case 'satisfaction':
        data = await getGuestSatisfaction();
        break;
      case 'trends':
        data = await getBookingTrends();
        break;
      default:
        throw Exception('Unknown analytics key: $key');
    }

    // Update cache
    _cache[key] = data;
    _cacheTimestamp = now;

    return data;
  }

  // Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamp = null;
  }
}
