import 'package:flutter/material.dart' hide Notification;
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/models/guest.dart';
import 'package:hotel_booking_app/models/notification.dart';
import 'package:hotel_booking_app/models/review.dart';
import 'package:hotel_booking_app/services/guest_service.dart';

class GuestProvider with ChangeNotifier {
  final GuestService _guestService = GuestService();

  Guest? _currentGuest;
  List<Booking> _bookings = [];
  List<Review> _reviews = [];
  List<Notification> _notifications = [];

  Guest? get currentGuest => _currentGuest;
  List<Booking> get bookings => _bookings;
  List<Review> get reviews => _reviews;
  List<Notification> get notifications => _notifications;

  void setCurrentGuest(Guest guest) {
    _currentGuest = guest;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentGuest == null) return;
    await _guestService.updateGuest(_currentGuest!.guestId, updates);
    // Reload guest data if needed
    notifyListeners();
  }

  Future<void> loadBookings() async {
    if (_currentGuest == null) return;
    _bookings = await _guestService.getGuestBookingHistory(
      _currentGuest!.guestId,
    );
    notifyListeners();
  }

  Future<void> loadReviews() async {
    if (_currentGuest == null) return;
    _reviews = await _guestService.getGuestReviews(_currentGuest!.guestId);
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    if (_currentGuest == null) return;
    _notifications = await _guestService.getGuestNotifications(
      _currentGuest!.guestId,
    );
    notifyListeners();
  }

  Future<void> loadAllData() async {
    await loadBookings();
    await loadReviews();
    await loadNotifications();
  }
}
