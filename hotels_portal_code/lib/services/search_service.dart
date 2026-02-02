import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/hotel.dart';

class SearchFilters {
  final String? location;
  final String? city;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? amenities;
  final int? minStarRating;
  final int? maxStarRating;
  final String? searchQuery;

  SearchFilters({
    this.location,
    this.city,
    this.checkInDate,
    this.checkOutDate,
    this.minPrice,
    this.maxPrice,
    this.amenities,
    this.minStarRating,
    this.maxStarRating,
    this.searchQuery,
  });

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'checkInDate': checkInDate?.toIso8601String(),
      'checkOutDate': checkOutDate?.toIso8601String(),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'amenities': amenities,
      'minStarRating': minStarRating,
      'maxStarRating': maxStarRating,
      'searchQuery': searchQuery,
    };
  }
}

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Advanced hotel search with multiple filters
  Future<List<Hotel>> searchHotels({
    required SearchFilters filters,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection('hotels');

      // Apply filters
      if (filters.location != null && filters.location!.isNotEmpty) {
        // Search in hotelState, hotelCity, or hotelAddress
        query = query.where('hotelState', isEqualTo: filters.location);
      }

      if (filters.city != null && filters.city!.isNotEmpty) {
        query = query.where('hotelCity', isEqualTo: filters.city);
      }

      if (filters.minStarRating != null) {
        query = query.where(
          'starRate',
          isGreaterThanOrEqualTo: filters.minStarRating,
        );
      }

      if (filters.maxStarRating != null) {
        query = query.where(
          'starRate',
          isLessThanOrEqualTo: filters.maxStarRating,
        );
      }

      // Only approved hotels
      query = query.where('approved', isEqualTo: true);

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      List<Hotel> hotels = [];

      for (var doc in snapshot.docs) {
        try {
          Hotel hotel = Hotel.fromMap(doc.data() as Map<String, dynamic>);

          // Additional filtering that can't be done in Firestore query
          bool matchesFilters = true;

          // Price filtering (would need room data)
          if (filters.minPrice != null || filters.maxPrice != null) {
            // Get rooms for this hotel
            final roomsSnapshot = await _firestore
                .collection('rooms')
                .where('hotelId', isEqualTo: hotel.hotelId)
                .get();

            bool hasMatchingRoom = false;
            for (var roomDoc in roomsSnapshot.docs) {
              final roomData = roomDoc.data();
              final price = roomData['pricePerNight'] as double? ?? 0.0;

              if ((filters.minPrice == null || price >= filters.minPrice!) &&
                  (filters.maxPrice == null || price <= filters.maxPrice!)) {
                hasMatchingRoom = true;
                break;
              }
            }

            if (!hasMatchingRoom) {
              matchesFilters = false;
            }
          }

          // Amenities filtering
          if (filters.amenities != null && filters.amenities!.isNotEmpty) {
            final hotelData = doc.data() as Map<String, dynamic>;
            final hotelAmenities =
                hotelData['amenities'] as List<dynamic>? ?? [];
            final hasAllAmenities = filters.amenities!.every(
              (amenity) => hotelAmenities.contains(amenity),
            );

            if (!hasAllAmenities) {
              matchesFilters = false;
            }
          }

          // Availability filtering (check-in/check-out dates)
          if (filters.checkInDate != null && filters.checkOutDate != null) {
            final isAvailable = await _checkHotelAvailability(
              hotel.hotelId,
              filters.checkInDate!,
              filters.checkOutDate!,
            );

            if (!isAvailable) {
              matchesFilters = false;
            }
          }

          // Text search filtering
          if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
            final query = filters.searchQuery!.toLowerCase();
            final matchesSearch =
                hotel.hotelName.toLowerCase().contains(query) ||
                hotel.hotelDescription.toLowerCase().contains(query) ||
                hotel.hotelCity.toLowerCase().contains(query) ||
                hotel.hotelState.toLowerCase().contains(query);

            if (!matchesSearch) {
              matchesFilters = false;
            }
          }

          if (matchesFilters) {
            hotels.add(hotel);
          }
        } catch (e) {
          print('Error parsing hotel ${doc.id}: $e');
          continue;
        }
      }

      return hotels;
    } catch (e) {
      print('Error searching hotels: $e');
      throw Exception('Failed to search hotels: $e');
    }
  }

  // Check hotel availability for given dates
  Future<bool> _checkHotelAvailability(
    String hotelId,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    try {
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: hotelId)
          .where('bookingStatus', whereIn: ['confirmed', 'checked_in'])
          .get();

      // Check if any booking overlaps with the requested dates
      for (var bookingDoc in bookingsSnapshot.docs) {
        final booking = bookingDoc.data();
        final bookingCheckIn = (booking['checkInDate'] as Timestamp).toDate();
        final bookingCheckOut = (booking['checkOutDate'] as Timestamp).toDate();

        // Check for date overlap
        if (checkIn.isBefore(bookingCheckOut) &&
            checkOut.isAfter(bookingCheckIn)) {
          return false; // Overlap found
        }
      }

      return true; // No overlaps, hotel is available
    } catch (e) {
      print('Error checking hotel availability: $e');
      // If permission denied or other error, assume hotel is available
      // This allows search results to show hotels even if we can't check bookings
      return true;
    }
  }

  // Get popular hotels (based on booking count)
  Future<List<Hotel>> getPopularHotels({int limit = 10}) async {
    try {
      // Get hotels with most bookings in the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
          )
          .where(
            'bookingStatus',
            whereIn: ['confirmed', 'checked_in', 'completed'],
          )
          .get();

      // Count bookings per hotel
      Map<String, int> hotelBookingCounts = {};
      for (var bookingDoc in bookingsSnapshot.docs) {
        final hotelId = bookingDoc.data()['hotelId'] as String?;
        if (hotelId != null) {
          hotelBookingCounts[hotelId] = (hotelBookingCounts[hotelId] ?? 0) + 1;
        }
      }

      // Sort hotels by booking count
      final entries = hotelBookingCounts.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));
      final sortedHotelIds = entries.take(limit).map((e) => e.key).toList();

      // Fetch hotel details
      List<Hotel> popularHotels = [];
      for (var hotelId in sortedHotelIds) {
        try {
          final hotelDoc = await _firestore
              .collection('hotels')
              .doc(hotelId)
              .get();
          if (hotelDoc.exists) {
            final hotel = Hotel.fromMap(hotelDoc.data()!);
            popularHotels.add(hotel);
          }
        } catch (e) {
          print('Error fetching popular hotel $hotelId: $e');
          continue;
        }
      }

      return popularHotels;
    } catch (e) {
      print('Error getting popular hotels: $e');
      throw Exception('Failed to get popular hotels: $e');
    }
  }

  // Get recommended hotels for a guest (based on past bookings and preferences)
  Future<List<Hotel>> getRecommendedHotels(
    String guestId, {
    int limit = 10,
  }) async {
    try {
      // Get guest's past bookings
      final pastBookingsSnapshot = await _firestore
          .collection('bookings')
          .where('guestId', isEqualTo: guestId)
          .where('bookingStatus', isEqualTo: 'completed')
          .get();

      // Analyze preferences from past bookings
      Set<String> preferredStates = {};
      Set<String> preferredCities = {};
      Set<int> preferredStarRatings = {};

      for (var bookingDoc in pastBookingsSnapshot.docs) {
        final booking = bookingDoc.data();
        final hotelId = booking['hotelId'] as String?;

        if (hotelId != null) {
          try {
            final hotelDoc = await _firestore
                .collection('hotels')
                .doc(hotelId)
                .get();
            if (hotelDoc.exists) {
              final hotelData = hotelDoc.data()!;
              preferredStates.add(hotelData['hotelState']);
              preferredCities.add(hotelData['hotelCity']);
              preferredStarRatings.add(hotelData['starRate']);
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Build recommendation query
      Query query = _firestore
          .collection('hotels')
          .where('approved', isEqualTo: true)
          .limit(limit * 2); // Get more to filter

      // Apply preference filters if available
      if (preferredStates.isNotEmpty) {
        query = query.where(
          'hotelState',
          whereIn: preferredStates.take(10).toList(),
        );
      }

      if (preferredStarRatings.isNotEmpty) {
        final avgRating =
            preferredStarRatings.reduce((a, b) => a + b) /
            preferredStarRatings.length;
        query = query.where(
          'starRate',
          isGreaterThanOrEqualTo: avgRating.round(),
        );
      }

      final snapshot = await query.get();
      List<Hotel> recommendations = [];

      for (var doc in snapshot.docs) {
        try {
          final hotel = Hotel.fromMap(doc.data() as Map<String, dynamic>);
          recommendations.add(hotel);
        } catch (e) {
          continue;
        }
      }

      // Shuffle and limit results
      recommendations.shuffle();
      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error getting recommended hotels: $e');
      // Fallback to popular hotels
      return getPopularHotels(limit: limit);
    }
  }

  // Get search suggestions/autocomplete
  Future<List<String>> getSearchSuggestions(
    String query, {
    int limit = 10,
  }) async {
    try {
      if (query.isEmpty) return [];

      final lowercaseQuery = query.toLowerCase();

      // Search in hotel names, cities, and states
      final hotelsSnapshot = await _firestore
          .collection('hotels')
          .where('approved', isEqualTo: true)
          .limit(100) // Get more to filter
          .get();

      Set<String> suggestions = {};

      for (var doc in hotelsSnapshot.docs) {
        final data = doc.data();
        final name = data['hotelName'] as String? ?? '';
        final city = data['hotelCity'] as String? ?? '';
        final state = data['hotelState'] as String? ?? '';

        // Add matching suggestions
        if (name.toLowerCase().contains(lowercaseQuery)) {
          suggestions.add(name);
        }
        if (city.toLowerCase().contains(lowercaseQuery)) {
          suggestions.add(city);
        }
        if (state.toLowerCase().contains(lowercaseQuery)) {
          suggestions.add(state);
        }
      }

      // Convert to list and sort by relevance
      final suggestionsList = suggestions.toList();
      suggestionsList.sort((a, b) {
        final aStartsWith = a.toLowerCase().startsWith(lowercaseQuery);
        final bStartsWith = b.toLowerCase().startsWith(lowercaseQuery);

        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;

        return a.compareTo(b);
      });

      return suggestionsList.take(limit).toList();
    } catch (e) {
      print('Error getting search suggestions: $e');
      return [];
    }
  }

  // Save search history for analytics
  Future<void> saveSearchHistory(String guestId, SearchFilters filters) async {
    try {
      await _firestore.collection('search_history').add({
        'guestId': guestId,
        'filters': filters.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving search history: $e');
      // Don't throw - search history is not critical
    }
  }

  // Get hotels by location (state/city)
  Future<List<Hotel>> getHotelsByLocation(
    String location, {
    int limit = 50,
  }) async {
    try {
      final filters = SearchFilters(location: location);
      return searchHotels(filters: filters, limit: limit);
    } catch (e) {
      print('Error getting hotels by location: $e');
      throw Exception('Failed to get hotels by location: $e');
    }
  }

  // Get hotels by price range
  Future<List<Hotel>> getHotelsByPriceRange(
    double minPrice,
    double maxPrice, {
    int limit = 50,
  }) async {
    try {
      final filters = SearchFilters(minPrice: minPrice, maxPrice: maxPrice);
      return searchHotels(filters: filters, limit: limit);
    } catch (e) {
      print('Error getting hotels by price range: $e');
      throw Exception('Failed to get hotels by price range: $e');
    }
  }

  // Get hotels by star rating
  Future<List<Hotel>> getHotelsByStarRating(
    int minStars, {
    int limit = 50,
  }) async {
    try {
      final filters = SearchFilters(minStarRating: minStars);
      return searchHotels(filters: filters, limit: limit);
    } catch (e) {
      print('Error getting hotels by star rating: $e');
      throw Exception('Failed to get hotels by star rating: $e');
    }
  }
}
