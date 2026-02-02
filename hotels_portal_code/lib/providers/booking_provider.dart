import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/services/booking_service.dart';

class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<Booking> _bookings = [];
  List<Booking> _hotelBookings = [];
  List<Booking> _userBookings = [];
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  List<Booking> get hotelBookings => _hotelBookings;
  List<Booking> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookings = await _bookingService.getAllBookings();
    } catch (e) {
      _error = e.toString();
      print("Error fetching bookings: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookingsForHotel(String hotelId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _hotelBookings = await _bookingService.getBookingsByHotelId(hotelId);
    } catch (e) {
      _error = e.toString();
      print("Error fetching hotel bookings: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookingsForUser(String guestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userBookings = await _bookingService.getBookingsByGuest(guestId);
    } catch (e) {
      _error = e.toString();
      print("Error fetching user bookings: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBookingStatus(
    String bookingId,
    String status,
    String hotelId,
  ) async {
    try {
      await _bookingService.updateBooking(bookingId, {'bookingStatus': status});
      // Refresh the list after updating
      await fetchBookingsForHotel(hotelId);
    } catch (e) {
      _error = e.toString();
      print("Error updating booking status: $_error");
      notifyListeners();
    }
  }
}
