import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/models/review.dart';
import 'package:hotel_booking_app/models/room.dart';
import 'package:hotel_booking_app/services/booking_service.dart';
import 'package:hotel_booking_app/services/connectivity_service.dart';
import 'package:hotel_booking_app/services/guest_service.dart';
import 'package:hotel_booking_app/services/hotel_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HotelProvider with ChangeNotifier {
  final HotelService _hotelService = HotelService();
  final GuestService _guestService = GuestService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final BookingService _bookingService = BookingService(); // ADD INSTANCE

  List<Hotel> _hotels = [];
  Hotel? _selectedHotel;
  List<Room> _rooms = [];
  List<Review> _reviews = [];
  bool _isLoadingMore = false;
  bool _hasMoreHotels = true;
  DocumentSnapshot? _lastHotelDoc;
  String? _error;
  bool _isLoading = false;
  Hotel? _hotel;
  List<Hotel> _featuredHotels = [];
  List<Hotel> _favoriteHotels = [];

  List<Hotel> get hotels => _hotels;
  Hotel? get selectedHotel => _selectedHotel;
  List<Room> get rooms => _rooms;
  List<Review> get reviews => _reviews;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreHotels => _hasMoreHotels;
  String? get error => _error;
  bool get isLoading => _isLoading;
  Hotel? get hotel => _hotel;
  List<Hotel> get featuredHotels => _featuredHotels;
  List<Hotel> get favoriteHotels => _favoriteHotels;

  Future<void> _cacheHotels(List<Hotel> hotels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = hotels
          .map((hotel) => jsonEncode(hotel.toJson()))
          .toList();
      await prefs.setStringList('cached_hotels', jsonList);
    } catch (e) {
      print('Error caching hotels: $e');
    }
  }

  Future<List<Hotel>> _loadCachedHotels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('cached_hotels') ?? [];
      return jsonList
          .map((jsonStr) => Hotel.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      print('Error loading cached hotels: $e');
      return [];
    }
  }

  Future<void> loadHotels({
    bool loadMore = false,
    bool approvedOnly = false,
  }) async {
    if (loadMore && (_isLoadingMore || !_hasMoreHotels)) return;

    if (!loadMore) {
      _isLoading = true;
      _error = null;
    }
    _isLoadingMore = true;
    notifyListeners();

    try {
      final isConnected = await _connectivityService.isConnected;

      List<Hotel> newHotels;

      if (!isConnected && !loadMore) {
        // Load from cache if offline and initial load
        newHotels = await _loadCachedHotels();
        if (newHotels.isEmpty) {
          throw Exception(
            'No cached data available. Please check your connection.',
          );
        }
        _hasMoreHotels = false; // No more loading from cache
      } else {
        // Online: fetch from service
        Map<String, dynamic> result = await _hotelService.getAllHotels(
          limit: 20,
          startAfter: loadMore ? _lastHotelDoc : null,
          approvedOnly: approvedOnly,
        );

        newHotels = result['hotels'] as List<Hotel>;

        if (newHotels.length < 20) {
          _hasMoreHotels = false;
        }

        _lastHotelDoc = result['lastDocument'] as DocumentSnapshot?;

        // Cache the new hotels if online
        await _cacheHotels(newHotels);
      }

      if (loadMore) {
        _hotels.addAll(newHotels);
      } else {
        _hotels = newHotels;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading hotels: $e');
    } finally {
      _isLoadingMore = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectHotel(Hotel hotel) {
    _selectedHotel = hotel;
    notifyListeners();
  }

  Future<void> loadRooms(String hotelId) async {
    _isLoading = true;
    _rooms = [];
    notifyListeners();
    try {
      _rooms = await _hotelService.getHotelRooms(hotelId);
      _error = null;
    } catch (e) {
      _error = "Failed to load rooms: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReviews(String hotelId) async {
    _isLoading = true;
    _reviews = [];
    notifyListeners();
    try {
      _reviews = await _guestService.getHotelReviews(hotelId);
      _error = null;
    } catch (e) {
      _error = "Failed to load reviews: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRoom(Room room) async {
    try {
      await _hotelService.addHotelRoom(room.hotelId, room);
      await loadRooms(room.hotelId);
    } catch (e) {
      _error = "Failed to add room: $e";
      notifyListeners();
    }
  }

  Future<void> updateRoom(Room room) async {
    try {
      await _hotelService.updateHotelRoom(room.roomId, room.toMap());
      await loadRooms(room.hotelId);
    } catch (e) {
      _error = "Failed to update room: $e";
      notifyListeners();
    }
  }

  Future<void> getHotel(String hotelId) async {
    _isLoading = true;
    _hotel = await _hotelService.getHotel(hotelId);
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> createBooking(
    Booking booking,
    String guestId,
    String guestName,
  ) async {
    try {
      String bookingId = await _bookingService.createBooking(
        booking,
        guestId,
        guestName,
      );
      notifyListeners();
      return bookingId;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> fetchFeaturedHotels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _featuredHotels = await _hotelService.getTopRatedHotels(limit: 5);
    } catch (e) {
      _error = e.toString();
      print('Error fetching featured hotels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFavoriteHotels(List<String> hotelIds) async {
    _isLoading = true;
    _error = null;
    _favoriteHotels = []; // Clear previous favorites
    notifyListeners();
    try {
      final List<Hotel> favorites = [];
      for (String id in hotelIds) {
        final hotel = await _hotelService.getHotel(id);
        if (hotel != null) {
          favorites.add(hotel);
        }
      }
      _favoriteHotels = favorites;
    } catch (e) {
      _error = e.toString();
      print('Error fetching favorite hotels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
